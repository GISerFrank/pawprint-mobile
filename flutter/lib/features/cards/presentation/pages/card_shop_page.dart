import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/models/models.dart';
import '../../../../core/providers/providers.dart';
import '../../../../shared/widgets/widgets.dart';

class CardShopPage extends ConsumerStatefulWidget {
  const CardShopPage({super.key});

  @override
  ConsumerState<CardShopPage> createState() => _CardShopPageState();
}

class _CardShopPageState extends ConsumerState<CardShopPage> {
  String _view = 'shop'; // 'shop', 'opening', 'collection', 'detail'
  CardPack? _selectedPack;
  String _openingState = 'idle'; // 'idle', 'shaking', 'revealing'
  CollectibleCard? _newCard;
  CollectibleCard? _selectedCard;

  // 使用 provider 中定义的卡包列表
  List<CardPack> get _packs => availablePacks;

  Future<void> _claimCoins() async {
    final pet = ref.read(currentPetProvider).valueOrNull;
    if (pet == null) return;

    await ref.read(petNotifierProvider.notifier).updateCoins(pet.id, pet.coins + 100);
    if (mounted) {
      showAppNotification(context, message: 'Collected +100 Coins!', type: NotificationType.success);
    }
  }

  Future<void> _openPack(CardPack pack) async {
    final pet = ref.read(currentPetProvider).valueOrNull;
    if (pet == null) return;

    if (pet.avatarUrl == null || pet.avatarUrl!.isEmpty) {
      showAppNotification(context, message: 'Upload a profile photo first!', type: NotificationType.error);
      return;
    }

    if (pet.coins < pack.price) {
      showAppNotification(context, message: 'Not enough coins! Claim daily reward.', type: NotificationType.error);
      return;
    }

    // 金币扣除由 provider 的 openPack 方法处理
    setState(() {
      _selectedPack = pack;
      _view = 'opening';
      _openingState = 'idle';
    });
  }

  Future<void> _startOpening() async {
    if (_selectedPack == null) return;

    final pet = ref.read(currentPetProvider).valueOrNull;
    if (pet == null) return;

    setState(() => _openingState = 'shaking');

    // 调用 provider 的 openPack 方法（会处理金币扣除和卡牌生成）
    await ref.read(cardSystemNotifierProvider.notifier).openPack(
      petId: pet.id,
      pack: _selectedPack!,
      avatarBase64: pet.avatarUrl ?? '',
      species: pet.species.displayName,
      currentCoins: pet.coins,
    );

    // 检查结果
    final cardState = ref.read(cardSystemNotifierProvider);
    
    if (cardState.newCard != null) {
      setState(() {
        _newCard = cardState.newCard;
        _openingState = 'revealing';
      });
      showAppNotification(context, message: 'New card obtained!', type: NotificationType.success);
    } else if (cardState.error != null) {
      // 如果失败，provider 已经处理了金币退还
      showAppNotification(context, message: cardState.error!, type: NotificationType.error);
      setState(() {
        _view = 'shop';
        _openingState = 'idle';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final petAsync = ref.watch(currentPetProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: petAsync.when(
          loading: () => const Center(child: AppLoadingIndicator()),
          error: (e, _) => ErrorStateWidget(message: 'Failed to load', onRetry: () => ref.invalidate(currentPetProvider)),
          data: (pet) {
            if (pet == null) return const Center(child: Text('No pet'));
            
            return switch (_view) {
              'shop' => _ShopView(
                pet: pet,
                packs: _packs,
                onClaimCoins: _claimCoins,
                onOpenPack: _openPack,
                onViewCollection: () => setState(() => _view = 'collection'),
                onClose: () => context.pop(),
              ),
              'opening' => _OpeningView(
                pack: _selectedPack!,
                openingState: _openingState,
                newCard: _newCard,
                onStartOpening: _startOpening,
                onViewCollection: () => setState(() => _view = 'collection'),
                onBack: () => setState(() => _view = 'shop'),
              ),
              'collection' => _CollectionView(
                pet: pet,
                packs: _packs,
                onSelectCard: (card) => setState(() { _selectedCard = card; _view = 'detail'; }),
                onBack: () => setState(() => _view = 'shop'),
              ),
              'detail' => _CardDetailView(
                card: _selectedCard!,
                onBack: () => setState(() => _view = 'collection'),
              ),
              _ => const SizedBox(),
            };
          },
        ),
      ),
    );
  }
}

class _ShopView extends StatelessWidget {
  final Pet pet;
  final List<CardPack> packs;
  final VoidCallback onClaimCoins;
  final Function(CardPack) onOpenPack;
  final VoidCallback onViewCollection;
  final VoidCallback onClose;

  const _ShopView({required this.pet, required this.packs, required this.onClaimCoins, required this.onOpenPack, required this.onViewCollection, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(onPressed: onClose, icon: const Icon(Icons.close), style: IconButton.styleFrom(backgroundColor: AppColors.stone100)),
              GestureDetector(
                onTap: onViewCollection,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.soft),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 18, color: Colors.amber.shade600),
                      const SizedBox(width: 4),
                      Text('${pet.collection?.length ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.stone700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Card Shop', style: Theme.of(context).textTheme.headlineSmall),
                    TextButton.icon(onPressed: onViewCollection, icon: const Icon(Icons.grid_view, size: 18), label: const Text('Collection')),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.stone800, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.monetization_on, color: Colors.white)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Balance', style: TextStyle(color: AppColors.stone400, fontSize: 12)),
                            Text('${pet.coins}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: onClaimCoins,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Get'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.stone700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, mainAxisSpacing: 12, crossAxisSpacing: 12),
                  itemCount: packs.length,
                  itemBuilder: (context, index) {
                    final pack = packs[index];
                    final canAfford = pet.coins >= pack.price;
                    final cardCount = pet.collection?.where((c) => c.theme == pack.theme).length ?? 0;
                    return GestureDetector(
                      onTap: () => onOpenPack(pack),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: _getPackColor(pack.theme), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white, width: 2), boxShadow: AppShadows.soft),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pack.icon, style: const TextStyle(fontSize: 36)),
                            const SizedBox(height: 8),
                            Text(pack.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text(pack.description, style: const TextStyle(fontSize: 11, color: AppColors.stone600)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: canAfford ? Colors.white.withOpacity(0.6) : AppColors.error.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.monetization_on, size: 14, color: canAfford ? AppColors.stone700 : AppColors.error),
                                  const SizedBox(width: 2),
                                  Text('${pack.price}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: canAfford ? AppColors.stone700 : AppColors.error)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
                              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                const Text('Cards', style: TextStyle(fontSize: 11, color: AppColors.stone600)),
                                Text('$cardCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.stone700)),
                              ]),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                if (AppConfig.useLocalMode) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppConfig.geminiApiKey.isNotEmpty ? AppColors.mint100 : AppColors.primary50, 
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          AppConfig.geminiApiKey.isNotEmpty ? Icons.check_circle : Icons.info_outline, 
                          color: AppConfig.geminiApiKey.isNotEmpty ? AppColors.mint500 : AppColors.primary500, 
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppConfig.geminiApiKey.isNotEmpty 
                              ? 'AI-powered card generation enabled! Each pack creates unique artwork.'
                              : 'Demo mode: Cards use your avatar. Add Gemini API key for AI-generated artwork.',
                            style: TextStyle(
                              fontSize: 11, 
                              color: AppConfig.geminiApiKey.isNotEmpty ? AppColors.mint500 : AppColors.primary600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getPackColor(PackTheme theme) {
    switch (theme) {
      case PackTheme.daily: return Colors.orange.shade100;
      case PackTheme.profile: return Colors.blue.shade100;
      case PackTheme.fun: return Colors.pink.shade100;
      case PackTheme.sticker: return Colors.yellow.shade100;
    }
  }
}

class _OpeningView extends StatelessWidget {
  final CardPack pack;
  final String openingState;
  final CollectibleCard? newCard;
  final VoidCallback onStartOpening;
  final VoidCallback onViewCollection;
  final VoidCallback onBack;

  const _OpeningView({required this.pack, required this.openingState, required this.newCard, required this.onStartOpening, required this.onViewCollection, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Align(alignment: Alignment.centerLeft, child: IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back))),
          const Spacer(),
          if (openingState == 'revealing' && newCard != null) ...[
            Container(
              width: 300,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(28), 
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 30, offset: const Offset(0, 15))],
              ),
              child: Column(
                children: [
                  // New Card 标签
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), 
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Colors.amber, Colors.orange]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.4), blurRadius: 8)],
                    ), 
                    child: const Text('✨ New Card Unlocked!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),
                  
                  // 卡牌图片
                  Container(
                    height: 220, 
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.stone100, 
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppShadows.soft,
                    ), 
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: _buildCardImage(newCard!.imageUrl),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 稀有度
                  _RarityBadge(rarity: newCard!.rarity),
                  const SizedBox(height: 10),
                  
                  // 名称
                  Text(newCard!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  const SizedBox(height: 6),
                  
                  // 描述
                  if (newCard!.description != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.stone50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary100),
                      ),
                      child: Text(
                        '"${newCard!.description}"', 
                        style: const TextStyle(color: AppColors.stone600, fontStyle: FontStyle.italic, fontSize: 13), 
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 12),
                  
                  // 标签
                  if (newCard!.tags.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: newCard!.tags.map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.primary50, borderRadius: BorderRadius.circular(8)),
                        child: Text('#$tag', style: const TextStyle(color: AppColors.primary600, fontSize: 11, fontWeight: FontWeight.bold)),
                      )).toList(),
                    ),
                  const SizedBox(height: 20),
                  
                  // 按钮
                  SizedBox(
                    width: double.infinity, 
                    child: ElevatedButton(
                      onPressed: onViewCollection, 
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppColors.primary500,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('View Collection'),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Text(openingState == 'shaking' ? 'Opening...' : 'Open ${pack.name}', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: openingState == 'idle' ? onStartOpening : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 200,
                height: 280,
                decoration: BoxDecoration(
                  color: _getPackColor(pack.theme), 
                  borderRadius: BorderRadius.circular(24), 
                  border: Border.all(color: Colors.white, width: 8), 
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Center(
                  child: openingState == 'shaking' 
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(color: Colors.white),
                          const SizedBox(height: 16),
                          Text('Creating magic...', style: TextStyle(color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.bold)),
                        ],
                      )
                    : Text(pack.icon, style: const TextStyle(fontSize: 64)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (openingState == 'idle') const Text('Tap pack to open!', style: TextStyle(color: AppColors.stone400, fontWeight: FontWeight.bold)),
          ],
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildCardImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Center(child: Text(pack.icon, style: const TextStyle(fontSize: 64)));
    }
    
    if (imageUrl.startsWith('data:')) {
      try {
        final base64Data = imageUrl.split(',').last;
        final bytes = base64Decode(base64Data);
        return Image.memory(Uint8List.fromList(bytes), fit: BoxFit.cover);
      } catch (e) {
        return Center(child: Text(pack.icon, style: const TextStyle(fontSize: 64)));
      }
    }
    
    return Image.network(
      imageUrl, 
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Center(child: Text(pack.icon, style: const TextStyle(fontSize: 64))),
    );
  }

  Color _getPackColor(PackTheme theme) {
    switch (theme) {
      case PackTheme.daily: return Colors.orange.shade200;
      case PackTheme.profile: return Colors.blue.shade200;
      case PackTheme.fun: return Colors.pink.shade200;
      case PackTheme.sticker: return Colors.yellow.shade200;
    }
  }
}

class _CollectionView extends ConsumerWidget {
  final Pet pet;
  final List<CardPack> packs;
  final Function(CollectibleCard) onSelectCard;
  final VoidCallback onBack;

  const _CollectionView({required this.pet, required this.packs, required this.onSelectCard, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collection = pet.collection ?? [];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
              const SizedBox(width: 8),
              Text('My Collection', style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: AppColors.primary50, borderRadius: BorderRadius.circular(16)), child: Text('${collection.length} Cards', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary600))),
            ],
          ),
        ),
        Expanded(
          child: collection.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.style_outlined, size: 64, color: AppColors.stone300),
                      SizedBox(height: 16),
                      Text('No cards yet', style: TextStyle(color: AppColors.stone500, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('Open packs to collect cards!', style: TextStyle(color: AppColors.stone400)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: packs.length,
                  itemBuilder: (context, index) {
                    final pack = packs[index];
                    final packCards = collection.where((c) => c.theme == pack.theme).toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [Text(pack.icon, style: const TextStyle(fontSize: 20)), const SizedBox(width: 8), Text(pack.name, style: const TextStyle(fontWeight: FontWeight.bold))]),
                        const SizedBox(height: 12),
                        if (packCards.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(color: AppColors.stone50, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.stone200, width: 2)),
                            child: const Text('No cards yet', style: TextStyle(color: AppColors.stone400, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.75, mainAxisSpacing: 8, crossAxisSpacing: 8),
                            itemCount: packCards.length,
                            itemBuilder: (context, cardIndex) {
                              final card = packCards[cardIndex];
                              return GestureDetector(
                                onTap: () => onSelectCard(card),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white, 
                                    borderRadius: BorderRadius.circular(12), 
                                    border: Border.all(color: AppColors.stone100), 
                                    boxShadow: AppShadows.soft,
                                  ),
                                  child: Stack(
                                    children: [
                                      // 卡牌图片
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(11), 
                                        child: SizedBox.expand(
                                          child: _buildCardThumbnail(card.imageUrl, pack.icon, card.theme),
                                        ),
                                      ),
                                      // 稀有度指示点
                                      Positioned(
                                        top: 4, 
                                        right: 4, 
                                        child: Container(
                                          width: 12, 
                                          height: 12, 
                                          decoration: BoxDecoration(
                                            color: _getRarityColor(card.rarity), 
                                            shape: BoxShape.circle, 
                                            border: Border.all(color: Colors.white, width: 2),
                                            boxShadow: [BoxShadow(color: _getRarityColor(card.rarity).withOpacity(0.5), blurRadius: 4)],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCardThumbnail(String? imageUrl, String fallbackIcon, PackTheme theme) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        color: _getPackColor(theme),
        child: Center(child: Text(fallbackIcon, style: const TextStyle(fontSize: 32))),
      );
    }
    
    if (imageUrl.startsWith('data:')) {
      try {
        final base64Data = imageUrl.split(',').last;
        final bytes = base64Decode(base64Data);
        return Image.memory(Uint8List.fromList(bytes), fit: BoxFit.cover);
      } catch (e) {
        return Container(
          color: _getPackColor(theme),
          child: Center(child: Text(fallbackIcon, style: const TextStyle(fontSize: 32))),
        );
      }
    }
    
    return Image.network(
      imageUrl, 
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: _getPackColor(theme),
        child: Center(child: Text(fallbackIcon, style: const TextStyle(fontSize: 32))),
      ),
    );
  }

  Color _getPackColor(PackTheme theme) {
    switch (theme) {
      case PackTheme.daily: return Colors.orange.shade100;
      case PackTheme.profile: return Colors.blue.shade100;
      case PackTheme.fun: return Colors.pink.shade100;
      case PackTheme.sticker: return Colors.yellow.shade100;
    }
  }

  Color _getRarityColor(Rarity rarity) {
    switch (rarity) {
      case Rarity.common: return AppColors.stone400;
      case Rarity.rare: return Colors.blue;
      case Rarity.epic: return Colors.purple;
      case Rarity.legendary: return Colors.amber;
    }
  }
}

class _CardDetailView extends StatelessWidget {
  final CollectibleCard card;
  final VoidCallback onBack;

  const _CardDetailView({required this.card, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 30, offset: const Offset(0, 15))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 关闭按钮
                Align(
                  alignment: Alignment.topRight, 
                  child: Padding(
                    padding: const EdgeInsets.all(12), 
                    child: IconButton(
                      onPressed: onBack, 
                      icon: const Icon(Icons.close), 
                      style: IconButton.styleFrom(backgroundColor: AppColors.stone100),
                    ),
                  ),
                ),
                
                // 卡牌图片
                Container(
                  height: 240, 
                  margin: const EdgeInsets.symmetric(horizontal: 24), 
                  decoration: BoxDecoration(
                    color: _getPackColor(card.theme), 
                    borderRadius: BorderRadius.circular(20), 
                    boxShadow: [
                      BoxShadow(color: _getRarityGlow(card.rarity), blurRadius: 20, spreadRadius: 2),
                      ...AppShadows.soft,
                    ],
                  ), 
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _buildCardImage(card.imageUrl),
                  ),
                ),
                const SizedBox(height: 20),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // 稀有度徽章
                      _RarityBadge(rarity: card.rarity),
                      const SizedBox(height: 12),
                      
                      // 卡牌名称
                      Text(card.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                      const SizedBox(height: 8),
                      
                      // 主题标签
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), 
                        decoration: BoxDecoration(color: AppColors.primary50, borderRadius: BorderRadius.circular(14)), 
                        child: Text('${card.theme.displayName} Pack', style: const TextStyle(color: AppColors.primary600, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      const SizedBox(height: 16),
                      
                      // 描述
                      if (card.description != null) 
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14), 
                          decoration: BoxDecoration(
                            color: AppColors.stone50, 
                            borderRadius: BorderRadius.circular(14), 
                            border: Border.all(color: AppColors.primary100, width: 2),
                          ), 
                          child: Text(
                            '"${card.description}"', 
                            style: const TextStyle(color: AppColors.stone600, fontStyle: FontStyle.italic, fontSize: 14, height: 1.4), 
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(height: 14),
                      
                      // 标签
                      if (card.tags.isNotEmpty) 
                        Wrap(
                          spacing: 8, 
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: card.tags.map((tag) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), 
                            decoration: BoxDecoration(color: AppColors.primary50, borderRadius: BorderRadius.circular(10)), 
                            child: Text('#$tag', style: const TextStyle(color: AppColors.primary600, fontSize: 12, fontWeight: FontWeight.bold)),
                          )).toList(),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // 按钮
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {}, 
                          icon: const Icon(Icons.share), 
                          label: const Text('Share'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onBack, 
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: AppColors.primary500,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Nice!'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Center(child: Text(_getThemeIcon(card.theme), style: const TextStyle(fontSize: 72)));
    }
    
    if (imageUrl.startsWith('data:')) {
      try {
        final base64Data = imageUrl.split(',').last;
        final bytes = base64Decode(base64Data);
        return Image.memory(Uint8List.fromList(bytes), fit: BoxFit.cover, width: double.infinity, height: double.infinity);
      } catch (e) {
        return Center(child: Text(_getThemeIcon(card.theme), style: const TextStyle(fontSize: 72)));
      }
    }
    
    return Image.network(
      imageUrl, 
      fit: BoxFit.cover,
      width: double.infinity, 
      height: double.infinity,
      errorBuilder: (_, __, ___) => Center(child: Text(_getThemeIcon(card.theme), style: const TextStyle(fontSize: 72))),
    );
  }

  Color _getPackColor(PackTheme theme) {
    switch (theme) {
      case PackTheme.daily: return Colors.orange.shade100;
      case PackTheme.profile: return Colors.blue.shade100;
      case PackTheme.fun: return Colors.pink.shade100;
      case PackTheme.sticker: return Colors.yellow.shade100;
    }
  }

  Color _getRarityGlow(Rarity rarity) {
    switch (rarity) {
      case Rarity.common: return Colors.grey.withOpacity(0.3);
      case Rarity.rare: return Colors.blue.withOpacity(0.4);
      case Rarity.epic: return Colors.purple.withOpacity(0.4);
      case Rarity.legendary: return Colors.amber.withOpacity(0.5);
    }
  }

  String _getThemeIcon(PackTheme theme) {
    switch (theme) {
      case PackTheme.daily: return '☕';
      case PackTheme.profile: return '🏆';
      case PackTheme.fun: return '🎾';
      case PackTheme.sticker: return '⭐';
    }
  }
}

class _RarityBadge extends StatelessWidget {
  final Rarity rarity;

  const _RarityBadge({required this.rarity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: _getColor(), borderRadius: BorderRadius.circular(12)),
      child: Text(rarity.displayName.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1)),
    );
  }

  Color _getColor() {
    switch (rarity) {
      case Rarity.common: return AppColors.stone400;
      case Rarity.rare: return Colors.blue;
      case Rarity.epic: return Colors.purple;
      case Rarity.legendary: return Colors.amber.shade700;
    }
  }
}