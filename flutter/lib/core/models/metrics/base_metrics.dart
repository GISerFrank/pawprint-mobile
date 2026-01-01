/// 预置指标的基础定义
/// 
/// 这些指标是固定的、标准化的健康追踪指标，
/// 不再由 AI 动态生成，而是预先定义好模板。

import '../models.dart';

/// 预置指标模板
class MetricTemplate {
  final String id;
  final CareCategory category;
  final MetricCategory? metricCategory; // 9大身体部位/系统分类
  final String name;
  final String nameZh; // 中文名
  final String description;
  final String descriptionZh; // 中文描述
  final String emoji;
  final MetricFrequency frequency;
  final MetricValueType valueType;
  final String? unit;
  final double? targetValue;
  final double? minValue;
  final double? maxValue;
  final List<String>? options;
  final int priority;
  final bool isPinned;
  
  /// 是否需要 AI 生成参考图
  final bool requiresAIImage;
  
  /// AI 图片类型（如 'bcs', 'mcs'）
  final String? aiImageType;

  const MetricTemplate({
    required this.id,
    required this.category,
    this.metricCategory,
    required this.name,
    required this.nameZh,
    required this.description,
    required this.descriptionZh,
    required this.emoji,
    required this.frequency,
    required this.valueType,
    this.unit,
    this.targetValue,
    this.minValue,
    this.maxValue,
    this.options,
    this.priority = 5,
    this.isPinned = false,
    this.requiresAIImage = false,
    this.aiImageType,
  });

  /// 转换为 CareMetric
  CareMetric toMetric(String petId) {
    final now = DateTime.now();
    return CareMetric(
      id: '${petId}_${id}',
      petId: petId,
      category: category,
      source: MetricSource.aiBase,
      name: name,
      description: description,
      emoji: emoji,
      frequency: frequency,
      valueType: valueType,
      unit: unit,
      targetValue: targetValue,
      minValue: minValue,
      maxValue: maxValue,
      options: options,
      isEnabled: true,
      isPinned: isPinned,
      priority: priority,
      metricCategory: metricCategory,
      createdAt: now,
      updatedAt: now,
    );
  }
}

/// 评分等级描述
class ScoreLevel {
  final int score;
  final String label;
  final String labelZh;
  final String description;
  final String descriptionZh;
  final String? imagePrompt; // 用于 AI 生成图片的 prompt

  const ScoreLevel({
    required this.score,
    required this.label,
    required this.labelZh,
    required this.description,
    required this.descriptionZh,
    this.imagePrompt,
  });
}

/// 1-5 分通用评分等级
class RatingScaleLevels {
  static const List<ScoreLevel> standard = [
    ScoreLevel(
      score: 1,
      label: 'Very Poor',
      labelZh: '很差',
      description: 'Severe issues, needs immediate attention',
      descriptionZh: '严重异常，需立即关注',
    ),
    ScoreLevel(
      score: 2,
      label: 'Poor',
      labelZh: '较差',
      description: 'Notable issues present',
      descriptionZh: '明显异常',
    ),
    ScoreLevel(
      score: 3,
      label: 'Fair',
      labelZh: '一般',
      description: 'Some minor issues',
      descriptionZh: '轻微异常',
    ),
    ScoreLevel(
      score: 4,
      label: 'Good',
      labelZh: '良好',
      description: 'Mostly normal with minor concerns',
      descriptionZh: '基本正常',
    ),
    ScoreLevel(
      score: 5,
      label: 'Excellent',
      labelZh: '优秀',
      description: 'Completely healthy and normal',
      descriptionZh: '完全健康正常',
    ),
  ];
}

/// BCS (Body Condition Score) 评分等级 - 9分制
class BCSLevels {
  static const List<ScoreLevel> cat = [
    ScoreLevel(
      score: 1,
      label: 'Emaciated',
      labelZh: '极度消瘦',
      description: 'Ribs, spine, and hip bones easily visible. No body fat. Severe muscle wasting.',
      descriptionZh: '肋骨、脊椎和髋骨清晰可见，无体脂肪，严重肌肉萎缩。',
      imagePrompt: 'extremely thin cat, visible ribs and spine, no body fat, severe muscle loss',
    ),
    ScoreLevel(
      score: 2,
      label: 'Very Thin',
      labelZh: '非常瘦',
      description: 'Ribs, spine easily visible. Minimal fat. Obvious waist.',
      descriptionZh: '肋骨、脊椎容易看到，脂肪极少，腰部明显。',
      imagePrompt: 'very thin cat, ribs and spine visible, minimal body fat, pronounced waist',
    ),
    ScoreLevel(
      score: 3,
      label: 'Thin',
      labelZh: '偏瘦',
      description: 'Ribs easily felt with minimal fat. Obvious waist from above.',
      descriptionZh: '肋骨容易摸到但有少量脂肪覆盖，从上方看腰部明显。',
      imagePrompt: 'thin cat, ribs easily palpable, slight fat cover, visible waist from above',
    ),
    ScoreLevel(
      score: 4,
      label: 'Underweight',
      labelZh: '体重不足',
      description: 'Ribs felt with slight fat cover. Waist visible from above.',
      descriptionZh: '肋骨可摸到，有薄层脂肪覆盖，从上方可见腰部曲线。',
      imagePrompt: 'slightly underweight cat, ribs palpable with thin fat layer, waist visible',
    ),
    ScoreLevel(
      score: 5,
      label: 'Ideal',
      labelZh: '理想体态',
      description: 'Ribs felt without excess fat. Waist visible from above. Abdominal tuck.',
      descriptionZh: '肋骨可摸到无多余脂肪，从上方可见腰部，腹部收紧。',
      imagePrompt: 'ideal weight cat, well-proportioned, visible waist, healthy body condition',
    ),
    ScoreLevel(
      score: 6,
      label: 'Overweight',
      labelZh: '超重',
      description: 'Ribs felt with slight excess fat. Waist barely visible.',
      descriptionZh: '肋骨可摸到但有稍多脂肪覆盖，腰部勉强可见。',
      imagePrompt: 'slightly overweight cat, ribs palpable with some fat, waist barely visible',
    ),
    ScoreLevel(
      score: 7,
      label: 'Heavy',
      labelZh: '偏胖',
      description: 'Ribs difficult to feel. Fat deposits visible. No waist.',
      descriptionZh: '肋骨难以摸到，有明显脂肪堆积，看不到腰部曲线。',
      imagePrompt: 'overweight cat, ribs hard to feel, noticeable fat deposits, no visible waist',
    ),
    ScoreLevel(
      score: 8,
      label: 'Obese',
      labelZh: '肥胖',
      description: 'Ribs not felt under heavy fat. Obvious fat deposits. Distended abdomen.',
      descriptionZh: '厚重脂肪下摸不到肋骨，明显脂肪堆积，腹部膨胀。',
      imagePrompt: 'obese cat, ribs not palpable, heavy fat deposits, distended belly',
    ),
    ScoreLevel(
      score: 9,
      label: 'Severely Obese',
      labelZh: '严重肥胖',
      description: 'Massive fat deposits. Severely distended abdomen. Fat deposits on limbs.',
      descriptionZh: '大量脂肪堆积，腹部严重膨胀，四肢也有脂肪堆积。',
      imagePrompt: 'severely obese cat, massive fat deposits, very distended abdomen, fat on limbs',
    ),
  ];

  static const List<ScoreLevel> dog = [
    ScoreLevel(
      score: 1,
      label: 'Emaciated',
      labelZh: '极度消瘦',
      description: 'Ribs, spine, hip bones prominent. No body fat. Severe muscle wasting.',
      descriptionZh: '肋骨、脊椎和髋骨突出，无体脂肪，严重肌肉萎缩。',
      imagePrompt: 'extremely thin dog, prominent ribs spine and hip bones, no body fat',
    ),
    ScoreLevel(
      score: 2,
      label: 'Very Thin',
      labelZh: '非常瘦',
      description: 'Ribs, spine easily visible. Minimal fat. Obvious waist and tuck.',
      descriptionZh: '肋骨、脊椎容易看到，脂肪极少，腰部和腹部收紧明显。',
      imagePrompt: 'very thin dog, visible ribs and spine, minimal fat, obvious waist',
    ),
    ScoreLevel(
      score: 3,
      label: 'Thin',
      labelZh: '偏瘦',
      description: 'Ribs easily felt, may be visible. Obvious waist. Abdominal tuck evident.',
      descriptionZh: '肋骨容易摸到可能可见，腰部明显，腹部收紧明显。',
      imagePrompt: 'thin dog, ribs easily palpable, clear waist, evident abdominal tuck',
    ),
    ScoreLevel(
      score: 4,
      label: 'Underweight',
      labelZh: '体重不足',
      description: 'Ribs easily felt with minimal fat. Waist easily noted. Abdominal tuck evident.',
      descriptionZh: '肋骨容易摸到有少量脂肪，腰部容易看到，腹部收紧明显。',
      imagePrompt: 'slightly underweight dog, ribs palpable with minimal fat, visible waist',
    ),
    ScoreLevel(
      score: 5,
      label: 'Ideal',
      labelZh: '理想体态',
      description: 'Ribs felt without excess fat. Waist observed. Abdominal tuck present.',
      descriptionZh: '肋骨可摸到无多余脂肪，可观察到腰部，腹部收紧。',
      imagePrompt: 'ideal weight dog, well-proportioned body, visible waist, healthy condition',
    ),
    ScoreLevel(
      score: 6,
      label: 'Overweight',
      labelZh: '超重',
      description: 'Ribs felt with slight excess fat. Waist visible from above but not prominent.',
      descriptionZh: '肋骨可摸到但有稍多脂肪，从上方可见腰部但不明显。',
      imagePrompt: 'slightly overweight dog, ribs palpable with fat, waist less visible',
    ),
    ScoreLevel(
      score: 7,
      label: 'Heavy',
      labelZh: '偏胖',
      description: 'Ribs difficult to feel. Fat deposits over back and tail base. Waist absent.',
      descriptionZh: '肋骨难以摸到，背部和尾根有脂肪堆积，看不到腰部。',
      imagePrompt: 'overweight dog, ribs hard to feel, fat deposits on back, no waist',
    ),
    ScoreLevel(
      score: 8,
      label: 'Obese',
      labelZh: '肥胖',
      description: 'Ribs not felt. Heavy fat over back, spine, tail base. No waist. Abdominal distension.',
      descriptionZh: '摸不到肋骨，背部脊椎尾根脂肪厚重，无腰部，腹部膨胀。',
      imagePrompt: 'obese dog, ribs not palpable, heavy fat deposits, distended abdomen',
    ),
    ScoreLevel(
      score: 9,
      label: 'Severely Obese',
      labelZh: '严重肥胖',
      description: 'Massive fat deposits. Severely distended abdomen. Fat on neck and limbs.',
      descriptionZh: '大量脂肪堆积，腹部严重膨胀，颈部和四肢也有脂肪。',
      imagePrompt: 'severely obese dog, massive fat everywhere, very distended abdomen',
    ),
  ];
}

/// MCS (Muscle Condition Score) 评分等级 - 4分制 (0-3)
class MCSLevels {
  static const List<ScoreLevel> standard = [
    ScoreLevel(
      score: 0,
      label: 'Severe Muscle Wasting',
      labelZh: '严重肌肉萎缩',
      description: 'Severe loss of muscle mass over spine, skull, shoulders, and hips.',
      descriptionZh: '脊椎、头骨、肩部和臀部严重肌肉流失。',
      imagePrompt: 'pet with severe muscle wasting, prominent bones visible at spine skull shoulders hips',
    ),
    ScoreLevel(
      score: 1,
      label: 'Moderate Muscle Wasting',
      labelZh: '中度肌肉萎缩',
      description: 'Moderate loss of muscle mass over spine, skull, shoulders, and hips.',
      descriptionZh: '脊椎、头骨、肩部和臀部中度肌肉流失。',
      imagePrompt: 'pet with moderate muscle wasting, bones somewhat visible at spine and hips',
    ),
    ScoreLevel(
      score: 2,
      label: 'Mild Muscle Wasting',
      labelZh: '轻度肌肉萎缩',
      description: 'Mild loss of muscle mass over spine, skull, shoulders, and hips.',
      descriptionZh: '脊椎、头骨、肩部和臀部轻度肌肉流失。',
      imagePrompt: 'pet with mild muscle wasting, slight bone prominence at spine',
    ),
    ScoreLevel(
      score: 3,
      label: 'Normal Muscle Mass',
      labelZh: '正常肌肉量',
      description: 'Normal muscle mass over spine, skull, shoulders, and hips.',
      descriptionZh: '脊椎、头骨、肩部和臀部肌肉量正常。',
      imagePrompt: 'pet with normal healthy muscle mass, well-muscled body',
    ),
  ];
}