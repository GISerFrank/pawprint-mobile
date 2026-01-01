import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/pet_theme.dart';
import '../../../../../core/models/models.dart';
import '../../../../../core/providers/wellness_provider.dart';
import 'bcs_selector_sheet.dart';
import 'sparkline.dart';
import 'log_detail_sheet.dart';

/// BCS 体况评分卡片
/// 点击后打开评分选择器
/// 长按查看历史记录
class BCSCard extends ConsumerWidget {
  final Pet pet;
  final PetTheme theme;

  const BCSCard({
    super.key,
    required this.pet,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bcsAsync = ref.watch(currentBCSProvider);
    final historyAsync = ref.watch(bcsHistoryProvider);

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
          onTap: () => _openBCSSelector(context),
          onLongPress: () => _showHistorySheet(context, ref),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 图标、标题和分数
                Row(
                  children: [
                    const Text('🏋️', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'BCS',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.stone800,
                        ),
                      ),
                    ),
                    // 分数
                    bcsAsync.when(
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
                          maxScore: 9,
                          color: _getBCSColor(score),
                        );
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // 状态标签
                bcsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (score) {
                    if (score == null) return const SizedBox.shrink();
                    return Text(
                      _getBCSLabel(score),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _getBCSColor(score),
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
                        .map((log) => log.rangeValue ?? 5)
                        .toList()
                        .reversed
                        .toList();
                    return BodyScoreSparkline(
                      scores: scores,
                      maxScore: 9,
                      idealScore: 5,
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

  void _openBCSSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BCSelectorSheet(
        pet: pet,
        theme: theme,
      ),
    );
  }

  void _showHistorySheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BCSHistorySheet(pet: pet, theme: theme),
    );
  }

  String _getBCSLabel(int score) {
    if (score <= 2) return 'Underweight';
    if (score <= 4) return 'Thin';
    if (score == 5) return 'Ideal';
    if (score <= 7) return 'Overweight';
    return 'Obese';
  }

  Color _getBCSColor(int score) {
    if (score <= 2) return AppColors.orange500;
    if (score <= 4) return AppColors.amber500;
    if (score == 5) return AppColors.green500;
    if (score <= 7) return AppColors.amber500;
    return AppColors.red500;
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

/// BCS 历史记录弹窗
class _BCSHistorySheet extends ConsumerWidget {
  final Pet pet;
  final PetTheme theme;

  const _BCSHistorySheet({
    required this.pet,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(bcsHistoryProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 拖动指示器
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.stone300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 标题
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text('🏋️', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BCS History',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Body Condition Score records',
                        style: TextStyle(color: AppColors.stone500, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 历史列表
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Failed to load')),
              data: (history) {
                if (history.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 48, color: AppColors.stone300),
                        const SizedBox(height: 16),
                        Text(
                          'No records yet',
                          style: TextStyle(color: AppColors.stone500),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: history.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final log = history[index];
                    final score = log.rangeValue ?? 0;
                    final isToday = DateFormat('yyyy-MM-dd').format(log.loggedAt) ==
                        DateFormat('yyyy-MM-dd').format(DateTime.now());
                    final hasAttachment = (log.notes?.isNotEmpty ?? false) ||
                        (log.imageUrls?.isNotEmpty ?? false);

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _getBCSColor(score).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '$score',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _getBCSColor(score),
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        isToday ? 'Today' : DateFormat('EEEE, MMM d').format(log.loggedAt),
                        style: TextStyle(
                          fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        '${_getBCSLabel(score)} • ${DateFormat('h:mm a').format(log.loggedAt)}',
                        style: TextStyle(color: AppColors.stone500, fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasAttachment)
                            Icon(Icons.attachment, color: AppColors.stone400, size: 18),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right, color: AppColors.stone300, size: 20),
                        ],
                      ),
                      onTap: () => showLogDetailSheet(
                        context,
                        log: log,
                        theme: theme,
                        metricName: 'BCS ${log.rangeValue}/9',
                        emoji: '🏋️',
                        maxScore: 9,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getBCSLabel(int score) {
    if (score <= 2) return 'Underweight';
    if (score <= 4) return 'Thin';
    if (score == 5) return 'Ideal';
    if (score <= 7) return 'Overweight';
    return 'Obese';
  }

  Color _getBCSColor(int score) {
    if (score <= 2) return AppColors.orange500;
    if (score <= 4) return AppColors.amber500;
    if (score == 5) return AppColors.green500;
    if (score <= 7) return AppColors.amber500;
    return AppColors.red500;
  }
}
