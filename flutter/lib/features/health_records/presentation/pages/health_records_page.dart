import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/models/models.dart';
import '../../../../shared/widgets/widgets.dart';

class HealthRecordsPage extends ConsumerStatefulWidget {
  const HealthRecordsPage({super.key});

  @override
  ConsumerState<HealthRecordsPage> createState() => _HealthRecordsPageState();
}

class _HealthRecordsPageState extends ConsumerState<HealthRecordsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final petAsync = ref.watch(currentPetProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
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
            return Column(
              children: [
                _buildHeader(context, pet),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _ScheduleTab(petId: pet.id),
                      _RecordsTab(petId: pet.id),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Pet pet) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Timeline', style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: 4),
                  Text(
                    'Track ${pet.name}\'s wellness',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.stone500),
                  ),
                ],
              ),
              Row(
                children: [
                  _AddButton(
                    icon: Icons.add_alarm,
                    label: 'Reminder',
                    color: AppColors.primary500,
                    onTap: () => _showAddReminderSheet(context, pet.id),
                  ),
                  const SizedBox(width: 8),
                  _AddButton(
                    icon: Icons.add_chart,
                    label: 'Record',
                    color: AppColors.mint500,
                    onTap: () => _showAddRecordSheet(context, pet.id),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.soft,
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary500,
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.all(4),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.stone500,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              dividerColor: Colors.transparent,
              tabs: const [Tab(text: 'Schedule'), Tab(text: 'Records')],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddReminderSheet(BuildContext context, String petId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddReminderSheet(petId: petId),
    );
  }

  void _showAddRecordSheet(BuildContext context, String petId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddRecordSheet(petId: petId),
    );
  }
}

class _AddButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AddButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// Schedule Tab
class _ScheduleTab extends ConsumerWidget {
  final String petId;
  const _ScheduleTab({required this.petId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(remindersProvider);
    final appointmentsAsync = ref.watch(upcomingAppointmentsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(remindersProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            appointmentsAsync.when(
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
              data: (appointments) {
                if (appointments.isEmpty) return const SizedBox();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(title: 'Upcoming Appointments', icon: Icons.calendar_month),
                    const SizedBox(height: 12),
                    ...appointments.map((a) => AppointmentCard(appointment: a)),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
            _SectionTitle(title: 'To-Do List', icon: Icons.checklist),
            const SizedBox(height: 12),
            remindersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Failed to load'),
              data: (reminders) {
                final tasks = reminders.where((r) => r.reminderType != ReminderType.appointment).toList();
                if (tasks.isEmpty) return const EmptyStateCard(icon: Icons.task_alt, title: 'No tasks yet');
                return Column(children: tasks.map((r) => ReminderItem(reminder: r)).toList());
              },
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

// Records Tab
class _RecordsTab extends ConsumerWidget {
  final String petId;
  const _RecordsTab({required this.petId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(healthRecordsProvider);
    final weightAsync = ref.watch(weightRecordsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(healthRecordsProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            weightAsync.when(
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
              data: (records) {
                if (records.length < 2) return const SizedBox();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(title: 'Weight Trend', icon: Icons.show_chart),
                    const SizedBox(height: 12),
                    WeightChart(records: records),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
            _SectionTitle(title: 'Health History', icon: Icons.history),
            const SizedBox(height: 12),
            recordsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Failed to load'),
              data: (records) {
                if (records.isEmpty) return const EmptyStateCard(icon: Icons.note_add, title: 'No records yet');
                return Column(children: records.map((r) => RecordItem(record: r)).toList());
              },
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.stone500),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.stone700)),
      ],
    );
  }
}

class EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  const EmptyStateCard({super.key, required this.icon, required this.title});

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
            decoration: BoxDecoration(color: AppColors.stone50, shape: BoxShape.circle),
            child: Icon(icon, size: 32, color: AppColors.stone400),
          ),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.stone700)),
        ],
      ),
    );
  }
}

class AppointmentCard extends ConsumerWidget {
  final Reminder appointment;
  const AppointmentCard({super.key, required this.appointment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary500, AppColors.primary600]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.primary(AppColors.primary500),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.calendar_today, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appointment.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(_formatDT(appointment.scheduledAt), style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ref.read(remindersNotifierProvider.notifier).toggleComplete(appointment.id, true);
              showAppNotification(context, message: 'Done!', type: NotificationType.success);
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.check, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDT(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    return '${dt.month}/${dt.day} at $h:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }
}

class ReminderItem extends ConsumerWidget {
  final Reminder reminder;
  const ReminderItem({super.key, required this.reminder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = reminder.reminderType == ReminderType.medication ? AppColors.peach500 : AppColors.mint500;
    final icon = reminder.reminderType == ReminderType.medication ? Icons.medication : Icons.content_cut;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.soft),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => ref.read(remindersNotifierProvider.notifier).toggleComplete(reminder.id, !reminder.isCompleted),
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: reminder.isCompleted ? AppColors.mint500 : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: reminder.isCompleted ? AppColors.mint500 : AppColors.stone300, width: 2),
              ),
              child: reminder.isCompleted ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
            ),
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              reminder.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: reminder.isCompleted ? AppColors.stone400 : AppColors.stone800,
                decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: AppColors.stone400, size: 20),
            onPressed: () {
              ref.read(remindersNotifierProvider.notifier).deleteReminder(reminder.id);
              showAppNotification(context, message: 'Deleted', type: NotificationType.info);
            },
          ),
        ],
      ),
    );
  }
}

class RecordItem extends StatelessWidget {
  final HealthRecord record;
  const RecordItem({super.key, required this.record});

  Color get _color {
    switch (record.recordType) {
      case HealthRecordType.weight: return AppColors.sky500;
      case HealthRecordType.vaccine: return AppColors.mint500;
      case HealthRecordType.symptom: return AppColors.peach500;
      default: return AppColors.primary500;
    }
  }

  IconData get _icon {
    switch (record.recordType) {
      case HealthRecordType.weight: return Icons.monitor_weight;
      case HealthRecordType.vaccine: return Icons.vaccines;
      case HealthRecordType.symptom: return Icons.healing;
      case HealthRecordType.checkup: return Icons.medical_services;
      case HealthRecordType.medication: return Icons.medication;
      case HealthRecordType.grooming: return Icons.content_cut;
      case HealthRecordType.food: return Icons.restaurant;
      case HealthRecordType.activity: return Icons.directions_run;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.soft),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(_icon, color: _color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.recordType.displayName, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.stone800)),
                if (record.note != null && record.note!.isNotEmpty)
                  Text(record.note!, style: TextStyle(fontSize: 13, color: AppColors.stone500), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (record.value != null)
                Text(
                  record.recordType == HealthRecordType.weight ? '${record.value} kg' : record.value!,
                  style: TextStyle(fontWeight: FontWeight.bold, color: _color, fontSize: 16),
                ),
              Text('${record.recordDate.month}/${record.recordDate.day}', style: TextStyle(fontSize: 12, color: AppColors.stone400)),
            ],
          ),
        ],
      ),
    );
  }
}

class WeightChart extends StatelessWidget {
  final List<HealthRecord> records;
  const WeightChart({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    final spots = records.asMap().entries.map((e) {
      final w = double.tryParse(e.value.value ?? '0') ?? 0;
      return FlSpot(e.key.toDouble(), w);
    }).toList();

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 1;
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 1;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppShadows.soft),
      child: LineChart(
        LineChartData(
          minY: minY, maxY: maxY,
          gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: AppColors.stone100, strokeWidth: 1)),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, _) => Text('${v.toStringAsFixed(1)}', style: TextStyle(fontSize: 10, color: AppColors.stone400)))),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
              if (v.toInt() >= records.length) return const SizedBox();
              final d = records[v.toInt()].recordDate;
              return Padding(padding: const EdgeInsets.only(top: 8), child: Text('${d.month}/${d.day}', style: TextStyle(fontSize: 10, color: AppColors.stone400)));
            })),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots, isCurved: true, color: AppColors.primary500, barWidth: 3, isStrokeCapRound: true,
              dotData: FlDotData(show: true, getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(radius: 4, color: Colors.white, strokeWidth: 2, strokeColor: AppColors.primary500)),
              belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [AppColors.primary500.withOpacity(0.3), AppColors.primary500.withOpacity(0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
            ),
          ],
        ),
      ),
    );
  }
}

// Add Reminder Sheet
class AddReminderSheet extends ConsumerStatefulWidget {
  final String petId;
  const AddReminderSheet({super.key, required this.petId});

  @override
  ConsumerState<AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends ConsumerState<AddReminderSheet> {
  final _titleCtrl = TextEditingController();
  ReminderType _type = ReminderType.medication;
  DateTime _date = DateTime.now().add(const Duration(hours: 1));
  bool _loading = false;

  @override
  void dispose() { _titleCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_titleCtrl.text.isEmpty) {
      showAppNotification(context, message: 'Enter a title', type: NotificationType.error);
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(remindersNotifierProvider.notifier).addReminder(
        Reminder(id: '', petId: widget.petId, title: _titleCtrl.text, reminderType: _type, scheduledAt: _date, isCompleted: false, createdAt: DateTime.now()),
      );
      if (mounted) { Navigator.pop(context); showAppNotification(context, message: 'Added!', type: NotificationType.success); }
    } catch (_) {
      showAppNotification(context, message: 'Failed', type: NotificationType.error);
    } finally { if (mounted) setState(() => _loading = false); }
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
            Text('Add Reminder', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g., Heartworm pill')),
            const SizedBox(height: 16),
            Text('Type', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.stone600)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: ReminderType.values.map((t) => ChoiceChip(label: Text(t.displayName), selected: _type == t, selectedColor: AppColors.primary100, onSelected: (_) => setState(() => _type = t))).toList()),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.calendar_today, color: AppColors.primary500),
              title: Text('${_date.month}/${_date.day} at ${_date.hour}:${_date.minute.toString().padLeft(2, '0')}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                if (d != null) {
                  final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_date));
                  if (t != null) setState(() => _date = DateTime(d.year, d.month, d.day, t.hour, t.minute));
                }
              },
            ),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: _loading ? null : _save, child: _loading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Add Reminder'))),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// Add Record Sheet
class AddRecordSheet extends ConsumerStatefulWidget {
  final String petId;
  const AddRecordSheet({super.key, required this.petId});

  @override
  ConsumerState<AddRecordSheet> createState() => _AddRecordSheetState();
}

class _AddRecordSheetState extends ConsumerState<AddRecordSheet> {
  HealthRecordType _type = HealthRecordType.weight;
  final _valueCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  bool _loading = false;

  @override
  void dispose() { _valueCtrl.dispose(); _noteCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_type == HealthRecordType.weight && _valueCtrl.text.isEmpty) {
      showAppNotification(context, message: 'Enter weight', type: NotificationType.error);
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(healthRecordsNotifierProvider.notifier).addRecord(
        HealthRecord(id: '', petId: widget.petId, recordType: _type, recordDate: _date, value: _valueCtrl.text.isNotEmpty ? _valueCtrl.text : null, note: _noteCtrl.text.isNotEmpty ? _noteCtrl.text : null, createdAt: DateTime.now()),
      );
      if (mounted) { Navigator.pop(context); showAppNotification(context, message: 'Record added!', type: NotificationType.success); }
    } catch (_) {
      showAppNotification(context, message: 'Failed', type: NotificationType.error);
    } finally { if (mounted) setState(() => _loading = false); }
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
            Text('Add Health Record', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            Text('Type', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.stone600)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: HealthRecordType.values.map((t) => ChoiceChip(label: Text(t.displayName), selected: _type == t, selectedColor: AppColors.primary100, onSelected: (_) => setState(() => _type = t))).toList()),
            const SizedBox(height: 16),
            if (_type == HealthRecordType.weight)
              TextField(controller: _valueCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Weight (kg)', hintText: '0.0')),
            if (_type != HealthRecordType.weight)
              TextField(controller: _valueCtrl, decoration: InputDecoration(labelText: 'Value', hintText: _type == HealthRecordType.vaccine ? 'Vaccine name' : 'Optional')),
            const SizedBox(height: 16),
            TextField(controller: _noteCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes', hintText: 'Any additional details')),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.calendar_today, color: AppColors.primary500),
              title: Text('${_date.month}/${_date.day}/${_date.year}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now());
                if (d != null) setState(() => _date = d);
              },
            ),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: _loading ? null : _save, child: _loading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save Record'))),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}