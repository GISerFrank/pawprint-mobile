import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/pet_theme.dart';
import '../../../../../core/models/models.dart';
import '../../../../../core/providers/wellness_provider.dart';
import 'mcs_selector_sheet.dart';
import 'sparkline.dart';

/// MCS 肌肉评分卡片
/// 点击后打开评分选择器
class MCSCard extends ConsumerWidget {
  final Pet pet;
  final PetTheme theme;

  const MCSCard({
    super.key,
    required this.pet,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mcsAsync = ref.watch(currentMCSProvider);
    final historyAsync = ref.watch(mcsHistoryProvider);

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
          onTap: () => _openMCSSelector(context),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 图标、标题和分数
                Row(
                  children: [
                    const Text('💪', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'MCS',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.stone800,
                        ),
                      ),
                    ),
                    // 分数
                    mcsAsync.when(
                      loading: () => const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (_, __) => _buildAddLabel(context),
                      data: (score) {
                        if (score == null) return _buildAddLabel(context);
                        return _ScoreBadge(
                          score: score,
                          maxScore: 3,
                          color: _getMCSColor(score),
                        );
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // 状态标签
                mcsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (score) {
                    if (score == null) return const SizedBox.shrink();
                    return Text(
                      _getMCSLabel(score),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _getMCSColor(score),
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
                
                const Spacer(),
                
                // Sparkline
                historyAsync.when(
                  loading: () => const SizedBox(height: 20),
                  error: (_, __) => const SizedBox(height: 20),
                  data: (history) {
                    if (history.isEmpty) {
                      return const SizedBox(height: 20);
                    }
                    final scores = history
                        .take(7)
                        .map((log) => log.rangeValue ?? 3)
                        .toList()
                        .reversed
                        .toList();
                    return BodyScoreSparkline(
                      scores: scores,
                      maxScore: 3,
                      idealScore: 3,
                      height: 20,
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

  Widget _buildAddLabel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.stone100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Add',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.stone500,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _openMCSSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MCSSelectorSheet(
        pet: pet,
        theme: theme,
      ),
    );
  }

  String _getMCSLabel(int score) {
    switch (score) {
      case 0: return 'Severe Loss';
      case 1: return 'Moderate Loss';
      case 2: return 'Mild Loss';
      case 3: return 'Normal';
      default: return 'Unknown';
    }
  }

  Color _getMCSColor(int score) {
    switch (score) {
      case 0: return AppColors.red500;
      case 1: return AppColors.orange500;
      case 2: return AppColors.amber500;
      case 3: return AppColors.green500;
      default: return AppColors.stone500;
    }
  }
}

/// 分数徽章
class _ScoreBadge extends StatelessWidget {
  final int score;
  final int maxScore;
  final Color color;

  const _ScoreBadge({
    required this.score,
    required this.maxScore,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$score',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            TextSpan(
              text: '/$maxScore',
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
