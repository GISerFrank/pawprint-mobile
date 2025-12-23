import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';
import '../app_notification.dart';
import '../app_text_field.dart';
import '../draggable_bottom_sheet.dart';

/// 标记生病的 Sheet 内容组件
/// 用于 showDraggableBottomSheet
class MarkSickSheetContent extends ConsumerStatefulWidget {
  final String petId;
  final String petName;

  const MarkSickSheetContent({super.key, required this.petId, required this.petName});

  @override
  ConsumerState<MarkSickSheetContent> createState() => _MarkSickSheetContentState();
}

class _MarkSickSheetContentState extends ConsumerState<MarkSickSheetContent> {
  int _step = 0;
  SickType _selectedSickType = SickType.undiagnosed;
  final _symptomsController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _vetNotesController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime? _followUpDate;
  bool _loading = false;

  @override
  void dispose() {
    _symptomsController.dispose();
    _diagnosisController.dispose();
    _vetNotesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_symptomsController.text.isEmpty) {
      showAppNotification(context,
          message: 'Please describe the symptoms',
          type: NotificationType.error);
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(illnessNotifierProvider.notifier).startIllness(
            petId: widget.petId,
            sickType: _selectedSickType,
            symptoms: _symptomsController.text,
            diagnosis: _selectedSickType == SickType.diagnosed
                ? _diagnosisController.text
                : null,
            vetNotes: _selectedSickType == SickType.diagnosed
                ? _vetNotesController.text
                : null,
            followUpDate: _followUpDate,
          );
      if (mounted) {
        Navigator.pop(context);
        showAppNotification(context,
            message: 'Get well soon, ${widget.petName}! 💚',
            type: NotificationType.info);
      }
    } catch (e) {
      showAppNotification(context,
          message: 'Failed to save', type: NotificationType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardAwareSheetContent(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_step == 0) _buildStatusSelection(),
          if (_step == 1) _buildSickTypeSelection(),
          if (_step == 2) _buildDetailsForm(),
        ],
      ),
    );
  }

  Widget _buildStatusSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How is ${widget.petName} feeling?',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
                child: _StatusOption(
                    icon: Icons.favorite,
                    label: 'Healthy',
                    color: AppColors.mint500,
                    onTap: () {
                      Navigator.pop(context);
                      showAppNotification(context,
                          message: 'Great! ${widget.petName} is healthy! 🎉',
                          type: NotificationType.success);
                    })),
            const SizedBox(width: 16),
            Expanded(
                child: _StatusOption(
                    icon: Icons.healing,
                    label: 'Sick',
                    color: AppColors.peach500,
                    onTap: () => setState(() => _step = 1))),
          ],
        ),
      ],
    );
  }

  Widget _buildSickTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
                onPressed: () => setState(() => _step = 0),
                icon: const Icon(Icons.arrow_back),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints()),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Has ${widget.petName} seen a vet?',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SickTypeOption(
            icon: Icons.local_hospital,
            title: 'Yes, already diagnosed',
            subtitle: 'I have a diagnosis and treatment plan',
            isSelected: _selectedSickType == SickType.diagnosed,
            onTap: () => setState(() {
                  _selectedSickType = SickType.diagnosed;
                  _step = 2;
                })),
        const SizedBox(height: 12),
        _SickTypeOption(
            icon: Icons.help_outline,
            title: 'Not yet',
            subtitle: 'I want to track symptoms first',
            isSelected: _selectedSickType == SickType.undiagnosed,
            onTap: () => setState(() {
                  _selectedSickType = SickType.undiagnosed;
                  _step = 2;
                })),
      ],
    );
  }

  Widget _buildDetailsForm() {
    final isDiagnosed = _selectedSickType == SickType.diagnosed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
                onPressed: () => setState(() => _step = 1),
                icon: const Icon(Icons.arrow_back),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints()),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                  isDiagnosed
                      ? 'Diagnosis & Treatment'
                      : 'What symptoms do you notice?',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Symptoms',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.stone600)),
        const SizedBox(height: 8),
        AppTextField(
            controller: _symptomsController,
            maxLines: 2,
            hintText: 'e.g., Not eating, low energy, limping...'),
        const SizedBox(height: 16),
        if (isDiagnosed) ...[
          Text('Diagnosis',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.stone600)),
          const SizedBox(height: 8),
          AppTextField(
              controller: _diagnosisController,
              hintText: 'What did the vet say?'),
          const SizedBox(height: 16),
          Text('Treatment / Vet Notes',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.stone600)),
          const SizedBox(height: 8),
          AppTextField(
              controller: _vetNotesController,
              maxLines: 2,
              hintText: 'Treatment instructions...'),
          const SizedBox(height: 16),
          Text('Follow-up Appointment',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.stone600)),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: AppColors.primary100,
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.calendar_today,
                    color: AppColors.primary500, size: 20)),
            title: Text(
                _followUpDate != null
                    ? '${_followUpDate!.month}/${_followUpDate!.day}/${_followUpDate!.year}'
                    : 'No appointment scheduled',
                style: TextStyle(
                    color: _followUpDate != null
                        ? AppColors.stone800
                        : AppColors.stone400)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 7)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)));
              if (date != null) setState(() => _followUpDate = date);
            },
          ),
        ],
        Text('When did it start?',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.stone600)),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppColors.peach100,
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.event, color: AppColors.peach500, size: 20)),
          title:
              Text('${_startDate.month}/${_startDate.day}/${_startDate.year}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            final date = await showDatePicker(
                context: context,
                initialDate: _startDate,
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now());
            if (date != null) setState(() => _startDate = date);
          },
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _loading ? null : _save,
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.peach500),
            child: _loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Start Tracking'),
          ),
        ),
      ],
    );
  }
}

class _StatusOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _StatusOption(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: AppColors.stone50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.stone200, width: 2)),
        child: Column(
          children: [
            Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.2), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 32)),
            const SizedBox(height: 12),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.stone800)),
          ],
        ),
      ),
    );
  }
}

class _SickTypeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _SickTypeOption(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: isSelected ? AppColors.primary50 : AppColors.stone50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isSelected ? AppColors.primary500 : AppColors.stone200,
                width: 2)),
        child: Row(
          children: [
            Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color:
                        isSelected ? AppColors.primary100 : AppColors.stone100,
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon,
                    color: isSelected
                        ? AppColors.primary500
                        : AppColors.stone500)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.stone800)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style:
                          TextStyle(fontSize: 12, color: AppColors.stone500)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.stone400),
          ],
        ),
      ),
    );
  }
}
