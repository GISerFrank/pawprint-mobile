import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/pet_theme.dart';
import '../../../../../core/models/models.dart';
import '../../../../../core/providers/wellness_provider.dart';
import 'log_detail_sheet.dart';

/// 图片类型指标卡片（Eye/Ear Condition）
class ImageMetricCard extends ConsumerWidget {
  final String petId;
  final PetTheme theme;
  final String metricId; // e.g., 'eye_condition' or 'ear_condition'
  final String name;
  final String emoji;
  final String description;
  final MetricCategory metricCategory;

  const ImageMetricCard({
    super.key,
    required this.petId,
    required this.theme,
    required this.metricId,
    required this.name,
    required this.emoji,
    required this.description,
    required this.metricCategory,
  });

  String get _fullMetricId => '${petId}_wellness_$metricId';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(imageMetricHistoryProvider(_fullMetricId));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showLogSheet(context, ref),
          onLongPress: () => _showHistorySheet(context, ref),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 图标、标题和状态
                Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.stone800,
                        ),
                      ),
                    ),
                    // 状态指示
                    historyAsync.when(
                      loading: () => const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (_, __) => _buildAddLabel(context),
                      data: (history) {
                        if (history.isEmpty) return _buildAddLabel(context);
                        // 显示最近一次记录的缩略图
                        final latest = history.first;
                        if (latest.imageUrls?.isNotEmpty == true) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              latest.imageUrls!.first,
                              width: 28,
                              height: 28,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildPhotoIcon(),
                            ),
                          );
                        }
                        return _buildPhotoIcon();
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 6),
                
                // 描述或最近记录时间
                historyAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.stone500,
                      fontSize: 11,
                    ),
                  ),
                  data: (history) {
                    if (history.isEmpty) {
                      return Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.stone500,
                          fontSize: 11,
                        ),
                      );
                    }
                    final latest = history.first;
                    final isToday = DateFormat('yyyy-MM-dd').format(latest.loggedAt) ==
                        DateFormat('yyyy-MM-dd').format(DateTime.now());
                    return Text(
                      isToday ? 'Updated today' : DateFormat('MMM d').format(latest.loggedAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isToday ? AppColors.green500 : AppColors.stone500,
                        fontWeight: isToday ? FontWeight.w500 : FontWeight.normal,
                        fontSize: 11,
                      ),
                    );
                  },
                ),
                
                const Spacer(),
                
                // 最近记录缩略图行
                historyAsync.when(
                  loading: () => const SizedBox(height: 20),
                  error: (_, __) => const SizedBox(height: 20),
                  data: (history) {
                    if (history.isEmpty) {
                      return const SizedBox(height: 20);
                    }
                    // 显示最近几次记录的小缩略图
                    final recentWithImages = history
                        .where((log) => log.imageUrls?.isNotEmpty == true)
                        .take(4)
                        .toList();
                    if (recentWithImages.isEmpty) {
                      return const SizedBox(height: 20);
                    }
                    return SizedBox(
                      height: 20,
                      child: Row(
                        children: [
                          ...recentWithImages.take(3).map((log) => Container(
                            width: 20,
                            height: 20,
                            margin: const EdgeInsets.only(right: 4),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                log.imageUrls!.first,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: AppColors.stone200,
                                  child: Icon(Icons.photo, size: 12, color: AppColors.stone400),
                                ),
                              ),
                            ),
                          )),
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
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddLabel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.stone100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Add',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.stone500,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPhotoIcon() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: theme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        Icons.photo_camera,
        size: 16,
        color: theme.primary,
      ),
    );
  }

  void _showLogSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ImageMetricLogSheet(
        petId: petId,
        metricId: _fullMetricId,
        name: name,
        emoji: emoji,
        description: description,
        theme: theme,
        metricCategory: metricCategory,
      ),
    );
  }

  void _showHistorySheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ImageMetricHistorySheet(
        petId: petId,
        metricId: _fullMetricId,
        name: name,
        emoji: emoji,
        theme: theme,
      ),
    );
  }
}

/// 图片指标记录弹窗
class _ImageMetricLogSheet extends ConsumerStatefulWidget {
  final String petId;
  final String metricId;
  final String name;
  final String emoji;
  final String description;
  final PetTheme theme;
  final MetricCategory metricCategory;

  const _ImageMetricLogSheet({
    required this.petId,
    required this.metricId,
    required this.name,
    required this.emoji,
    required this.description,
    required this.theme,
    required this.metricCategory,
  });

  @override
  ConsumerState<_ImageMetricLogSheet> createState() => _ImageMetricLogSheetState();
}

class _ImageMetricLogSheetState extends ConsumerState<_ImageMetricLogSheet> {
  final List<String> _imageUrls = [];
  final _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
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
                  Text(widget.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.description,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.stone500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 检查提示
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: widget.theme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.theme.primary.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 16,
                          color: widget.theme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'What to check',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: widget.theme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: widget.metricCategory.hints.map((hint) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            hint,
                            style: TextStyle(fontSize: 12, color: AppColors.stone600),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 拍照区域
              Text(
                'Take a Photo',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              
              if (_imageUrls.isEmpty)
                GestureDetector(
                  onTap: _showImageSourcePicker,
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
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: _showImageSourcePicker,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
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
                  ],
                ),
              const SizedBox(height: 20),

              // 备注
              Text(
                'Notes (optional)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Any observations...',
                  hintStyle: TextStyle(color: AppColors.stone400),
                  filled: true,
                  fillColor: AppColors.stone50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
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

  void _showImageSourcePicker() {
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

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);
    
    if (image != null) {
      setState(() {
        _imageUrls.clear();
        _imageUrls.add(image.path);
      });
    }
  }

  Future<void> _saveLog() async {
    if (_imageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please take a photo first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final success = await ref.read(wellnessScoreNotifierProvider.notifier).saveImageMetricLog(
        petId: widget.petId,
        metricId: widget.metricId,
        imageUrls: _imageUrls,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (success && mounted) {
        ref.invalidate(imageMetricHistoryProvider(widget.metricId));
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.emoji} ${widget.name} logged!'),
            backgroundColor: AppColors.green500,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

/// 图片指标历史记录弹窗
class _ImageMetricHistorySheet extends ConsumerWidget {
  final String petId;
  final String metricId;
  final String name;
  final String emoji;
  final PetTheme theme;

  const _ImageMetricHistorySheet({
    required this.petId,
    required this.metricId,
    required this.name,
    required this.emoji,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(imageMetricHistoryProvider(metricId));

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
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
                Text(emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$name History',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Photo records over time',
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

          // 照片网格
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
                        Icon(Icons.photo_library_outlined, size: 48, color: AppColors.stone300),
                        const SizedBox(height: 16),
                        Text(
                          'No photos yet',
                          style: TextStyle(color: AppColors.stone500),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final log = history[index];
                    final hasImage = log.imageUrls?.isNotEmpty == true;
                    final isToday = DateFormat('yyyy-MM-dd').format(log.loggedAt) ==
                        DateFormat('yyyy-MM-dd').format(DateTime.now());

                    return GestureDetector(
                      onTap: () => showLogDetailSheet(
                        context,
                        log: log,
                        theme: theme,
                        metricName: name,
                        emoji: emoji,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (hasImage)
                              Image.network(
                                log.imageUrls!.first,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: AppColors.stone200,
                                  child: Icon(Icons.broken_image, color: AppColors.stone400),
                                ),
                              )
                            else
                              Container(
                                color: AppColors.stone200,
                                child: Icon(Icons.photo, color: AppColors.stone400),
                              ),
                            // 日期标签
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.6),
                                    ],
                                  ),
                                ),
                                child: Text(
                                  isToday ? 'Today' : DateFormat('M/d').format(log.loggedAt),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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
}
