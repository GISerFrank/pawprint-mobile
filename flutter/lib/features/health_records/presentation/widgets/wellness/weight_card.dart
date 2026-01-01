import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/pet_theme.dart';
import '../../../../../core/models/models.dart';
import '../../../../../core/providers/wellness_provider.dart';
import 'sparkline.dart';

/// 体重追踪卡片
class WeightCard extends ConsumerWidget {
  final Pet pet;
  final PetTheme theme;

  const WeightCard({
    super.key,
    required this.pet,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestWeightAsync = ref.watch(latestWeightProvider);
    final trendAsync = ref.watch(weightTrendProvider);
    final historyAsync = ref.watch(weightHistoryProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showWeightInputDialog(context, ref),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题行
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.blue50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '⚖️',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Weight',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.stone800,
                            ),
                          ),
                          // 趋势指示
                          trendAsync.when(
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                            data: (trend) => _TrendLabel(trend: trend),
                          ),
                        ],
                      ),
                    ),
                    // 当前体重显示
                    latestWeightAsync.when(
                      loading: () => const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (_, __) => _buildAddButton(context),
                      data: (weight) {
                        if (weight == null) {
                          return _buildAddButton(context);
                        }
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.primaryLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${weight.toStringAsFixed(1)} kg',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.primary,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                
                // Sparkline 趋势图
                historyAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (history) {
                    if (history.isEmpty) return const SizedBox.shrink();
                    
                    // 取最近7条记录
                    final recentWeights = history
                        .take(7)
                        .map((log) => log.numberValue ?? 0.0)
                        .toList()
                        .reversed
                        .toList();
                    
                    if (recentWeights.isEmpty) return const SizedBox.shrink();
                    
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: WeightSparkline(
                        weights: recentWeights,
                        height: 32,
                        color: theme.primary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.stone100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.add,
            size: 16,
            color: AppColors.stone600,
          ),
          const SizedBox(width: 4),
          Text(
            'Add',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.stone600,
            ),
          ),
        ],
      ),
    );
  }

  void _showWeightInputDialog(BuildContext context, WidgetRef ref) {
    final latestWeight = ref.read(latestWeightProvider).valueOrNull;
    final controller = TextEditingController(
      text: latestWeight?.toStringAsFixed(1) ?? pet.weightKg?.toStringAsFixed(1) ?? '',
    );
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Update Weight'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  hintText: 'e.g., 4.5',
                  suffixText: 'kg',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Text(
                'Record ${pet.name}\'s current weight',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.stone500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isSaving ? null : () async {
                final weight = double.tryParse(controller.text);
                if (weight != null && weight > 0) {
                  setDialogState(() => isSaving = true);
                  
                  final success = await ref.read(wellnessScoreNotifierProvider.notifier).saveWeight(
                    petId: pet.id,
                    weightKg: weight,
                  );
                  
                  if (success && dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Weight ${weight.toStringAsFixed(1)} kg saved!'),
                        backgroundColor: AppColors.green500,
                      ),
                    );
                  }
                }
              },
              child: isSaving 
                ? const SizedBox(
                    width: 16,
                    height: 16, 
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 趋势标签（简洁版）
class _TrendLabel extends StatelessWidget {
  final WeightTrend trend;

  const _TrendLabel({required this.trend});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    String label;
    Color color;

    switch (trend) {
      case WeightTrend.increasing:
        icon = Icons.arrow_upward;
        label = 'Increasing';
        color = AppColors.amber600;
        break;
      case WeightTrend.decreasing:
        icon = Icons.arrow_downward;
        label = 'Decreasing';
        color = AppColors.amber600;
        break;
      case WeightTrend.stable:
        icon = Icons.remove;
        label = 'Stable';
        color = AppColors.green600;
        break;
    }

    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
