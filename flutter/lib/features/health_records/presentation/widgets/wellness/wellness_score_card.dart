import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/pet_theme.dart';
import '../../../../../core/models/models.dart';
import '../../../../../core/providers/wellness_provider.dart';

/// Wellness 综合评分卡片
/// 显示宠物的整体健康评分 (0-100)
class WellnessScoreCard extends ConsumerWidget {
  final Pet pet;
  final PetTheme theme;

  const WellnessScoreCard({
    super.key,
    required this.pet,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayScoresAsync = ref.watch(todayWellnessScoresProvider);
    final bcsAsync = ref.watch(currentBCSProvider);
    final mcsAsync = ref.watch(currentMCSProvider);
    final weightTrendAsync = ref.watch(weightTrendProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primary,
            theme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // 标题
          Row(
            children: [
              const Text(
                '🌟',
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Text(
                'Wellness Score',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 评分显示
          _buildScoreDisplay(
            context,
            ref,
            todayScoresAsync,
            bcsAsync,
            mcsAsync,
            weightTrendAsync,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDisplay(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<TodayWellnessScores> todayScoresAsync,
    AsyncValue<int?> bcsAsync,
    AsyncValue<int?> mcsAsync,
    AsyncValue<WeightTrend> weightTrendAsync,
  ) {
    // 计算综合评分
    final todayScores = todayScoresAsync.valueOrNull;
    final bcs = bcsAsync.valueOrNull;
    final mcs = mcsAsync.valueOrNull;
    final weightTrend = weightTrendAsync.valueOrNull;

    final scoreResult = _calculateWellnessScore(
      todayScores: todayScores,
      bcs: bcs,
      mcs: mcs,
      weightTrend: weightTrend,
    );

    final score = scoreResult.score;
    final label = scoreResult.label;
    final message = scoreResult.message;

    return Row(
      children: [
        // 分数圆环
        SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 背景圆环
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation(Colors.white.withOpacity(0.2)),
                ),
              ),
              // 进度圆环
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                  strokeCap: StrokeCap.round,
                ),
              ),
              // 分数文字
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$score',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '/100',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        
        // 状态描述
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 状态标签
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // 描述消息
              Text(
                message,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              // 完成度指示
              if (todayScores != null)
                _CompletionIndicator(
                  completed: todayScores.completedCount,
                  total: TodayWellnessScores.totalDailyMetrics,
                ),
            ],
          ),
        ),
      ],
    );
  }

  _ScoreResult _calculateWellnessScore({
    TodayWellnessScores? todayScores,
    int? bcs,
    int? mcs,
    WeightTrend? weightTrend,
  }) {
    int totalPoints = 0;
    int maxPoints = 0;

    // 1. 体重趋势 (10分)
    if (weightTrend != null) {
      maxPoints += 10;
      if (weightTrend == WeightTrend.stable) {
        totalPoints += 10;
      } else {
        totalPoints += 5; // 有变化但不是太差
      }
    }

    // 2. BCS 评分 (20分) - 5分是理想
    if (bcs != null) {
      maxPoints += 20;
      final bcsDeviation = (bcs - 5).abs();
      if (bcsDeviation == 0) {
        totalPoints += 20;
      } else if (bcsDeviation == 1) {
        totalPoints += 15;
      } else if (bcsDeviation == 2) {
        totalPoints += 10;
      } else {
        totalPoints += 5;
      }
    }

    // 3. MCS 评分 (20分) - 3分是理想
    if (mcs != null) {
      maxPoints += 20;
      if (mcs == 3) {
        totalPoints += 20;
      } else if (mcs == 2) {
        totalPoints += 14;
      } else if (mcs == 1) {
        totalPoints += 8;
      } else {
        totalPoints += 2;
      }
    }

    // 4. 每日检查 (50分) - 每项约7分
    if (todayScores != null && todayScores.completedCount > 0) {
      final dailyMaxPoints = 50;
      maxPoints += dailyMaxPoints;
      
      // 计算每日评分的平均得分
      int dailyTotalScore = 0;
      int dailyCount = 0;
      
      todayScores.scores.forEach((_, score) {
        dailyTotalScore += score;
        dailyCount++;
      });
      
      if (dailyCount > 0) {
        // 平均分 1-5 转换为百分比
        final avgScore = dailyTotalScore / dailyCount;
        final dailyPercentage = (avgScore - 1) / 4; // 转换到 0-1
        totalPoints += (dailyPercentage * dailyMaxPoints * (dailyCount / TodayWellnessScores.totalDailyMetrics)).round();
      }
    }

    // 计算最终分数
    int finalScore;
    if (maxPoints == 0) {
      finalScore = 0;
    } else {
      finalScore = ((totalPoints / maxPoints) * 100).round();
    }

    // 确定标签和消息
    String label;
    String message;

    if (maxPoints == 0) {
      label = 'Not Assessed';
      message = 'Start tracking ${pet.name}\'s health to see the wellness score.';
    } else if (finalScore >= 90) {
      label = 'Excellent';
      message = '${pet.name} is in great health! Keep up the good work.';
    } else if (finalScore >= 75) {
      label = 'Good';
      message = '${pet.name} is doing well. A few areas could use attention.';
    } else if (finalScore >= 60) {
      label = 'Fair';
      message = '${pet.name} needs some attention. Review the indicators below.';
    } else if (finalScore >= 40) {
      label = 'Needs Attention';
      message = 'Several health indicators need improvement. Consider a vet visit.';
    } else {
      label = 'Concerning';
      message = 'Please consult a veterinarian about ${pet.name}\'s health.';
    }

    return _ScoreResult(
      score: finalScore,
      label: label,
      message: message,
    );
  }
}

class _ScoreResult {
  final int score;
  final String label;
  final String message;

  const _ScoreResult({
    required this.score,
    required this.label,
    required this.message,
  });
}

/// 完成度指示器
class _CompletionIndicator extends StatelessWidget {
  final int completed;
  final int total;

  const _CompletionIndicator({
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 进度点
        ...List.generate(total, (index) {
          final isCompleted = index < completed;
          return Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted 
                  ? Colors.white 
                  : Colors.white.withOpacity(0.3),
            ),
          );
        }),
        const SizedBox(width: 8),
        Text(
          '$completed/$total checked',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
