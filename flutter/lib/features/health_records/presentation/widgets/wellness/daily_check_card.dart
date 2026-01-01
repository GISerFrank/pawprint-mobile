import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/pet_theme.dart';
import '../../../../../core/models/models.dart';
import '../../../../../core/providers/wellness_provider.dart';
import '../../pages/daily_check_history_page.dart';
import 'sparkline.dart';
import 'metric_attachment_input.dart';

/// 每日健康检查卡片
/// 显示单个指标的 1-5 分评分
/// 右上角 Add To 按钮可将卡片添加到 Quick Log
class DailyCheckCard extends ConsumerWidget {
  final String petId;
  final String indicatorId;
  final String name;
  final String nameZh;
  final String emoji;
  final String description;
  final PetTheme theme;
  final bool showAddTo; // 是否显示 Add To 按钮（在 Quick Log 中不显示）

  const DailyCheckCard({
    super.key,
    required this.petId,
    required this.indicatorId,
    required this.name,
    required this.nameZh,
    required this.emoji,
    required this.description,
    required this.theme,
    this.showAddTo = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayScoresAsync = ref.watch(todayWellnessScoresProvider);
    final historyAsync = ref.watch(dailyCheckHistoryProvider(indicatorId));
    final isPinnedAsync = ref.watch(isMetricPinnedProvider(indicatorId));

    return todayScoresAsync.when(
      loading: () => _buildCard(context, ref, null, [], false),
      error: (_, __) => _buildCard(context, ref, null, [], false),
      data: (scores) {
        return historyAsync.when(
          loading: () => _buildCard(context, ref, scores.getScore(indicatorId),
              [], isPinnedAsync.valueOrNull ?? false),
          error: (_, __) => _buildCard(
              context,
              ref,
              scores.getScore(indicatorId),
              [],
              isPinnedAsync.valueOrNull ?? false),
          data: (history) {
            final recentScores = history
                .take(7)
                .map((log) => log.rangeValue ?? 3)
                .toList()
                .reversed
                .toList();
            return _buildCard(context, ref, scores.getScore(indicatorId),
                recentScores, isPinnedAsync.valueOrNull ?? false);
          },
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, WidgetRef ref, int? todayScore,
      List<int> historyScores, bool isPinned) {
    final hasScore = todayScore != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _showRatingDialog(context, ref, todayScore),
              onLongPress: () => _showHistory(context),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题行
                    Row(
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            name,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.stone800,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // 今日评分（右上角已有 Add To 按钮，这里只显示分数）
                        if (hasScore)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  _getScoreColor(todayScore).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$todayScore',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _getScoreColor(todayScore),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const Spacer(),

                    // Sparkline 或评分条
                    if (historyScores.isNotEmpty)
                      ScoreSparkline(scores: historyScores, height: 20)
                    else if (hasScore)
                      _ScoreBar(score: todayScore)
                    else
                      Text(
                        'Tap to rate',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.stone400,
                              fontSize: 11,
                            ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Add To 按钮
          if (showAddTo)
            Positioned(
              top: 2,
              right: 2,
              child: _AddToButton(
                isPinned: isPinned,
                indicatorId: indicatorId,
                name: name,
                theme: theme,
              ),
            ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score <= 2) return AppColors.red400;
    if (score == 3) return AppColors.amber400;
    return AppColors.green400;
  }

  void _showRatingDialog(
      BuildContext context, WidgetRef ref, int? currentScore) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _RatingSheet(
        petId: petId,
        indicatorId: indicatorId,
        name: name,
        nameZh: nameZh,
        emoji: emoji,
        description: description,
        currentScore: currentScore,
        theme: theme,
      ),
    );
  }

  void _showHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DailyCheckHistoryPage(
          indicatorId: indicatorId,
          name: name,
          nameZh: nameZh,
          emoji: emoji,
        ),
      ),
    );
  }
}

/// Add To 按钮 - 点击显示添加选项
class _AddToButton extends ConsumerWidget {
  final bool isPinned;
  final String indicatorId;
  final String name;
  final PetTheme theme;

  const _AddToButton({
    required this.isPinned,
    required this.indicatorId,
    required this.name,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showAddToSheet(context, ref),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: isPinned
              ? Icon(Icons.push_pin, size: 14, color: theme.primary)
              : Text(
                  'Add To',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.stone400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
      ),
    );
  }

  void _showAddToSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.stone300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.add_circle_outline,
                          color: theme.primary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Add To',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Choose where to add this metric',
                            style: TextStyle(
                                color: AppColors.stone500, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Quick Log 选项
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isPinned ? theme.primaryLight : AppColors.stone100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.bolt,
                    color: isPinned ? theme.primary : AppColors.stone500,
                    size: 20,
                  ),
                ),
                title: const Text('Quick Log'),
                subtitle: Text(
                  isPinned
                      ? 'Currently added'
                      : 'Add to Care page for quick access',
                  style: TextStyle(fontSize: 12, color: AppColors.stone500),
                ),
                trailing: isPinned
                    ? Icon(Icons.check_circle, color: theme.primary)
                    : Icon(Icons.add_circle_outline, color: AppColors.stone400),
                onTap: () async {
                  Navigator.pop(context);
                  if (isPinned) {
                    await ref
                        .read(pinnedMetricsNotifierProvider.notifier)
                        .unpinMetric(indicatorId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$name removed from Quick Log')),
                      );
                    }
                  } else {
                    await ref
                        .read(pinnedMetricsNotifierProvider.notifier)
                        .pinMetric(indicatorId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$name added to Quick Log')),
                      );
                    }
                  }
                },
              ),

              // Home Widget 选项（Coming Soon）
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.stone100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.widgets_outlined,
                      color: AppColors.stone400, size: 20),
                ),
                title: const Text('Home Widget'),
                subtitle: Text(
                  'Coming soon',
                  style: TextStyle(fontSize: 12, color: AppColors.stone400),
                ),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.stone100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Soon',
                    style: TextStyle(fontSize: 10, color: AppColors.stone500),
                  ),
                ),
                enabled: false,
              ),

              // Watch 选项（Coming Soon）
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.stone100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.watch_outlined,
                      color: AppColors.stone400, size: 20),
                ),
                title: const Text('Apple Watch'),
                subtitle: Text(
                  'Coming soon',
                  style: TextStyle(fontSize: 12, color: AppColors.stone400),
                ),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.stone100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Soon',
                    style: TextStyle(fontSize: 10, color: AppColors.stone500),
                  ),
                ),
                enabled: false,
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// 简单评分条
class _ScoreBar extends StatelessWidget {
  final int score;

  const _ScoreBar({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score <= 2
        ? AppColors.red400
        : (score == 3 ? AppColors.amber400 : AppColors.green400);

    return Row(
      children: List.generate(5, (index) {
        final isActive = index < score;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < 4 ? 2 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: isActive ? color : AppColors.stone200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

/// 评分选择底部弹窗
class _RatingSheet extends ConsumerStatefulWidget {
  final String petId;
  final String indicatorId;
  final String name;
  final String nameZh;
  final String emoji;
  final String description;
  final int? currentScore;
  final PetTheme theme;

  const _RatingSheet({
    required this.petId,
    required this.indicatorId,
    required this.name,
    required this.nameZh,
    required this.emoji,
    required this.description,
    this.currentScore,
    required this.theme,
  });

  @override
  ConsumerState<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends ConsumerState<_RatingSheet> {
  late int _selectedScore;
  bool _isSaving = false;
  final _notesController = TextEditingController();
  final List<String> _imageUrls = [];

  @override
  void initState() {
    super.initState();
    _selectedScore = widget.currentScore ?? 5;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync =
        ref.watch(dailyCheckHistoryProvider(widget.indicatorId));

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 拖动指示器
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.stone300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // 标题
              Row(
                children: [
                  Text(
                    widget.emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.name,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          widget.description,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.stone500,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 历史预览
              historyAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (history) {
                  if (history.isEmpty) return const SizedBox.shrink();
                  return _HistoryPreview(
                    history: history,
                    indicatorId: widget.indicatorId,
                    name: widget.name,
                    nameZh: widget.nameZh,
                    emoji: widget.emoji,
                  );
                },
              ),
              const SizedBox(height: 20),

              // 评分选择
              Row(
                children: List.generate(5, (index) {
                  final score = index + 1;
                  final isSelected = score == _selectedScore;
                  final color = _getScoreColor(score);

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedScore = score),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: EdgeInsets.only(right: index < 4 ? 8 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? color : AppColors.stone100,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(color: color, width: 2)
                              : Border.all(color: AppColors.stone200),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$score',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.stone600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getScoreLabel(score),
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected
                                    ? Colors.white.withOpacity(0.9)
                                    : AppColors.stone500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              // 当前选择描述
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getScoreColor(_selectedScore).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getScoreDescription(_selectedScore),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _getScoreColor(_selectedScore),
                        fontWeight: FontWeight.w500,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),

              // 备注和图片附件
              MetricAttachmentInput(
                notesController: _notesController,
                imageUrls: _imageUrls,
                onImagesChanged: (urls) => setState(() {
                  _imageUrls.clear();
                  _imageUrls.addAll(urls);
                }),
              ),
              const SizedBox(height: 20),

              // 保存按钮
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveScore,
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.theme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveScore() async {
    setState(() => _isSaving = true);

    final success =
        await ref.read(wellnessScoreNotifierProvider.notifier).saveDailyScore(
              petId: widget.petId,
              indicatorId: widget.indicatorId,
              score: _selectedScore,
              notes: _notesController.text.isNotEmpty
                  ? _notesController.text
                  : null,
              imageUrls: _imageUrls.isNotEmpty ? _imageUrls : null,
            );

    setState(() => _isSaving = false);

    if (success && mounted) {
      // 刷新相关 providers
      ref.invalidate(todayWellnessScoresProvider);
      ref.invalidate(dailyCheckHistoryProvider(widget.indicatorId));

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.name} rated $_selectedScore/5'),
          backgroundColor: AppColors.green500,
        ),
      );
    }
  }

  Color _getScoreColor(int score) {
    if (score == 1) return AppColors.red500;
    if (score == 2) return AppColors.orange500;
    if (score == 3) return AppColors.amber500;
    if (score == 4) return AppColors.lime500;
    return AppColors.green500;
  }

  String _getScoreLabel(int score) {
    switch (score) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'OK';
      case 4:
        return 'Good';
      case 5:
        return 'Great';
      default:
        return '';
    }
  }

  String _getScoreDescription(int score) {
    switch (score) {
      case 1:
        return 'Severe issue - needs immediate attention';
      case 2:
        return 'Notable concern - monitor closely';
      case 3:
        return 'Minor issue - keep an eye on it';
      case 4:
        return 'Mostly normal - minor variation';
      case 5:
        return 'Excellent - completely healthy!';
      default:
        return '';
    }
  }
}

/// 历史预览组件
class _HistoryPreview extends StatelessWidget {
  final List<MetricLog> history;
  final String indicatorId;
  final String name;
  final String nameZh;
  final String emoji;

  const _HistoryPreview({
    required this.history,
    required this.indicatorId,
    required this.name,
    required this.nameZh,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    // 取最近7条记录
    final recentHistory = history.take(7).toList();
    final scores = recentHistory.map((h) => h.rangeValue ?? 0).toList();
    final avgScore =
        scores.isEmpty ? 0.0 : scores.reduce((a, b) => a + b) / scores.length;

    // 显示最近5个分数
    final displayScores = scores.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.stone50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.stone200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            children: [
              Icon(Icons.history, size: 14, color: AppColors.stone500),
              const SizedBox(width: 6),
              Text(
                'Recent',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.stone600,
                ),
              ),
              const Spacer(),
              // 平均分
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getAvgColor(avgScore).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'avg ${avgScore.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _getAvgColor(avgScore),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 分数序列
          Row(
            children: [
              // 最近分数点
              Expanded(
                child: Row(
                  children: displayScores.asMap().entries.map((entry) {
                    final index = entry.key;
                    final score = entry.value;
                    final isLast = index == displayScores.length - 1;
                    return Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: _getScoreColor(score).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '$score',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _getScoreColor(score),
                                ),
                              ),
                            ),
                          ),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                height: 2,
                                color: AppColors.stone200,
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Sparkline
          SizedBox(
            height: 24,
            child: ScoreSparkline(
              scores: scores.reversed.toList(),
              height: 24,
            ),
          ),
          const SizedBox(height: 10),

          // 查看全部链接
          GestureDetector(
            onTap: () {
              Navigator.pop(context); // 关闭底部弹窗
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DailyCheckHistoryPage(
                    indicatorId: indicatorId,
                    name: name,
                    nameZh: nameZh,
                    emoji: emoji,
                  ),
                ),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'View full history',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.stone500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 10,
                  color: AppColors.stone500,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score <= 2) return AppColors.red500;
    if (score == 3) return AppColors.amber500;
    if (score == 4) return AppColors.lime500;
    return AppColors.green500;
  }

  Color _getAvgColor(double avg) {
    if (avg < 2.5) return AppColors.red500;
    if (avg < 3.5) return AppColors.amber500;
    return AppColors.green500;
  }
}
