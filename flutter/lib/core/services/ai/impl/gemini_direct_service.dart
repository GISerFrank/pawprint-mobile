import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

import '../../../config/app_config.dart';
import '../../../models/models.dart';
import '../ai_service.dart';
import '../ai_types.dart';

/// Gemini 直接 API 调用实现
/// 用于本地开发或不需要服务端代理的场景
class GeminiDirectService extends BaseAIService {
  late final GenerativeModel _textModel;
  final String _apiKey;

  static const String _imageModelName = 'gemini-2.0-flash-exp-image-generation';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  GeminiDirectService() : _apiKey = AppConfig.geminiApiKey {
    if (_apiKey.isEmpty) {
      throw Exception('Gemini API key not configured');
    }

    _textModel = GenerativeModel(
      model: 'gemini-2.5-flash-preview-05-20',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.4,
        maxOutputTokens: 2000,
      ),
    );
  }

  @override
  String get providerName => 'Gemini';

  @override
  bool get isAvailable => _apiKey.isNotEmpty;

  @override
  Future<String> analyzePetHealth({
    required String symptoms,
    required BodyPart bodyPart,
    String? currentImageBase64,
    String? baselineImageBase64,
  }) async {
    final prompt =
        'Analyze the health of a pet\'s ${bodyPart.displayName}.\n\nSymptoms described: $symptoms';

    final content = <Content>[];

    if (currentImageBase64 != null) {
      final imageData = extractBase64Data(currentImageBase64);
      content.add(Content.multi([
        TextPart(healthAnalysisSystemPrompt),
        TextPart(prompt),
        DataPart('image/jpeg', base64Decode(imageData)),
      ]));
    } else {
      content.add(Content.text(
          '$healthAnalysisSystemPrompt\n\n$prompt\n\n(No image provided, please analyze based on text description only.)'));
    }

    final response = await _textModel.generateContent(content);
    return response.text ?? 'Unable to analyze. Please try again.';
  }

  @override
  Future<PetPersonality> generatePetPersonality({
    required String imageBase64,
  }) async {
    try {
      final imageData = extractBase64Data(imageBase64);

      final prompt = '''
Analyze this pet's appearance and generate a fun, whimsical personality profile.

Return your response in the following JSON format only, with no additional text:
{
  "tags": ["tag1", "tag2", "tag3"],
  "description": "A short, 1-sentence whimsical description of this pet's vibe."
}

The tags should be 3 short, fun personality adjectives (e.g. 'Sassy', 'Cuddly', 'Speedster').
''';

      final response = await _textModel.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', base64Decode(imageData)),
        ])
      ]);

      final text = response.text ?? '';
      final jsonStr = extractJson(text);
      final json = jsonDecode(jsonStr);

      return PetPersonality(
        tags: List<String>.from(json['tags'] ?? ['Mystery', 'Cute', 'Unknown']),
        description: json['description'] ?? 'A mysterious and lovely friend.',
      );
    } catch (e) {
      print('Error generating personality with Gemini: $e');
      return PetPersonality.empty();
    }
  }

  @override
  Future<List<GeneratedMetricData>> generateInitialCareMetrics({
    required PetInfoForMetrics petInfo,
  }) async {
    try {
      final prompt = getCareMetricsPrompt(petInfo);
      final response = await _textModel.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      final jsonStr = extractJsonArray(text);
      final List<dynamic> jsonList = jsonDecode(jsonStr);

      return jsonList
          .map((item) =>
              GeneratedMetricData.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error generating care metrics with Gemini: $e');
      rethrow;
    }
  }

  @override
  Future<String?> generateCartoonAvatar({
    required String imageBase64,
    required IDCardStyle style,
  }) async {
    try {
      final imageData = extractBase64Data(imageBase64);
      final styleDesc = getStyleDescription(style);

      final prompt = '''
Transform this pet photo into a $styleDesc cartoon avatar.
Keep the pet's unique features recognizable but stylize them artistically.
The background should be simple and clean.
Output a high-quality image suitable for a profile picture.
''';

      final url = Uri.parse('$_baseUrl/$_imageModelName:generateContent');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': _apiKey,
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
                {
                  'inlineData': {
                    'mimeType': 'image/jpeg',
                    'data': imageData,
                  }
                }
              ]
            }
          ],
          'generationConfig': {
            'responseModalities': ['TEXT', 'IMAGE'],
          },
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Image generation failed: ${response.statusCode}');
      }

      final jsonResponse = jsonDecode(response.body);
      final candidates = jsonResponse['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) return null;

      final parts = candidates[0]['content']['parts'] as List<dynamic>?;
      if (parts == null) return null;

      for (final part in parts) {
        if (part['inlineData'] != null) {
          final mimeType = part['inlineData']['mimeType'] as String;
          final data = part['inlineData']['data'] as String;
          return 'data:$mimeType;base64,$data';
        }
      }

      return null;
    } catch (e) {
      print('Error generating cartoon avatar with Gemini: $e');
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
      final imageData = extractBase64Data(imageBase64);

      // 1. 生成卡牌元数据
      final themeDesc = getThemeDescription(theme);
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

      final metadataResponse = await _textModel.generateContent([
        Content.multi([
          TextPart(metadataPrompt),
          DataPart('image/jpeg', base64Decode(imageData)),
        ])
      ]);

      final metadataText = metadataResponse.text ?? '';
      final metadataJson = jsonDecode(extractJson(metadataText));

      // 2. 生成卡牌图片
      final imagePrompt = '''
Create a collectible trading card artwork featuring this $species pet.
Theme: ${theme.displayName} - $themeDesc
Card name: ${metadataJson['name']}

Style: High-quality digital art, dynamic pose, theme-appropriate elements, rich colors.
''';

      final url = Uri.parse('$_baseUrl/$_imageModelName:generateContent');
      final imageResponse = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': _apiKey,
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': imagePrompt},
                {
                  'inlineData': {
                    'mimeType': 'image/jpeg',
                    'data': imageData,
                  }
                }
              ]
            }
          ],
          'generationConfig': {
            'responseModalities': ['TEXT', 'IMAGE'],
          },
        }),
      );

      if (imageResponse.statusCode != 200) {
        throw Exception('Card image generation failed');
      }

      final jsonResponse = jsonDecode(imageResponse.body);
      String? cardImageBase64;

      final candidates = jsonResponse['candidates'] as List<dynamic>?;
      if (candidates != null && candidates.isNotEmpty) {
        final parts = candidates[0]['content']['parts'] as List<dynamic>?;
        if (parts != null) {
          for (final part in parts) {
            if (part['inlineData'] != null) {
              final mimeType = part['inlineData']['mimeType'] as String;
              final data = part['inlineData']['data'] as String;
              cardImageBase64 = 'data:$mimeType;base64,$data';
              break;
            }
          }
        }
      }

      if (cardImageBase64 == null) return null;

      return GeneratedCardData(
        name: metadataJson['name'] ?? 'Mystery Card',
        description:
            metadataJson['description'] ?? 'A mysterious collectible card.',
        rarity: parseRarity(metadataJson['rarity']),
        tags: List<String>.from(metadataJson['tags'] ?? ['Mystery']),
        imageBase64: cardImageBase64,
      );
    } catch (e) {
      print('Error generating collectible card with Gemini: $e');
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

      final url = Uri.parse('$_baseUrl/$_imageModelName:generateContent');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': _apiKey,
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
                {
                  'inlineData': {
                    'mimeType': refImage.mimeType,
                    'data': refImage.data,
                  }
                },
                {
                  'inlineData': {
                    'mimeType': petImage.mimeType,
                    'data': petImage.data,
                  }
                }
              ]
            }
          ],
          'generationConfig': {
            'responseModalities': ['TEXT', 'IMAGE'],
          },
        }),
      );

      if (response.statusCode != 200) {
        print('Body score image generation failed: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }

      final jsonResponse = jsonDecode(response.body);
      final candidates = jsonResponse['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) return null;

      final parts = candidates[0]['content']['parts'] as List<dynamic>?;
      if (parts == null) return null;

      for (final part in parts) {
        if (part['inlineData'] != null) {
          final mimeType = part['inlineData']['mimeType'] as String;
          final data = part['inlineData']['data'] as String;
          return 'data:$mimeType;base64,$data';
        }
      }

      return null;
    } catch (e) {
      print('Error generating body score image with Gemini: $e');
      return null;
    }
  }

  /// 解析 base64 图片数据，提取 mimeType 和纯数据
  ({String mimeType, String data}) _parseImageData(String imageString) {
    // 格式: data:image/png;base64,xxxxx 或纯 base64
    if (imageString.startsWith('data:')) {
      final parts = imageString.split(',');
      if (parts.length == 2) {
        final mimeMatch = RegExp(r'data:([^;]+)').firstMatch(parts[0]);
        final mimeType = mimeMatch?.group(1) ?? 'image/jpeg';
        return (mimeType: mimeType, data: parts[1]);
      }
    }
    // 纯 base64，默认 jpeg
    return (mimeType: 'image/jpeg', data: imageString);
  }
}