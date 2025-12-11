import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

class CardShopPage extends StatelessWidget {
  const CardShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => context.pop(),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '0',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Card Shop',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        TextButton.icon(
                          onPressed: () {
                            // TODO: Navigate to collection
                          },
                          icon: const Icon(Icons.grid_view, size: 18),
                          label: const Text('My Collection'),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Coin balance banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.stone800,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.monetization_on,
                              color: Colors.amber,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'BALANCE',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.stone400,
                                  ),
                                ),
                                Text(
                                  '200',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Claim coins
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Get Coins'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.stone700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Card packs grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.8,
                      children: [
                        _PackCard(
                          name: 'Cozy Moments',
                          description: 'Sweet everyday memories.',
                          icon: '☕',
                          color: Colors.orange.shade100,
                          price: 50,
                        ),
                        _PackCard(
                          name: 'Heroic Portraits',
                          description: 'Your pet looking epic.',
                          icon: '🏆',
                          color: Colors.blue.shade100,
                          price: 100,
                        ),
                        _PackCard(
                          name: 'Playtime Fun',
                          description: 'Silly and energetic!',
                          icon: '🎾',
                          color: Colors.pink.shade100,
                          price: 75,
                        ),
                        _PackCard(
                          name: 'Pop Stickers',
                          description: 'Bold and collectable.',
                          icon: '⭐',
                          color: Colors.yellow.shade100,
                          price: 150,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackCard extends StatelessWidget {
  final String name;
  final String description;
  final String icon;
  final Color color;
  final int price;

  const _PackCard({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 36),
          ),
          const Spacer(),
          Text(
            name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white60,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on, size: 14, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  '$price',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
