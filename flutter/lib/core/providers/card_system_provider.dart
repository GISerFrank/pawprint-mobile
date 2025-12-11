import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../services/services.dart';
import 'service_providers.dart';
import 'pet_provider.dart';

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
final collectibleCardsProvider = FutureProvider<List<CollectibleCard>>((ref) async {
  final petId = ref.watch(selectedPetIdProvider);
  if (petId == null) return [];

  final db = ref.watch(databaseServiceProvider);
  return db.getCollectibleCards(petId);
});

/// 按主题分组的卡牌
final cardsByThemeProvider = FutureProvider<Map<PackTheme, List<CollectibleCard>>>((ref) async {
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
  final GeminiService _gemini;
  final DatabaseService _db;
  final StorageService _storage;
  final Ref _ref;

  CardSystemNotifier(this._gemini, this._db, this._storage, this._ref)
      : super(const CardPackState());

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
      // 扣除金币
      await _db.updateCoins(petId, currentCoins - pack.price);
      _ref.invalidate(currentPetProvider);

      // 生成卡牌
      final generatedCard = await _gemini.generateCollectibleCard(
        imageBase64: avatarBase64,
        theme: pack.theme,
        species: species,
      );

      if (generatedCard == null) {
        // 退还金币
        await _db.updateCoins(petId, currentCoins);
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
      final imageUrl = await _storage.uploadCollectibleCardImage(
        petId: petId,
        cardId: cardId,
        fileBytes: generatedCard.imageData,
      );

      // 保存到数据库
      final savedCard = await _db.createCollectibleCard(CollectibleCard(
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

      state = CardPackState(
        openingState: PackOpeningState.revealing,
        selectedPack: pack,
        newCard: savedCard,
        isLoading: false,
      );
    } catch (e) {
      // 退还金币
      try {
        await _db.updateCoins(petId, currentCoins);
        _ref.invalidate(currentPetProvider);
      } catch (_) {}

      state = state.copyWith(
        openingState: PackOpeningState.idle,
        isLoading: false,
        error: 'Error: $e',
      );
    }
  }

  /// 领取金币
  Future<void> claimCoins(String petId, int currentCoins) async {
    await _db.updateCoins(petId, currentCoins + 100);
    _ref.invalidate(currentPetProvider);
  }

  /// 重置状态
  void reset() {
    state = const CardPackState();
  }
}

/// 卡牌系统 Provider
final cardSystemNotifierProvider = StateNotifierProvider<CardSystemNotifier, CardPackState>((ref) {
  final gemini = ref.watch(geminiServiceProvider);
  final db = ref.watch(databaseServiceProvider);
  final storage = ref.watch(storageServiceProvider);
  return CardSystemNotifier(gemini, db, storage, ref);
});
