import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/pet_theme.dart';
import '../../../../../core/models/models.dart';
import '../../../../../core/services/wellness_report_service.dart';
import '../../../../../core/providers/wellness_provider.dart';

/// Wellness 页面顶部 Header
class WellnessHeader extends ConsumerWidget {
  final Pet pet;
  final PetTheme theme;

  const WellnessHeader({
    super.key,
    required this.pet,
    required this.theme,
  });

  // Wellness 主题色
  static const _primaryColor = Color(0xFF10B981); // Emerald 500

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: _primaryColor,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back, color: Colors.white),
      ),
      actions: [
        // Help 按钮
        IconButton(
          onPressed: () => _showHelpDialog(context),
          icon: const Icon(Icons.help_outline, color: Colors.white),
          tooltip: 'Help',
        ),
        // Share 按钮
        IconButton(
          onPressed: () => _shareReport(context, ref),
          icon: const Icon(Icons.ios_share, color: Colors.white),
          tooltip: 'Share Report',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _primaryColor,
                _primaryColor.withOpacity(0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Wellness',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _shareReport(BuildContext context, WidgetRef ref) async {
    // 收集报告数据
    final todayScores = ref.read(todayWellnessScoresProvider).valueOrNull;
    final bcs = ref.read(currentBCSProvider).valueOrNull;
    final mcs = ref.read(currentMCSProvider).valueOrNull;
    final weight = ref.read(latestWeightProvider).valueOrNull;
    final weightTrend = ref.read(weightTrendProvider).valueOrNull;

    // 计算综合评分
    final scoreResult = _calculateScore(todayScores, bcs, mcs, weightTrend);

    // 构建每日检查数据
    final dailyScores = <String, int?>{};
    if (todayScores != null) {
      dailyScores['gum_color'] = todayScores.getScore('gum_color');
      dailyScores['coat_condition'] = todayScores.getScore('coat_condition');
      dailyScores['eye_clarity'] = todayScores.getScore('eye_clarity');
      dailyScores['breathing'] = todayScores.getScore('breathing');
      dailyScores['energy'] = todayScores.getScore('energy');
      dailyScores['stool'] = todayScores.getScore('stool');
      dailyScores['hydration'] = todayScores.getScore('hydration');
    }

    String? trendText;
    if (weightTrend != null) {
      switch (weightTrend) {
        case WeightTrend.increasing:
          trendText = 'Increasing';
          break;
        case WeightTrend.decreasing:
          trendText = 'Decreasing';
          break;
        case WeightTrend.stable:
          trendText = 'Stable';
          break;
      }
    }

    final reportData = WellnessReportData(
      overallScore: scoreResult.$1,
      scoreLabel: scoreResult.$2,
      weight: weight,
      weightTrend: trendText,
      bcs: bcs,
      mcs: mcs,
      dailyScores: dailyScores,
    );

    await WellnessReportService.shareReport(
      context: context,
      pet: pet,
      data: reportData,
    );
  }

  (int, String) _calculateScore(
    TodayWellnessScores? todayScores,
    int? bcs,
    int? mcs,
    WeightTrend? weightTrend,
  ) {
    int totalPoints = 0;
    int maxPoints = 0;

    // 体重趋势 (10分)
    if (weightTrend != null) {
      maxPoints += 10;
      totalPoints += weightTrend == WeightTrend.stable ? 10 : 5;
    }

    // BCS (20分)
    if (bcs != null) {
      maxPoints += 20;
      final deviation = (bcs - 5).abs();
      if (deviation == 0) totalPoints += 20;
      else if (deviation == 1) totalPoints += 15;
      else if (deviation == 2) totalPoints += 10;
      else totalPoints += 5;
    }

    // MCS (20分)
    if (mcs != null) {
      maxPoints += 20;
      if (mcs == 3) totalPoints += 20;
      else if (mcs == 2) totalPoints += 14;
      else if (mcs == 1) totalPoints += 8;
      else totalPoints += 2;
    }

    // 每日检查 (50分)
    if (todayScores != null && todayScores.completedCount > 0) {
      maxPoints += 50;
      int dailyTotal = 0;
      todayScores.scores.forEach((_, score) => dailyTotal += score);
      final avgScore = dailyTotal / todayScores.completedCount;
      final percentage = (avgScore - 1) / 4;
      totalPoints += (percentage * 50 * (todayScores.completedCount / 7)).round();
    }

    final score = maxPoints == 0 ? 0 : ((totalPoints / maxPoints) * 100).round();
    
    String label;
    if (score >= 90) label = 'Excellent';
    else if (score >= 75) label = 'Good';
    else if (score >= 60) label = 'Fair';
    else if (score >= 40) label = 'Needs Attention';
    else label = 'Concerning';

    return (score, label);
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Text('❓ '),
            Text('Understanding Wellness'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _HelpSection(
                title: '🌟 Wellness Score',
                content: 'A composite score (0-100) based on all health indicators. '
                    'Higher is better.',
              ),
              const SizedBox(height: 16),
              _HelpSection(
                title: '⚖️ Weight',
                content: 'Track weight regularly. Stable weight is usually healthy. '
                    'Sudden changes may need attention.',
              ),
              const SizedBox(height: 16),
              _HelpSection(
                title: '🏋️ BCS (Body Condition Score)',
                content: '1-9 scale. Score 5 is ideal. '
                    '1-3 = underweight, 7-9 = overweight.',
              ),
              const SizedBox(height: 16),
              _HelpSection(
                title: '💪 MCS (Muscle Condition Score)',
                content: '0-3 scale. Score 3 is normal muscle mass. '
                    'Lower scores indicate muscle loss.',
              ),
              const SizedBox(height: 16),
              _HelpSection(
                title: '📋 Daily Checks',
                content: 'Quick 1-5 ratings for 7 health indicators. '
                    '5 = excellent, 1 = needs immediate attention.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  final String title;
  final String content;

  const _HelpSection({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.stone600,
          ),
        ),
      ],
    );
  }
}
