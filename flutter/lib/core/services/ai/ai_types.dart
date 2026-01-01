/// AI 服务相关的类型定义

// 从 models 导入共享的枚举类型
import '../../models/enums.dart';
export '../../models/enums.dart' show IDCardStyle, Rarity, PackTheme;

/// 宠物性格描述
class PetPersonality {
  final List<String> tags;
  final String description;

  const PetPersonality({
    required this.tags,
    required this.description,
  });

  factory PetPersonality.empty() => const PetPersonality(
        tags: ['Mystery', 'Cute', 'Unknown'],
        description: 'A mysterious and lovely friend.',
      );
}

/// AI 生成的卡牌数据
class GeneratedCardData {
  final String name;
  final String description;
  final Rarity rarity;
  final List<String> tags;
  final String imageBase64; // 可能是 base64 或 URL

  const GeneratedCardData({
    required this.name,
    required this.description,
    required this.rarity,
    required this.tags,
    required this.imageBase64,
  });
}

/// 用于 AI 生成护理指标的宠物信息
class PetInfoForMetrics {
  final String petId;
  final String name;
  final String species;
  final String? breed;
  final int? ageMonths;
  final double? weightKg;
  final String gender;
  final bool isNeutered;
  final List<String>? allergies;

  const PetInfoForMetrics({
    required this.petId,
    required this.name,
    required this.species,
    this.breed,
    this.ageMonths,
    this.weightKg,
    required this.gender,
    required this.isNeutered,
    this.allergies,
  });

  /// 转换为适合 AI prompt 的上下文
  Map<String, dynamic> toPromptContext() {
    String ageDescription = 'Unknown age';
    if (ageMonths != null) {
      if (ageMonths! < 12) {
        ageDescription = '$ageMonths months old (young/puppy/kitten)';
      } else {
        final years = ageMonths! ~/ 12;
        final months = ageMonths! % 12;
        if (years >= 7) {
          ageDescription = '$years years old (senior)';
        } else {
          ageDescription = months > 0
              ? '$years years and $months months old (adult)'
              : '$years years old (adult)';
        }
      }
    }

    return {
      'name': name,
      'species': species,
      'breed': breed ?? 'Unknown breed',
      'age': ageDescription,
      'weight_kg': weightKg ?? 'Unknown',
      'gender': gender,
      'is_neutered': isNeutered ? 'Yes' : 'No',
      'allergies':
          allergies?.isNotEmpty == true ? allergies!.join(', ') : 'None known',
    };
  }
}

/// AI 生成的单个护理指标数据
class GeneratedMetricData {
  final String category;
  final String name;
  final String description;
  final String emoji;
  final String frequency;
  final String valueType;
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
    required this.description,
    required this.emoji,
    required this.frequency,
    required this.valueType,
    this.unit,
    this.targetValue,
    this.minValue,
    this.maxValue,
    this.options,
    this.isPinned = false,
    this.priority = 3,
    this.aiReason,
  });

  factory GeneratedMetricData.fromJson(Map<String, dynamic> json) {
    return GeneratedMetricData(
      category: json['category'] as String? ?? 'wellness',
      name: json['name'] as String? ?? 'Unknown Metric',
      description: json['description'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '📊',
      frequency: json['frequency'] as String? ?? 'daily',
      valueType: json['value_type'] as String? ?? 'boolean',
      unit: json['unit'] as String?,
      targetValue: (json['target_value'] as num?)?.toDouble(),
      minValue: (json['min_value'] as num?)?.toDouble(),
      maxValue: (json['max_value'] as num?)?.toDouble(),
      options: (json['options'] as List<dynamic>?)?.cast<String>(),
      isPinned: json['is_pinned'] as bool? ?? false,
      priority: json['priority'] as int? ?? 3,
      aiReason: json['ai_reason'] as String?,
    );
  }
}

/// AI 健康分析请求参数
class HealthAnalysisRequest {
  final String symptoms;
  final String bodyPart;
  final String? currentImageBase64;
  final String? baselineImageBase64;

  const HealthAnalysisRequest({
    required this.symptoms,
    required this.bodyPart,
    this.currentImageBase64,
    this.baselineImageBase64,
  });
}
