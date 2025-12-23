import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/models.dart';
import '../../../../core/providers/providers.dart';
import '../../../../shared/widgets/widgets.dart';

class MedicalDetailPage extends ConsumerWidget {
  final Pet pet;
  const MedicalDetailPage({super.key, required this.pet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(remindersProvider);
    final recordsAsync = ref.watch(healthRecordsProvider);
    final illnessHistoryAsync = ref.watch(illnessHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Medical'),
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
          ref.invalidate(remindersProvider);
          ref.invalidate(healthRecordsProvider);
          ref.invalidate(illnessHistoryProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Upcoming Appointments
              _UpcomingAppointments(remindersAsync: remindersAsync),
              const SizedBox(height: 24),

              // Vaccination Records
              _VaccinationSection(recordsAsync: recordsAsync),
              const SizedBox(height: 24),

              // Checkup History
              _CheckupSection(recordsAsync: recordsAsync),
              const SizedBox(height: 24),

              // Illness History
              _IllnessHistorySection(illnessHistoryAsync: illnessHistoryAsync),

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
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.stone200, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            Text('Add Medical Record', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            _AddOption(
              icon: Icons.calendar_today,
              title: 'Schedule Appointment',
              subtitle: 'Book a vet visit',
              color: AppColors.primary500,
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _AddAppointmentSheet(petId: pet.id),
                );
              },
            ),
            const SizedBox(height: 12),
            _AddOption(
              icon: Icons.vaccines,
              title: 'Log Vaccination',
              subtitle: 'Record a vaccine shot',
              color: AppColors.mint500,
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _AddVaccinationSheet(petId: pet.id),
                );
              },
            ),
            const SizedBox(height: 12),
            _AddOption(
              icon: Icons.medical_services,
              title: 'Log Checkup',
              subtitle: 'Record a vet visit',
              color: AppColors.sky500,
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _AddCheckupSheet(petId: pet.id),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _AddOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AddOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }
}

// ============================================
// Upcoming Appointments Section
// ============================================

class _UpcomingAppointments extends ConsumerWidget {
  final AsyncValue<List<Reminder>> remindersAsync;

  const _UpcomingAppointments({required this.remindersAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Upcoming Appointments', icon: Icons.calendar_month),
        const SizedBox(height: 12),
        remindersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('Failed to load'),
          data: (reminders) {
            final appointments = reminders
                .where((r) => r.reminderType == ReminderType.appointment && !r.isCompleted)
                .toList()
              ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

            if (appointments.isEmpty) {
              return _EmptyCard(
                icon: Icons.event_available,
                title: 'No upcoming appointments',
                subtitle: 'Schedule a vet visit',
              );
            }

            return Column(
              children: appointments.take(3).map((a) => _AppointmentCard(appointment: a)).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _AppointmentCard extends ConsumerWidget {
  final Reminder appointment;

  const _AppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysUntil = appointment.scheduledAt.difference(DateTime.now()).inDays;
    final isUrgent = daysUntil <= 2;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isUrgent 
              ? [AppColors.peach400, AppColors.peach500]
              : [AppColors.primary400, AppColors.primary500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isUrgent ? AppColors.peach500 : AppColors.primary500).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '${appointment.scheduledAt.day}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                ),
                Text(
                  _monthName(appointment.scheduledAt.month),
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(appointment.scheduledAt),
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                ),
                if (daysUntil >= 0)
                  Text(
                    daysUntil == 0 ? 'Today!' : daysUntil == 1 ? 'Tomorrow' : 'In $daysUntil days',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ref.read(remindersNotifierProvider.notifier).toggleComplete(appointment.id, true);
              showAppNotification(context, message: 'Marked as done!', type: NotificationType.success);
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    return '$h:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }
}

// ============================================
// Vaccination Section
// ============================================

class _VaccinationSection extends StatelessWidget {
  final AsyncValue<List<HealthRecord>> recordsAsync;

  const _VaccinationSection({required this.recordsAsync});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Vaccinations', icon: Icons.vaccines),
        const SizedBox(height: 12),
        recordsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('Failed to load'),
          data: (records) {
            final vaccines = records.where((r) => r.recordType == HealthRecordType.vaccine).toList()
              ..sort((a, b) => b.recordDate.compareTo(a.recordDate));

            if (vaccines.isEmpty) {
              return _EmptyCard(
                icon: Icons.vaccines,
                title: 'No vaccination records',
                subtitle: 'Log your pet\'s vaccines',
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppShadows.soft,
              ),
              child: Column(
                children: vaccines.take(5).map((v) => _VaccineItem(record: v)).toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _VaccineItem extends StatelessWidget {
  final HealthRecord record;

  const _VaccineItem({required this.record});

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
              color: AppColors.mint100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.vaccines, color: AppColors.mint500, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.value ?? 'Vaccination',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.stone800),
                ),
                if (record.note != null && record.note!.isNotEmpty)
                  Text(
                    record.note!,
                    style: TextStyle(fontSize: 12, color: AppColors.stone500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${record.recordDate.month}/${record.recordDate.day}/${record.recordDate.year}',
                style: TextStyle(fontSize: 12, color: AppColors.stone500),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.mint100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '✓ Done',
                  style: TextStyle(fontSize: 10, color: AppColors.mint600, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================
// Checkup Section
// ============================================

class _CheckupSection extends StatelessWidget {
  final AsyncValue<List<HealthRecord>> recordsAsync;

  const _CheckupSection({required this.recordsAsync});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Checkup History', icon: Icons.medical_services),
        const SizedBox(height: 12),
        recordsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('Failed to load'),
          data: (records) {
            final checkups = records.where((r) => r.recordType == HealthRecordType.checkup).toList()
              ..sort((a, b) => b.recordDate.compareTo(a.recordDate));

            if (checkups.isEmpty) {
              return _EmptyCard(
                icon: Icons.medical_services,
                title: 'No checkup records',
                subtitle: 'Log vet visits here',
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppShadows.soft,
              ),
              child: Column(
                children: checkups.take(5).map((c) => _CheckupItem(record: c)).toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CheckupItem extends StatelessWidget {
  final HealthRecord record;

  const _CheckupItem({required this.record});

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
              color: AppColors.sky100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.medical_services, color: AppColors.sky500, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.value ?? 'Vet Checkup',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.stone800),
                ),
                if (record.note != null && record.note!.isNotEmpty)
                  Text(
                    record.note!,
                    style: TextStyle(fontSize: 12, color: AppColors.stone500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Text(
            '${record.recordDate.month}/${record.recordDate.day}',
            style: TextStyle(fontSize: 12, color: AppColors.stone500),
          ),
        ],
      ),
    );
  }
}

// ============================================
// Illness History Section
// ============================================

class _IllnessHistorySection extends StatelessWidget {
  final AsyncValue<List<IllnessRecord>> illnessHistoryAsync;

  const _IllnessHistorySection({required this.illnessHistoryAsync});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Illness History', icon: Icons.healing),
        const SizedBox(height: 12),
        illnessHistoryAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('Failed to load'),
          data: (records) {
            final completed = records.where((r) => r.endDate != null).toList()
              ..sort((a, b) => b.startDate.compareTo(a.startDate));

            if (completed.isEmpty) {
              return _EmptyCard(
                icon: Icons.healing,
                title: 'No illness history',
                subtitle: 'Past illnesses will appear here',
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppShadows.soft,
              ),
              child: Column(
                children: completed.take(5).map((i) => _IllnessHistoryItem(illness: i)).toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _IllnessHistoryItem extends StatelessWidget {
  final IllnessRecord illness;

  const _IllnessHistoryItem({required this.illness});

  @override
  Widget build(BuildContext context) {
    final duration = illness.endDate != null
        ? illness.endDate!.difference(illness.startDate).inDays + 1
        : null;

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
            child: const Icon(Icons.healing, color: AppColors.peach500, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  illness.diagnosis ?? illness.symptoms,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.stone800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Text(
                      '${illness.startDate.month}/${illness.startDate.day}',
                      style: TextStyle(fontSize: 12, color: AppColors.stone500),
                    ),
                    if (duration != null) ...[
                      Text(' • ', style: TextStyle(color: AppColors.stone400)),
                      Text(
                        '$duration days',
                        style: TextStyle(fontSize: 12, color: AppColors.stone500),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.mint100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Recovered',
              style: TextStyle(fontSize: 11, color: AppColors.mint600, fontWeight: FontWeight.bold),
            ),
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
// Add Sheets
// ============================================

class _AddAppointmentSheet extends ConsumerStatefulWidget {
  final String petId;
  const _AddAppointmentSheet({required this.petId});

  @override
  ConsumerState<_AddAppointmentSheet> createState() => _AddAppointmentSheetState();
}

class _AddAppointmentSheetState extends ConsumerState<_AddAppointmentSheet> {
  final _titleController = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  bool _loading = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.isEmpty) {
      showAppNotification(context, message: 'Enter appointment title', type: NotificationType.error);
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(remindersNotifierProvider.notifier).addReminder(
        Reminder(
          id: '',
          petId: widget.petId,
          title: _titleController.text,
          reminderType: ReminderType.appointment,
          scheduledAt: _date,
          isCompleted: false,
          createdAt: DateTime.now(),
        ),
      );
      if (mounted) {
        Navigator.pop(context);
        showAppNotification(context, message: 'Appointment scheduled!', type: NotificationType.success);
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.stone200, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Schedule Appointment', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Appointment Title',
                hintText: 'e.g., Annual checkup, Vaccination',
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today, color: AppColors.primary500),
              title: Text('${_date.month}/${_date.day}/${_date.year} at ${_date.hour}:${_date.minute.toString().padLeft(2, '0')}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (d != null) {
                  final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_date));
                  if (t != null) setState(() => _date = DateTime(d.year, d.month, d.day, t.hour, t.minute));
                }
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
                    : const Text('Schedule'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _AddVaccinationSheet extends ConsumerStatefulWidget {
  final String petId;
  const _AddVaccinationSheet({required this.petId});

  @override
  ConsumerState<_AddVaccinationSheet> createState() => _AddVaccinationSheetState();
}

class _AddVaccinationSheetState extends ConsumerState<_AddVaccinationSheet> {
  final _nameController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _date = DateTime.now();
  bool _loading = false;

  final _commonVaccines = ['Rabies', 'DHPP', 'FVRCP', 'Bordetella', 'Lyme', 'Leptospirosis', 'Canine Influenza'];

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty) {
      showAppNotification(context, message: 'Enter vaccine name', type: NotificationType.error);
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(healthRecordsNotifierProvider.notifier).addRecord(
        HealthRecord(
          id: '',
          petId: widget.petId,
          recordType: HealthRecordType.vaccine,
          recordDate: _date,
          value: _nameController.text,
          note: _noteController.text.isNotEmpty ? _noteController.text : null,
          createdAt: DateTime.now(),
        ),
      );
      if (mounted) {
        Navigator.pop(context);
        showAppNotification(context, message: 'Vaccination logged! 💉', type: NotificationType.success);
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.stone200, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Log Vaccination', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Vaccine Name',
                hintText: 'e.g., Rabies, DHPP',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _commonVaccines.map((v) => ActionChip(
                label: Text(v, style: const TextStyle(fontSize: 12)),
                onPressed: () => _nameController.text = v,
                backgroundColor: AppColors.mint50,
              )).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Clinic name, batch number, etc.',
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today, color: AppColors.primary500),
              title: Text('${_date.month}/${_date.day}/${_date.year}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (d != null) setState(() => _date = d);
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.mint500),
                child: _loading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Vaccination'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _AddCheckupSheet extends ConsumerStatefulWidget {
  final String petId;
  const _AddCheckupSheet({required this.petId});

  @override
  ConsumerState<_AddCheckupSheet> createState() => _AddCheckupSheetState();
}

class _AddCheckupSheetState extends ConsumerState<_AddCheckupSheet> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _date = DateTime.now();
  bool _loading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await ref.read(healthRecordsNotifierProvider.notifier).addRecord(
        HealthRecord(
          id: '',
          petId: widget.petId,
          recordType: HealthRecordType.checkup,
          recordDate: _date,
          value: _titleController.text.isNotEmpty ? _titleController.text : 'Vet Checkup',
          note: _noteController.text.isNotEmpty ? _noteController.text : null,
          createdAt: DateTime.now(),
        ),
      );
      if (mounted) {
        Navigator.pop(context);
        showAppNotification(context, message: 'Checkup logged!', type: NotificationType.success);
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.stone200, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Log Checkup', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Visit Type',
                hintText: 'e.g., Annual checkup, Dental cleaning',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'What did the vet say? Any recommendations?',
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today, color: AppColors.primary500),
              title: Text('${_date.month}/${_date.day}/${_date.year}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (d != null) setState(() => _date = d);
              },
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
                    : const Text('Save Checkup'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
