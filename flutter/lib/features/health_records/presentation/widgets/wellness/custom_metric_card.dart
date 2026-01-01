import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/pet_theme.dart';
import '../../../../../core/models/models.dart';
import '../../../../../core/providers/wellness_provider.dart';
import 'sparkline.dart';
import 'metric_attachment_input.dart';
import 'log_detail_sheet.dart';

/// 自定义指标卡片
class CustomMetricCard extends ConsumerWidget {
  final CareMetric metric;
  final PetTheme theme;

  const CustomMetricCard({
    super.key,
    required this.metric,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayLogAsync = ref.watch(customMetricTodayLogProvider(metric.id));
    final historyAsync = ref.watch(customMetricHistoryProvider(metric.id));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showLogDialog(context, ref, todayLogAsync.valueOrNull),
          onLongPress: () => _showOptionsMenu(context, ref),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题行
                Row(
                  children: [
                    Text(metric.emoji ?? '📊', style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        metric.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.stone800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // 今日值
                    todayLogAsync.when(
                      loading: () => const SizedBox(width: 16, height: 16),
                      error: (_, __) => Icon(Icons.add, size: 16, color: AppColors.stone400),
                      data: (log) {
                        if (log == null) {
                          return Icon(Icons.add, size: 16, color: AppColors.stone400);
                        }
                        return _buildTodayValue(context, log);
                      },
                    ),
                  ],
                ),
                
                const Spacer(),
                
                // Sparkline 或空状态
                historyAsync.when(
                  loading: () => const SizedBox(height: 20),
                  error: (_, __) => const SizedBox(height: 20),
                  data: (history) {
                    if (history.isEmpty) {
                      return Text(
                        'Tap to log',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.stone400,
                          fontSize: 11,
                        ),
                      );
                    }
                    return _buildSparkline(history);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodayValue(BuildContext context, MetricLog log) {
    String valueText;
    Color color = AppColors.green500;
    IconData? icon;

    switch (metric.valueType) {
      case MetricValueType.range:
        final score = log.rangeValue ?? 0;
        valueText = '$score';
        color = score <= 2 ? AppColors.red400 : (score == 3 ? AppColors.amber400 : AppColors.green400);
        break;
      case MetricValueType.number:
        valueText = log.numberValue?.toStringAsFixed(1) ?? '-';
        break;
      case MetricValueType.boolean:
        valueText = log.boolValue == true ? '✓' : '✗';
        color = log.boolValue == true ? AppColors.green500 : AppColors.red400;
        break;
      case MetricValueType.text:
        valueText = '📝';
        break;
      case MetricValueType.image:
        valueText = '';
        icon = Icons.photo;
        color = AppColors.blue500;
        break;
      case MetricValueType.video:
        valueText = '';
        icon = Icons.videocam;
        color = AppColors.red500;
        break;
      default:
        valueText = '-';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: icon != null
          ? Icon(icon, size: 16, color: color)
          : Text(
              valueText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
    );
  }

  Widget _buildSparkline(List<MetricLog> history) {
    switch (metric.valueType) {
      case MetricValueType.range:
        final scores = history.take(7).map((l) => l.rangeValue ?? 3).toList().reversed.toList();
        return ScoreSparkline(scores: scores, height: 20);
      case MetricValueType.number:
        final values = history.take(7).map((l) => l.numberValue ?? 0.0).toList().reversed.toList();
        return WeightSparkline(weights: values, height: 20);
      case MetricValueType.image:
      case MetricValueType.video:
        // 显示最近记录的缩略图
        final recentLogs = history.take(4).toList();
        if (recentLogs.isEmpty) {
          return const SizedBox(height: 20);
        }
        return SizedBox(
          height: 24,
          child: Row(
            children: [
              ...recentLogs.take(3).map((log) {
                final hasImage = log.imageUrls?.isNotEmpty == true;
                return Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: hasImage ? AppColors.blue100 : AppColors.stone100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    metric.valueType == MetricValueType.image
                        ? Icons.photo
                        : Icons.videocam,
                    size: 14,
                    color: hasImage ? AppColors.blue500 : AppColors.stone400,
                  ),
                );
              }),
              if (history.length > 3)
                Text(
                  '+${history.length - 3}',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.stone500,
                  ),
                ),
            ],
          ),
        );
      default:
        return const SizedBox(height: 20);
    }
  }

  void _showLogDialog(BuildContext context, WidgetRef ref, MetricLog? existingLog) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CustomMetricLogSheet(
        metric: metric,
        existingLog: existingLog,
        theme: theme,
      ),
    );
  }

  void _showOptionsMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.stone300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(metric.emoji ?? '📊', style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Text(
                      metric.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.history, color: AppColors.stone600),
                title: const Text('View History'),
                onTap: () {
                  Navigator.pop(context);
                  _showHistorySheet(context, ref);
                },
              ),
              ListTile(
                leading: Icon(Icons.edit_outlined, color: AppColors.stone600),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditSheet(context, ref);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: AppColors.red500),
                title: Text('Delete', style: TextStyle(color: AppColors.red500)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, ref);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showHistorySheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CustomMetricHistorySheet(
        metric: metric,
        theme: theme,
      ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditMetricSheet(
        metric: metric,
        theme: theme,
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Metric?'),
        content: Text('Are you sure you want to delete "${metric.name}"? This will also delete all recorded data for this metric.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref.read(wellnessScoreNotifierProvider.notifier).deleteCustomMetric(
                metricId: metric.id,
              );
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${metric.emoji ?? ''} ${metric.name} deleted'),
                    backgroundColor: AppColors.stone600,
                  ),
                );
              }
            },
            child: Text('Delete', style: TextStyle(color: AppColors.red500)),
          ),
        ],
      ),
    );
  }
}

/// 自定义指标记录底部弹窗
class _CustomMetricLogSheet extends ConsumerStatefulWidget {
  final CareMetric metric;
  final MetricLog? existingLog;
  final PetTheme theme;

  const _CustomMetricLogSheet({
    required this.metric,
    this.existingLog,
    required this.theme,
  });

  @override
  ConsumerState<_CustomMetricLogSheet> createState() => _CustomMetricLogSheetState();
}

class _CustomMetricLogSheetState extends ConsumerState<_CustomMetricLogSheet> {
  late int _rangeValue;
  late double _numberValue;
  late bool _boolValue;
  final _textController = TextEditingController();
  final _notesController = TextEditingController();
  final List<String> _imageUrls = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _rangeValue = widget.existingLog?.rangeValue ?? 5;
    _numberValue = widget.existingLog?.numberValue ?? 0;
    _boolValue = widget.existingLog?.boolValue ?? true;
    _textController.text = widget.existingLog?.textValue ?? '';
    _notesController.text = widget.existingLog?.notes ?? '';
    if (widget.existingLog?.imageUrls != null) {
      _imageUrls.addAll(widget.existingLog!.imageUrls!);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 拖动指示器
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.stone300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 标题
              Row(
                children: [
                  Text(widget.metric.emoji ?? '📊', style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.metric.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.metric.description?.isNotEmpty == true)
                          Text(
                            widget.metric.description!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.stone500,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 值输入
              _buildValueInput(),
              const SizedBox(height: 20),

              // 备注输入
              Text(
                'Notes (optional)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add any observations...',
                  filled: true,
                  fillColor: AppColors.stone50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 图片添加
              _buildImageSection(),
              const SizedBox(height: 24),

              // 保存按钮
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveLog,
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.theme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValueInput() {
    switch (widget.metric.valueType) {
      case MetricValueType.range:
        return _buildRangeInput();
      case MetricValueType.number:
        return _buildNumberInput();
      case MetricValueType.boolean:
        return _buildBooleanInput();
      case MetricValueType.text:
        return _buildTextInput();
      case MetricValueType.image:
        return _buildImageInput();
      case MetricValueType.video:
        return _buildVideoInput();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildRangeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rating',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(5, (index) {
            final score = index + 1;
            final isSelected = score == _rangeValue;
            final color = _getScoreColor(score);
            
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _rangeValue = score),
                child: Container(
                  margin: EdgeInsets.only(right: index < 4 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? color : AppColors.stone100,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected ? Border.all(color: color, width: 2) : null,
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$score',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : AppColors.stone600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildNumberInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Value',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) => _numberValue = double.tryParse(v) ?? 0,
          decoration: InputDecoration(
            hintText: 'Enter value',
            filled: true,
            fillColor: AppColors.stone50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            suffixText: widget.metric.unit,
          ),
          controller: TextEditingController(text: _numberValue > 0 ? _numberValue.toString() : ''),
        ),
      ],
    );
  }

  Widget _buildBooleanInput() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _boolValue = true),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _boolValue ? AppColors.green500 : AppColors.stone100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '✓ Yes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _boolValue ? Colors.white : AppColors.stone600,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _boolValue = false),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: !_boolValue ? AppColors.red400 : AppColors.stone100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '✗ No',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: !_boolValue ? Colors.white : AppColors.stone600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Entry',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _textController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter your observation...',
            filled: true,
            fillColor: AppColors.stone50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  /// 图片类型的主输入（必须上传图片）
  Widget _buildImageInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Take a Photo',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Capture the current condition',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.stone500,
          ),
        ),
        const SizedBox(height: 12),
        if (_imageUrls.isEmpty)
          // 大型拍照按钮
          GestureDetector(
            onTap: () => _showImageSourcePicker(isRequired: true),
            child: Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: widget.theme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.theme.primary.withOpacity(0.3),
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: widget.theme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: 32,
                      color: widget.theme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tap to take photo',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: widget.theme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'or choose from gallery',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.stone500,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          // 已上传的图片预览
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Image.network(
                      _imageUrls.first,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: double.infinity,
                        height: 200,
                        color: AppColors.stone200,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image, size: 48, color: AppColors.stone400),
                            const SizedBox(height: 8),
                            Text('Image preview', style: TextStyle(color: AppColors.stone500)),
                          ],
                        ),
                      ),
                    ),
                    // 删除按钮
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _imageUrls.clear()),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 18, color: Colors.white),
                        ),
                      ),
                    ),
                    // 重新拍照按钮
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _showImageSourcePicker(isRequired: true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.refresh, size: 16, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'Retake',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 添加更多图片
              if (_imageUrls.length < 4)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: OutlinedButton.icon(
                    onPressed: () => _showImageSourcePicker(isRequired: false),
                    icon: const Icon(Icons.add_photo_alternate, size: 18),
                    label: const Text('Add more photos'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.stone600,
                      side: BorderSide(color: AppColors.stone300),
                    ),
                  ),
                ),
            ],
          ),
        // 额外图片缩略图
        if (_imageUrls.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _imageUrls.length - 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final actualIndex = index + 1;
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _imageUrls[actualIndex],
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 60,
                            height: 60,
                            color: AppColors.stone200,
                            child: const Icon(Icons.image, size: 24),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => setState(() => _imageUrls.removeAt(actualIndex)),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  /// 视频类型的主输入
  Widget _buildVideoInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Record a Video',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Capture movement or behavior',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.stone500,
          ),
        ),
        const SizedBox(height: 12),
        if (_imageUrls.isEmpty) // 复用 _imageUrls 存储视频路径
          // 大型录制按钮
          GestureDetector(
            onTap: _showVideoSourcePicker,
            child: Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.red50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.red200,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.red100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.videocam,
                      size: 32,
                      color: AppColors.red500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tap to record video',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.red500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'or choose from gallery',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.stone500,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          // 视频已录制
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.green50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.green200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.green100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, color: AppColors.green600),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Video recorded',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.green700,
                        ),
                      ),
                      Text(
                        'Ready to save',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.stone500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _imageUrls.clear()),
                  icon: Icon(Icons.delete_outline, color: AppColors.red500),
                ),
                IconButton(
                  onPressed: _showVideoSourcePicker,
                  icon: Icon(Icons.refresh, color: AppColors.stone600),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// 显示图片来源选择器
  void _showImageSourcePicker({required bool isRequired}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.stone300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.theme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.camera_alt, color: widget.theme.primary),
                ),
                title: const Text('Take Photo'),
                subtitle: const Text('Use camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.purple100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.photo_library, color: AppColors.purple500),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select existing photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// 显示视频来源选择器
  void _showVideoSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.stone300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.red100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.videocam, color: AppColors.red500),
                ),
                title: const Text('Record Video'),
                subtitle: const Text('Use camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.purple100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.video_library, color: AppColors.purple500),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select existing video'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickVideo(ImageSource source) async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(
      source: source,
      maxDuration: const Duration(seconds: 30),
    );
    
    if (video != null) {
      setState(() {
        _imageUrls.clear();
        _imageUrls.add(video.path);
      });
    }
  }

  /// 可选的照片附件（仅在非 image/video 类型时显示）
  Widget _buildImageSection() {
    // 如果是 image 或 video 类型，主输入已经处理了图片/视频，不需要额外的附件区域
    if (widget.metric.valueType == MetricValueType.image ||
        widget.metric.valueType == MetricValueType.video) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photos (optional)',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // 已添加的图片
            ..._imageUrls.asMap().entries.map((entry) => Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    entry.value,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 70,
                      height: 70,
                      color: AppColors.stone200,
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: () => setState(() => _imageUrls.removeAt(entry.key)),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            )),
            // 添加按钮
            if (_imageUrls.length < 4)
              GestureDetector(
                onTap: () => _pickImage(ImageSource.gallery),
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppColors.stone100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.stone300, style: BorderStyle.solid),
                  ),
                  child: Icon(Icons.add_a_photo, color: AppColors.stone400),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);
    
    if (image != null) {
      // TODO: 上传到存储服务获取URL
      // 暂时使用本地路径作为示例
      setState(() {
        if (widget.metric.valueType == MetricValueType.image && _imageUrls.isEmpty) {
          // image 类型第一张图片
          _imageUrls.add(image.path);
        } else {
          _imageUrls.add(image.path);
        }
      });
    }
  }

  Color _getScoreColor(int score) {
    if (score == 1) return AppColors.red500;
    if (score == 2) return AppColors.orange500;
    if (score == 3) return AppColors.amber500;
    if (score == 4) return AppColors.lime500;
    return AppColors.green500;
  }

  Future<void> _saveLog() async {
    // 验证 image 和 video 类型必须有文件
    if ((widget.metric.valueType == MetricValueType.image ||
         widget.metric.valueType == MetricValueType.video) &&
        _imageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.metric.valueType == MetricValueType.image
                ? 'Please take a photo first'
                : 'Please record a video first',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() => _isSaving = true);

    try {
      final success = await ref.read(wellnessScoreNotifierProvider.notifier).saveCustomMetricLog(
        petId: widget.metric.petId,
        metricId: widget.metric.id,
        rangeValue: widget.metric.valueType == MetricValueType.range ? _rangeValue : null,
        numberValue: widget.metric.valueType == MetricValueType.number ? _numberValue : null,
        boolValue: widget.metric.valueType == MetricValueType.boolean ? _boolValue : null,
        textValue: widget.metric.valueType == MetricValueType.text ? _textController.text : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        imageUrls: _imageUrls.isNotEmpty ? _imageUrls : null,
      );

      if (success && mounted) {
        // 刷新providers
        ref.invalidate(customMetricTodayLogProvider(widget.metric.id));
        ref.invalidate(customMetricHistoryProvider(widget.metric.id));
        
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.metric.emoji ?? '📊'} ${widget.metric.name} logged!'),
            backgroundColor: AppColors.green500,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

/// 编辑指标底部弹窗
class _EditMetricSheet extends ConsumerStatefulWidget {
  final CareMetric metric;
  final PetTheme theme;

  const _EditMetricSheet({
    required this.metric,
    required this.theme,
  });

  @override
  ConsumerState<_EditMetricSheet> createState() => _EditMetricSheetState();
}

class _EditMetricSheetState extends ConsumerState<_EditMetricSheet> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late String _selectedEmoji;
  bool _isSaving = false;

  final List<String> _emojiOptions = [
    '📊', '📈', '💊', '🩺', '🌡️', '💉', '🩹', '🧪',
    '🦴', '🦷', '👂', '👃', '🫁', '🫀', '🧠', '💪',
    '🤮', '💩', '🍽️', '😷', '🤧', '🐾', '🦵', '😊', '😴',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.metric.name);
    _descriptionController = TextEditingController(text: widget.metric.description ?? '');
    _selectedEmoji = widget.metric.emoji ?? '📊';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 拖动指示器
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.stone300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Edit Metric',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Emoji 选择
              Text('Icon', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _emojiOptions.map((emoji) {
                  final isSelected = emoji == _selectedEmoji;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedEmoji = emoji),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected ? widget.theme.primary.withOpacity(0.1) : AppColors.stone100,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected ? Border.all(color: widget.theme.primary, width: 2) : null,
                      ),
                      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // 名称输入
              Text('Name', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Metric name',
                  filled: true,
                  fillColor: AppColors.stone50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),

              // 描述输入
              Text('Description', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Optional description',
                  filled: true,
                  fillColor: AppColors.stone50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 8),
              
              // 类型提示（不可更改）
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.stone50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppColors.stone500),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Value type (${_getTypeLabel()}) cannot be changed',
                        style: TextStyle(fontSize: 12, color: AppColors.stone500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 保存按钮
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.theme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTypeLabel() {
    switch (widget.metric.valueType) {
      case MetricValueType.range:
        return '1-5 Rating';
      case MetricValueType.number:
        return 'Number';
      case MetricValueType.boolean:
        return 'Yes/No';
      case MetricValueType.text:
        return 'Text';
      default:
        return 'Unknown';
    }
  }

  Future<void> _saveChanges() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final success = await ref.read(wellnessScoreNotifierProvider.notifier).updateCustomMetric(
        metricId: widget.metric.id,
        name: name,
        description: _descriptionController.text.trim(),
        emoji: _selectedEmoji,
      );

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$_selectedEmoji $name updated!'), backgroundColor: AppColors.green500),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

/// Custom Metric 历史记录弹窗
class _CustomMetricHistorySheet extends ConsumerWidget {
  final CareMetric metric;
  final PetTheme theme;

  const _CustomMetricHistorySheet({
    required this.metric,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(customMetricHistoryProvider(metric.id));

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 拖动指示器
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.stone300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 标题
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(metric.emoji ?? '📊', style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${metric.name} History',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (metric.description?.isNotEmpty == true)
                        Text(
                          metric.description!,
                          style: TextStyle(color: AppColors.stone500, fontSize: 13),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 历史列表
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Failed to load')),
              data: (history) {
                if (history.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 48, color: AppColors.stone300),
                        const SizedBox(height: 16),
                        Text(
                          'No records yet',
                          style: TextStyle(color: AppColors.stone500),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: history.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final log = history[index];
                    final isToday = DateFormat('yyyy-MM-dd').format(log.loggedAt) ==
                        DateFormat('yyyy-MM-dd').format(DateTime.now());
                    final hasAttachment = (log.notes?.isNotEmpty ?? false) ||
                        (log.imageUrls?.isNotEmpty ?? false);

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: _buildValueBadge(log),
                      title: Text(
                        isToday ? 'Today' : DateFormat('EEEE, MMM d').format(log.loggedAt),
                        style: TextStyle(
                          fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        DateFormat('h:mm a').format(log.loggedAt),
                        style: TextStyle(color: AppColors.stone500, fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasAttachment)
                            Icon(Icons.attachment, color: AppColors.stone400, size: 18),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right, color: AppColors.stone300, size: 20),
                        ],
                      ),
                      onTap: () => showLogDetailSheet(
                        context,
                        log: log,
                        theme: theme,
                        metricName: metric.name,
                        emoji: metric.emoji,
                        maxScore: metric.valueType == MetricValueType.range ? 5 : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueBadge(MetricLog log) {
    switch (metric.valueType) {
      case MetricValueType.range:
        final score = log.rangeValue ?? 0;
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _getScoreColor(score).withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              '$score',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _getScoreColor(score),
              ),
            ),
          ),
        );
      case MetricValueType.number:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.blue100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${log.numberValue ?? 0}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.blue600,
            ),
          ),
        );
      case MetricValueType.boolean:
        final value = log.boolValue ?? false;
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: value ? AppColors.green100 : AppColors.red100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Icon(
              value ? Icons.check : Icons.close,
              color: value ? AppColors.green600 : AppColors.red600,
            ),
          ),
        );
      case MetricValueType.text:
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.purple100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Icon(
              Icons.description,
              color: AppColors.purple600,
            ),
          ),
        );
      case MetricValueType.image:
        // 如果有图片，显示缩略图
        if (log.imageUrls?.isNotEmpty == true) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              log.imageUrls!.first,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.blue100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.photo, color: AppColors.blue600),
              ),
            ),
          );
        }
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.blue100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Icon(Icons.photo, color: AppColors.blue600),
          ),
        );
      case MetricValueType.video:
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.red100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Icon(Icons.videocam, color: AppColors.red600),
          ),
        );
      default:
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.stone100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(metric.emoji ?? '📊', style: const TextStyle(fontSize: 20)),
          ),
        );
    }
  }

  Color _getScoreColor(int score) {
    if (score == 1) return AppColors.red500;
    if (score == 2) return AppColors.orange500;
    if (score == 3) return AppColors.amber500;
    if (score == 4) return AppColors.lime500;
    return AppColors.green500;
  }
}
