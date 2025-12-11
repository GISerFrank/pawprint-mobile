import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Storage 桶名称
class StorageBuckets {
  static const String petAvatars = 'pet-avatars';
  static const String petBodyImages = 'pet-body-images';
  static const String petIdCards = 'pet-id-cards';
  static const String collectibleCards = 'collectible-cards';
  static const String aiAnalysisImages = 'ai-analysis-images';
}

/// Supabase Storage 服务
class StorageService {
  final SupabaseClient _client;

  StorageService(this._client);

  String get _userId => _client.auth.currentUser?.id ?? 'anonymous';

  /// 上传图片到指定桶
  Future<String> uploadImage({
    required String bucket,
    required String fileName,
    required Uint8List fileBytes,
    String? contentType,
  }) async {
    final path = '$_userId/$fileName';
    
    await _client.storage.from(bucket).uploadBinary(
      path,
      fileBytes,
      fileOptions: FileOptions(
        contentType: contentType ?? 'image/jpeg',
        upsert: true,
      ),
    );

    // 返回公开 URL
    final publicUrl = _client.storage.from(bucket).getPublicUrl(path);
    return publicUrl;
  }

  /// 上传宠物头像
  Future<String> uploadPetAvatar({
    required String petId,
    required Uint8List fileBytes,
  }) async {
    return uploadImage(
      bucket: StorageBuckets.petAvatars,
      fileName: '$petId-avatar.jpg',
      fileBytes: fileBytes,
    );
  }

  /// 上传身体部位图片
  Future<String> uploadBodyPartImage({
    required String petId,
    required String bodyPart,
    required Uint8List fileBytes,
  }) async {
    final sanitizedBodyPart = bodyPart.toLowerCase().replaceAll(' ', '-').replaceAll('&', 'and');
    return uploadImage(
      bucket: StorageBuckets.petBodyImages,
      fileName: '$petId-$sanitizedBodyPart.jpg',
      fileBytes: fileBytes,
    );
  }

  /// 上传 AI 生成的 ID 卡片图片
  Future<String> uploadIdCardImage({
    required String petId,
    required Uint8List fileBytes,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return uploadImage(
      bucket: StorageBuckets.petIdCards,
      fileName: '$petId-idcard-$timestamp.png',
      fileBytes: fileBytes,
      contentType: 'image/png',
    );
  }

  /// 上传收藏卡牌图片
  Future<String> uploadCollectibleCardImage({
    required String petId,
    required String cardId,
    required Uint8List fileBytes,
  }) async {
    return uploadImage(
      bucket: StorageBuckets.collectibleCards,
      fileName: '$petId-$cardId.png',
      fileBytes: fileBytes,
      contentType: 'image/png',
    );
  }

  /// 上传 AI 分析时的症状图片
  Future<String> uploadAnalysisImage({
    required String petId,
    required String sessionId,
    required Uint8List fileBytes,
  }) async {
    return uploadImage(
      bucket: StorageBuckets.aiAnalysisImages,
      fileName: '$petId-$sessionId.jpg',
      fileBytes: fileBytes,
    );
  }

  /// 删除文件
  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    await _client.storage.from(bucket).remove([path]);
  }

  /// 从 URL 提取文件路径
  String? extractPathFromUrl(String url, String bucket) {
    final bucketUrl = _client.storage.from(bucket).getPublicUrl('');
    if (url.startsWith(bucketUrl)) {
      return url.substring(bucketUrl.length);
    }
    return null;
  }
}
