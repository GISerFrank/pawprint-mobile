import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/models.dart';
import '../../../../core/providers/providers.dart';
import '../../../../shared/widgets/widgets.dart';

class DietDetailPage extends ConsumerWidget {
  final Pet pet;
  const DietDetailPage({super.key, required this.pet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedingLogsAsync = ref.watch(todayFeedingLogsProvider);
    final waterTotalAsync = ref.watch(todayWaterTotalProvider);
    final recentLogsAsync = ref.watch(recentFeedingLogsProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Diet'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showAddOptions(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayFeedingLogsProvider);
          ref.invalidate(todayWaterLogsProvider);
          ref.invalidate(todayWaterTotalProvider);
          ref.invalidate(recentFeedingLogsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Today's Summary
              _TodaySummary(
                feedingLogsAsync: feedingLogsAsync,
                waterTotalAsync: waterTotalAsync,
                petId: pet.id,
              ),
              const SizedBox(height: 24),

              // Quick Add Buttons
              _QuickAddSection(petId: pet.id),
              const SizedBox(height: 24),

              // Today's Meals
              _TodayMealsSection(feedingLogsAsync: feedingLogsAsync),
              const SizedBox(height: 24),

              // Recent History
              _RecentHistorySection(recentLogsAsync: recentLogsAsync),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.stone200, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text('Log Diet', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _AddOptionCard(
                    icon: Icons.restaurant,
                    label: 'Meal',
                    color: AppColors.peach500,
                    onTap: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => _AddMealSheet(petId: pet.id),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _AddOptionCard(
                    icon: Icons.water_drop,
                    label: 'Water',
                    color: AppColors.sky500,
                    onTap: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => _AddWaterSheet(petId: pet.id),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _AddOptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AddOptionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 12),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

// ============================================
// Today's Summary
// ============================================

class _TodaySummary extends ConsumerWidget {
  final AsyncValue<List<FeedingLog>> feedingLogsAsync;
  final AsyncValue<double> waterTotalAsync;
  final String petId;

  const _TodaySummary({
    required this.feedingLogsAsync,
    required this.waterTotalAsync,
    required this.petId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.peach400, AppColors.peach500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.peach500.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Diet",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: feedingLogsAsync.when(
                  loading: () => _SummaryItem(icon: Icons.restaurant, value: '...', label: 'Meals'),
                  error: (_, __) => _SummaryItem(icon: Icons.restaurant, value: '0', label: 'Meals'),
                  data: (logs) => _SummaryItem(icon: Icons.restaurant, value: '${logs.length}', label: 'Meals'),
                ),
              ),
              Container(width: 1, height: 50, color: Colors.white24),
              Expanded(
                child: waterTotalAsync.when(
                  loading: () => _SummaryItem(icon: Icons.water_drop, value: '...', label: 'Water'),
                  error: (_, __) => _SummaryItem(icon: Icons.water_drop, value: '0ml', label: 'Water'),
                  data: (total) => _SummaryItem(icon: Icons.water_drop, value: '${total.toInt()}ml', label: 'Water'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _SummaryItem({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
      ],
    );
  }
}

// ============================================
// Quick Add Section
// ============================================

class _QuickAddSection extends ConsumerWidget {
  final String petId;
  const _QuickAddSection({required this.petId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Quick Log', icon: Icons.bolt),
        const SizedBox(height: 12),
        Row(
          children: [
            _QuickMealButton(mealType: MealType.breakfast, petId: petId),
            const SizedBox(width: 8),
            _QuickMealButton(mealType: MealType.lunch, petId: petId),
            const SizedBox(width: 8),
            _QuickMealButton(mealType: MealType.dinner, petId: petId),
            const SizedBox(width: 8),
            _QuickMealButton(mealType: MealType.snack, petId: petId),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _QuickWaterButton(amount: 50, petId: petId),
            const SizedBox(width: 8),
            _QuickWaterButton(amount: 100, petId: petId),
            const SizedBox(width: 8),
            _QuickWaterButton(amount: 200, petId: petId),
            const SizedBox(width: 8),
            _QuickWaterButton(amount: 500, petId: petId),
          ],
        ),
      ],
    );
  }
}

class _QuickMealButton extends ConsumerWidget {
  final MealType mealType;
  final String petId;

  const _QuickMealButton({required this.mealType, required this.petId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(dietNotifierProvider.notifier).logFeeding(
            petId: petId,
            mealType: mealType,
            foodType: FoodType.dryFood,
          );
          showAppNotification(context, message: '${mealType.emoji} ${mealType.displayName} logged!', type: NotificationType.success);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            children: [
              Text(mealType.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Text(mealType.displayName, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.stone600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickWaterButton extends ConsumerWidget {
  final double amount;
  final String petId;

  const _QuickWaterButton({required this.amount, required this.petId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(dietNotifierProvider.notifier).logWater(petId: petId, amount: amount);
          showAppNotification(context, message: '💧 ${amount.toInt()}ml logged!', type: NotificationType.success);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.sky50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.sky200),
          ),
          child: Column(
            children: [
              const Icon(Icons.water_drop, color: AppColors.sky500, size: 20),
              const SizedBox(height: 4),
              Text('${amount.toInt()}ml', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.sky600)),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// Today's Meals Section
// ============================================

class _TodayMealsSection extends StatelessWidget {
  final AsyncValue<List<FeedingLog>> feedingLogsAsync;

  const _TodayMealsSection({required this.feedingLogsAsync});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: "Today's Meals", icon: Icons.restaurant),
        const SizedBox(height: 12),
        feedingLogsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('Failed to load'),
          data: (logs) {
            if (logs.isEmpty) {
              return _EmptyCard(
                icon: Icons.restaurant_menu,
                title: 'No meals logged today',
                subtitle: 'Tap the buttons above to log meals',
              );
            }
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppShadows.soft,
              ),
              child: Column(
                children: logs.map((log) => _MealItem(log: log)).toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MealItem extends StatelessWidget {
  final FeedingLog log;
  const _MealItem({required this.log});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.stone100)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.peach100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(log.mealType.emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.mealType.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '${log.foodType.displayName}${log.foodName != null ? ' • ${log.foodName}' : ''}',
                  style: TextStyle(fontSize: 12, color: AppColors.stone500),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (log.amount != null)
                Text('${log.amount!.toInt()}g', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.peach500)),
              Text(_formatTime(log.feedingTime), style: TextStyle(fontSize: 12, color: AppColors.stone400)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    return '$h:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }
}

// ============================================
// Recent History Section
// ============================================

class _RecentHistorySection extends StatelessWidget {
  final AsyncValue<List<FeedingLog>> recentLogsAsync;

  const _RecentHistorySection({required this.recentLogsAsync});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'This Week', icon: Icons.history),
        const SizedBox(height: 12),
        recentLogsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('Failed to load'),
          data: (logs) {
            if (logs.isEmpty) {
              return const SizedBox();
            }
            // Group by day
            final grouped = _groupByDay(logs);
            return Column(
              children: grouped.entries.take(5).map((entry) => _DayGroup(date: entry.key, logs: entry.value)).toList(),
            );
          },
        ),
      ],
    );
  }

  Map<String, List<FeedingLog>> _groupByDay(List<FeedingLog> logs) {
    final Map<String, List<FeedingLog>> grouped = {};
    for (final log in logs) {
      final key = _dateKey(log.feedingTime);
      grouped.putIfAbsent(key, () => []).add(log);
    }
    return grouped;
  }

  String _dateKey(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    if (date == today) return 'Today';
    if (date == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${dt.month}/${dt.day}';
  }
}

class _DayGroup extends StatelessWidget {
  final String date;
  final List<FeedingLog> logs;

  const _DayGroup({required this.date, required this.logs});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(date, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.stone500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: logs.map((log) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppShadows.soft,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(log.mealType.emoji),
                  const SizedBox(width: 4),
                  Text(log.mealType.displayName, style: const TextStyle(fontSize: 12)),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

// ============================================
// Shared Components
// ============================================

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.stone500),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.stone700)),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyCard({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.stone100),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: AppColors.stone50, shape: BoxShape.circle),
            child: Icon(icon, size: 32, color: AppColors.stone400),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.stone700)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: AppColors.stone500, fontSize: 13)),
        ],
      ),
    );
  }
}

// ============================================
// Add Meal Sheet
// ============================================

class _AddMealSheet extends ConsumerStatefulWidget {
  final String petId;
  const _AddMealSheet({required this.petId});

  @override
  ConsumerState<_AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends ConsumerState<_AddMealSheet> {
  MealType _mealType = MealType.breakfast;
  FoodType _foodType = FoodType.dryFood;
  final _foodNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _foodNameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await ref.read(dietNotifierProvider.notifier).logFeeding(
        petId: widget.petId,
        mealType: _mealType,
        foodType: _foodType,
        foodName: _foodNameController.text.isNotEmpty ? _foodNameController.text : null,
        amount: double.tryParse(_amountController.text),
        note: _noteController.text.isNotEmpty ? _noteController.text : null,
      );
      if (mounted) {
        Navigator.pop(context);
        showAppNotification(context, message: '${_mealType.emoji} Meal logged!', type: NotificationType.success);
      }
    } catch (_) {
      showAppNotification(context, message: 'Failed', type: NotificationType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.stone200, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Log Meal', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),

            const Text('Meal Type', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.stone600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MealType.values.map((t) => ChoiceChip(
                label: Text('${t.emoji} ${t.displayName}'),
                selected: _mealType == t,
                selectedColor: AppColors.peach100,
                onSelected: (_) => setState(() => _mealType = t),
              )).toList(),
            ),
            const SizedBox(height: 16),

            const Text('Food Type', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.stone600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: FoodType.values.map((t) => ChoiceChip(
                label: Text(t.displayName),
                selected: _foodType == t,
                selectedColor: AppColors.peach100,
                onSelected: (_) => setState(() => _foodType = t),
              )).toList(),
            ),
            const SizedBox(height: 16),

            TextField(controller: _foodNameController, decoration: const InputDecoration(labelText: 'Food Name (optional)', hintText: 'e.g., Royal Canin')),
            const SizedBox(height: 16),
            TextField(controller: _amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (g)', hintText: '0')),
            const SizedBox(height: 16),
            TextField(controller: _noteController, decoration: const InputDecoration(labelText: 'Notes (optional)')),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.peach500),
                child: _loading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Meal'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ============================================
// Add Water Sheet
// ============================================

class _AddWaterSheet extends ConsumerStatefulWidget {
  final String petId;
  const _AddWaterSheet({required this.petId});

  @override
  ConsumerState<_AddWaterSheet> createState() => _AddWaterSheetState();
}

class _AddWaterSheetState extends ConsumerState<_AddWaterSheet> {
  double _amount = 100;
  bool _loading = false;

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await ref.read(dietNotifierProvider.notifier).logWater(petId: widget.petId, amount: _amount);
      if (mounted) {
        Navigator.pop(context);
        showAppNotification(context, message: '💧 ${_amount.toInt()}ml logged!', type: NotificationType.success);
      }
    } catch (_) {
      showAppNotification(context, message: 'Failed', type: NotificationType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.stone200, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('Log Water', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.sky50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.water_drop, color: AppColors.sky500, size: 48),
                  const SizedBox(height: 16),
                  Text('${_amount.toInt()}ml', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.sky600)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Slider(
              value: _amount,
              min: 50,
              max: 1000,
              divisions: 19,
              activeColor: AppColors.sky500,
              inactiveColor: AppColors.sky100,
              onChanged: (v) => setState(() => _amount = v),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('50ml', style: TextStyle(color: AppColors.stone400, fontSize: 12)),
                Text('1000ml', style: TextStyle(color: AppColors.stone400, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.sky500),
                child: _loading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
