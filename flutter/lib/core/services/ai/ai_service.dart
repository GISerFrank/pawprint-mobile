import '../../models/models.dart';
import 'ai_types.dart';

export 'ai_types.dart';

/// AI 服务抽象接口
/// 定义所有 AI 服务实现必须提供的功能
abstract class AIService {
  /// 服务提供商名称
  String get providerName;

  /// 检查服务是否可用
  bool get isAvailable;

  /// 分析宠物健康状况
  /// 
  /// [symptoms] 症状描述
  /// [bodyPart] 身体部位
  /// [currentImageBase64] 当前图片（可选）
  /// [baselineImageBase64] 基线图片用于对比（可选）
  Future<String> analyzePetHealth({
    required String symptoms,
    required BodyPart bodyPart,
    String? currentImageBase64,
    String? baselineImageBase64,
  });

  /// 生成宠物性格描述
  /// 
  /// [imageBase64] 宠物图片
  Future<PetPersonality> generatePetPersonality({
    required String imageBase64,
  });

  /// 生成个性化护理指标
  /// 
  /// [petInfo] 宠物信息
  Future<List<GeneratedMetricData>> generateInitialCareMetrics({
    required PetInfoForMetrics petInfo,
  });

  /// 生成卡通头像
  /// 
  /// [imageBase64] 原始宠物图片
  /// [style] 卡通风格
  /// 返回生成的图片 URL 或 base64，失败返回 null
  Future<String?> generateCartoonAvatar({
    required String imageBase64,
    required IDCardStyle style,
  });

  /// 生成收藏卡牌
  /// 
  /// [imageBase64] 宠物图片
  /// [theme] 卡牌主题
  /// [species] 宠物种类
  Future<GeneratedCardData?> generateCollectibleCard({
    required String imageBase64,
    required PackTheme theme,
    required String species,
  });

  /// 生成 BCS/MCS 参考图
  /// 
  /// 将标准参考图中的动物替换为用户的宠物形象
  /// 
  /// [petImageBase64] 用户宠物照片
  /// [referenceImageBase64] 原始参考图
  /// [prompt] 生成指令
  /// 返回生成的图片 base64 或 URL
  Future<String?> generateBodyScoreImage({
    required String petImageBase64,
    required String referenceImageBase64,
    required String prompt,
  });
}

/// AI 服务基类
/// 提供一些通用的辅助方法
abstract class BaseAIService implements AIService {
  /// 从 base64 字符串中提取纯数据部分（去除 data:image/...;base64, 前缀）
  String extractBase64Data(String base64String) {
    if (base64String.contains(',')) {
      return base64String.split(',').last;
    }
    return base64String;
  }

  /// 从文本中提取 JSON 对象
  String extractJson(String text) {
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
    if (jsonMatch != null) {
      return jsonMatch.group(0)!;
    }
    throw Exception('No JSON found in response');
  }

  /// 从文本中提取 JSON 数组
  String extractJsonArray(String text) {
    final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(text);
    if (jsonMatch != null) {
      return jsonMatch.group(0)!;
    }
    throw Exception('No JSON array found in response');
  }

  /// 解析稀有度字符串
  Rarity parseRarity(String? rarity) {
    return switch (rarity?.toLowerCase()) {
      'common' => Rarity.common,
      'uncommon' => Rarity.rare, // models 中没有 uncommon，映射到 rare
      'rare' => Rarity.rare,
      'epic' => Rarity.epic,
      'legendary' => Rarity.legendary,
      _ => Rarity.common,
    };
  }

  /// 获取 ID 卡片风格描述
  String getStyleDescription(IDCardStyle style) {
    return switch (style) {
      IDCardStyle.cute => 'cute chibi anime style with big eyes, soft colors, and adorable expression',
      IDCardStyle.cool => 'cool and stylish illustration with confident pose, sharp lines, and vibrant colors',
      IDCardStyle.pixel => 'retro pixel art style with blocky shapes and nostalgic game aesthetics',
    };
  }

  /// 获取卡包主题描述
  String getThemeDescription(PackTheme theme) {
    return switch (theme) {
      PackTheme.daily => 'Everyday life moments, casual activities, cozy home scenes',
      PackTheme.profile => 'Portrait style, professional headshot, clean background',
      PackTheme.fun => 'Playful and energetic, toys, games, happy moments',
      PackTheme.sticker => 'Cute sticker style, simple shapes, expressive emotions',
    };
  }

  /// 健康分析的系统提示词
  String get healthAnalysisSystemPrompt => '''
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

  /// 生成护理指标的提示词
  String getCareMetricsPrompt(PetInfoForMetrics petInfo) {
    final context = petInfo.toPromptContext();
    return '''
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
  }
}
