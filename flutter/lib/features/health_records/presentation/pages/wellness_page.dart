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

/// Wellness 健康状态页面
/// 特色功能：健康趋势图表、症状追踪、体重变化
class WellnessPage extends ConsumerWidget {
  const WellnessPage({super.key});

  static const category = CareCategory.wellness;

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
          return _WellnessContent(pet: pet, theme: theme);
        },
      ),
    );
  }
}

class _WellnessContent extends ConsumerWidget {
  final Pet pet;
  final PetTheme theme;

  const _WellnessContent({required this.pet, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsMap = ref.watch(metricsByCategoryProvider);
    final metrics = metricsMap[WellnessPage.category] ?? [];
    final todayTasksAsync = ref.watch(todayTasksProvider);
    final illnessAsync = ref.watch(activeIllnessProvider);

    return CustomScrollView(
      slivers: [
        // Header
        _buildHeader(context),

        // Health Status Alert (if sick)
        illnessAsync.maybeWhen(
          data: (illness) {
            if (illness == null || !pet.isSick) return const SliverToBoxAdapter(child: SizedBox());
            return SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: HealthAlertBanner(
                  petName: pet.name,
                  illness: illness,
                  onUpdateTap: () => _showSymptomTracker(context, ref, illness),
                  onVisitedVetTap: illness.sickType == SickType.undiagnosed 
                      ? () => _showVisitedVetSheet(context, ref, illness)
                      : null,
                ),
              ),
            );
          },
          orElse: () => const SliverToBoxAdapter(child: SizedBox()),
        ),

        // Wellness Overview Card
        SliverToBoxAdapter(
          child: _WellnessOverviewCard(pet: pet, theme: theme),
        ),

        // Weight Trend (if has weight metric)
        SliverToBoxAdapter(
          child: _WeightTrendCard(pet: pet, theme: theme),
        ),

        // Today's Wellness Tasks
        _buildTodayTasks(context, ref, todayTasksAsync),

        // All Wellness Metrics
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Icon(Icons.favorite, color: WellnessPage.category.color, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Health Metrics',
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
                    foregroundColor: WellnessPage.category.color,
                  ),
                ),
              ],
            ),
          ),
        ),

        if (metrics.isEmpty)
          SliverToBoxAdapter(
            child: EmptyMetricsWidget(
              category: WellnessPage.category,
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
                    category: WellnessPage.category,
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
      backgroundColor: WellnessPage.category.color,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back, color: Colors.white),
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.insights, color: Colors.white),
          tooltip: 'Health Insights',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                WellnessPage.category.color,
                WellnessPage.category.color.withOpacity(0.8),
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
                    child: const Icon(Icons.favorite, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Wellness',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Track ${pet.name}\'s health & vitals',
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
            .where((t) => t.metric.category == WellnessPage.category)
            .toList();

        if (categoryTasks.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox());
        }

        return SliverToBoxAdapter(
          child: TodayTasksSection(
            tasks: categoryTasks,
            pet: pet,
            theme: theme,
            category: WellnessPage.category,
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
        category: WellnessPage.category,
        petId: pet.id,
      ),
    );
  }

  void _showSymptomTracker(BuildContext context, WidgetRef ref, IllnessRecord illness) {
    showDraggableBottomSheet(
      context: context,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      child: DailySymptomTrackerContent(illness: illness),
    );
  }

  void _showVisitedVetSheet(BuildContext context, WidgetRef ref, IllnessRecord illness) {
    showDraggableBottomSheet(
      context: context,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      child: VisitedVetSheetContent(illness: illness),
    );
  }
}

// ============================================
// Wellness Specific Widgets
// ============================================

class _WellnessOverviewCard extends StatelessWidget {
  final Pet pet;
  final PetTheme theme;

  const _WellnessOverviewCard({required this.pet, required this.theme});

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
              Icon(Icons.monitor_heart, color: WellnessPage.category.color, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Health Overview',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _OverviewItem(
                icon: Icons.favorite,
                label: 'Status',
                value: pet.isSick ? 'Needs Care' : 'Healthy',
                color: pet.isSick ? AppColors.peach500 : AppColors.mint500,
              ),
              const SizedBox(width: 16),
              _OverviewItem(
                icon: Icons.monitor_weight,
                label: 'Weight',
                value: '${pet.weightKg.toStringAsFixed(1)} kg',
                color: theme.primary,
              ),
              const SizedBox(width: 16),
              _OverviewItem(
                icon: Icons.cake,
                label: 'Age',
                value: _formatAge(pet.ageMonths),
                color: AppColors.lavender500,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatAge(int months) {
    if (months < 12) return '$months mo';
    final years = months ~/ 12;
    final remainingMonths = months % 12;
    if (remainingMonths == 0) return '$years yr';
    return '$years yr $remainingMonths mo';
  }
}

class _OverviewItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _OverviewItem({
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
                fontSize: 14,
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

class _WeightTrendCard extends ConsumerWidget {
  final Pet pet;
  final PetTheme theme;

  const _WeightTrendCard({required this.pet, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Implement weight trend chart with actual data
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
              Icon(Icons.show_chart, color: theme.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Weight Trend',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to detailed weight history
                },
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Placeholder for chart
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.stone50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_graph, size: 32, color: AppColors.stone300),
                  const SizedBox(height: 8),
                  Text(
                    'Log weight to see trends',
                    style: TextStyle(color: AppColors.stone400, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// Symptom Tracker Sheet Content
// ============================================

class DailySymptomTrackerContent extends ConsumerStatefulWidget {
  final IllnessRecord illness;

  const DailySymptomTrackerContent({super.key, required this.illness});

  @override
  ConsumerState<DailySymptomTrackerContent> createState() => _DailySymptomTrackerContentState();
}

class _DailySymptomTrackerContentState extends ConsumerState<DailySymptomTrackerContent> {
  final _notesController = TextEditingController();
  int _overallFeeling = 3;
  bool _loading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await ref.read(illnessNotifierProvider.notifier).addSymptomLog(
        illnessId: widget.illness.id,
        overallFeeling: _overallFeeling,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );
      if (mounted) {
        Navigator.pop(context);
        showAppNotification(context, message: 'Symptoms logged', type: NotificationType.success);
      }
    } catch (e) {
      showAppNotification(context, message: 'Failed to log', type: NotificationType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardAwareSheetContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Daily Symptom Check', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'How is your pet feeling today?',
            style: TextStyle(color: AppColors.stone500),
          ),
          const SizedBox(height: 24),

          // Overall feeling slider
          Text('Overall Feeling', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.stone600)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final value = index + 1;
              final isSelected = value <= _overallFeeling;
              return GestureDetector(
                onTap: () => setState(() => _overallFeeling = value),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    isSelected ? Icons.favorite : Icons.favorite_border,
                    size: 36,
                    color: isSelected ? AppColors.peach500 : AppColors.stone300,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _getFeelingLabel(_overallFeeling),
              style: TextStyle(color: AppColors.stone600, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 24),

          // Notes
          Text('Notes', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.stone600)),
          const SizedBox(height: 8),
          AppTextField(
            controller: _notesController,
            hintText: 'Any changes or observations...',
            maxLines: 3,
          ),
          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _loading ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.peach500),
              child: _loading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Log Symptoms'),
            ),
          ),
        ],
      ),
    );
  }

  String _getFeelingLabel(int value) {
    return switch (value) {
      1 => 'Very Poor',
      2 => 'Poor',
      3 => 'Fair',
      4 => 'Good',
      5 => 'Much Better',
      _ => '',
    };
  }
}

// ============================================
// Visited Vet Sheet Content
// ============================================

class VisitedVetSheetContent extends ConsumerStatefulWidget {
  final IllnessRecord illness;

  const VisitedVetSheetContent({super.key, required this.illness});

  @override
  ConsumerState<VisitedVetSheetContent> createState() => _VisitedVetSheetContentState();
}

class _VisitedVetSheetContentState extends ConsumerState<VisitedVetSheetContent> {
  final _diagnosisController = TextEditingController();
  final _vetNotesController = TextEditingController();
  DateTime? _followUpDate;
  bool _loading = false;

  @override
  void dispose() {
    _diagnosisController.dispose();
    _vetNotesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_diagnosisController.text.isEmpty) {
      showAppNotification(context, message: 'Please enter the diagnosis', type: NotificationType.error);
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(illnessNotifierProvider.notifier).updateIllness(
        illnessId: widget.illness.id,
        sickType: SickType.diagnosed,
        diagnosis: _diagnosisController.text,
        vetNotes: _vetNotesController.text.isNotEmpty ? _vetNotesController.text : null,
        followUpDate: _followUpDate,
      );
      if (mounted) {
        Navigator.pop(context);
        showAppNotification(context, message: 'Updated! Hope the treatment helps 💚', type: NotificationType.success);
      }
    } catch (e) {
      showAppNotification(context, message: 'Failed to update', type: NotificationType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardAwareSheetContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What did the vet say?', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),

          Text('Diagnosis', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.stone600)),
          const SizedBox(height: 8),
          AppTextField(
            controller: _diagnosisController,
            hintText: 'e.g., Upper respiratory infection',
          ),
          const SizedBox(height: 16),

          Text('Treatment / Notes', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.stone600)),
          const SizedBox(height: 8),
          AppTextField(
            controller: _vetNotesController,
            maxLines: 2,
            hintText: 'Any instructions from the vet...',
          ),
          const SizedBox(height: 16),

          Text('Follow-up Appointment', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.stone600)),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.calendar_today, color: AppColors.primary500, size: 20),
            ),
            title: Text(
              _followUpDate != null
                  ? '${_followUpDate!.month}/${_followUpDate!.day}/${_followUpDate!.year}'
                  : 'No appointment scheduled',
              style: TextStyle(
                color: _followUpDate != null ? AppColors.stone800 : AppColors.stone400,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 7)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) setState(() => _followUpDate = date);
            },
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
