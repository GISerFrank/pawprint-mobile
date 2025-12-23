import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/pet_theme.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/models/models.dart';
import '../../../../shared/widgets/widgets.dart';

class PetCarePage extends ConsumerWidget {
  const PetCarePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petAsync = ref.watch(currentPetProvider);
    final theme = ref.watch(currentPetThemeProvider);

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: petAsync.when(
          loading: () => const Center(child: AppLoadingIndicator()),
          error: (e, _) => ErrorStateWidget(
            message: 'Failed to load data',
            onRetry: () => ref.invalidate(currentPetProvider),
          ),
          data: (pet) {
            if (pet == null) {
              return const Center(child: Text('No pet selected'));
            }
            return _PetCareContent(pet: pet, theme: theme);
          },
        ),
      ),
    );
  }
}

class _PetCareContent extends ConsumerStatefulWidget {
  final Pet pet;
  final PetTheme theme;

  const _PetCareContent({required this.pet, required this.theme});

  @override
  ConsumerState<_PetCareContent> createState() => _PetCareContentState();
}

class _PetCareContentState extends ConsumerState<_PetCareContent> {
  @override
  void initState() {
    super.initState();
    // 检查是否需要初始化基础指标
    _checkAndInitializeMetrics();
  }

  Future<void> _checkAndInitializeMetrics() async {
    final metrics = await ref.read(careMetricsProvider.future);
    if (metrics.isEmpty) {
      // 首次使用，初始化基础指标
      await ref.read(carePlanNotifierProvider.notifier).initializeBaseMetrics(
        widget.pet.id,
        widget.pet.species,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final wellnessScoreAsync = ref.watch(wellnessScoreProvider);
    final todayTasksAsync = ref.watch(todayTasksProvider);
    final progress = ref.watch(todayProgressProvider);
    final illnessAsync = ref.watch(activeIllnessProvider);

    return RefreshIndicator(
      color: widget.theme.primary,
      onRefresh: () async {
        ref.invalidate(currentPetProvider);
        ref.invalidate(careMetricsProvider);
        ref.invalidate(todayTasksProvider);
        ref.invalidate(wellnessScoreProvider);
        ref.invalidate(activeIllnessProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Pet Switcher
            _Header(pet: widget.pet, theme: widget.theme),
            const SizedBox(height: 20),

            // Health Alert (if sick)
            illnessAsync.maybeWhen(
              data: (illness) {
                if (illness == null || !widget.pet.isSick) return const SizedBox();
                return Column(
                  children: [
                    HealthAlertBanner(
                      petName: widget.pet.name,
                      illness: illness,
                      onUpdateTap: () {},
                      onVisitedVetTap: illness.sickType == SickType.undiagnosed ? () {} : null,
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
              orElse: () => const SizedBox(),
            ),

            // Wellness Score Card
            wellnessScoreAsync.when(
              loading: () => _WellnessScoreCardSkeleton(theme: widget.theme),
              error: (_, __) => const SizedBox(),
              data: (score) => _WellnessScoreCard(
                score: score,
                pet: widget.pet,
                theme: widget.theme,
              ),
            ),
            const SizedBox(height: 20),

            // Today's Plan
            _TodayPlanSection(
              tasksAsync: todayTasksAsync,
              progress: progress,
              pet: widget.pet,
              theme: widget.theme,
            ),
            const SizedBox(height: 20),

            // Category Cards
            _CategoryCardsSection(pet: widget.pet, theme: widget.theme),
            const SizedBox(height: 20),

            // AI Insights (placeholder for future)
            _AIInsightsSection(theme: widget.theme),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

// ============================================
// Header
// ============================================

class _Header extends StatelessWidget {
  final Pet pet;
  final PetTheme theme;

  const _Header({required this.pet, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PetAvatarButton(size: 48),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${pet.name}\'s Care',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Track wellness & daily care',
                style: TextStyle(color: AppColors.stone500, fontSize: 14),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            // TODO: Open settings/metrics management
          },
          icon: Icon(Icons.tune, color: theme.primary),
          tooltip: 'Manage Metrics',
        ),
      ],
    );
  }
}

// ============================================
// Wellness Score Card
// ============================================

class _WellnessScoreCard extends StatelessWidget {
  final WellnessScore score;
  final Pet pet;
  final PetTheme theme;

  const _WellnessScoreCard({
    required this.score,
    required this.pet,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primary, theme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Score Circle
              _ScoreCircle(score: score.overall, theme: theme),
              const SizedBox(width: 20),
              
              // Score Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wellness Score',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          score.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            score.grade,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (pet.isSick) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.healing, size: 14, color: Colors.white.withOpacity(0.9)),
                            const SizedBox(width: 4),
                            Text(
                              'Recovery Mode',
                              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Category Scores
          Row(
            children: [
              _CategoryScorePill(
                icon: Icons.favorite,
                label: 'Wellness',
                score: score.wellnessScore,
              ),
              const SizedBox(width: 8),
              _CategoryScorePill(
                icon: Icons.restaurant,
                label: 'Nutrition',
                score: score.nutritionScore,
              ),
              const SizedBox(width: 8),
              _CategoryScorePill(
                icon: Icons.auto_awesome,
                label: 'Enrichment',
                score: score.enrichmentScore,
              ),
              const SizedBox(width: 8),
              _CategoryScorePill(
                icon: Icons.medical_services,
                label: 'Care',
                score: score.careScore,
              ),
            ],
          ),
          
          // Improvements
          if (score.improvements.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.white.withOpacity(0.9), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      score.improvements.first,
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScoreCircle extends StatelessWidget {
  final double score;
  final PetTheme theme;

  const _ScoreCircle({required this.score, required this.theme});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        children: [
          // Background circle
          CustomPaint(
            size: const Size(80, 80),
            painter: _CircleProgressPainter(
              progress: score / 100,
              backgroundColor: Colors.white.withOpacity(0.2),
              progressColor: Colors.white,
              strokeWidth: 6,
            ),
          ),
          // Score text
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  score.round().toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '/100',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  _CircleProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _CategoryScorePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final double score;

  const _CategoryScorePill({
    required this.icon,
    required this.label,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(height: 4),
            Text(
              '${score.round()}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WellnessScoreCardSkeleton extends StatelessWidget {
  final PetTheme theme;

  const _WellnessScoreCardSkeleton({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primary.withOpacity(0.5), theme.primaryDark.withOpacity(0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}

// ============================================
// Today's Plan Section
// ============================================

class _TodayPlanSection extends ConsumerWidget {
  final AsyncValue<List<DailyTask>> tasksAsync;
  final ({int completed, int total, double percentage}) progress;
  final Pet pet;
  final PetTheme theme;

  const _TodayPlanSection({
    required this.tasksAsync,
    required this.progress,
    required this.pet,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.today, color: theme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Plan',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _getDateString(),
                      style: TextStyle(color: AppColors.stone500, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _ProgressBadge(progress: progress, theme: theme),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.percentage,
              backgroundColor: AppColors.stone100,
              valueColor: AlwaysStoppedAnimation(
                progress.percentage == 1.0 ? AppColors.mint500 : theme.primary,
              ),
              minHeight: 6,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Tasks
          tasksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Failed to load tasks'),
            data: (tasks) {
              if (tasks.isEmpty) {
                return _EmptyTasks(theme: theme);
              }
              
              // Group by time
              final morningTasks = tasks.where((t) => (t.scheduledTime ?? 0) < 12).toList();
              final afternoonTasks = tasks.where((t) => (t.scheduledTime ?? 12) >= 12 && (t.scheduledTime ?? 0) < 17).toList();
              final eveningTasks = tasks.where((t) => (t.scheduledTime ?? 17) >= 17).toList();
              final anytimeTasks = tasks.where((t) => t.scheduledTime == null).toList();
              
              return Column(
                children: [
                  if (morningTasks.isNotEmpty) _TaskGroup(label: '🌅 Morning', tasks: morningTasks, pet: pet, theme: theme),
                  if (afternoonTasks.isNotEmpty) _TaskGroup(label: '☀️ Afternoon', tasks: afternoonTasks, pet: pet, theme: theme),
                  if (eveningTasks.isNotEmpty) _TaskGroup(label: '🌙 Evening', tasks: eveningTasks, pet: pet, theme: theme),
                  if (anytimeTasks.isNotEmpty) _TaskGroup(label: '📋 Anytime', tasks: anytimeTasks, pet: pet, theme: theme),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _getDateString() {
    final now = DateTime.now();
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }
}

class _ProgressBadge extends StatelessWidget {
  final ({int completed, int total, double percentage}) progress;
  final PetTheme theme;

  const _ProgressBadge({required this.progress, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isComplete = progress.completed == progress.total && progress.total > 0;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isComplete ? AppColors.mint100 : theme.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isComplete ? '✓ All done!' : '${progress.completed}/${progress.total}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isComplete ? AppColors.mint600 : theme.primary,
        ),
      ),
    );
  }
}

class _TaskGroup extends StatelessWidget {
  final String label;
  final List<DailyTask> tasks;
  final Pet pet;
  final PetTheme theme;

  const _TaskGroup({
    required this.label,
    required this.tasks,
    required this.pet,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.stone500,
            ),
          ),
        ),
        ...tasks.map((task) => _TaskItem(task: task, pet: pet, theme: theme)),
      ],
    );
  }
}

class _TaskItem extends ConsumerWidget {
  final DailyTask task;
  final Pet pet;
  final PetTheme theme;

  const _TaskItem({
    required this.task,
    required this.pet,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metric = task.metric;
    final isCompleted = task.isCompleted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: isCompleted ? null : () => _completeTask(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isCompleted ? AppColors.mint50 : AppColors.stone50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCompleted ? AppColors.mint200 : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              // Checkbox/Icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.mint500 : metric.category.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : Center(
                        child: Text(
                          metric.emoji ?? '📋',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              
              // Task info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metric.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isCompleted ? AppColors.stone500 : AppColors.stone800,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (metric.description != null)
                      Text(
                        metric.description!,
                        style: TextStyle(fontSize: 12, color: AppColors.stone400),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              
              // Category badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: metric.category.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  metric.category.icon,
                  size: 14,
                  color: metric.category.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _completeTask(BuildContext context, WidgetRef ref) async {
    final metric = task.metric;

    if (metric.valueType == MetricValueType.boolean) {
      // Quick complete
      await ref.read(carePlanNotifierProvider.notifier).quickCompleteTask(metric, pet.id);
      if (context.mounted) {
        showAppNotification(context, message: '${metric.emoji ?? "✓"} ${metric.name} done!', type: NotificationType.success);
      }
    } else {
      // Show input dialog
      _showInputDialog(context, ref);
    }
  }

  void _showInputDialog(BuildContext context, WidgetRef ref) {
    final metric = task.metric;
    
    showDraggableBottomSheet(
      context: context,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      child: _MetricInputSheetContent(
        metric: metric,
        petId: pet.id,
        theme: theme,
      ),
    );
  }
}

class _EmptyTasks extends StatelessWidget {
  final PetTheme theme;

  const _EmptyTasks({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle, size: 40, color: theme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks for today',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.stone700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add metrics to start tracking',
            style: TextStyle(color: AppColors.stone500, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ============================================
// Metric Input Sheet
// ============================================

class _MetricInputSheetContent extends ConsumerStatefulWidget {
  final CareMetric metric;
  final String petId;
  final PetTheme theme;

  const _MetricInputSheetContent({
    required this.metric,
    required this.petId,
    required this.theme,
  });

  @override
  ConsumerState<_MetricInputSheetContent> createState() => _MetricInputSheetContentState();
}

class _MetricInputSheetContentState extends ConsumerState<_MetricInputSheetContent> {
  final _textController = TextEditingController();
  double _numberValue = 0;
  int _rangeValue = 3;
  String? _selectionValue;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _numberValue = widget.metric.targetValue ?? 0;
    if (widget.metric.options?.isNotEmpty == true) {
      _selectionValue = widget.metric.options!.first;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardAwareSheetContent(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                widget.metric.emoji ?? '📋',
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.metric.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    if (widget.metric.description != null)
                      Text(
                        widget.metric.description!,
                        style: TextStyle(color: AppColors.stone500, fontSize: 13),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Input based on type
          _buildInput(),
          
          const SizedBox(height: 24),
          
          // Save button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _loading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.theme.primary,
              ),
              child: _loading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Log'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    switch (widget.metric.valueType) {
      case MetricValueType.number:
        return _buildNumberInput();
      case MetricValueType.range:
        return _buildRangeInput();
      case MetricValueType.selection:
        return _buildSelectionInput();
      case MetricValueType.text:
        return _buildTextInput();
      default:
        return const SizedBox();
    }
  }

  Widget _buildNumberInput() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () => setState(() => _numberValue = (_numberValue - 1).clamp(0, 999)),
              icon: const Icon(Icons.remove_circle_outline),
              iconSize: 32,
            ),
            const SizedBox(width: 20),
            Column(
              children: [
                Text(
                  _numberValue.toStringAsFixed(widget.metric.unit == 'kg' ? 1 : 0),
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                ),
                if (widget.metric.unit != null)
                  Text(
                    widget.metric.unit!,
                    style: TextStyle(color: AppColors.stone500, fontSize: 16),
                  ),
              ],
            ),
            const SizedBox(width: 20),
            IconButton(
              onPressed: () => setState(() => _numberValue = (_numberValue + 1).clamp(0, 999)),
              icon: const Icon(Icons.add_circle_outline),
              iconSize: 32,
            ),
          ],
        ),
        if (widget.metric.targetValue != null) ...[
          const SizedBox(height: 12),
          Text(
            'Target: ${widget.metric.targetValue} ${widget.metric.unit ?? ""}',
            style: TextStyle(color: AppColors.stone500),
          ),
        ],
      ],
    );
  }

  Widget _buildRangeInput() {
    final emojis = ['😢', '😕', '😐', '🙂', '😊'];
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (index) {
            final value = index + 1;
            final isSelected = _rangeValue == value;
            return GestureDetector(
              onTap: () => setState(() => _rangeValue = value),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isSelected ? widget.theme.primary : AppColors.stone100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    emojis[index],
                    style: TextStyle(fontSize: isSelected ? 28 : 24),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Text(
          _getRangeLabel(_rangeValue),
          style: TextStyle(
            color: widget.theme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _getRangeLabel(int value) {
    switch (value) {
      case 1: return 'Poor';
      case 2: return 'Fair';
      case 3: return 'Good';
      case 4: return 'Very Good';
      case 5: return 'Excellent';
      default: return '';
    }
  }

  Widget _buildSelectionInput() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.metric.options!.map((option) {
        final isSelected = _selectionValue == option;
        return ChoiceChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (selected) => setState(() => _selectionValue = option),
          selectedColor: widget.theme.primary,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.stone700,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextInput() {
    return TextField(
      controller: _textController,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Add notes...',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await ref.read(carePlanNotifierProvider.notifier).logMetric(
        metricId: widget.metric.id,
        petId: widget.petId,
        boolValue: widget.metric.valueType == MetricValueType.boolean ? true : null,
        numberValue: widget.metric.valueType == MetricValueType.number ? _numberValue : null,
        rangeValue: widget.metric.valueType == MetricValueType.range ? _rangeValue : null,
        selectionValue: widget.metric.valueType == MetricValueType.selection ? _selectionValue : null,
        textValue: widget.metric.valueType == MetricValueType.text ? _textController.text : null,
      );
      if (mounted) {
        Navigator.pop(context);
        showAppNotification(context, message: '${widget.metric.emoji ?? "✓"} Logged!', type: NotificationType.success);
      }
    } catch (e) {
      showAppNotification(context, message: 'Failed to log', type: NotificationType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ============================================
// Category Cards Section
// ============================================

class _CategoryCardsSection extends ConsumerWidget {
  final Pet pet;
  final PetTheme theme;

  const _CategoryCardsSection({required this.pet, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsMap = ref.watch(metricsByCategoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.dashboard, size: 20, color: AppColors.stone500),
            const SizedBox(width: 8),
            Text(
              'Categories',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.stone700),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: CareCategory.values.map((category) {
            final metrics = metricsMap[category] ?? [];
            return _CategoryCard(
              category: category,
              metricsCount: metrics.length,
              pet: pet,
              theme: theme,
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CareCategory category;
  final int metricsCount;
  final Pet pet;
  final PetTheme theme;

  const _CategoryCard({
    required this.category,
    required this.metricsCount,
    required this.pet,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _navigateToDetail(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(category.icon, color: category.color, size: 20),
                ),
                const Spacer(),
                Icon(Icons.chevron_right, color: AppColors.stone300, size: 20),
              ],
            ),
            const Spacer(),
            Text(
              category.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 2),
            Text(
              '$metricsCount metrics',
              style: TextStyle(color: AppColors.stone500, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context) {
    final route = switch (category) {
      CareCategory.wellness => AppRoutes.wellness,
      CareCategory.nutrition => AppRoutes.nutrition,
      CareCategory.enrichment => AppRoutes.enrichment,
      CareCategory.care => AppRoutes.grooming,
    };
    context.push(route);
  }
}

// ============================================
// AI Insights Section
// ============================================

class _AIInsightsSection extends StatelessWidget {
  final PetTheme theme;

  const _AIInsightsSection({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.primaryLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: theme.gradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Insights',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  'Get personalized recommendations based on your pet\'s data',
                  style: TextStyle(color: AppColors.stone500, fontSize: 13),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: theme.primary),
        ],
      ),
    );
  }
}
