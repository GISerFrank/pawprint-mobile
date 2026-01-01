import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/pet_theme.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/models/models.dart';
import '../../../../shared/widgets/widgets.dart';
import '../widgets/wellness/wellness_charts.dart';

/// Wellness 趋势详情页面
class WellnessTrendsPage extends ConsumerWidget {
  const WellnessTrendsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petAsync = ref.watch(currentPetProvider);
    final theme = ref.watch(currentPetThemeProvider);

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: AppColors.stone800),
        ),
        title: Text(
          'Health Trends',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.stone800,
          ),
        ),
        centerTitle: true,
      ),
      body: petAsync.when(
        loading: () => const Center(child: AppLoadingIndicator()),
        error: (e, _) => ErrorStateWidget(
          message: 'Failed to load data',
          onRetry: () => ref.invalidate(currentPetProvider),
        ),
        data: (pet) {
          if (pet == null) {
            return const Center(child: Text('No pet selected'));
          }
          return _TrendsContent(pet: pet, theme: theme);
        },
      ),
    );
  }
}

class _TrendsContent extends StatelessWidget {
  final Pet pet;
  final PetTheme theme;

  const _TrendsContent({
    required this.pet,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 体重趋势
          WeightTrendChart(pet: pet, theme: theme),
          const SizedBox(height: 16),

          // BCS 历史
          BCSHistoryChart(pet: pet, theme: theme),
          const SizedBox(height: 16),

          // MCS 历史
          MCSHistoryChart(pet: pet, theme: theme),
          const SizedBox(height: 16),

          // 图例说明
          _LegendCard(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// 图例说明卡片
class _LegendCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.stone50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.stone200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Understanding the Charts',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.stone800,
            ),
          ),
          const SizedBox(height: 12),
          
          _LegendItem(
            color: AppColors.green500,
            label: 'Ideal / Normal',
            description: 'BCS 5, MCS 3',
          ),
          const SizedBox(height: 8),
          _LegendItem(
            color: AppColors.amber500,
            label: 'Slightly Off',
            description: 'Minor deviation from ideal',
          ),
          const SizedBox(height: 8),
          _LegendItem(
            color: AppColors.orange500,
            label: 'Needs Attention',
            description: 'Consider consulting a vet',
          ),
          const SizedBox(height: 8),
          _LegendItem(
            color: AppColors.red500,
            label: 'Concerning',
            description: 'Veterinary consultation recommended',
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String description;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.stone700,
                ),
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.stone500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
