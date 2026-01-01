import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/pet_theme.dart';
import '../../../../core/models/models.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/providers/wellness_provider.dart';
import '../widgets/wellness/log_detail_sheet.dart';

/// 单个 Daily Check 指标的历史趋势页面
class DailyCheckHistoryPage extends ConsumerWidget {
  final String indicatorId;
  final String name;
  final String nameZh;
  final String emoji;

  const DailyCheckHistoryPage({
    super.key,
    required this.indicatorId,
    required this.name,
    required this.nameZh,
    required this.emoji,
  });

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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(
              name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.stone800,
                  ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: petAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load')),
        data: (pet) {
          if (pet == null) return const Center(child: Text('No pet selected'));
          return _HistoryContent(
            pet: pet,
            theme: theme,
            indicatorId: indicatorId,
            name: name,
            nameZh: nameZh,
          );
        },
      ),
    );
  }
}

class _HistoryContent extends ConsumerWidget {
  final Pet pet;
  final PetTheme theme;
  final String indicatorId;
  final String name;
  final String nameZh;

  const _HistoryContent({
    required this.pet,
    required this.theme,
    required this.indicatorId,
    required this.name,
    required this.nameZh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(dailyCheckHistoryProvider(indicatorId));

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (history) {
        if (history.isEmpty) {
          return _EmptyState(name: name);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 统计卡片
              _StatsCard(history: history, theme: theme),
              const SizedBox(height: 16),

              // 趋势图表
              _TrendChart(history: history, theme: theme),
              const SizedBox(height: 16),

              // 历史记录列表
              _HistoryList(history: history, theme: theme),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

/// 空状态
class _EmptyState extends StatelessWidget {
  final String name;

  const _EmptyState({required this.name});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: AppColors.stone300),
          const SizedBox(height: 16),
          Text(
            'No $name records yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.stone500,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start tracking to see trends',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.stone400,
                ),
          ),
        ],
      ),
    );
  }
}

/// 统计卡片
class _StatsCard extends StatelessWidget {
  final List<MetricLog> history;
  final PetTheme theme;

  const _StatsCard({
    required this.history,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    // 计算统计数据
    final scores = history
        .where((log) => log.rangeValue != null)
        .map((log) => log.rangeValue!)
        .toList();

    if (scores.isEmpty) return const SizedBox.shrink();

    final avgScore = scores.reduce((a, b) => a + b) / scores.length;
    final latestScore = scores.first;
    final totalRecords = scores.length;

    // 计算最近7天的趋势
    final recentScores = history
        .where((log) =>
            log.rangeValue != null &&
            log.loggedAt
                .isAfter(DateTime.now().subtract(const Duration(days: 7))))
        .map((log) => log.rangeValue!)
        .toList();

    String trendText = 'Stable';
    IconData trendIcon = Icons.trending_flat;
    Color trendColor = AppColors.stone500;

    if (recentScores.length >= 2) {
      final recentAvg =
          recentScores.reduce((a, b) => a + b) / recentScores.length;
      final diff = recentAvg - avgScore;
      if (diff > 0.3) {
        trendText = 'Improving';
        trendIcon = Icons.trending_up;
        trendColor = AppColors.green500;
      } else if (diff < -0.3) {
        trendText = 'Declining';
        trendIcon = Icons.trending_down;
        trendColor = AppColors.red500;
      }
    }

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
      child: Row(
        children: [
          // 最新评分
          Expanded(
            child: _StatItem(
              label: 'Latest',
              value: '$latestScore',
              subValue: '/5',
              color: _getScoreColor(latestScore),
            ),
          ),
          _VerticalDivider(),
          // 平均分
          Expanded(
            child: _StatItem(
              label: 'Average',
              value: avgScore.toStringAsFixed(1),
              subValue: '/5',
              color: _getScoreColor(avgScore.round()),
            ),
          ),
          _VerticalDivider(),
          // 趋势
          Expanded(
            child: Column(
              children: [
                Icon(trendIcon, color: trendColor, size: 28),
                const SizedBox(height: 4),
                Text(
                  trendText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: trendColor,
                  ),
                ),
                Text(
                  'Last 7 days',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.stone400,
                  ),
                ),
              ],
            ),
          ),
          _VerticalDivider(),
          // 记录数
          Expanded(
            child: _StatItem(
              label: 'Records',
              value: '$totalRecords',
              subValue: '',
              color: AppColors.stone600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score == 1) return AppColors.red500;
    if (score == 2) return AppColors.orange500;
    if (score == 3) return AppColors.amber500;
    if (score == 4) return AppColors.lime500;
    return AppColors.green500;
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final String subValue;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.subValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (subValue.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  subValue,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.stone400,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.stone500,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 1,
      color: AppColors.stone200,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

/// 趋势图表
class _TrendChart extends StatelessWidget {
  final List<MetricLog> history;
  final PetTheme theme;

  const _TrendChart({
    required this.history,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    // 只取最近30条记录
    final displayHistory = history.length > 30
        ? history.sublist(0, 30).reversed.toList()
        : history.reversed.toList();

    final spots = <FlSpot>[];
    for (int i = 0; i < displayHistory.length; i++) {
      final log = displayHistory[i];
      if (log.rangeValue != null) {
        spots.add(FlSpot(i.toDouble(), log.rangeValue!.toDouble()));
      }
    }

    if (spots.isEmpty) return const SizedBox.shrink();

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
              Icon(Icons.show_chart, color: theme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Trend',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              Text(
                'Last ${displayHistory.length} records',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.stone500,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
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
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value == value.roundToDouble() &&
                            value >= 1 &&
                            value <= 5) {
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
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: (displayHistory.length / 5)
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
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (displayHistory.length - 1).toDouble(),
                minY: 0.5,
                maxY: 5.5,
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
                        final score = spot.y.toInt();
                        return FlDotCirclePainter(
                          radius: 5,
                          color: _getScoreColor(score),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: theme.primary.withOpacity(0.1),
                    ),
                  ),
                  // 理想线 (score = 5)
                  LineChartBarData(
                    spots: [
                      FlSpot(0, 5),
                      FlSpot((displayHistory.length - 1).toDouble(), 5),
                    ],
                    isCurved: false,
                    color: AppColors.green300,
                    barWidth: 1,
                    dotData: const FlDotData(show: false),
                    dashArray: [5, 5],
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: AppColors.stone800,
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots
                          .map((spot) {
                            if (spot.barIndex != 0) return null; // 忽略理想线
                            final index = spot.x.toInt();
                            if (index >= displayHistory.length) return null;
                            final date = displayHistory[index].loggedAt;
                            return LineTooltipItem(
                              '${spot.y.toInt()}/5\n',
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
                          })
                          .whereType<LineTooltipItem>()
                          .toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 图例
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(color: theme.primary, label: 'Your scores'),
              const SizedBox(width: 24),
              _LegendItem(
                  color: AppColors.green300,
                  label: 'Ideal (5)',
                  isDashed: true),
            ],
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score == 1) return AppColors.red500;
    if (score == 2) return AppColors.orange500;
    if (score == 3) return AppColors.amber500;
    if (score == 4) return AppColors.lime500;
    return AppColors.green500;
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDashed;

  const _LegendItem({
    required this.color,
    required this.label,
    this.isDashed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: isDashed ? Colors.transparent : color,
            border: isDashed
                ? Border(
                    bottom: BorderSide(
                        color: color, width: 2, style: BorderStyle.solid),
                  )
                : null,
          ),
          child: isDashed
              ? CustomPaint(
                  painter: _DashedLinePainter(color: color),
                )
              : null,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.stone500,
          ),
        ),
      ],
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;

    const dashWidth = 3.0;
    const dashSpace = 2.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 历史记录列表
class _HistoryList extends StatelessWidget {
  final List<MetricLog> history;
  final PetTheme theme;

  const _HistoryList({required this.history, required this.theme});

  @override
  Widget build(BuildContext context) {
    // 按日期分组
    final groupedByDate = <String, List<MetricLog>>{};
    for (final log in history) {
      final dateKey = DateFormat('yyyy-MM-dd').format(log.loggedAt);
      groupedByDate.putIfAbsent(dateKey, () => []).add(log);
    }

    final sortedDates = groupedByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    // 只显示最近10天
    final displayDates = sortedDates.take(10).toList();

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.history, color: AppColors.stone600, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Recent Records',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayDates.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final dateKey = displayDates[index];
              final logs = groupedByDate[dateKey]!;
              final latestLog = logs.first;
              final date = DateTime.parse(dateKey);
              final isToday =
                  DateFormat('yyyy-MM-dd').format(DateTime.now()) == dateKey;

              final hasAttachment =
                  (latestLog.notes != null && latestLog.notes!.isNotEmpty) ||
                      (latestLog.imageUrls != null &&
                          latestLog.imageUrls!.isNotEmpty);

              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: _ScoreBadge(score: latestLog.rangeValue ?? 0),
                title: Text(
                  isToday ? 'Today' : DateFormat('EEEE, MMM d').format(date),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            isToday ? FontWeight.w600 : FontWeight.normal,
                      ),
                ),
                subtitle: Text(
                  DateFormat('h:mm a').format(latestLog.loggedAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.stone400,
                      ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasAttachment)
                      Icon(Icons.attachment,
                          color: AppColors.stone400, size: 18),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right,
                        color: AppColors.stone300, size: 20),
                  ],
                ),
                onTap: () => _showLogDetail(context, latestLog),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showLogDetail(BuildContext context, MetricLog log) {
    showLogDetailSheet(
      context,
      log: log,
      theme: theme,
      maxScore: 5,
    );
  }
}

/// 分数徽章
class _ScoreBadge extends StatelessWidget {
  final int score;

  const _ScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _getScoreColor(score).withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          '$score',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _getScoreColor(score),
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score == 1) return AppColors.red500;
    if (score == 2) return AppColors.orange500;
    if (score == 3) return AppColors.amber500;
    if (score == 4) return AppColors.lime500;
    return AppColors.green500;
  }
}
