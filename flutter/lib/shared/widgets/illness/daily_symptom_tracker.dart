import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';
import '../app_notification.dart';
import '../app_text_field.dart';

/// 每日症状追踪卡片
class DailySymptomTracker extends ConsumerWidget {
  final String petId;
  final String petName;
  final IllnessRecord illness;

  const DailySymptomTracker({
    super.key,
    required this.petId,
    required this.petName,
    required this.illness,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(dailySymptomLogsProvider);

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
                  color: AppColors.primary100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.trending_up,
                    color: AppColors.primary500, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How is your pet feeling?',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'Day ${illness.daysSick} of illness',
                      style: TextStyle(fontSize: 12, color: AppColors.stone500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Symptom Level Buttons
          Row(
            children: [
              Expanded(
                child: _SymptomButton(
                  level: SymptomLevel.worse,
                  onTap: () => _logSymptom(context, ref, SymptomLevel.worse),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SymptomButton(
                  level: SymptomLevel.same,
                  onTap: () => _logSymptom(context, ref, SymptomLevel.same),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SymptomButton(
                  level: SymptomLevel.better,
                  onTap: () => _logSymptom(context, ref, SymptomLevel.better),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Recent Logs
          logsAsync.when(
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
            data: (logs) {
              if (logs.isEmpty) return const SizedBox();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Recent Tracking',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.stone500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...logs.reversed.take(5).map((log) => _LogItem(log: log)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _logSymptom(BuildContext context, WidgetRef ref, SymptomLevel level) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SymptomNoteSheet(
        petId: petId,
        illnessId: illness.id,
        level: level,
      ),
    );
  }
}

class _SymptomButton extends StatelessWidget {
  final SymptomLevel level;
  final VoidCallback onTap;

  const _SymptomButton({required this.level, required this.onTap});

  Color get _color {
    switch (level) {
      case SymptomLevel.worse:
        return AppColors.peach500;
      case SymptomLevel.same:
        return AppColors.stone500;
      case SymptomLevel.better:
        return AppColors.mint500;
    }
  }

  Color get _bgColor {
    switch (level) {
      case SymptomLevel.worse:
        return AppColors.peach50;
      case SymptomLevel.same:
        return AppColors.stone50;
      case SymptomLevel.better:
        return AppColors.mint50;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              level.emoji,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 4),
            Text(
              level.displayName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _color,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogItem extends StatelessWidget {
  final DailySymptomLog log;

  const _LogItem({required this.log});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(log.level.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            _formatDate(log.date),
            style: TextStyle(fontSize: 13, color: AppColors.stone600),
          ),
          if (log.note != null && log.note!.isNotEmpty) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                log.note!,
                style: TextStyle(fontSize: 12, color: AppColors.stone400),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final logDate = DateTime(date.year, date.month, date.day);

    if (logDate == today) return 'Today';
    if (logDate == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${date.month}/${date.day}';
  }
}

class _SymptomNoteSheet extends ConsumerStatefulWidget {
  final String petId;
  final String illnessId;
  final SymptomLevel level;

  const _SymptomNoteSheet({
    required this.petId,
    required this.illnessId,
    required this.level,
  });

  @override
  ConsumerState<_SymptomNoteSheet> createState() => _SymptomNoteSheetState();
}

class _SymptomNoteSheetState extends ConsumerState<_SymptomNoteSheet> {
  final _noteController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await ref.read(illnessNotifierProvider.notifier).logDailySymptom(
            illnessId: widget.illnessId,
            petId: widget.petId,
            level: widget.level,
            note: _noteController.text.isNotEmpty ? _noteController.text : null,
          );
      if (mounted) {
        Navigator.pop(context);
        showAppNotification(
          context,
          message: 'Symptom logged ${widget.level.emoji}',
          type: NotificationType.success,
        );
      }
    } catch (e) {
      showAppNotification(context,
          message: 'Failed to log', type: NotificationType.error);
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.stone200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '${widget.level.emoji} Feeling ${widget.level.displayName}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: _noteController,
              maxLines: 3,
              labelText: 'Add a note (optional)',
              hintText: 'Any observations or details...',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
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
