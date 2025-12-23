import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';
import '../app_notification.dart';
import '../app_text_field.dart';

/// 用药管理列表
class MedicationList extends ConsumerWidget {
  final String petId;
  final String illnessId;

  const MedicationList({
    super.key,
    required this.petId,
    required this.illnessId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicationsAsync = ref.watch(medicationsProvider);

    return Container(
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.peach100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.medication, color: AppColors.peach500, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Medications',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              IconButton(
                onPressed: () => _showAddMedicationSheet(context),
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.peach100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add, color: AppColors.peach500, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          medicationsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Failed to load medications'),
            data: (medications) {
              if (medications.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.stone50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.medication_outlined, size: 40, color: AppColors.stone300),
                      const SizedBox(height: 12),
                      Text(
                        'No medications added',
                        style: TextStyle(color: AppColors.stone500),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => _showAddMedicationSheet(context),
                        child: const Text('+ Add Medication'),
                      ),
                    ],
                  ),
                );
              }
              return Column(
                children: medications.map((m) => _MedicationItem(
                  medication: m,
                  petId: petId,
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAddMedicationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddMedicationSheet(
        petId: petId,
        illnessId: illnessId,
      ),
    );
  }
}

class _MedicationItem extends ConsumerWidget {
  final Medication medication;
  final String petId;

  const _MedicationItem({required this.medication, required this.petId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(todayMedicationLogsProvider);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.peach50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.peach100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medication.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.peach800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${medication.dosage ?? 'As needed'} • ${medication.frequency}',
                      style: TextStyle(fontSize: 13, color: AppColors.peach600),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: AppColors.peach400),
                onSelected: (value) {
                  if (value == 'delete') {
                    _confirmDelete(context, ref);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Today's doses
          logsAsync.when(
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
            data: (logs) {
              final todayLogs = logs.where((l) => l.medicationId == medication.id).toList();
              final takenCount = todayLogs.where((l) => l.isTaken).length;
              
              return Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, size: 16, color: takenCount > 0 ? AppColors.mint500 : AppColors.stone300),
                        const SizedBox(width: 6),
                        Text(
                          '$takenCount/${medication.timesPerDay} today',
                          style: TextStyle(
                            fontSize: 13,
                            color: takenCount > 0 ? AppColors.mint600 : AppColors.stone500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (takenCount < medication.timesPerDay)
                    TextButton.icon(
                      onPressed: () => _logDose(context, ref),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Log Dose'),
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.peach500,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _logDose(BuildContext context, WidgetRef ref) {
    ref.read(illnessNotifierProvider.notifier).logMedicationTaken(
      medicationId: medication.id,
      petId: petId,
      scheduledTime: DateTime.now(),
    );
    showAppNotification(context, message: '${medication.name} logged 💊', type: NotificationType.success);
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Medication?'),
        content: Text('Remove ${medication.name} from the list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(illnessNotifierProvider.notifier).deleteMedication(medication.id);
              Navigator.pop(ctx);
              showAppNotification(context, message: 'Medication deleted', type: NotificationType.info);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

/// 添加药物表单
class AddMedicationSheet extends ConsumerStatefulWidget {
  final String petId;
  final String illnessId;

  const AddMedicationSheet({
    super.key,
    required this.petId,
    required this.illnessId,
  });

  @override
  ConsumerState<AddMedicationSheet> createState() => _AddMedicationSheetState();
}

class _AddMedicationSheetState extends ConsumerState<AddMedicationSheet> {
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  String _frequency = 'Daily';
  int _timesPerDay = 1;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _loading = false;

  final _frequencyOptions = ['Daily', 'Twice daily', 'Every 8 hours', 'As needed', 'Weekly'];

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty) {
      showAppNotification(context, message: 'Enter medication name', type: NotificationType.error);
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(illnessNotifierProvider.notifier).addMedication(
        illnessId: widget.illnessId,
        petId: widget.petId,
        name: _nameController.text,
        dosage: _dosageController.text.isNotEmpty ? _dosageController.text : null,
        frequency: _frequency,
        timesPerDay: _timesPerDay,
        startDate: _startDate,
        endDate: _endDate,
      );
      if (mounted) {
        Navigator.pop(context);
        showAppNotification(context, message: 'Medication added', type: NotificationType.success);
      }
    } catch (e) {
      showAppNotification(context, message: 'Failed to add', type: NotificationType.error);
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
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.stone200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Add Medication', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),

            // Name
            AppTextField(
              controller: _nameController,
              labelText: 'Medication Name',
              hintText: 'e.g., Amoxicillin',
              prefixIcon: const Icon(Icons.medication),
            ),
            const SizedBox(height: 16),

            // Dosage
            AppTextField(
              controller: _dosageController,
              labelText: 'Dosage (optional)',
              hintText: 'e.g., 250mg, 1 tablet',
              prefixIcon: const Icon(Icons.science),
            ),
            const SizedBox(height: 16),

            // Frequency
            const Text('Frequency', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.stone600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _frequencyOptions.map((f) => ChoiceChip(
                label: Text(f),
                selected: _frequency == f,
                selectedColor: AppColors.peach100,
                onSelected: (_) => setState(() => _frequency = f),
              )).toList(),
            ),
            const SizedBox(height: 16),

            // Times per day
            const Text('Times per day', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.stone600)),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: _timesPerDay > 1 ? () => setState(() => _timesPerDay--) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: AppColors.peach500,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.peach50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_timesPerDay',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.peach600),
                  ),
                ),
                IconButton(
                  onPressed: _timesPerDay < 10 ? () => setState(() => _timesPerDay++) : null,
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppColors.peach500,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // End Date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.stone100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.event, color: AppColors.stone500, size: 20),
              ),
              title: Text(_endDate != null
                  ? 'Until ${_endDate!.month}/${_endDate!.day}/${_endDate!.year}'
                  : 'No end date'),
              subtitle: const Text('When to stop medication'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 7)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) setState(() => _endDate = date);
              },
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.peach500),
                child: _loading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Add Medication'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}