import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../services/ai/ai_service_provider.dart';
import 'service_providers.dart';
import 'pet_provider.dart';
import 'auth_provider.dart';

/// 卡包定义
class CardPack {
  final String id;
  final PackTheme theme;
  final String name;
  final String description;
  final String icon;
  final int price;

  const CardPack({
    required this.id,
    required this.theme,
    required this.name,
    required this.description,
    required this.icon,
    required this.price,
  });
}

/// 可用卡包列表
const availablePacks = [
  CardPack(
    id: 'daily',
    theme: PackTheme.daily,
    name: 'Cozy Moments',
    description: 'Sweet everyday memories.',
    icon: '☕',
    price: 50,
  ),
  CardPack(
    id: 'profile',
    theme: PackTheme.profile,
    name: 'Heroic Portraits',
    description: 'Your pet looking epic.',
    icon: '🏆',
    price: 100,
  ),
  CardPack(
    id: 'fun',
    theme: PackTheme.fun,
    name: 'Playtime Fun',
    description: 'Silly and energetic!',
    icon: '🎾',
    price: 75,
  ),
  CardPack(
    id: 'sticker',
    theme: PackTheme.sticker,
    name: 'Pop Stickers',
    description: 'Bold and collectable.',
    icon: '⭐',
    price: 150,
  ),
];

/// 当前宠物的卡牌收藏
final collectibleCardsProvider =
    FutureProvider<List<CollectibleCard>>((ref) async {
  final petId = ref.watch(selectedPetIdProvider);
  if (petId == null) return [];

  if (AppConfig.useLocalMode) {
    final localStorage = ref.watch(localStorageServiceProvider);
    return localStorage.getCollectibleCards(petId);
  } else {
    final db = ref.watch(databaseServiceProvider);
    return db.getCollectibleCards(petId);
  }
});

/// 按主题分组的卡牌
final cardsByThemeProvider =
    FutureProvider<Map<PackTheme, List<CollectibleCard>>>((ref) async {
  final cards = await ref.watch(collectibleCardsProvider.future);

  final grouped = <PackTheme, List<CollectibleCard>>{};
  for (final theme in PackTheme.values) {
    grouped[theme] = cards.where((c) => c.theme == theme).toList();
  }

  return grouped;
});

/// 卡牌开包状态
enum PackOpeningState { idle, shaking, revealing }

class CardPackState {
  final PackOpeningState openingState;
  final CardPack? selectedPack;
  final CollectibleCard? newCard;
  final bool isLoading;
  final String? error;

  const CardPackState({
    this.openingState = PackOpeningState.idle,
    this.selectedPack,
    this.newCard,
    this.isLoading = false,
    this.error,
  });

  CardPackState copyWith({
    PackOpeningState? openingState,
    CardPack? selectedPack,
    CollectibleCard? newCard,
    bool? isLoading,
    String? error,
  }) {
    return CardPackState(
      openingState: openingState ?? this.openingState,
      selectedPack: selectedPack ?? this.selectedPack,
      newCard: newCard,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 卡牌系统 Notifier
class CardSystemNotifier extends StateNotifier<CardPackState> {
  final Ref _ref;

  CardSystemNotifier(this._ref) : super(const CardPackState());

  /// 选择卡包
  void selectPack(CardPack pack) {
    state = CardPackState(selectedPack: pack);
  }

  /// 开始开包
  Future<void> openPack({
    required String petId,
    required CardPack pack,
    required String avatarBase64,
    required String species,
    required int currentCoins,
  }) async {
    if (currentCoins < pack.price) {
      state = state.copyWith(error: 'Not enough coins!');
      return;
    }

    state = state.copyWith(
      openingState: PackOpeningState.shaking,
      isLoading: true,
      error: null,
    );

    try {
      CollectibleCard savedCard;

      if (AppConfig.useLocalMode) {
        // 本地模式
        final localStorage = _ref.read(localStorageServiceProvider);

        // 扣除金币
        await localStorage.updatePetCoins(petId, currentCoins - pack.price);
        _ref.invalidate(currentPetProvider);

        // 生成卡牌
        GeneratedCardData? generatedCard;
        final aiService = _ref.read(aiServiceProvider);

        if (aiService != null) {
          // 有 AI 服务，使用 AI 生成
          generatedCard = await aiService.generateCollectibleCard(
            imageBase64: avatarBase64,
            theme: pack.theme,
            species: species,
          );
        }

        if (generatedCard != null) {
          // AI 生成成功
          savedCard = await localStorage.createCollectibleCard(CollectibleCard(
            id: '',
            petId: petId,
            name: generatedCard.name,
            imageUrl: generatedCard.imageBase64,
            description: generatedCard.description,
            rarity: generatedCard.rarity,
            theme: pack.theme,
            tags: generatedCard.tags,
            obtainedAt: DateTime.now(),
          ));
        } else {
          // 无 AI 服务或生成失败，使用 Mock 卡牌
          savedCard = await _createMockCard(
              localStorage, petId, pack, avatarBase64, species);
        }

        _ref.invalidate(collectibleCardsProvider);
      } else {
        // Supabase 模式
        final aiService = _ref.read(aiServiceProvider);
        final db = _ref.read(databaseServiceProvider);
        final storage = _ref.read(storageServiceProvider);

        if (aiService == null) {
          throw Exception('AI service not available');
        }

        // 扣除金币
        await db.updateCoins(petId, currentCoins - pack.price);
        _ref.invalidate(currentPetProvider);

        // 生成卡牌
        final generatedCard = await aiService.generateCollectibleCard(
          imageBase64: avatarBase64,
          theme: pack.theme,
          species: species,
        );

        if (generatedCard == null) {
          // 退还金币
          await db.updateCoins(petId, currentCoins);
          _ref.invalidate(currentPetProvider);
          state = state.copyWith(
            openingState: PackOpeningState.idle,
            isLoading: false,
            error: 'Failed to generate card. Coins refunded.',
          );
          return;
        }

        // 上传卡牌图片
        final cardId = DateTime.now().millisecondsSinceEpoch.toString();
        // generatedCard.imageBase64 可能是 URL 或 base64，需要处理
        String imageUrl;
        if (generatedCard.imageBase64.startsWith('http')) {
          // 已经是 URL，直接使用
          imageUrl = generatedCard.imageBase64;
        } else {
          // 是 base64，需要上传
          // 先解码 base64 为 bytes
          final base64Data = generatedCard.imageBase64.contains(',')
              ? generatedCard.imageBase64.split(',').last
              : generatedCard.imageBase64;
          final bytes = base64Decode(base64Data);
          imageUrl = await storage.uploadCollectibleCardImage(
            petId: petId,
            cardId: cardId,
            fileBytes: bytes,
          );
        }

        // 保存到数据库
        savedCard = await db.createCollectibleCard(CollectibleCard(
          id: '',
          petId: petId,
          name: generatedCard.name,
          imageUrl: imageUrl,
          description: generatedCard.description,
          rarity: generatedCard.rarity,
          theme: pack.theme,
          tags: generatedCard.tags,
          obtainedAt: DateTime.now(),
        ));

        _ref.invalidate(collectibleCardsProvider);
      }

      state = CardPackState(
        openingState: PackOpeningState.revealing,
        selectedPack: pack,
        newCard: savedCard,
        isLoading: false,
      );
    } catch (e) {
      // 退还金币
      try {
        if (AppConfig.useLocalMode) {
          final localStorage = _ref.read(localStorageServiceProvider);
          await localStorage.updatePetCoins(petId, currentCoins);
        } else {
          final db = _ref.read(databaseServiceProvider);
          await db.updateCoins(petId, currentCoins);
        }
        _ref.invalidate(currentPetProvider);
      } catch (_) {}

      state = state.copyWith(
        openingState: PackOpeningState.idle,
        isLoading: false,
        error: 'Error: $e',
      );
    }
  }

  /// 创建 Mock 卡牌（本地模式无 API Key 时使用）
  Future<CollectibleCard> _createMockCard(
    LocalStorageService localStorage,
    String petId,
    CardPack pack,
    String avatarBase64,
    String species,
  ) async {
    // 随机稀有度
    final rarities = [
      Rarity.common,
      Rarity.common,
      Rarity.common,
      Rarity.rare,
      Rarity.rare,
      Rarity.epic,
      Rarity.legendary
    ];
    final rarity = rarities[DateTime.now().millisecond % rarities.length];

    // 生成名字
    final names = {
      PackTheme.daily: [
        'Cozy Nap',
        'Sunny Day',
        'Snack Time',
        'Morning Stretch'
      ],
      PackTheme.profile: [
        'Noble Guardian',
        'Majestic One',
        'The Champion',
        'Royal Portrait'
      ],
      PackTheme.fun: [
        'Party Animal',
        'Silly Moment',
        'Playful Spirit',
        'Goofy Time'
      ],
      PackTheme.sticker: [
        'Pop Star',
        'Sticker Bomb',
        'Neon Vibes',
        'Retro Cool'
      ],
    };
    final name =
        names[pack.theme]![DateTime.now().second % names[pack.theme]!.length];

    // 生成描述
    final descriptions = [
      'A rare glimpse into $species life.',
      'Captured in the perfect moment.',
      'Pure joy in one image.',
      'This one is special!',
    ];
    final description =
        descriptions[DateTime.now().millisecond % descriptions.length];

    return await localStorage.createCollectibleCard(CollectibleCard(
      id: '',
      petId: petId,
      name: name,
      imageUrl: avatarBase64, // 使用原始头像作为卡牌图片
      description: description,
      rarity: rarity,
      theme: pack.theme,
      tags: [
        pack.theme.displayName.toLowerCase(),
        rarity.displayName.toLowerCase()
      ],
      obtainedAt: DateTime.now(),
    ));
  }

  /// 领取金币
  Future<void> claimCoins(String petId, int currentCoins) async {
    if (AppConfig.useLocalMode) {
      final localStorage = _ref.read(localStorageServiceProvider);
      await localStorage.updatePetCoins(petId, currentCoins + 100);
    } else {
      final db = _ref.read(databaseServiceProvider);
      await db.updateCoins(petId, currentCoins + 100);
    }
    _ref.invalidate(currentPetProvider);
  }

  /// 重置状态
  void reset() {
    state = const CardPackState();
  }
}

/// 卡牌系统 Provider
final cardSystemNotifierProvider =
    StateNotifierProvider<CardSystemNotifier, CardPackState>((ref) {
  return CardSystemNotifier(ref);
});
