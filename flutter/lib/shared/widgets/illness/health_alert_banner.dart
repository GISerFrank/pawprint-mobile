import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/models.dart';

class HealthAlertBanner extends StatelessWidget {
  final String petName;
  final IllnessRecord illness;
  final VoidCallback onUpdateTap;
  final VoidCallback? onVisitedVetTap;

  const HealthAlertBanner({
    super.key,
    required this.petName,
    required this.illness,
    required this.onUpdateTap,
    this.onVisitedVetTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUndiagnosed = illness.sickType == SickType.undiagnosed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isUndiagnosed ? [AppColors.peach100, AppColors.peach50] : [AppColors.sky100, AppColors.sky50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isUndiagnosed ? AppColors.peach200 : AppColors.sky100, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isUndiagnosed ? AppColors.peach500 : AppColors.sky500).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isUndiagnosed ? Icons.warning_amber_rounded : Icons.medication,
                  color: isUndiagnosed ? AppColors.peach500 : AppColors.sky500,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isUndiagnosed ? '$petName is not feeling well' : '$petName is under treatment',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isUndiagnosed ? AppColors.peach800 : AppColors.sky900),
                    ),
                    const SizedBox(height: 2),
                    Text('Day ${illness.daysSick}', style: TextStyle(fontSize: 12, color: isUndiagnosed ? AppColors.peach500 : AppColors.sky500, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(isUndiagnosed ? Icons.description_outlined : Icons.medical_information, size: 16, color: AppColors.stone500),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isUndiagnosed ? 'Symptoms: ${illness.symptoms}' : 'Diagnosis: ${illness.diagnosis ?? illness.symptoms}',
                    style: TextStyle(fontSize: 13, color: AppColors.stone700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (illness.followUpDate != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: AppColors.primary500.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event, size: 14, color: AppColors.primary600),
                  const SizedBox(width: 6),
                  Text('Follow-up: ${_formatDate(illness.followUpDate!)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary600)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (isUndiagnosed && onVisitedVetTap != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onVisitedVetTap,
                    icon: const Icon(Icons.local_hospital, size: 16),
                    label: const Text('I visited a vet'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary600,
                      side: BorderSide(color: AppColors.primary300),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              if (isUndiagnosed && onVisitedVetTap != null) const SizedBox(width: 8),
              Expanded(
                child: TextButton.icon(
                  onPressed: onUpdateTap,
                  icon: Icon(Icons.edit_note, size: 16, color: AppColors.stone600),
                  label: Text('Update', style: TextStyle(color: AppColors.stone600)),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff < 7) return 'In $diff days';
    return '${date.month}/${date.day}';
  }
}
