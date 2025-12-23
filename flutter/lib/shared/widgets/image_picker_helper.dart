import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../core/theme/app_theme.dart';
import 'draggable_bottom_sheet.dart';

/// 图片选择结果
class ImagePickResult {
  final Uint8List bytes;
  final String? path;

  const ImagePickResult({
    required this.bytes,
    this.path,
  });
}

/// 图片选择工具类
class ImagePickerHelper {
  static final _picker = ImagePicker();

  /// 从相册选择图片
  static Future<ImagePickResult?> pickFromGallery({
    int maxWidth = 800,
    int quality = 70,
  }) async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: maxWidth.toDouble(),
    );

    if (file == null) return null;

    final bytes = await _compressImage(
      await file.readAsBytes(),
      quality: quality,
    );

    return ImagePickResult(bytes: bytes, path: file.path);
  }

  /// 从相机拍照
  static Future<ImagePickResult?> pickFromCamera({
    int maxWidth = 800,
    int quality = 70,
  }) async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: maxWidth.toDouble(),
    );

    if (file == null) return null;

    final bytes = await _compressImage(
      await file.readAsBytes(),
      quality: quality,
    );

    return ImagePickResult(bytes: bytes, path: file.path);
  }

  /// 显示选择对话框
  static Future<ImagePickResult?> showPicker(BuildContext context, {
    int maxWidth = 800,
    int quality = 70,
  }) async {
    final source = await showDraggableBottomSheet<ImageSource>(
      context: context,
      initialChildSize: 0.3,
      minChildSize: 0.2,
      maxChildSize: 0.4,
      child: const _ImageSourcePickerContent(),
    );

    if (source == null) return null;

    final XFile? file = await _picker.pickImage(
      source: source,
      maxWidth: maxWidth.toDouble(),
    );

    if (file == null) return null;

    final bytes = await _compressImage(
      await file.readAsBytes(),
      quality: quality,
    );

    return ImagePickResult(bytes: bytes, path: file.path);
  }

  static Future<Uint8List> _compressImage(
    Uint8List bytes, {
    int quality = 70,
  }) async {
    final result = await FlutterImageCompress.compressWithList(
      bytes,
      quality: quality,
      format: CompressFormat.jpeg,
    );
    return result;
  }
}

class _ImageSourcePickerContent extends StatelessWidget {
  const _ImageSourcePickerContent();
  
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Choose Photo',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _SourceOption(
                icon: Icons.camera_alt,
                label: 'Camera',
                color: AppColors.primary500,
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ),
            Expanded(
              child: _SourceOption(
                icon: Icons.photo_library,
                label: 'Gallery',
                color: AppColors.peach500,
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SourceOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}

/// 图片上传占位组件
class ImageUploadPlaceholder extends StatelessWidget {
  final Uint8List? imageBytes;
  final String? imageUrl;
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final double? size;

  const ImageUploadPlaceholder({
    super.key,
    this.imageBytes,
    this.imageUrl,
    required this.label,
    required this.onTap,
    this.onRemove,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageBytes != null || (imageUrl != null && imageUrl!.isNotEmpty);

    return GestureDetector(
      onTap: hasImage ? null : onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hasImage ? AppColors.primary300 : AppColors.stone200,
              width: 2,
              style: hasImage ? BorderStyle.solid : BorderStyle.none,
            ),
            color: hasImage ? AppColors.primary50 : AppColors.stone50,
          ),
          child: hasImage
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: imageBytes != null
                          ? Image.memory(
                              imageBytes!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            )
                          : Image.network(
                              imageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                    ),
                    if (onRemove != null)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: onRemove,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: AppColors.primary600,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.stone500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
