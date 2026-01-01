import 'dart:convert';
import 'package:flutter/services.dart';

import '../models/models.dart';
import 'ai/ai_service.dart';

/// BCS/MCS 参考图生成服务
///
/// 负责：
/// 1. 加载原始 BCS/MCS 参考图
/// 2. 调用 AI 将参考图中的动物替换为用户的宠物
/// 3. 管理生成图片的缓存和存储
class BodyScoreImageService {
  final AIService _aiService;

  BodyScoreImageService(this._aiService);

  /// BCS 评分数量
  static const int bcsScoreCount = 9;

  /// MCS 评分数量
  static const int mcsScoreCount = 4;

  /// 生成宠物专属的 BCS 参考图
  ///
  /// [petImageBase64] 用户宠物的照片
  /// [species] 宠物种类（用于选择对应的参考图）
  /// [score] 要生成的 BCS 分数 (1-9)
  ///
  /// 返回生成的图片 base64 或 URL
  Future<String?> generateBCSImage({
    required String petImageBase64,
    required PetSpecies species,
    required int score,
  }) async {
    if (score < 1 || score > 9) {
      throw ArgumentError('BCS score must be between 1 and 9');
    }

    try {
      // 加载对应种类的 BCS 参考图
      final referenceImageBase64 = await _loadBCSReferenceImage(species);

      // 获取该分数的描述
      final scoreDescription = _getBCSDescription(species, score);
      final speciesName = species == PetSpecies.cat ? 'cat' : 'dog';

      // 构建 AI prompt
      final prompt = '''
You are an expert pet illustrator. I'm providing two images:
1. A reference chart showing different body condition scores for ${speciesName}s
2. A photo of my pet $speciesName

Your task: Create an illustration of MY PET at Body Condition Score $score.

BCS $score characteristics:
$scoreDescription

Instructions:
- Study my pet's unique features: fur color, pattern, face shape, ear shape, eye color
- Draw my pet in the same pose and style as shown in the BCS $score reference (both side view and top view)
- Keep the illustration style consistent with veterinary educational materials
- The result should help me visualize what MY specific pet would look like at BCS $score
- Include both a side profile view and a top-down view

Important: The output should look like my pet, not a generic $speciesName.
''';

      // 调用 AI 生成图片
      final result = await _aiService.generateBodyScoreImage(
        petImageBase64: petImageBase64,
        referenceImageBase64: referenceImageBase64,
        prompt: prompt,
      );

      return result;
    } catch (e) {
      print('Error generating BCS image: $e');
      return null;
    }
  }

  /// 生成宠物专属的 MCS 参考图
  ///
  /// [petImageBase64] 用户宠物的照片
  /// [species] 宠物种类
  /// [score] 要生成的 MCS 分数 (0-3)
  Future<String?> generateMCSImage({
    required String petImageBase64,
    required PetSpecies species,
    required int score,
  }) async {
    if (score < 0 || score > 3) {
      throw ArgumentError('MCS score must be between 0 and 3');
    }

    try {
      // 加载 MCS 参考图
      final referenceImageBase64 = await _loadMCSReferenceImage();

      // 获取该分数的描述
      final scoreDescription = _getMCSDescription(score);
      final speciesName = species == PetSpecies.cat ? 'cat' : 'dog';

      final prompt = '''
You are an expert pet illustrator. I'm providing two images:
1. A reference chart showing different muscle condition scores
2. A photo of my pet $speciesName

Your task: Create an illustration of MY PET at Muscle Condition Score $score.

MCS $score characteristics:
$scoreDescription

Instructions:
- Study my pet's unique features: fur color, pattern, face shape, ear shape
- Draw my pet showing the muscle condition at score $score
- Show the key areas: spine, shoulders, hips with appropriate muscle mass
- Keep the illustration style consistent with veterinary educational materials
- Include visual indicators showing muscle mass at spine, shoulders, and hips

Important: The output should look like my pet, not a generic $speciesName.
''';

      final result = await _aiService.generateBodyScoreImage(
        petImageBase64: petImageBase64,
        referenceImageBase64: referenceImageBase64,
        prompt: prompt,
      );

      return result;
    } catch (e) {
      print('Error generating MCS image: $e');
      return null;
    }
  }

  /// 批量生成所有 BCS 参考图
  ///
  /// 返回 Map<score, imageBase64>
  Future<Map<int, String>> generateAllBCSImages({
    required String petImageBase64,
    required PetSpecies species,
    void Function(int completed, int total)? onProgress,
  }) async {
    final results = <int, String>{};

    for (int score = 1; score <= bcsScoreCount; score++) {
      onProgress?.call(score - 1, bcsScoreCount);

      final image = await generateBCSImage(
        petImageBase64: petImageBase64,
        species: species,
        score: score,
      );

      if (image != null) {
        results[score] = image;
      }

      // 避免 API 限流，添加延迟
      if (score < bcsScoreCount) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    onProgress?.call(bcsScoreCount, bcsScoreCount);
    return results;
  }

  /// 批量生成所有 MCS 参考图
  Future<Map<int, String>> generateAllMCSImages({
    required String petImageBase64,
    required PetSpecies species,
    void Function(int completed, int total)? onProgress,
  }) async {
    final results = <int, String>{};

    for (int score = 0; score <= 3; score++) {
      onProgress?.call(score, mcsScoreCount);

      final image = await generateMCSImage(
        petImageBase64: petImageBase64,
        species: species,
        score: score,
      );

      if (image != null) {
        results[score] = image;
      }

      if (score < 3) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    onProgress?.call(mcsScoreCount, mcsScoreCount);
    return results;
  }

  /// 加载 BCS 参考图（返回带 mimeType 的 data URI）
  Future<String> _loadBCSReferenceImage(PetSpecies species) async {
    final assetPath = species == PetSpecies.cat
        ? 'assets/images/reference/bcs_cat.png'
        : 'assets/images/reference/bcs_dog.webp';

    try {
      final bytes = await rootBundle.load(assetPath);
      final mimeType = _getMimeType(assetPath);
      return 'data:$mimeType;base64,${base64Encode(bytes.buffer.asUint8List())}';
    } catch (e) {
      // 如果找不到猫的图，使用狗的图作为备用
      final bytes =
          await rootBundle.load('assets/images/reference/bcs_dog.webp');
      return 'data:image/webp;base64,${base64Encode(bytes.buffer.asUint8List())}';
    }
  }

  /// 加载 MCS 参考图（返回带 mimeType 的 data URI）
  Future<String> _loadMCSReferenceImage() async {
    final bytes = await rootBundle.load('assets/images/reference/mcs.png');
    return 'data:image/png;base64,${base64Encode(bytes.buffer.asUint8List())}';
  }

  /// 根据文件扩展名获取 MIME 类型
  String _getMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    return switch (ext) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'image/png',
    };
  }

  /// 获取 BCS 分数描述
  String _getBCSDescription(PetSpecies species, int score) {
    // 猫和狗的描述略有不同，这里使用通用描述
    final descriptions = {
      1: '''
- Ribs, spine and hip bones easily visible
- No palpable fat
- Severe loss of muscle mass
- Extreme waist and abdominal tuck
''',
      2: '''
- Ribs easily visible on shorthaired pets
- Lumbar vertebrae obvious
- Pronounced abdominal tuck
- No palpable fat pads
''',
      3: '''
- Ribs easily felt with minimal fat covering
- Lumbar vertebrae obvious
- Obvious waist behind ribs
- Minimal abdominal fat
''',
      4: '''
- Ribs felt with minimal fat covering
- Noticeable waist behind ribs
- Slight abdominal tuck
- Minimal abdominal fat pads
''',
      5: '''
- Well-proportioned (IDEAL)
- Ribs felt with slight fat covering
- Waist seen behind ribs but not pronounced
- Abdominal fat pad minimal
''',
      6: '''
- Ribs felt with slight excess fat covering
- Waist and abdominal fat pad present but not obvious
- Abdominal tuck may be absent
''',
      7: '''
- Ribs not easily felt through moderate fat covering
- Waist poorly seen
- Slight rounding of abdomen may be present
- Moderate abdominal fat pad
''',
      8: '''
- Ribs not felt due to excess fat covering
- Waist absent
- Obvious rounding of abdomen with prominent fat pad
- Fat deposits present over lower back area
''',
      9: '''
- Ribs not felt under heavy fat cover
- Heavy fat deposits over lumbar area, face, and limbs
- Distention of abdomen with no waist
- Extensive abdominal fat deposits
''',
    };

    return descriptions[score] ?? '';
  }

  /// 获取 MCS 分数描述
  String _getMCSDescription(int score) {
    final descriptions = {
      0: '''
- Severe loss of muscle mass
- Prominent bones visible at spine, skull, shoulders, and hips
- Very little muscle tissue remaining
- Bones feel sharp with no muscle covering
''',
      1: '''
- Moderate loss of muscle mass
- Bones somewhat visible at spine and hips
- Reduced muscle mass over key areas
- Some muscle wasting evident
''',
      2: '''
- Mild loss of muscle mass
- Slight bone prominence at spine
- Minor reduction in muscle mass
- Muscles feel slightly less firm
''',
      3: '''
- Normal muscle mass (IDEAL)
- Well-muscled body
- Good muscle coverage over spine, shoulders, and hips
- Muscles feel firm and well-developed
''',
    };

    return descriptions[score] ?? '';
  }
}
