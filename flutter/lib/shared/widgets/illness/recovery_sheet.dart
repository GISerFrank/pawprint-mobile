import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';
import '../app_notification.dart';
import '../app_text_field.dart';

class RecoverySheet extends ConsumerStatefulWidget {
  final String petId;
  final String petName;
  final IllnessRecord illness;

  const RecoverySheet({
    super.key,
    required this.petId,
    required this.petName,
    required this.illness,
  });

  @override
  ConsumerState<RecoverySheet> createState() => _RecoverySheetState();
}

class _RecoverySheetState extends ConsumerState<RecoverySheet> {
  final _noteController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _confirmRecovery() async {
    setState(() => _loading = true);
    try {
      await ref.read(illnessNotifierProvider.notifier).markRecovered(
            petId: widget.petId,
            illnessId: widget.illness.id,
            recoveryNote:
                _noteController.text.isNotEmpty ? _noteController.text : null,
          );
      if (mounted) {
        Navigator.pop(context);
        showAppNotification(
          context,
          message: '🎉 ${widget.petName} is healthy again!',
          type: NotificationType.success,
        );
      }
    } catch (e) {
      showAppNotification(context,
          message: 'Failed to update', type: NotificationType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.stone200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Celebration Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.mint400, AppColors.mint500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.mint500.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.celebration,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              'Mark ${widget.petName} as Recovered?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              'Sick for ${widget.illness.daysSick} days',
              style: TextStyle(
                color: AppColors.stone500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.stone50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _SummaryRow(
                    icon: Icons.calendar_today,
                    label: 'Started',
                    value: _formatDate(widget.illness.startDate),
                  ),
                  const SizedBox(height: 12),
                  if (widget.illness.diagnosis != null) ...[
                    _SummaryRow(
                      icon: Icons.medical_information,
                      label: 'Diagnosis',
                      value: widget.illness.diagnosis!,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _SummaryRow(
                    icon: Icons.healing,
                    label: 'Symptoms',
                    value: widget.illness.symptoms,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Recovery Note
            AppTextField(
              controller: _noteController,
              maxLines: 2,
              labelText: 'Recovery Notes (optional)',
              hintText: 'How did ${widget.petName} recover?',
              prefixIcon: const Icon(Icons.note_alt_outlined),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: AppColors.stone300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Not Yet',
                      style: TextStyle(color: AppColors.stone600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _confirmRecovery,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mint500,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle),
                              SizedBox(width: 8),
                              Text('Yes, Recovered!'),
                            ],
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.stone400),
        const SizedBox(width: 10),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.stone500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.stone700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
