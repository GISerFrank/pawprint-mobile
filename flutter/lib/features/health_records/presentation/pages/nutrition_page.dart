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

/// Nutrition 营养管理页面
/// 特色功能：喂食时间表、水分摄入追踪、饮食记录
class NutritionPage extends ConsumerWidget {
  const NutritionPage({super.key});

  static const category = CareCategory.nutrition;

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
          return _NutritionContent(pet: pet, theme: theme);
        },
      ),
    );
  }
}

class _NutritionContent extends ConsumerWidget {
  final Pet pet;
  final PetTheme theme;

  const _NutritionContent({required this.pet, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsMap = ref.watch(metricsByCategoryProvider);
    final metrics = metricsMap[NutritionPage.category] ?? [];
    final todayTasksAsync = ref.watch(todayTasksProvider);

    return CustomScrollView(
      slivers: [
        // Header
        _buildHeader(context),

        // Feeding Summary Card
        SliverToBoxAdapter(
          child: _FeedingSummaryCard(pet: pet, theme: theme),
        ),

        // Quick Actions
        SliverToBoxAdapter(
          child: _QuickActionsCard(pet: pet, theme: theme),
        ),

        // Today's Feeding Tasks
        _buildTodayTasks(context, ref, todayTasksAsync),

        // All Nutrition Metrics
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Icon(Icons.restaurant, color: NutritionPage.category.color, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Nutrition Tracking',
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
                    foregroundColor: NutritionPage.category.color,
                  ),
                ),
              ],
            ),
          ),
        ),

        if (metrics.isEmpty)
          SliverToBoxAdapter(
            child: EmptyMetricsWidget(
              category: NutritionPage.category,
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
                    category: NutritionPage.category,
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
      backgroundColor: NutritionPage.category.color,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back, color: Colors.white),
      ),
      actions: [
        IconButton(
          onPressed: () {
            // TODO: Open feeding schedule
          },
          icon: const Icon(Icons.schedule, color: Colors.white),
          tooltip: 'Feeding Schedule',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                NutritionPage.category.color,
                NutritionPage.category.color.withOpacity(0.8),
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
                    child: const Icon(Icons.restaurant, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Nutrition',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage ${pet.name}\'s diet & feeding',
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
            .where((t) => t.metric.category == NutritionPage.category)
            .toList();

        if (categoryTasks.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox());
        }

        return SliverToBoxAdapter(
          child: TodayTasksSection(
            tasks: categoryTasks,
            pet: pet,
            theme: theme,
            category: NutritionPage.category,
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
        category: NutritionPage.category,
        petId: pet.id,
      ),
    );
  }
}

// ============================================
// Nutrition Specific Widgets
// ============================================

class _FeedingSummaryCard extends ConsumerWidget {
  final Pet pet;
  final PetTheme theme;

  const _FeedingSummaryCard({required this.pet, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayTasksAsync = ref.watch(todayTasksProvider);

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
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
              Icon(Icons.today, color: NutritionPage.category.color, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Today\'s Feeding',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          todayTasksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Failed to load'),
            data: (tasks) {
              final nutritionTasks = tasks.where((t) => t.metric.category == NutritionPage.category).toList();
              final completed = nutritionTasks.where((t) => t.isCompleted).length;
              final total = nutritionTasks.length;

              return Row(
                children: [
                  _FeedingStatItem(
                    icon: Icons.check_circle,
                    label: 'Completed',
                    value: '$completed',
                    color: AppColors.mint500,
                  ),
                  const SizedBox(width: 16),
                  _FeedingStatItem(
                    icon: Icons.pending,
                    label: 'Remaining',
                    value: '${total - completed}',
                    color: NutritionPage.category.color,
                  ),
                  const SizedBox(width: 16),
                  _FeedingStatItem(
                    icon: Icons.water_drop,
                    label: 'Water',
                    value: '✓',
                    color: AppColors.primary500,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FeedingStatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _FeedingStatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.stone500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  final Pet pet;
  final PetTheme theme;

  const _QuickActionsCard({required this.pet, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          _QuickActionButton(
            icon: Icons.breakfast_dining,
            label: 'Log Meal',
            color: NutritionPage.category.color,
            onTap: () {
              // TODO: Quick log meal
              showAppNotification(context, message: 'Meal logged!', type: NotificationType.success);
            },
          ),
          const SizedBox(width: 12),
          _QuickActionButton(
            icon: Icons.water_drop,
            label: 'Water',
            color: AppColors.primary500,
            onTap: () {
              // TODO: Quick log water
              showAppNotification(context, message: 'Water logged!', type: NotificationType.success);
            },
          ),
          const SizedBox(width: 12),
          _QuickActionButton(
            icon: Icons.cookie,
            label: 'Treat',
            color: AppColors.peach500,
            onTap: () {
              // TODO: Quick log treat
              showAppNotification(context, message: 'Treat logged!', type: NotificationType.success);
            },
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
