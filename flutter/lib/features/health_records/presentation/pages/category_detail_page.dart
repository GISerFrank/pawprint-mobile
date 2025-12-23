import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/pet_theme.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/models/models.dart';
import '../../../../shared/widgets/widgets.dart';

// ============================================
// Shared Components for Category Pages
// ============================================

/// Today's Tasks Section
class TodayTasksSection extends ConsumerWidget {
  final List<DailyTask> tasks;
  final Pet pet;
  final PetTheme theme;
  final CareCategory category;

  const TodayTasksSection({
    super.key,
    required this.tasks,
    required this.pet,
    required this.theme,
    required this.category,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completedCount = tasks.where((t) => t.isCompleted).length;

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
              Icon(Icons.today, color: category.color, size: 20),
              const SizedBox(width: 8),
              const Text("Today's Tasks", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: category.lightColor, borderRadius: BorderRadius.circular(12)),
                child: Text('$completedCount/${tasks.length}',
                    style: TextStyle(color: category.color, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...tasks.map((task) => _TodayTaskItem(task: task, pet: pet, theme: theme, category: category)),
        ],
      ),
    );
  }
}

class _TodayTaskItem extends ConsumerWidget {
  final DailyTask task;
  final Pet pet;
  final PetTheme theme;
  final CareCategory category;

  const _TodayTaskItem({required this.task, required this.pet, required this.theme, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompleted = task.isCompleted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _handleTap(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isCompleted ? category.lightColor : AppColors.stone50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isCompleted ? category.color.withOpacity(0.3) : AppColors.stone200),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: isCompleted ? category.color : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: isCompleted ? null : Border.all(color: AppColors.stone200),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : Center(child: Text(task.metric.emoji ?? '📋', style: const TextStyle(fontSize: 18))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.metric.name, style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14,
                      color: isCompleted ? AppColors.stone500 : AppColors.stone800,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    )),
                    if (task.metric.description != null)
                      Text(task.metric.description!, style: TextStyle(fontSize: 12, color: AppColors.stone400),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (task.scheduledTime != null && !isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  child: Text('${task.scheduledTime}:00', style: TextStyle(fontSize: 11, color: AppColors.stone500)),
                ),
              if (isCompleted) Icon(Icons.check_circle, color: category.color, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, WidgetRef ref) {
    if (task.isCompleted) {
      showDraggableBottomSheet(
        context: context, initialChildSize: 0.6, minChildSize: 0.4, maxChildSize: 0.9,
        child: MetricHistorySheetContent(metric: task.metric, petId: pet.id, category: category),
      );
    } else if (task.metric.valueType == MetricValueType.boolean) {
      ref.read(carePlanNotifierProvider.notifier).quickCompleteTask(task.metric, pet.id);
      showAppNotification(context, message: '${task.metric.name} completed! ✓', type: NotificationType.success);
    } else {
      showDraggableBottomSheet(
        context: context, initialChildSize: 0.5, minChildSize: 0.3, maxChildSize: 0.9,
        child: MetricInputSheetContent(metric: task.metric, petId: pet.id, theme: theme),
      );
    }
  }
}

/// Metric Card
class MetricCard extends ConsumerWidget {
  final CareMetric metric;
  final Pet pet;
  final PetTheme theme;
  final CareCategory category;

  const MetricCard({super.key, required this.metric, required this.pet, required this.theme, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.soft),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => showDraggableBottomSheet(
            context: context, initialChildSize: 0.4, minChildSize: 0.25, maxChildSize: 0.6,
            child: MetricOptionsSheetContent(metric: metric, petId: pet.id, theme: theme, category: category),
          ),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: category.lightColor, borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text(metric.emoji ?? '📋', style: const TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(child: Text(metric.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                        if (metric.isPinned) Icon(Icons.push_pin, size: 14, color: category.color),
                      ]),
                      const SizedBox(height: 4),
                      Row(children: [
                        _buildChip(metric.frequency.name, AppColors.stone100, AppColors.stone600),
                        const SizedBox(width: 8),
                        _buildSourceChip(metric.source),
                      ]),
                      if (metric.description != null) ...[
                        const SizedBox(height: 6),
                        Text(metric.description!, style: TextStyle(fontSize: 12, color: AppColors.stone500),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.stone300),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(fontSize: 10, color: fg)),
    );
  }

  Widget _buildSourceChip(MetricSource source) {
    final color = switch (source) {
      MetricSource.aiBase => AppColors.primary500,
      MetricSource.userCustom => AppColors.mint500,
      MetricSource.aiDynamic => AppColors.peach500,
      MetricSource.postIllness => AppColors.lavender500,
    };
    return _buildChip(source.name, color.withOpacity(0.1), color);
  }
}

/// Empty Metrics Widget
class EmptyMetricsWidget extends StatelessWidget {
  final CareCategory category;
  final VoidCallback onAdd;

  const EmptyMetricsWidget({super.key, required this.category, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppShadows.soft),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: category.lightColor, shape: BoxShape.circle),
            child: Icon(category.icon, size: 40, color: category.color),
          ),
          const SizedBox(height: 20),
          Text('No ${category.name} Metrics', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Text('Add metrics to start tracking', style: TextStyle(color: AppColors.stone500)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Metric'),
            style: ElevatedButton.styleFrom(backgroundColor: category.color),
          ),
        ],
      ),
    );
  }
}

// ============================================
// Sheet Contents
// ============================================

/// Add Metric Sheet
class AddMetricSheetContent extends ConsumerStatefulWidget {
  final CareCategory category;
  final String petId;

  const AddMetricSheetContent({super.key, required this.category, required this.petId});

  @override
  ConsumerState<AddMetricSheetContent> createState() => _AddMetricSheetContentState();
}

class _AddMetricSheetContentState extends ConsumerState<AddMetricSheetContent> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String _emoji = '📋';
  MetricFrequency _frequency = MetricFrequency.daily;
  MetricValueType _valueType = MetricValueType.boolean;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      showAppNotification(context, message: 'Please enter a name', type: NotificationType.error);
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(carePlanNotifierProvider.notifier).addCustomMetric(
        petId: widget.petId, category: widget.category,
        name: _nameController.text.trim(),
        description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
        emoji: _emoji, frequency: _frequency, valueType: _valueType,
      );
      if (mounted) { Navigator.pop(context); showAppNotification(context, message: 'Metric added!', type: NotificationType.success); }
    } catch (e) {
      showAppNotification(context, message: 'Failed to add', type: NotificationType.error);
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final emojis = ['📋', '❤️', '💊', '🍽️', '💧', '🏃', '😴', '✨', '🎯', '🧹', '✂️', '🦷'];
    return KeyboardAwareSheetContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add ${widget.category.name} Metric', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          Wrap(spacing: 8, runSpacing: 8, children: emojis.map((e) => GestureDetector(
            onTap: () => setState(() => _emoji = e),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: _emoji == e ? widget.category.lightColor : AppColors.stone50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _emoji == e ? widget.category.color : AppColors.stone200),
              ),
              child: Center(child: Text(e, style: const TextStyle(fontSize: 20))),
            ),
          )).toList()),
          const SizedBox(height: 16),
          AppTextField(controller: _nameController, hintText: 'Metric name *'),
          const SizedBox(height: 12),
          AppTextField(controller: _descController, hintText: 'Description (optional)'),
          const SizedBox(height: 16),
          Text('Frequency', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.stone600, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [MetricFrequency.daily, MetricFrequency.weekly, MetricFrequency.monthly].map((f) =>
            ChoiceChip(label: Text(f.name), selected: _frequency == f, onSelected: (_) => setState(() => _frequency = f),
                selectedColor: widget.category.lightColor)).toList()),
          const SizedBox(height: 16),
          Text('Value Type', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.stone600, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            _ValueTypeChip(type: MetricValueType.boolean, label: 'Yes/No', selected: _valueType, onTap: (t) => setState(() => _valueType = t), color: widget.category.color),
            _ValueTypeChip(type: MetricValueType.number, label: 'Number', selected: _valueType, onTap: (t) => setState(() => _valueType = t), color: widget.category.color),
            _ValueTypeChip(type: MetricValueType.range, label: 'Rating', selected: _valueType, onTap: (t) => setState(() => _valueType = t), color: widget.category.color),
          ]),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
            onPressed: _loading ? null : _save,
            style: ElevatedButton.styleFrom(backgroundColor: widget.category.color),
            child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Add'),
          )),
        ],
      ),
    );
  }
}

class _ValueTypeChip extends StatelessWidget {
  final MetricValueType type;
  final String label;
  final MetricValueType selected;
  final Function(MetricValueType) onTap;
  final Color color;

  const _ValueTypeChip({required this.type, required this.label, required this.selected, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == type;
    return GestureDetector(
      onTap: () => onTap(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : AppColors.stone50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? color : AppColors.stone200),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? color : AppColors.stone600, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }
}

/// Metric Options Sheet
class MetricOptionsSheetContent extends ConsumerWidget {
  final CareMetric metric;
  final String petId;
  final PetTheme theme;
  final CareCategory category;

  const MetricOptionsSheetContent({super.key, required this.metric, required this.petId, required this.theme, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          Text(metric.emoji ?? '📋', style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(metric.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            if (metric.description != null) Text(metric.description!, style: TextStyle(color: AppColors.stone500, fontSize: 13)),
          ])),
        ]),
        const SizedBox(height: 24),
        _OptionTile(icon: Icons.add_circle_outline, label: 'Log Now', color: category.color, onTap: () {
          Navigator.pop(context);
          showDraggableBottomSheet(context: context, initialChildSize: 0.5, minChildSize: 0.3, maxChildSize: 0.9,
            child: MetricInputSheetContent(metric: metric, petId: petId, theme: theme));
        }),
        _OptionTile(icon: Icons.history, label: 'View History', color: AppColors.stone600, onTap: () {
          Navigator.pop(context);
          showDraggableBottomSheet(context: context, initialChildSize: 0.6, minChildSize: 0.4, maxChildSize: 0.9,
            child: MetricHistorySheetContent(metric: metric, petId: petId, category: category));
        }),
        if (!metric.isPinned)
          _OptionTile(
            icon: metric.isEnabled ? Icons.visibility_off : Icons.visibility,
            label: metric.isEnabled ? 'Disable' : 'Enable',
            color: AppColors.stone600,
            onTap: () async {
              await ref.read(carePlanNotifierProvider.notifier).toggleMetric(metric.id, !metric.isEnabled);
              if (context.mounted) { Navigator.pop(context); showAppNotification(context, message: metric.isEnabled ? 'Disabled' : 'Enabled', type: NotificationType.info); }
            },
          ),
        if (metric.source == MetricSource.userCustom && !metric.isPinned)
          _OptionTile(icon: Icons.delete_outline, label: 'Delete', color: Colors.red, onTap: () => _confirmDelete(context, ref)),
      ],
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Delete?'),
      content: Text('Delete "${metric.name}"?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(onPressed: () async {
          Navigator.pop(ctx);
          Navigator.pop(context);
          await ref.read(carePlanNotifierProvider.notifier).deleteMetric(metric.id);
        }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
      ],
    ));
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OptionTile({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(onTap: onTap, leading: Icon(icon, color: color), title: Text(label, style: TextStyle(color: color)),
        trailing: Icon(Icons.chevron_right, color: AppColors.stone300), contentPadding: EdgeInsets.zero);
  }
}

/// Metric Input Sheet
class MetricInputSheetContent extends ConsumerStatefulWidget {
  final CareMetric metric;
  final String petId;
  final PetTheme theme;

  const MetricInputSheetContent({super.key, required this.metric, required this.petId, required this.theme});

  @override
  ConsumerState<MetricInputSheetContent> createState() => _MetricInputSheetContentState();
}

class _MetricInputSheetContentState extends ConsumerState<MetricInputSheetContent> {
  double _numberValue = 0;
  int _rangeValue = 3;
  final _textController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _numberValue = widget.metric.targetValue ?? 0;
  }

  @override
  void dispose() { _textController.dispose(); super.dispose(); }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await ref.read(carePlanNotifierProvider.notifier).logMetric(
        metricId: widget.metric.id, petId: widget.petId,
        boolValue: widget.metric.valueType == MetricValueType.boolean ? true : null,
        numberValue: widget.metric.valueType == MetricValueType.number ? _numberValue : null,
        rangeValue: widget.metric.valueType == MetricValueType.range ? _rangeValue : null,
        textValue: widget.metric.valueType == MetricValueType.text ? _textController.text : null,
      );
      if (mounted) { Navigator.pop(context); showAppNotification(context, message: 'Logged!', type: NotificationType.success); }
    } catch (e) {
      showAppNotification(context, message: 'Failed', type: NotificationType.error);
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardAwareSheetContent(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Text(widget.metric.emoji ?? '📋', style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Text(widget.metric.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ]),
          const SizedBox(height: 24),
          _buildInput(),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
            onPressed: _loading ? null : _save,
            style: ElevatedButton.styleFrom(backgroundColor: widget.theme.primary),
            child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Log'),
          )),
        ],
      ),
    );
  }

  Widget _buildInput() {
    switch (widget.metric.valueType) {
      case MetricValueType.boolean:
        return Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: widget.theme.primaryLight, shape: BoxShape.circle),
            child: Icon(Icons.check, size: 48, color: widget.theme.primary));
      case MetricValueType.number:
        return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(onPressed: () => setState(() => _numberValue = (_numberValue - 1).clamp(0, 999)), icon: const Icon(Icons.remove_circle_outline), iconSize: 32),
          Column(children: [
            Text(_numberValue.toStringAsFixed(0), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
            if (widget.metric.unit != null) Text(widget.metric.unit!, style: TextStyle(color: AppColors.stone500)),
          ]),
          IconButton(onPressed: () => setState(() => _numberValue = (_numberValue + 1).clamp(0, 999)), icon: const Icon(Icons.add_circle_outline), iconSize: 32),
        ]);
      case MetricValueType.range:
        return Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) {
            final v = i + 1;
            return GestureDetector(
              onTap: () => setState(() => _rangeValue = v),
              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Icon(v <= _rangeValue ? Icons.star : Icons.star_outline, size: 36, color: v <= _rangeValue ? Colors.amber : AppColors.stone300)),
            );
          })),
          const SizedBox(height: 8),
          Text(['', 'Poor', 'Fair', 'Good', 'Very Good', 'Excellent'][_rangeValue], style: TextStyle(color: AppColors.stone600, fontWeight: FontWeight.w500)),
        ]);
      case MetricValueType.text:
        return AppTextField(controller: _textController, hintText: 'Enter notes...', maxLines: 3);
      default:
        return const SizedBox();
    }
  }
}

/// Metric History Sheet
final metricHistoryProvider = FutureProvider.family<List<MetricLog>, String>((ref, metricId) async {
  final pet = await ref.watch(currentPetProvider.future);
  if (pet == null) return [];
  final now = DateTime.now();
  final monthAgo = now.subtract(const Duration(days: 30));
  if (AppConfig.useLocalMode) {
    final logs = await ref.watch(localStorageProvider).getMetricLogs(pet.id, monthAgo, now);
    return logs.where((l) => l.metricId == metricId).toList()..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
  } else {
    final logs = await ref.watch(databaseServiceProvider).getMetricLogs(pet.id, monthAgo, now);
    return logs.where((l) => l.metricId == metricId).toList()..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
  }
});

class MetricHistorySheetContent extends ConsumerWidget {
  final CareMetric metric;
  final String petId;
  final CareCategory category;

  const MetricHistorySheetContent({super.key, required this.metric, required this.petId, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(metricHistoryProvider(metric.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(metric.emoji ?? '📋', style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${metric.name} History', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Last 30 days', style: TextStyle(color: AppColors.stone500, fontSize: 13)),
          ]),
        ]),
        const SizedBox(height: 20),
        Expanded(child: historyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(child: Text('Failed to load', style: TextStyle(color: AppColors.stone500))),
          data: (logs) {
            if (logs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.history, size: 48, color: AppColors.stone300),
              const SizedBox(height: 12),
              Text('No logs yet', style: TextStyle(color: AppColors.stone500)),
            ]));
            return ListView.builder(itemCount: logs.length, itemBuilder: (context, i) => _HistoryItem(log: logs[i], metric: metric, category: category));
          },
        )),
      ],
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final MetricLog log;
  final CareMetric metric;
  final CareCategory category;

  const _HistoryItem({required this.log, required this.metric, required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.stone50, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: category.lightColor, borderRadius: BorderRadius.circular(10)),
          child: Icon(log.boolValue == true ? Icons.check : Icons.circle, color: category.color, size: log.boolValue == true ? 20 : 8),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_formatValue(), style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(_formatDate(log.loggedAt), style: TextStyle(color: AppColors.stone500, fontSize: 12)),
        ])),
      ]),
    );
  }

  String _formatValue() {
    if (log.boolValue == true) return 'Completed';
    if (log.numberValue != null) return '${log.numberValue}${metric.unit != null ? ' ${metric.unit}' : ''}';
    if (log.rangeValue != null) return '${log.rangeValue}/5 stars';
    if (log.textValue != null) return log.textValue!;
    return 'Logged';
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.month}/${date.day}';
  }
}
