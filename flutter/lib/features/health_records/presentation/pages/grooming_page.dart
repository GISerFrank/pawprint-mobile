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

/// Care 护理保健页面
/// 特色功能：美容护理追踪、疫苗提醒、清洁记录
class GroomingPage extends ConsumerWidget {
  const GroomingPage({super.key});

  static const category = CareCategory.care;

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
          return _GroomingContent(pet: pet, theme: theme);
        },
      ),
    );
  }
}

class _GroomingContent extends ConsumerWidget {
  final Pet pet;
  final PetTheme theme;

  const _GroomingContent({required this.pet, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsMap = ref.watch(metricsByCategoryProvider);
    final metrics = metricsMap[GroomingPage.category] ?? [];
    final todayTasksAsync = ref.watch(todayTasksProvider);

    return CustomScrollView(
      slivers: [
        // Header
        _buildHeader(context),

        // Care Summary Card
        SliverToBoxAdapter(
          child: _CareSummaryCard(pet: pet, theme: theme),
        ),

        // Upcoming Care Tasks
        SliverToBoxAdapter(
          child: _UpcomingCareCard(pet: pet, theme: theme),
        ),

        // Today's Care Tasks
        _buildTodayTasks(context, ref, todayTasksAsync),

        // All Care Metrics
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Icon(Icons.medical_services, color: GroomingPage.category.color, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Care Routines',
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
                    foregroundColor: GroomingPage.category.color,
                  ),
                ),
              ],
            ),
          ),
        ),

        if (metrics.isEmpty)
          SliverToBoxAdapter(
            child: EmptyMetricsWidget(
              category: GroomingPage.category,
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
                    category: GroomingPage.category,
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
      backgroundColor: GroomingPage.category.color,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back, color: Colors.white),
      ),
      actions: [
        IconButton(
          onPressed: () {
            // TODO: Care calendar/reminders
          },
          icon: const Icon(Icons.calendar_month, color: Colors.white),
          tooltip: 'Care Calendar',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                GroomingPage.category.color,
                GroomingPage.category.color.withOpacity(0.8),
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
                    child: const Icon(Icons.medical_services, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Care',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Grooming & health care for ${pet.name}',
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
            .where((t) => t.metric.category == GroomingPage.category)
            .toList();

        if (categoryTasks.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox());
        }

        return SliverToBoxAdapter(
          child: TodayTasksSection(
            tasks: categoryTasks,
            pet: pet,
            theme: theme,
            category: GroomingPage.category,
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
        category: GroomingPage.category,
        petId: pet.id,
      ),
    );
  }
}

// ============================================
// Care Specific Widgets
// ============================================

class _CareSummaryCard extends StatelessWidget {
  final Pet pet;
  final PetTheme theme;

  const _CareSummaryCard({required this.pet, required this.theme});

  @override
  Widget build(BuildContext context) {
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
              Icon(Icons.spa, color: GroomingPage.category.color, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Care Overview',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _CareStatItem(
                icon: Icons.shower,
                label: 'Last Bath',
                value: '3 days ago',
                color: AppColors.primary500,
              ),
              const SizedBox(width: 12),
              _CareStatItem(
                icon: Icons.content_cut,
                label: 'Last Groom',
                value: '1 week ago',
                color: GroomingPage.category.color,
              ),
              const SizedBox(width: 12),
              _CareStatItem(
                icon: Icons.cleaning_services,
                label: 'Habitat',
                value: 'Clean',
                color: AppColors.mint500,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CareStatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _CareStatItem({
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
                fontSize: 12,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.stone500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingCareCard extends StatelessWidget {
  final Pet pet;
  final PetTheme theme;

  const _UpcomingCareCard({required this.pet, required this.theme});

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              Icon(Icons.upcoming, color: AppColors.peach500, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Upcoming Care',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _UpcomingItem(
            icon: Icons.vaccines,
            title: 'Annual Vaccination',
            subtitle: 'Due in 2 weeks',
            color: AppColors.peach500,
          ),
          const SizedBox(height: 12),
          _UpcomingItem(
            icon: Icons.content_cut,
            title: 'Nail Trim',
            subtitle: 'Due in 5 days',
            color: GroomingPage.category.color,
          ),
          const SizedBox(height: 12),
          _UpcomingItem(
            icon: Icons.medical_services,
            title: 'Vet Checkup',
            subtitle: 'Scheduled for next month',
            color: AppColors.primary500,
          ),
        ],
      ),
    );
  }
}

class _UpcomingItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _UpcomingItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.stone50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.stone500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.stone300),
        ],
      ),
    );
  }
}
