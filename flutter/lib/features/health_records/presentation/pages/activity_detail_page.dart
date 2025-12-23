import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/models.dart';
import '../../../../core/providers/providers.dart';
import '../../../../shared/widgets/widgets.dart';

class ActivityDetailPage extends ConsumerWidget {
  final Pet pet;
  const ActivityDetailPage({super.key, required this.pet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayLogsAsync = ref.watch(todayActivityLogsProvider);
    final todayTotalAsync = ref.watch(todayActivityTotalProvider);
    final recentLogsAsync = ref.watch(recentActivityLogsProvider);
    final weeklyStatsAsync = ref.watch(weeklyActivityStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Activity'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => _AddActivitySheet(petId: pet.id),
            ),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayActivityLogsProvider);
          ref.invalidate(todayActivityTotalProvider);
          ref.invalidate(recentActivityLogsProvider);
          ref.invalidate(weeklyActivityStatsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TodaySummary(todayTotalAsync: todayTotalAsync, todayLogsAsync: todayLogsAsync),
              const SizedBox(height: 24),
              _QuickAddSection(petId: pet.id),
              const SizedBox(height: 24),
              _TodayActivitiesSection(todayLogsAsync: todayLogsAsync),
              const SizedBox(height: 24),
              _WeeklyStatsSection(weeklyStatsAsync: weeklyStatsAsync),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodaySummary extends StatelessWidget {
  final AsyncValue<int> todayTotalAsync;
  final AsyncValue<List<ActivityLog>> todayLogsAsync;

  const _TodaySummary({required this.todayTotalAsync, required this.todayLogsAsync});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.sky400, AppColors.sky500]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.sky500.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Today's Activity", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: todayTotalAsync.when(
                  loading: () => _SummaryItem(icon: Icons.timer, value: '...', label: 'Total Time'),
                  error: (_, __) => _SummaryItem(icon: Icons.timer, value: '0 min', label: 'Total Time'),
                  data: (total) => _SummaryItem(icon: Icons.timer, value: total < 60 ? '$total min' : '${total ~/ 60}h ${total % 60}m', label: 'Total Time'),
                ),
              ),
              Container(width: 1, height: 50, color: Colors.white24),
              Expanded(
                child: todayLogsAsync.when(
                  loading: () => _SummaryItem(icon: Icons.fitness_center, value: '...', label: 'Activities'),
                  error: (_, __) => _SummaryItem(icon: Icons.fitness_center, value: '0', label: 'Activities'),
                  data: (logs) => _SummaryItem(icon: Icons.fitness_center, value: '${logs.length}', label: 'Activities'),
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
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ActivityType.values.map((type) => Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _QuickActivityButton(activityType: type, petId: petId),
            )).toList(),
          ),
        ),
      ],
    );
  }
}

class _QuickActivityButton extends ConsumerWidget {
  final ActivityType activityType;
  final String petId;

  const _QuickActivityButton({required this.activityType, required this.petId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showDurationPicker(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.soft),
        child: Column(
          children: [
            Text(activityType.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(activityType.displayName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.stone600)),
          ],
        ),
      ),
    );
  }

  void _showDurationPicker(BuildContext context, WidgetRef ref) {
    int duration = 30;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.stone200, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text('${activityType.emoji} ${activityType.displayName}', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 24),
              Text('$duration min', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.sky600)),
              const SizedBox(height: 16),
              Slider(value: duration.toDouble(), min: 5, max: 120, divisions: 23, activeColor: AppColors.sky500, inactiveColor: AppColors.sky100, onChanged: (v) => setState(() => duration = v.round())),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('5 min', style: TextStyle(color: AppColors.stone400, fontSize: 12)), Text('2 hours', style: TextStyle(color: AppColors.stone400, fontSize: 12))]),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(activityNotifierProvider.notifier).logActivity(petId: petId, activityType: activityType, intensity: ActivityIntensity.moderate, durationMinutes: duration);
                    Navigator.pop(context);
                    showAppNotification(context, message: '${activityType.emoji} $duration min logged!', type: NotificationType.success);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.sky500),
                  child: const Text('Log Activity'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayActivitiesSection extends StatelessWidget {
  final AsyncValue<List<ActivityLog>> todayLogsAsync;

  const _TodayActivitiesSection({required this.todayLogsAsync});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: "Today's Activities", icon: Icons.directions_run),
        const SizedBox(height: 12),
        todayLogsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('Failed to load'),
          data: (logs) {
            if (logs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.stone100)),
                child: Column(
                  children: [
                    Container(padding: const EdgeInsets.all(16), decoration: const BoxDecoration(color: AppColors.stone50, shape: BoxShape.circle), child: const Icon(Icons.directions_run, size: 32, color: AppColors.stone400)),
                    const SizedBox(height: 16),
                    const Text('No activities logged today', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.stone700)),
                    const SizedBox(height: 4),
                    Text('Tap the buttons above to log activities', style: TextStyle(color: AppColors.stone500, fontSize: 13)),
                  ],
                ),
              );
            }
            return Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppShadows.soft),
              child: Column(children: logs.map((log) => _ActivityItem(log: log)).toList()),
            );
          },
        ),
      ],
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final ActivityLog log;
  const _ActivityItem({required this.log});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.stone100))),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.sky100, borderRadius: BorderRadius.circular(12)), child: Text(log.activityType.emoji, style: const TextStyle(fontSize: 20))),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.activityType.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                Row(children: [Text(log.intensity.emoji, style: const TextStyle(fontSize: 12)), const SizedBox(width: 4), Text(log.intensity.displayName, style: TextStyle(fontSize: 12, color: AppColors.stone500)), if (log.distanceKm != null) ...[Text(' • ', style: TextStyle(color: AppColors.stone400)), Text('${log.distanceKm!.toStringAsFixed(1)} km', style: TextStyle(fontSize: 12, color: AppColors.stone500))]]),
              ],
            ),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(log.formattedDuration, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.sky500)), Text(_formatTime(log.activityTime), style: TextStyle(fontSize: 12, color: AppColors.stone400))]),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    return '$h:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }
}

class _WeeklyStatsSection extends StatelessWidget {
  final AsyncValue<Map<String, int>> weeklyStatsAsync;

  const _WeeklyStatsSection({required this.weeklyStatsAsync});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'This Week', icon: Icons.bar_chart),
        const SizedBox(height: 12),
        weeklyStatsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('Failed to load'),
          data: (stats) {
            final total = stats.values.fold(0, (a, b) => a + b);
            if (total == 0) return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppShadows.soft), child: const Center(child: Text('No activity data this week', style: TextStyle(color: AppColors.stone500))));
            final entries = stats.entries.where((e) => e.value > 0).toList()..sort((a, b) => b.value.compareTo(a.value));
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppShadows.soft),
              child: Column(children: [Text('${total ~/ 60}h ${total % 60}m total', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.sky600)), const SizedBox(height: 16), ...entries.take(4).map((e) => _StatBar(label: e.key, minutes: e.value, maxMinutes: entries.first.value))]),
            );
          },
        ),
      ],
    );
  }
}

class _StatBar extends StatelessWidget {
  final String label;
  final int minutes;
  final int maxMinutes;

  const _StatBar({required this.label, required this.minutes, required this.maxMinutes});

  @override
  Widget build(BuildContext context) {
    final type = ActivityType.values.firstWhere((t) => t.displayName == label, orElse: () => ActivityType.other);
    final percentage = maxMinutes > 0 ? minutes / maxMinutes : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('${type.emoji} $label', style: const TextStyle(fontSize: 13)), Text(minutes < 60 ? '$minutes min' : '${minutes ~/ 60}h ${minutes % 60}m', style: TextStyle(fontSize: 13, color: AppColors.stone500))]),
          const SizedBox(height: 6),
          Container(height: 8, decoration: BoxDecoration(color: AppColors.stone100, borderRadius: BorderRadius.circular(4)), child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: percentage, child: Container(decoration: BoxDecoration(color: AppColors.sky500, borderRadius: BorderRadius.circular(4))))),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(children: [Icon(icon, size: 20, color: AppColors.stone500), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.stone700))]);
  }
}

class _AddActivitySheet extends ConsumerStatefulWidget {
  final String petId;
  const _AddActivitySheet({required this.petId});

  @override
  ConsumerState<_AddActivitySheet> createState() => _AddActivitySheetState();
}

class _AddActivitySheetState extends ConsumerState<_AddActivitySheet> {
  ActivityType _type = ActivityType.walk;
  ActivityIntensity _intensity = ActivityIntensity.moderate;
  int _duration = 30;
  final _distanceController = TextEditingController();
  final _noteController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _distanceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await ref.read(activityNotifierProvider.notifier).logActivity(petId: widget.petId, activityType: _type, intensity: _intensity, durationMinutes: _duration, distanceKm: double.tryParse(_distanceController.text), note: _noteController.text.isNotEmpty ? _noteController.text : null);
      if (mounted) {
        Navigator.pop(context);
        showAppNotification(context, message: '${_type.emoji} Activity logged!', type: NotificationType.success);
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
            Text('Log Activity', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            const Text('Activity Type', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.stone600)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: ActivityType.values.map((t) => ChoiceChip(label: Text('${t.emoji} ${t.displayName}'), selected: _type == t, selectedColor: AppColors.sky100, onSelected: (_) => setState(() => _type = t))).toList()),
            const SizedBox(height: 16),
            const Text('Intensity', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.stone600)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: ActivityIntensity.values.map((i) => ChoiceChip(label: Text('${i.emoji} ${i.displayName}'), selected: _intensity == i, selectedColor: AppColors.sky100, onSelected: (_) => setState(() => _intensity = i))).toList()),
            const SizedBox(height: 16),
            const Text('Duration', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.stone600)),
            const SizedBox(height: 8),
            Row(children: [IconButton(onPressed: _duration > 5 ? () => setState(() => _duration -= 5) : null, icon: const Icon(Icons.remove_circle_outline), color: AppColors.sky500), Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), decoration: BoxDecoration(color: AppColors.sky50, borderRadius: BorderRadius.circular(12)), child: Text('$_duration min', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.sky600))), IconButton(onPressed: _duration < 180 ? () => setState(() => _duration += 5) : null, icon: const Icon(Icons.add_circle_outline), color: AppColors.sky500)]),
            const SizedBox(height: 16),
            TextField(controller: _distanceController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Distance (km) - optional')),
            const SizedBox(height: 16),
            TextField(controller: _noteController, decoration: const InputDecoration(labelText: 'Notes (optional)')),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: _loading ? null : _save, style: ElevatedButton.styleFrom(backgroundColor: AppColors.sky500), child: _loading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save Activity'))),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
