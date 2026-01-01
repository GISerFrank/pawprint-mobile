import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/pet_theme.dart';
import '../../../../../core/models/models.dart';
import '../../../../../core/providers/wellness_provider.dart';

/// 体重趋势图表
class WeightTrendChart extends ConsumerWidget {
  final Pet pet;
  final PetTheme theme;

  const WeightTrendChart({
    super.key,
    required this.pet,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(weightHistoryProvider);

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              const Text('⚖️', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'Weight Trend',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              Text(
                'Last 30 days',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.stone500,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 图表
          historyAsync.when(
            loading: () => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const SizedBox(
              height: 200,
              child: Center(child: Text('Failed to load data')),
            ),
            data: (history) {
              if (history.isEmpty) {
                return SizedBox(
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.show_chart,
                            size: 48, color: AppColors.stone300),
                        const SizedBox(height: 12),
                        Text(
                          'No weight records yet',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.stone500,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Start tracking to see trends',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.stone400,
                                  ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SizedBox(
                height: 200,
                child: _WeightLineChart(
                  history: history,
                  theme: theme,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WeightLineChart extends StatelessWidget {
  final List<MetricLog> history;
  final PetTheme theme;

  const _WeightLineChart({
    required this.history,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    // 按时间排序（从旧到新）
    final sortedHistory = List<MetricLog>.from(history)
      ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));

    // 只取最近的记录
    final displayHistory = sortedHistory.length > 30
        ? sortedHistory.sublist(sortedHistory.length - 30)
        : sortedHistory;

    if (displayHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    // 计算数据点
    final spots = <FlSpot>[];
    for (int i = 0; i < displayHistory.length; i++) {
      final log = displayHistory[i];
      if (log.numberValue != null) {
        spots.add(FlSpot(i.toDouble(), log.numberValue!));
      }
    }

    if (spots.isEmpty) {
      return const Center(child: Text('No valid weight data'));
    }

    // 计算Y轴范围
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.2;
    final yMin = (minY - padding).clamp(0.0, double.infinity);
    final yMax = maxY + padding;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (yMax - yMin) / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.stone200,
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: (yMax - yMin) / 4,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: AppColors.stone500,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: (displayHistory.length / 4)
                  .ceilToDouble()
                  .clamp(1, double.infinity),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= displayHistory.length) {
                  return const SizedBox.shrink();
                }
                final date = displayHistory[index].loggedAt;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('M/d').format(date),
                    style: TextStyle(
                      color: AppColors.stone500,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (displayHistory.length - 1).toDouble(),
        minY: yMin,
        maxY: yMax,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: theme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: theme.primary,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: theme.primary.withOpacity(0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: AppColors.stone800,
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                final date = displayHistory[index].loggedAt;
                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(2)} kg\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: DateFormat('MMM d').format(date),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

/// BCS 历史图表
class BCSHistoryChart extends ConsumerWidget {
  final Pet pet;
  final PetTheme theme;

  const BCSHistoryChart({
    super.key,
    required this.pet,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(bcsHistoryProvider);

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏋️', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'BCS History',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          historyAsync.when(
            loading: () => const SizedBox(
              height: 150,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const SizedBox(
              height: 150,
              child: Center(child: Text('Failed to load data')),
            ),
            data: (history) {
              if (history.isEmpty) {
                return SizedBox(
                  height: 100,
                  child: Center(
                    child: Text(
                      'No BCS records yet',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.stone500,
                          ),
                    ),
                  ),
                );
              }

              // 显示最近5条记录
              final recent = history.take(5).toList().reversed.toList();

              return SizedBox(
                height: 150,
                child: _ScoreBarChart(
                  records: recent,
                  maxScore: 9,
                  idealScore: 5,
                  theme: theme,
                  scoreColorFn: _getBCSColor,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getBCSColor(int score) {
    if (score <= 2) return AppColors.orange500;
    if (score <= 4) return AppColors.amber500;
    if (score == 5) return AppColors.green500;
    if (score <= 7) return AppColors.amber500;
    return AppColors.red500;
  }
}

/// MCS 历史图表
class MCSHistoryChart extends ConsumerWidget {
  final Pet pet;
  final PetTheme theme;

  const MCSHistoryChart({
    super.key,
    required this.pet,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(mcsHistoryProvider);

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💪', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'MCS History',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          historyAsync.when(
            loading: () => const SizedBox(
              height: 150,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const SizedBox(
              height: 150,
              child: Center(child: Text('Failed to load data')),
            ),
            data: (history) {
              if (history.isEmpty) {
                return SizedBox(
                  height: 100,
                  child: Center(
                    child: Text(
                      'No MCS records yet',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.stone500,
                          ),
                    ),
                  ),
                );
              }

              final recent = history.take(5).toList().reversed.toList();

              return SizedBox(
                height: 150,
                child: _ScoreBarChart(
                  records: recent,
                  maxScore: 3,
                  idealScore: 3,
                  theme: theme,
                  scoreColorFn: _getMCSColor,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getMCSColor(int score) {
    switch (score) {
      case 0:
        return AppColors.red500;
      case 1:
        return AppColors.orange500;
      case 2:
        return AppColors.amber500;
      case 3:
        return AppColors.green500;
      default:
        return AppColors.stone500;
    }
  }
}

/// 评分柱状图
class _ScoreBarChart extends StatelessWidget {
  final List<MetricLog> records;
  final int maxScore;
  final int idealScore;
  final PetTheme theme;
  final Color Function(int) scoreColorFn;

  const _ScoreBarChart({
    required this.records,
    required this.maxScore,
    required this.idealScore,
    required this.theme,
    required this.scoreColorFn,
  });

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxScore.toDouble(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: AppColors.stone800,
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final record = records[group.x.toInt()];
              final score = record.rangeValue ?? 0;
              return BarTooltipItem(
                'Score: $score\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: DateFormat('MMM d').format(record.loggedAt),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= records.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('M/d').format(records[index].loggedAt),
                    style: TextStyle(
                      color: AppColors.stone500,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value == value.roundToDouble()) {
                  return Text(
                    '${value.toInt()}',
                    style: TextStyle(
                      color: AppColors.stone500,
                      fontSize: 10,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            final isIdeal = value == idealScore.toDouble();
            return FlLine(
              color: isIdeal ? AppColors.green300 : AppColors.stone200,
              strokeWidth: isIdeal ? 2 : 1,
              dashArray: isIdeal ? null : [5, 5],
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: records.asMap().entries.map((entry) {
          final index = entry.key;
          final record = entry.value;
          final score = record.rangeValue ?? 0;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: score.toDouble(),
                color: scoreColorFn(score),
                width: 24,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
