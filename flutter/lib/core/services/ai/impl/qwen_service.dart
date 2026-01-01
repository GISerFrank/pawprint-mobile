import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../config/app_config.dart';
import '../../../models/models.dart';
import '../ai_service.dart';
import '../ai_types.dart';

/// 阿里云通义千问 API 服务实现
/// 文档: https://help.aliyun.com/zh/dashscope/developer-reference/api-details
class QwenService extends BaseAIService {
  final String _apiKey;

  // API 端点
  static const String _textUrl =
      'https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation';
  static const String _visionUrl =
      'https://dashscope.aliyuncs.com/api/v1/services/aigc/multimodal-generation/generation';

  // 模型名称
  static const String _textModel = 'qwen-plus';
  static const String _visionModel = 'qwen-vl-plus';
  static const String _imageEditModel = 'qwen-image-edit-plus';
  static const String _imageGenModel = 'qwen-image-plus';

  QwenService() : _apiKey = AppConfig.qwenApiKey {
    if (_apiKey.isEmpty) {
      throw Exception('Qwen API key not configured');
    }
  }

  @override
  String get providerName => 'Qwen';

  @override
  bool get isAvailable => _apiKey.isNotEmpty;

  /// 发送文本请求
  Future<String> _sendTextRequest(String prompt, {String? systemPrompt}) async {
    final messages = <Map<String, dynamic>>[];

    if (systemPrompt != null) {
      messages.add({
        'role': 'system',
        'content': systemPrompt,
      });
    }

    messages.add({
      'role': 'user',
      'content': prompt,
    });

    final response = await http.post(
      Uri.parse(_textUrl),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _textModel,
        'input': {
          'messages': messages,
        },
        'parameters': {
          'temperature': 0.4,
          'max_tokens': 8000, // 增加 token 限制以支持长 JSON 输出
        },
      }),
    );

    if (response.statusCode != 200) {
      print('Qwen API error response: ${response.body}');
      throw Exception(
          'Qwen API error: ${response.statusCode} - ${response.body}');
    }

    final jsonResponse = jsonDecode(response.body);
    final text = jsonResponse['output']?['text'] ?? '';

    // 检查是否因为 token 限制被截断
    final finishReason = jsonResponse['output']?['finish_reason'];
    if (finishReason == 'length') {
      print('Warning: Qwen response was truncated due to max_tokens limit');
    }

    return text;
  }

  /// 发送视觉请求（带图片）
  Future<String> _sendVisionRequest(String prompt, String imageBase64,
      {String? systemPrompt}) async {
    final imageData = extractBase64Data(imageBase64);

    final messages = <Map<String, dynamic>>[];

    if (systemPrompt != null) {
      messages.add({
        'role': 'system',
        'content': [
          {'text': systemPrompt},
        ],
      });
    }

    messages.add({
      'role': 'user',
      'content': [
        {
          'image': 'data:image/jpeg;base64,$imageData',
        },
        {
          'text': prompt,
        },
      ],
    });

    final response = await http.post(
      Uri.parse(_visionUrl),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _visionModel,
        'input': {
          'messages': messages,
        },
        'parameters': {
          'temperature': 0.4,
          'max_tokens': 2000,
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Qwen Vision API error: ${response.statusCode} - ${response.body}');
    }

    final jsonResponse = jsonDecode(response.body);
    final content =
        jsonResponse['output']['choices']?[0]?['message']?['content'];
    if (content is List && content.isNotEmpty) {
      return content[0]['text'] ?? '';
    }
    return jsonResponse['output']['text'] ?? '';
  }

  @override
  Future<String> analyzePetHealth({
    required String symptoms,
    required BodyPart bodyPart,
    String? currentImageBase64,
    String? baselineImageBase64,
  }) async {
    final prompt =
        'Analyze the health of a pet\'s ${bodyPart.displayName}.\n\nSymptoms described: $symptoms';

    if (currentImageBase64 != null) {
      return _sendVisionRequest(prompt, currentImageBase64,
          systemPrompt: healthAnalysisSystemPrompt);
    } else {
      return _sendTextRequest(
          '$prompt\n\n(No image provided, please analyze based on text description only.)',
          systemPrompt: healthAnalysisSystemPrompt);
    }
  }

  @override
  Future<PetPersonality> generatePetPersonality({
    required String imageBase64,
  }) async {
    try {
      final prompt = '''
Analyze this pet's appearance and generate a fun, whimsical personality profile.

Return your response in the following JSON format only, with no additional text:
{
  "tags": ["tag1", "tag2", "tag3"],
  "description": "A short, 1-sentence whimsical description of this pet's vibe."
}

The tags should be 3 short, fun personality adjectives (e.g. 'Sassy', 'Cuddly', 'Speedster').
''';

      final response = await _sendVisionRequest(prompt, imageBase64);
      final jsonStr = extractJson(response);
      final json = jsonDecode(jsonStr);

      return PetPersonality(
        tags: List<String>.from(json['tags'] ?? ['Mystery', 'Cute', 'Unknown']),
        description: json['description'] ?? 'A mysterious and lovely friend.',
      );
    } catch (e) {
      print('Error generating personality with Qwen: $e');
      return PetPersonality.empty();
    }
  }

  @override
  Future<List<GeneratedMetricData>> generateInitialCareMetrics({
    required PetInfoForMetrics petInfo,
  }) async {
    try {
      final prompt = getCareMetricsPrompt(petInfo);
      print('Qwen: Sending care metrics request...');
      final response = await _sendTextRequest(prompt);
      print('Qwen: Raw response length: ${response.length}');
      print(
          'Qwen: Raw response (first 500 chars): ${response.substring(0, response.length > 500 ? 500 : response.length)}');

      final jsonStr = extractJsonArray(response);
      print('Qwen: Extracted JSON length: ${jsonStr.length}');

      final List<dynamic> jsonList = jsonDecode(jsonStr);
      print('Qwen: Parsed ${jsonList.length} metrics');

      return jsonList
          .map((item) =>
              GeneratedMetricData.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      print('Error generating care metrics with Qwen: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<String?> generateCartoonAvatar({
    required String imageBase64,
    required IDCardStyle style,
  }) async {
    try {
      final styleDesc = getStyleDescription(style);
      final prompt = '''
Transform this pet photo into a $styleDesc cartoon avatar.
Keep the pet's unique features recognizable but stylize them artistically.
The background should be simple and clean.
Output a high-quality image suitable for a profile picture.
''';

      return await _generateImage(prompt, referenceImageBase64: imageBase64);
    } catch (e) {
      print('Error generating cartoon avatar with Qwen: $e');
      return null;
    }
  }

  @override
  Future<GeneratedCardData?> generateCollectibleCard({
    required String imageBase64,
    required PackTheme theme,
    required String species,
  }) async {
    try {
      final themeDesc = getThemeDescription(theme);
      // 1. 生成卡牌元数据
      final metadataPrompt = '''
Based on this $species pet image, create collectible card metadata for a "${theme.displayName}" themed card.

Return ONLY a valid JSON object:
{
  "name": "Creative card name (2-4 words)",
  "description": "Poetic 1-2 sentence description",
  "rarity": "common|uncommon|rare|epic|legendary",
  "tags": ["tag1", "tag2", "tag3"]
}

Theme: $themeDesc
''';

      final metadataResponse =
          await _sendVisionRequest(metadataPrompt, imageBase64);
      final metadataJson = jsonDecode(extractJson(metadataResponse));

      // 2. 生成卡牌图片
      final imagePrompt = '''
Create a collectible trading card artwork featuring this $species pet.
Theme: ${theme.displayName} - $themeDesc
Card name: ${metadataJson['name']}

Style: High-quality digital art, dynamic pose, theme-appropriate elements, rich colors.
''';

      final cardImageUrl =
          await _generateImage(imagePrompt, referenceImageBase64: imageBase64);

      if (cardImageUrl == null) return null;

      return GeneratedCardData(
        name: metadataJson['name'] ?? 'Mystery Card',
        description:
            metadataJson['description'] ?? 'A mysterious collectible card.',
        rarity: parseRarity(metadataJson['rarity']),
        tags: List<String>.from(metadataJson['tags'] ?? ['Mystery']),
        imageBase64: cardImageUrl,
      );
    } catch (e) {
      print('Error generating collectible card with Qwen: $e');
      return null;
    }
  }

  /// 使用 Qwen-Image 生成图片
  Future<String?> _generateImage(String prompt,
      {String? referenceImageBase64}) async {
    try {
      final content = <Map<String, dynamic>>[];

      // 如果有参考图片，使用图像编辑模型
      if (referenceImageBase64 != null) {
        final imageData = extractBase64Data(referenceImageBase64);
        content.add({
          'image': 'data:image/jpeg;base64,$imageData',
        });
      }

      content.add({
        'text': prompt,
      });

      final response = await http.post(
        Uri.parse(_visionUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model':
              referenceImageBase64 != null ? _imageEditModel : _imageGenModel,
          'input': {
            'messages': [
              {
                'role': 'user',
                'content': content,
              }
            ],
          },
          'parameters': {
            'n': 1,
            'size': '1024*1024',
          },
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Qwen Image API error: ${response.statusCode} - ${response.body}');
      }

      final jsonResponse = jsonDecode(response.body);

      // 解析返回的图片 URL
      final output = jsonResponse['output'];
      if (output != null) {
        final choices = output['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final message = choices[0]['message'];
          final messageContent = message['content'] as List<dynamic>?;
          if (messageContent != null) {
            for (final item in messageContent) {
              if (item['image'] != null) {
                return item['image'] as String;
              }
            }
          }
        }
      }

      return null;
    } catch (e) {
      print('Error generating image with Qwen: $e');
      return null;
    }
  }

  @override
  Future<String?> generateBodyScoreImage({
    required String petImageBase64,
    required String referenceImageBase64,
    required String prompt,
  }) async {
    try {
      // 解析图片数据和 mimeType
      final petImage = _parseImageData(petImageBase64);
      final refImage = _parseImageData(referenceImageBase64);

      print('🔵 Qwen generateBodyScoreImage:');
      print(
          '   - Pet image mimeType: ${petImage.mimeType}, data length: ${petImage.data.length}');
      print(
          '   - Ref image mimeType: ${refImage.mimeType}, data length: ${refImage.data.length}');
      print('   - Model: $_imageEditModel');
      print('   - URL: $_visionUrl');

      // Qwen 使用图像编辑模型处理多图输入
      final response = await http.post(
        Uri.parse(_visionUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _imageEditModel,
          'input': {
            'messages': [
              {
                'role': 'user',
                'content': [
                  {
                    'image':
                        'data:${refImage.mimeType};base64,${refImage.data}',
                  },
                  {
                    'image':
                        'data:${petImage.mimeType};base64,${petImage.data}',
                  },
                  {
                    'text': prompt,
                  },
                ],
              }
            ],
          },
          'parameters': {
            'n': 1,
            'size': '1024*1024',
          },
        }),
      );

      print('🔵 Qwen response status: ${response.statusCode}');
      print(
          '🔵 Qwen response body: ${response.body.substring(0, response.body.length.clamp(0, 500))}...');

      if (response.statusCode != 200) {
        print(
            '🔴 Qwen body score image generation failed: ${response.statusCode}');
        print('🔴 Response: ${response.body}');
        return null;
      }

      final jsonResponse = jsonDecode(response.body);

      // 解析返回的图片 URL
      final output = jsonResponse['output'];
      if (output != null) {
        final choices = output['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final message = choices[0]['message'];
          final messageContent = message['content'] as List<dynamic>?;
          if (messageContent != null) {
            for (final item in messageContent) {
              if (item['image'] != null) {
                final imageResult = item['image'] as String;
                print('🟢 Qwen returned image, length: ${imageResult.length}');
                return imageResult;
              }
            }
          }
        }
      }

      print('🔴 No image found in Qwen response');
      print('🔴 Full response: $jsonResponse');
      return null;
    } catch (e) {
      print('🔴 Error generating body score image with Qwen: $e');
      return null;
    }
  }

  /// 解析 base64 图片数据，提取 mimeType 和纯数据
  ({String mimeType, String data}) _parseImageData(String imageString) {
    if (imageString.startsWith('data:')) {
      final parts = imageString.split(',');
      if (parts.length == 2) {
        final mimeMatch = RegExp(r'data:([^;]+)').firstMatch(parts[0]);
        final mimeType = mimeMatch?.group(1) ?? 'image/jpeg';
        return (mimeType: mimeType, data: parts[1]);
      }
    }
    return (mimeType: 'image/jpeg', data: imageString);
  }
}
