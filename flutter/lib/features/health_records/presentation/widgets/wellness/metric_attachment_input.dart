import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/theme/app_theme.dart';

/// 通用的备注和图片附件输入组件
/// 可用于所有 Metric 记录弹窗
class MetricAttachmentInput extends StatefulWidget {
  final TextEditingController notesController;
  final List<String> imageUrls;
  final ValueChanged<List<String>> onImagesChanged;
  final int maxImages;
  final bool showNotesFirst;

  const MetricAttachmentInput({
    super.key,
    required this.notesController,
    required this.imageUrls,
    required this.onImagesChanged,
    this.maxImages = 4,
    this.showNotesFirst = true,
  });

  @override
  State<MetricAttachmentInput> createState() => _MetricAttachmentInputState();
}

class _MetricAttachmentInputState extends State<MetricAttachmentInput> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    // 如果已有内容则默认展开
    _isExpanded = widget.notesController.text.isNotEmpty || widget.imageUrls.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isExpanded) {
      return _buildCollapsedView();
    }
    return _buildExpandedView();
  }

  Widget _buildCollapsedView() {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.stone50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.stone200),
        ),
        child: Row(
          children: [
            Icon(Icons.add_circle_outline, size: 20, color: AppColors.stone400),
            const SizedBox(width: 8),
            Text(
              'Add notes or photos',
              style: TextStyle(
                color: AppColors.stone500,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, size: 20, color: AppColors.stone400),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 备注输入
        Row(
          children: [
            Icon(Icons.notes, size: 16, color: AppColors.stone500),
            const SizedBox(width: 6),
            Text(
              'Notes',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.stone600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.notesController,
          maxLines: 2,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Add observations...',
            hintStyle: TextStyle(color: AppColors.stone400),
            filled: true,
            fillColor: AppColors.stone50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        const SizedBox(height: 16),

        // 图片添加
        Row(
          children: [
            Icon(Icons.photo_camera, size: 16, color: AppColors.stone500),
            const SizedBox(width: 6),
            Text(
              'Photos',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.stone600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildImageSection(),
      ],
    );
  }

  Widget _buildImageSection() {
    return SizedBox(
      height: 70,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // 已添加的图片
          ...widget.imageUrls.asMap().entries.map((entry) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildImageWidget(entry.value),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: () {
                      final newList = List<String>.from(widget.imageUrls);
                      newList.removeAt(entry.key);
                      widget.onImagesChanged(newList);
                    },
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
            ),
          )),
          // 添加按钮
          if (widget.imageUrls.length < widget.maxImages)
            GestureDetector(
              onTap: _showImagePicker,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppColors.stone100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.stone300),
                ),
                child: Icon(Icons.add_a_photo, color: AppColors.stone400, size: 24),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(String path) {
    // 判断是本地文件还是网络URL
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        width: 70,
        height: 70,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildErrorPlaceholder(),
      );
    } else {
      return Image.file(
        File(path),
        width: 70,
        height: 70,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildErrorPlaceholder(),
      );
    }
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      width: 70,
      height: 70,
      color: AppColors.stone200,
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }

  Future<void> _showImagePicker() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: source, imageQuality: 80);
      
      if (image != null) {
        final newList = List<String>.from(widget.imageUrls);
        newList.add(image.path);
        widget.onImagesChanged(newList);
      }
    }
  }
}

/// 简化版本 - 只显示一行按钮
class MetricAttachmentButton extends StatelessWidget {
  final bool hasNotes;
  final bool hasPhotos;
  final VoidCallback onTap;

  const MetricAttachmentButton({
    super.key,
    required this.hasNotes,
    required this.hasPhotos,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasContent = hasNotes || hasPhotos;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: hasContent ? AppColors.blue50 : AppColors.stone50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasContent ? AppColors.blue200 : AppColors.stone200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasContent ? Icons.attachment : Icons.add,
              size: 16,
              color: hasContent ? AppColors.blue500 : AppColors.stone500,
            ),
            const SizedBox(width: 4),
            Text(
              hasContent ? 'Edit attachment' : 'Add notes/photos',
              style: TextStyle(
                fontSize: 12,
                color: hasContent ? AppColors.blue600 : AppColors.stone600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
