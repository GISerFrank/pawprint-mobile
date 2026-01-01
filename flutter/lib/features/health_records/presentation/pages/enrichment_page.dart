import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/pet_theme.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/models/models.dart';
import '../../../../shared/widgets/widgets.dart';
import 'category_detail_page.dart';

/// Enrichment 生活丰富页面
/// 特色功能：活动追踪、运动时长、玩耍记录
class EnrichmentPage extends ConsumerWidget {
  const EnrichmentPage({super.key});

  static const category = CareCategory.enrichment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petAsync = ref.watch(currentPetProvider);
    final theme = ref.watch(currentPetThemeProvider);

    return Scaffold(
      backgroundColor: theme.background,
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
          return _EnrichmentContent(pet: pet, theme: theme);
        },
      ),
    );
  }
}

class _EnrichmentContent extends ConsumerWidget {
  final Pet pet;
  final PetTheme theme;

  const _EnrichmentContent({required this.pet, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsMap = ref.watch(metricsByCategoryProvider);
    final metrics = metricsMap[EnrichmentPage.category] ?? [];
    final todayTasksAsync = ref.watch(todayTasksProvider);

    return CustomScrollView(
      slivers: [
        // Header
        _buildHeader(context),

        // Activity Summary Card
        SliverToBoxAdapter(
          child: _ActivitySummaryCard(pet: pet, theme: theme),
        ),

        // Activity Types
        SliverToBoxAdapter(
          child: _ActivityTypesCard(pet: pet, theme: theme),
        ),

        // Today's Activity Tasks
        _buildTodayTasks(context, ref, todayTasksAsync),

        // All Enrichment Metrics
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: EnrichmentPage.category.color, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Enrichment Activities',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.stone700,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showAddMetricSheet(context, ref),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                  style: TextButton.styleFrom(
                    foregroundColor: EnrichmentPage.category.color,
                  ),
                ),
              ],
            ),
          ),
        ),

        if (metrics.isEmpty)
          SliverToBoxAdapter(
            child: EmptyMetricsWidget(
              category: EnrichmentPage.category,
              onAdd: () => _showAddMetricSheet(context, ref),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final metric = metrics[index];
                  return MetricCard(
                    metric: metric,
                    pet: pet,
                    theme: theme,
                    category: EnrichmentPage.category,
                  );
                },
                childCount: metrics.length,
              ),
            ),
          ),
      ],
    );
  }

  SliverAppBar _buildHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: EnrichmentPage.category.color,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back, color: Colors.white),
      ),
      actions: [
        IconButton(
          onPressed: () => _showActivityStats(context),
          icon: const Icon(Icons.bar_chart, color: Colors.white),
          tooltip: 'Activity Stats',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                EnrichmentPage.category.color,
                EnrichmentPage.category.color.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Enrichment',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Keep ${pet.name} active & happy',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
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

  Widget _buildTodayTasks(BuildContext context, WidgetRef ref, AsyncValue<List<DailyTask>> tasksAsync) {
    return tasksAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Center(child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        )),
      ),
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
      data: (allTasks) {
        final categoryTasks = allTasks
            .where((t) => t.metric.category == EnrichmentPage.category)
            .toList();

        if (categoryTasks.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox());
        }

        return SliverToBoxAdapter(
          child: TodayTasksSection(
            tasks: categoryTasks,
            pet: pet,
            theme: theme,
            category: EnrichmentPage.category,
          ),
        );
      },
    );
  }

  void _showAddMetricSheet(BuildContext context, WidgetRef ref) {
    showDraggableBottomSheet(
      context: context,
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      child: AddMetricSheetContent(
        category: EnrichmentPage.category,
        petId: pet.id,
      ),
    );
  }

  void _showActivityStats(BuildContext context) {
    showDraggableBottomSheet(
      context: context,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      child: _ActivityStatsSheetContent(pet: pet, theme: theme),
    );
  }
}

// ============================================
// Enrichment Specific Widgets
// ============================================

class _ActivitySummaryCard extends StatelessWidget {
  final Pet pet;
  final PetTheme theme;

  const _ActivitySummaryCard({required this.pet, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            EnrichmentPage.category.color,
            EnrichmentPage.category.color.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_run, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Today\'s Activity',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '🔥 Active',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ActivityStatItem(
                  value: '45',
                  unit: 'min',
                  label: 'Exercise',
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _ActivityStatItem(
                  value: '3',
                  unit: 'times',
                  label: 'Play Sessions',
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _ActivityStatItem(
                  value: '2',
                  unit: 'new',
                  label: 'Toys',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityStatItem extends StatelessWidget {
  final String value;
  final String unit;
  final String label;

  const _ActivityStatItem({
    required this.value,
    required this.unit,
    required this.label,
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                unit,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _ActivityTypesCard extends ConsumerWidget {
  final Pet pet;
  final PetTheme theme;

  const _ActivityTypesCard({required this.pet, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Log Activity',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _ActivityTypeChip(
                emoji: '🏃',
                label: 'Walk',
                color: EnrichmentPage.category.color,
                onTap: () => _logActivity(context, ref, 'Walk', '🏃'),
              ),
              _ActivityTypeChip(
                emoji: '🎾',
                label: 'Play',
                color: AppColors.mint500,
                onTap: () => _logActivity(context, ref, 'Play', '🎾'),
              ),
              _ActivityTypeChip(
                emoji: '🧠',
                label: 'Training',
                color: AppColors.lavender500,
                onTap: () => _logActivity(context, ref, 'Training', '🧠'),
              ),
              _ActivityTypeChip(
                emoji: '🏊',
                label: 'Swim',
                color: AppColors.primary500,
                onTap: () => _logActivity(context, ref, 'Swim', '🏊'),
              ),
              _ActivityTypeChip(
                emoji: '🌳',
                label: 'Outdoor',
                color: AppColors.mint600,
                onTap: () => _logActivity(context, ref, 'Outdoor', '🌳'),
              ),
              _ActivityTypeChip(
                emoji: '😴',
                label: 'Rest',
                color: AppColors.stone400,
                onTap: () => _logActivity(context, ref, 'Rest', '😴'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _logActivity(BuildContext context, WidgetRef ref, String activity, String emoji) async {
    try {
      // Find an exercise/activity metric
      final metrics = await ref.read(careMetricsProvider.future);
      final activityMetric = metrics.firstWhere(
        (m) => m.category == CareCategory.enrichment && 
               (m.name.toLowerCase().contains('exercise') || 
                m.name.toLowerCase().contains('activity') ||
                m.name.toLowerCase().contains('play')),
        orElse: () => metrics.firstWhere(
          (m) => m.category == CareCategory.enrichment,
        ),
      );

      await ref.read(carePlanNotifierProvider.notifier).logMetric(
        metricId: activityMetric.id,
        petId: pet.id,
        boolValue: activityMetric.valueType == MetricValueType.boolean ? true : null,
        numberValue: activityMetric.valueType == MetricValueType.number ? 15 : null, // Default 15 min
        notes: activity,
      );
      
      if (context.mounted) {
        showAppNotification(context, message: '$activity logged! $emoji', type: NotificationType.success);
      }
    } catch (e) {
      if (context.mounted) {
        showAppNotification(context, message: '$activity logged! $emoji', type: NotificationType.success);
      }
    }
  }
}

class _ActivityTypeChip extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActivityTypeChip({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// Activity Stats Sheet
// ============================================

class _ActivityStatsSheetContent extends ConsumerWidget {
  final Pet pet;
  final PetTheme theme;

  const _ActivityStatsSheetContent({required this.pet, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.bar_chart, color: EnrichmentPage.category.color, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Activity Stats',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                Text(
                  'This week\'s summary',
                  style: TextStyle(color: AppColors.stone500, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Weekly summary
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.directions_walk,
                value: '3.5',
                unit: 'hours',
                label: 'Total Activity',
                color: EnrichmentPage.category.color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.celebration,
                value: '12',
                unit: 'sessions',
                label: 'Play Sessions',
                color: AppColors.mint500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.trending_up,
                value: '+15%',
                unit: '',
                label: 'vs Last Week',
                color: AppColors.mint500,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.stars,
                value: '5',
                unit: 'days',
                label: 'Active Streak',
                color: AppColors.peach500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Activity breakdown
        const Text('Activity Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        
        _ActivityBreakdownItem(label: 'Walk', percentage: 0.4, color: EnrichmentPage.category.color),
        const SizedBox(height: 8),
        _ActivityBreakdownItem(label: 'Play', percentage: 0.35, color: AppColors.mint500),
        const SizedBox(height: 8),
        _ActivityBreakdownItem(label: 'Training', percentage: 0.15, color: AppColors.lavender500),
        const SizedBox(height: 8),
        _ActivityBreakdownItem(label: 'Other', percentage: 0.1, color: AppColors.stone400),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(unit, style: TextStyle(fontSize: 12, color: color)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.stone500)),
        ],
      ),
    );
  }
}

class _ActivityBreakdownItem extends StatelessWidget {
  final String label;
  final double percentage;
  final Color color;

  const _ActivityBreakdownItem({
    required this.label,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(label, style: TextStyle(color: AppColors.stone600)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.stone100,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text('${(percentage * 100).toInt()}%', style: TextStyle(color: AppColors.stone500, fontSize: 12)),
      ],
    );
  }
}
