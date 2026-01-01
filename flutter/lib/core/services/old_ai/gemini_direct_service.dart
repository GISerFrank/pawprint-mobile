import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/models.dart';
import 'gemini_service.dart';

/// 直接调用 Gemini API 的服务（用于本地开发）
/// 模型配置与 React 项目保持一致：
/// - 文本/分析: gemini-2.5-flash
/// - 图片生成: gemini-2.0-flash-preview-image-generation (通过 HTTP 调用)
class GeminiDirectService {
  late final GenerativeModel _textModel;
  final String _apiKey;

  static const String _imageModelName = 'gemini-3-pro-image-preview';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  static const String _systemInstruction = '''
You are PetGuard AI, a compassionate and knowledgeable veterinary assistant AI. 
Your goal is to help pet owners understand their pet's health based on provided details and images.

Guidance:
1. Analyze the provided image (if any) specifically looking for signs of inflammation, infection, injury, or parasites related to the specified body part.
2. Correlate visual findings with the described symptoms.
3. Provide a structured response:
   - **Observation**: What you see in the image and understand from the text.
   - **Potential Causes**: List 2-3 possible reasons (e.g., allergies, infection, trauma).
   - **Recommendation**: Immediate home care steps (if safe) and when to see a vet (e.g., "Monitor for 24h" vs "Emergency").
4. **Tone**: Calm, professional, but empathetic.
5. **Disclaimer**: ALWAYS end with: "Disclaimer: I am an AI, not a veterinarian. This analysis is for informational purposes only and does not replace professional veterinary advice."
''';

  GeminiDirectService() : _apiKey = AppConfig.geminiApiKey {
    if (_apiKey.isEmpty) {
      throw Exception('Gemini API key not configured');
    }

    // 文本模型 - 用于健康分析和性格生成
    _textModel = GenerativeModel(
      model: 'gemini-2.5-flash-preview-09-2025',
      apiKey: _apiKey,
      systemInstruction: Content.system(_systemInstruction),
      generationConfig: GenerationConfig(
        temperature: 0.4,
        maxOutputTokens: 1000,
      ),
    );
  }

  /// 从 base64 字符串中提取纯数据部分
  String _extractBase64Data(String base64String) {
    if (base64String.contains(',')) {
      return base64String.split(',').last;
    }
    return base64String;
  }

  /// 分析宠物健康状况
  Future<String> analyzePetHealth({
    required String symptoms,
    required BodyPart bodyPart,
    String? currentImageBase64,
    String? baselineImageBase64,
  }) async {
    try {
      final List<Part> parts = [];

      // 构建提示文本
      String promptText =
          'Analyze the health of a pet\'s ${bodyPart.displayName}.\n\nSymptoms described: $symptoms';

      if (baselineImageBase64 != null) {
        promptText +=
            '\n\nI have provided two images. The first image is the BASELINE (healthy) image from their profile. The second image is the CURRENT condition. Please compare them if possible to identify changes.';

        // 添加基线图片
        final baselineData = _extractBase64Data(baselineImageBase64);
        parts.add(DataPart('image/jpeg', base64Decode(baselineData)));
      }

      if (currentImageBase64 != null) {
        // 添加当前图片
        final currentData = _extractBase64Data(currentImageBase64);
        parts.add(DataPart('image/jpeg', base64Decode(currentData)));
      } else {
        promptText +=
            '\n\n(No current image provided, please analyze based on text description only.)';
      }

      parts.add(TextPart(promptText));

      final response = await _textModel.generateContent([Content.multi(parts)]);

      return response.text ??
          'Sorry, I could not generate an analysis at this time.';
    } catch (e) {
      return 'An error occurred while communicating with the AI. Please try again later.\n\nError: $e';
    }
  }

  /// 生成宠物性格描述
  Future<PetPersonality> generatePetPersonality({
    required String imageBase64,
  }) async {
    try {
      final imageData = _extractBase64Data(imageBase64);

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
          DataPart('image/jpeg', base64Decode(imageData)),
          TextPart(prompt),
        ])
      ]);

      final text = response.text;
      if (text == null) throw Exception('No response');

      // 解析 JSON 响应
      final jsonStr = _extractJson(text);
      final json = jsonDecode(jsonStr);

      return PetPersonality(
        tags: List<String>.from(json['tags'] ?? ['Mystery', 'Cute', 'Unknown']),
        description: json['description'] ?? 'A mysterious and lovely friend.',
      );
    } catch (e) {
      print('Error generating personality: $e');
      return const PetPersonality(
        tags: ['Mystery', 'Cute', 'Unknown'],
        description: 'A mysterious and lovely friend.',
      );
    }
  }

  /// 通过 HTTP 直接调用图片生成 API
  Future<String?> _generateImageViaHttp({
    required String imageBase64,
    required String prompt,
  }) async {
    try {
      final imageData = _extractBase64Data(imageBase64);

      final url = '$_baseUrl/$_imageModelName:generateContent?key=$_apiKey';

      final requestBody = {
        'contents': [
          {
            'parts': [
              {
                'inlineData': {
                  'mimeType': 'image/jpeg',
                  'data': imageData,
                }
              },
              {
                'text': prompt,
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 1.0,
          'maxOutputTokens': 8192,
        }
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        print(
            'Image generation HTTP error: ${response.statusCode} - ${response.body}');
        return null;
      }

      final jsonResponse = jsonDecode(response.body);

      // 解析响应获取生成的图片
      final candidates = jsonResponse['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        print('No candidates in response');
        return null;
      }

      final content = candidates[0]['content'];
      final parts = content['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        print('No parts in response');
        return null;
      }

      // 查找 inlineData 部分
      for (final part in parts) {
        if (part['inlineData'] != null) {
          final inlineData = part['inlineData'];
          final mimeType = inlineData['mimeType'] ?? 'image/png';
          final data = inlineData['data'];
          return 'data:$mimeType;base64,$data';
        }
      }

      // 如果没有图片，可能返回了文本（错误信息）
      for (final part in parts) {
        if (part['text'] != null) {
          print('API returned text instead of image: ${part['text']}');
        }
      }

      return null;
    } catch (e) {
      print('Error in _generateImageViaHttp: $e');
      return null;
    }
  }

  /// 生成卡通头像
  Future<String?> generateCartoonAvatar({
    required String imageBase64,
    required IDCardStyle style,
  }) async {
    try {
      String stylePrompt;
      switch (style) {
        case IDCardStyle.cool:
          stylePrompt =
              'cyberpunk character, cool neon lighting, sunglasses, bold vector art';
          break;
        case IDCardStyle.pixel:
          stylePrompt =
              'pixel art character, 8-bit retro game style, blocky, vibrant colors';
          break;
        case IDCardStyle.cute:
        default:
          stylePrompt =
              'adorable disney pixar style 3d character, soft lighting, cute big eyes';
          break;
      }

      final prompt =
          'Turn this image into a $stylePrompt. Maintain the fur color and breed characteristics. High quality, solid background.';

      return await _generateImageViaHttp(
        imageBase64: imageBase64,
        prompt: prompt,
      );
    } catch (e) {
      print('Error generating cartoon avatar: $e');
      return null;
    }
  }

  /// 生成收藏卡牌
  Future<GeneratedCardData?> generateCollectibleCard({
    required String imageBase64,
    required PackTheme theme,
    required String species,
  }) async {
    try {
      // 1. 生成卡牌元数据
      final metadata = await _generateCardMetadata(theme, species);

      // 2. 生成卡牌图片
      final cardImage = await _generateCardImage(imageBase64, theme, species);

      if (cardImage == null) {
        print('Failed to generate card image');
        return null;
      }

      return GeneratedCardData(
        name: metadata['name'] ?? '${theme.displayName} Card',
        description:
            metadata['description'] ?? 'A special card for your collection.',
        rarity: Rarity.fromString(metadata['rarity'] ?? 'Common'),
        tags: List<String>.from(metadata['tags'] ?? []),
        imageBase64: cardImage,
      );
    } catch (e) {
      print('Error generating collectible card: $e');
      return null;
    }
  }

  /// 生成卡牌元数据
  Future<Map<String, dynamic>> _generateCardMetadata(
      PackTheme theme, String species) async {
    try {
      final prompt = '''
Generate a creative collectible card metadata for a $species in a "${theme.displayName}" theme.

Themes:
- Daily: Slice of life, cozy.
- Profile: Heroic, best angle.
- Fun: Silly, costumes, playing.
- Sticker: Pop art, bold outlines.

Return your response in the following JSON format only, with no additional text:
{
  "name": "Creative card title",
  "description": "Fun flavor text",
  "rarity": "Common|Rare|Epic|Legendary",
  "tags": ["tag1", "tag2"]
}
''';

      final response = await _textModel.generateContent([Content.text(prompt)]);
      final text = response.text;

      if (text == null) throw Exception('No response');

      final jsonStr = _extractJson(text);
      return jsonDecode(jsonStr);
    } catch (e) {
      print('Error generating card metadata: $e');
      return {
        'name': '${theme.displayName} Card',
        'description': 'A special card for your collection.',
        'rarity': 'Common',
        'tags': [theme.displayName.toLowerCase()],
      };
    }
  }

  /// 生成卡牌图片
  Future<String?> _generateCardImage(
      String imageBase64, PackTheme theme, String species) async {
    try {
      String artPrompt;
      switch (theme) {
        case PackTheme.daily:
          artPrompt =
              'Turn this image into a cute illustration of the $species in a cozy, daily life setting (e.g. sleeping on a cloud, eating). Soft pastel colors, heartwarming style.';
          break;
        case PackTheme.fun:
          artPrompt =
              'Turn this image into a funny cartoon of the $species doing something silly (e.g. wearing a hat, playing). Vibrant colors, joyful expression.';
          break;
        case PackTheme.sticker:
          artPrompt =
              'Turn this image into a pop-art sticker design of the $species. Bold thick white outline, bright flat colors, simple background.';
          break;
        case PackTheme.profile:
        default:
          artPrompt =
              'Turn this image into an epic, heroic portrait of the $species. Cinematic lighting, detailed digital art, majestic pose.';
          break;
      }

      return await _generateImageViaHttp(
        imageBase64: imageBase64,
        prompt: artPrompt,
      );
    } catch (e) {
      print('Error generating card image: $e');
      return null;
    }
  }

  /// 从文本中提取 JSON
  String _extractJson(String text) {
    // 尝试找到 JSON 对象
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
    if (jsonMatch != null) {
      return jsonMatch.group(0)!;
    }
    throw Exception('No JSON found in response');
  }
}

/// 生成的卡牌数据（本地模式用）
class GeneratedCardData {
  final String name;
  final String description;
  final Rarity rarity;
  final List<String> tags;
  final String imageBase64;

  const GeneratedCardData({
    required this.name,
    required this.description,
    required this.rarity,
    required this.tags,
    required this.imageBase64,
  });
}

/// 宠物信息输入（用于 AI 生成指标）
class PetInfoForMetrics {
  final String petId;
  final String name;
  final String species;
  final String breed;
  final int? ageMonths;
  final double weightKg;
  final String gender;
  final bool isNeutered;
  final String? allergies;

  const PetInfoForMetrics({
    required this.petId,
    required this.name,
    required this.species,
    required this.breed,
    this.ageMonths,
    required this.weightKg,
    required this.gender,
    required this.isNeutered,
    this.allergies,
  });

  Map<String, dynamic> toPromptContext() {
    String ageDescription = 'unknown age';
    if (ageMonths != null) {
      if (ageMonths! < 12) {
        ageDescription = '$ageMonths months old (young/puppy/kitten)';
      } else if (ageMonths! < 84) {
        ageDescription = '${ageMonths! ~/ 12} years old (adult)';
      } else {
        ageDescription = '${ageMonths! ~/ 12} years old (senior)';
      }
    }

    return {
      'name': name,
      'species': species,
      'breed': breed,
      'age': ageDescription,
      'weight_kg': weightKg,
      'gender': gender,
      'is_neutered': isNeutered,
      'allergies': allergies ?? 'none known',
    };
  }
}

/// AI 生成的单个指标数据
class GeneratedMetricData {
  final String category; // wellness, nutrition, enrichment, care
  final String name;
  final String? description;
  final String? emoji;
  final String frequency; // daily, twiceDaily, threeTimesDaily, weekly, twiceWeekly, monthly, asNeeded
  final String valueType; // boolean, number, range, selection, text
  final String? unit;
  final double? targetValue;
  final double? minValue;
  final double? maxValue;
  final List<String>? options;
  final bool isPinned;
  final int priority;
  final String? aiReason;

  const GeneratedMetricData({
    required this.category,
    required this.name,
    this.description,
    this.emoji,
    required this.frequency,
    required this.valueType,
    this.unit,
    this.targetValue,
    this.minValue,
    this.maxValue,
    this.options,
    this.isPinned = false,
    this.priority = 0,
    this.aiReason,
  });

  factory GeneratedMetricData.fromJson(Map<String, dynamic> json) {
    return GeneratedMetricData(
      category: json['category'] as String? ?? 'wellness',
      name: json['name'] as String? ?? 'Unknown Metric',
      description: json['description'] as String?,
      emoji: json['emoji'] as String?,
      frequency: json['frequency'] as String? ?? 'daily',
      valueType: json['value_type'] as String? ?? 'boolean',
      unit: json['unit'] as String?,
      targetValue: (json['target_value'] as num?)?.toDouble(),
      minValue: (json['min_value'] as num?)?.toDouble(),
      maxValue: (json['max_value'] as num?)?.toDouble(),
      options: (json['options'] as List<dynamic>?)?.cast<String>(),
      isPinned: json['is_pinned'] as bool? ?? false,
      priority: json['priority'] as int? ?? 0,
      aiReason: json['ai_reason'] as String?,
    );
  }
}

/// GeminiDirectService 扩展方法
extension GeminiDirectServiceMetrics on GeminiDirectService {
  /// 根据宠物信息生成个性化的护理指标
  Future<List<GeneratedMetricData>> generateInitialCareMetrics({
    required PetInfoForMetrics petInfo,
  }) async {
    try {
      final context = petInfo.toPromptContext();
      
      final prompt = '''
You are a veterinary care expert. Based on the following pet information, generate a personalized set of care metrics/tasks for tracking this pet's health and wellness.

Pet Information:
- Name: ${context['name']}
- Species: ${context['species']}
- Breed: ${context['breed']}
- Age: ${context['age']}
- Weight: ${context['weight_kg']} kg
- Gender: ${context['gender']}
- Neutered/Spayed: ${context['is_neutered']}
- Known Allergies: ${context['allergies']}

Generate a comprehensive list of 12-18 care metrics across 4 categories:
1. **wellness** - Health monitoring (weight tracking, mood, energy levels, symptoms)
2. **nutrition** - Diet and hydration (meals, water intake, treats, supplements)
3. **enrichment** - Activity and mental stimulation (exercise, play, training, socialization)
4. **care** - Grooming and maintenance (brushing, bathing, nail trimming, dental care)

For each metric, consider:
- The pet's species-specific needs
- Age-appropriate care (puppies/kittens need different care than seniors)
- Breed-specific considerations
- Weight-based calculations (e.g., water intake = ~50-60ml per kg body weight)
- Any allergies that might affect recommendations

Return ONLY a valid JSON array with no additional text, using this exact structure:
[
  {
    "category": "wellness|nutrition|enrichment|care",
    "name": "Short metric name",
    "description": "Helpful description",
    "emoji": "Single relevant emoji",
    "frequency": "daily|twiceDaily|threeTimesDaily|weekly|twiceWeekly|monthly|asNeeded",
    "value_type": "boolean|number|range|selection|text",
    "unit": "kg|ml|min|hours|null for boolean/range",
    "target_value": null or number (for number type),
    "min_value": null or 1 (for range type, usually 1),
    "max_value": null or 5 (for range type, usually 5),
    "options": null or ["option1", "option2"] (for selection type),
    "is_pinned": true/false (mark 3-5 most important as pinned),
    "priority": 1-5 (1=highest priority within category),
    "ai_reason": "Brief explanation why this metric is important for this specific pet"
  }
]

Important guidelines:
- Calculate specific target values based on the pet's weight (e.g., daily water intake in ml)
- Adjust exercise duration based on breed and age
- Include senior-specific metrics for older pets (joint health, cognitive function)
- Include puppy/kitten-specific metrics for young pets (growth tracking, socialization)
- For boolean type: no unit, target_value, min_value, max_value needed
- For number type: include unit and target_value
- For range type: set min_value=1, max_value=5
- Ensure each category has 3-5 metrics
- Make ai_reason personalized to THIS specific pet
''';

      final response = await _textModel.generateContent([Content.text(prompt)]);
      final text = response.text;

      if (text == null) {
        throw Exception('No response from AI');
      }

      // 提取 JSON 数组
      final jsonStr = _extractJsonArray(text);
      final List<dynamic> jsonList = jsonDecode(jsonStr);

      return jsonList
          .map((item) => GeneratedMetricData.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error generating care metrics: $e');
      rethrow;
    }
  }

  /// 从文本中提取 JSON 数组
  String _extractJsonArray(String text) {
    // 尝试找到 JSON 数组
    final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(text);
    if (jsonMatch != null) {
      return jsonMatch.group(0)!;
    }
    throw Exception('No JSON array found in response');
  }
}
