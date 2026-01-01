/// Wellness 类别的预置指标
/// 
/// 包含：体重、BCS、MCS、眼部状况、耳部状况

import '../models.dart';
import 'base_metrics.dart';

/// Wellness 指标模板
class WellnessMetrics {
  /// 所有 Wellness 预设指标（5个）
  static List<MetricTemplate> get all => [
    weight,
    bcs,
    mcs,
    eyeCondition,
    earCondition,
  ];

  /// 体重
  static const weight = MetricTemplate(
    id: 'wellness_weight',
    category: CareCategory.wellness,
    name: 'Weight',
    nameZh: '体重',
    description: 'Regular weight tracking to monitor trends',
    descriptionZh: '定期称重，记录变化趋势',
    emoji: '⚖️',
    frequency: MetricFrequency.weekly,
    valueType: MetricValueType.number,
    unit: 'kg',
    priority: 1,
    isPinned: true,
  );

  /// BCS 体况评分 (1-9)
  static const bcs = MetricTemplate(
    id: 'wellness_bcs',
    category: CareCategory.wellness,
    name: 'Body Condition Score',
    nameZh: '体况评分 (BCS)',
    description: 'Assess body fat level by feeling ribs and observing waist',
    descriptionZh: '用手摸肋骨，从上方看腰线，评估体脂水平',
    emoji: '🏋️',
    frequency: MetricFrequency.weekly,
    valueType: MetricValueType.range,
    minValue: 1,
    maxValue: 9,
    targetValue: 5, // 理想分数
    priority: 2,
    isPinned: true,
    requiresAIImage: true,
    aiImageType: 'bcs',
  );

  /// MCS 肌肉评分 (0-3)
  static const mcs = MetricTemplate(
    id: 'wellness_mcs',
    category: CareCategory.wellness,
    name: 'Muscle Condition Score',
    nameZh: '肌肉评分 (MCS)',
    description: 'Assess muscle mass over spine, skull, shoulders and hips',
    descriptionZh: '评估脊椎、头骨、肩部和臀部的肌肉量',
    emoji: '💪',
    frequency: MetricFrequency.weekly,
    valueType: MetricValueType.range,
    minValue: 0,
    maxValue: 3,
    targetValue: 3, // 正常肌肉量
    priority: 3,
    isPinned: true,
    requiresAIImage: true,
    aiImageType: 'mcs',
  );

  /// 眼部状况 - 图片记录
  static const eyeCondition = MetricTemplate(
    id: 'wellness_eye_condition',
    category: CareCategory.wellness,
    metricCategory: MetricCategory.eyes,
    name: 'Eye Condition',
    nameZh: '眼部状况',
    description: 'Take a photo to track eye clarity, discharge, and tear stains',
    descriptionZh: '拍照记录眼睛清澈度、分泌物、泪痕',
    emoji: '👁️',
    frequency: MetricFrequency.weekly,
    valueType: MetricValueType.image,
    priority: 4,
    isPinned: true,
  );

  /// 耳部状况 - 图片记录
  static const earCondition = MetricTemplate(
    id: 'wellness_ear_condition',
    category: CareCategory.wellness,
    metricCategory: MetricCategory.ears,
    name: 'Ear Condition',
    nameZh: '耳部状况',
    description: 'Take a photo to track ear cleanliness, odor signs, and discharge',
    descriptionZh: '拍照记录耳朵清洁度、异味迹象、分泌物',
    emoji: '👂',
    frequency: MetricFrequency.weekly,
    valueType: MetricValueType.image,
    priority: 5,
    isPinned: true,
  );
}

/// 获取指标的评分等级描述
class WellnessScoreLevels {
  /// 获取 BCS 评分等级（根据宠物种类）
  static List<ScoreLevel> getBCSLevels(PetSpecies species) {
    switch (species) {
      case PetSpecies.cat:
        return BCSLevels.cat;
      case PetSpecies.dog:
        return BCSLevels.dog;
      default:
        return BCSLevels.cat; // 默认使用猫的标准
    }
  }

  /// 获取 MCS 评分等级
  static List<ScoreLevel> getMCSLevels() {
    return MCSLevels.standard;
  }
}
