import 'package:flutter/material.dart';
import 'enums.dart';

/// ============================================
/// 护理分类 (通用四大类)
/// ============================================

enum CareCategory {
  wellness('Wellness', '健康状态', Icons.favorite, Color(0xFFEF4444)),
  nutrition('Nutrition', '营养管理', Icons.restaurant, Color(0xFFF97316)),
  enrichment('Enrichment', '生活丰富', Icons.auto_awesome, Color(0xFF3B82F6)),
  care('Care', '护理保健', Icons.medical_services, Color(0xFF10B981));

  final String name;
  final String nameCN;
  final IconData icon;
  final Color color;

  const CareCategory(this.name, this.nameCN, this.icon, this.color);

  Color get lightColor => color.withOpacity(0.1);
}

/// ============================================
/// 指标来源类型
/// ============================================

enum MetricSource {
  /// AI 基于物种生成的基础指标 (注册时)
  aiBase('AI Base', 'Recommended for your pet'),
  
  /// 用户自定义添加的指标
  userCustom('Custom', 'Added by you'),
  
  /// AI 基于日常数据动态建议的指标
  aiDynamic('AI Suggestion', 'Based on recent activity'),
  
  /// 生病后整合疾病数据建议的指标
  postIllness('Post-Illness', 'Based on health history');

  final String name;
  final String description;

  const MetricSource(this.name, this.description);
}

/// ============================================
/// 指标频率
/// ============================================

enum MetricFrequency {
  daily('Daily', '每天', 1),
  twiceDaily('Twice Daily', '每天两次', 0.5),
  threeTimesDaily('3x Daily', '每天三次', 0.33),
  weekly('Weekly', '每周', 7),
  twiceWeekly('Twice Weekly', '每周两次', 3.5),
  monthly('Monthly', '每月', 30),
  asNeeded('As Needed', '按需', 0);

  final String name;
  final String nameCN;
  final double intervalDays; // 用于计算

  const MetricFrequency(this.name, this.nameCN, this.intervalDays);
}

/// ============================================
/// 指标值类型
/// ============================================

enum MetricValueType {
  /// 布尔类型 (完成/未完成)
  boolean,
  
  /// 数值类型 (体重、时长等)
  number,
  
  /// 范围类型 (1-5评分)
  range,
  
  /// 选择类型 (多选一)
  selection,
  
  /// 文本类型 (备注)
  text,
  
  /// 图片类型 (拍照记录)
  image,
  
  /// 视频类型 (视频记录)
  video,
}

/// ============================================
/// 指标类别 (9大身体部位/系统)
/// ============================================

enum MetricCategory {
  mouth('mouth', 'Mouth', '口腔', '👄', ['牙龈颜色', '牙齿', '口气', '舌头']),
  eyes('eyes', 'Eyes', '眼睛', '👁️', ['清澈度', '分泌物', '泪痕']),
  ears('ears', 'Ears', '耳朵', '👂', ['清洁度', '气味', '分泌物']),
  coat('coat', 'Coat & Skin', '毛发皮肤', '✨', ['光泽', '脱毛', '皮屑', '寄生虫']),
  digestion('digestion', 'Digestion', '消化', '🍽️', ['食欲', '排便', '呕吐']),
  energy('energy', 'Energy', '精力', '⚡', ['精神', '运动意愿', '睡眠']),
  hydration('hydration', 'Hydration', '水分', '💧', ['饮水量', '皮肤弹性']),
  breathing('breathing', 'Breathing', '呼吸', '🌬️', ['频率', '咳嗽', '打喷嚏']),
  mobility('mobility', 'Mobility', '行动', '🚶', ['步态', '姿态', '跛行']);

  final String id;
  final String name;
  final String nameZh;
  final String emoji;
  final List<String> hints; // 子项检查提示

  const MetricCategory(this.id, this.name, this.nameZh, this.emoji, this.hints);
}

/// ============================================
/// 护理指标定义
/// ============================================

class CareMetric {
  final String id;
  final String petId;
  final CareCategory category;
  final MetricSource source;
  final String name;
  final String? description;
  final String? emoji;
  final MetricFrequency frequency;
  final MetricValueType valueType;
  
  /// 数值类型的单位 (kg, ml, min, etc.)
  final String? unit;
  
  /// 数值类型的目标值
  final double? targetValue;
  
  /// 数值类型的最小值
  final double? minValue;
  
  /// 数值类型的最大值
  final double? maxValue;
  
  /// 选择类型的选项
  final List<String>? options;
  
  /// 是否启用
  final bool isEnabled;
  
  /// 是否固定 (AI Base 指标不可删除，只能禁用)
  final bool isPinned;
  
  /// 优先级 (用于排序)
  final int priority;
  
  /// AI 建议原因 (仅 aiDynamic/postIllness)
  final String? aiReason;
  
  /// 关联的疾病 ID (仅 postIllness)
  final String? linkedIllnessId;
  
  /// 指标类别 (9大身体部位/系统，仅 wellness 类型使用)
  final MetricCategory? metricCategory;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  const CareMetric({
    required this.id,
    required this.petId,
    required this.category,
    required this.source,
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
    this.isEnabled = true,
    this.isPinned = false,
    this.priority = 0,
    this.aiReason,
    this.linkedIllnessId,
    this.metricCategory,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CareMetric.fromJson(Map<String, dynamic> json) {
    return CareMetric(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      category: CareCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => CareCategory.wellness,
      ),
      source: MetricSource.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => MetricSource.userCustom,
      ),
      name: json['name'] as String,
      description: json['description'] as String?,
      emoji: json['emoji'] as String?,
      frequency: MetricFrequency.values.firstWhere(
        (e) => e.name == json['frequency'],
        orElse: () => MetricFrequency.daily,
      ),
      valueType: MetricValueType.values.firstWhere(
        (e) => e.name == json['value_type'],
        orElse: () => MetricValueType.boolean,
      ),
      unit: json['unit'] as String?,
      targetValue: (json['target_value'] as num?)?.toDouble(),
      minValue: (json['min_value'] as num?)?.toDouble(),
      maxValue: (json['max_value'] as num?)?.toDouble(),
      options: (json['options'] as List<dynamic>?)?.cast<String>(),
      isEnabled: json['is_enabled'] as bool? ?? true,
      isPinned: json['is_pinned'] as bool? ?? false,
      priority: json['priority'] as int? ?? 0,
      aiReason: json['ai_reason'] as String?,
      linkedIllnessId: json['linked_illness_id'] as String?,
      metricCategory: json['metric_category'] != null
          ? MetricCategory.values.firstWhere(
              (e) => e.id == json['metric_category'],
              orElse: () => MetricCategory.eyes,
            )
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'pet_id': petId,
    'category': category.name,
    'source': source.name,
    'name': name,
    'description': description,
    'emoji': emoji,
    'frequency': frequency.name,
    'value_type': valueType.name,
    'unit': unit,
    'target_value': targetValue,
    'min_value': minValue,
    'max_value': maxValue,
    'options': options,
    'is_enabled': isEnabled,
    'is_pinned': isPinned,
    'priority': priority,
    'ai_reason': aiReason,
    'linked_illness_id': linkedIllnessId,
    'metric_category': metricCategory?.id,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  CareMetric copyWith({
    String? id,
    String? petId,
    CareCategory? category,
    MetricSource? source,
    String? name,
    String? description,
    String? emoji,
    MetricFrequency? frequency,
    MetricValueType? valueType,
    String? unit,
    double? targetValue,
    double? minValue,
    double? maxValue,
    List<String>? options,
    bool? isEnabled,
    bool? isPinned,
    int? priority,
    String? aiReason,
    String? linkedIllnessId,
    MetricCategory? metricCategory,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CareMetric(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      category: category ?? this.category,
      source: source ?? this.source,
      name: name ?? this.name,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      frequency: frequency ?? this.frequency,
      valueType: valueType ?? this.valueType,
      unit: unit ?? this.unit,
      targetValue: targetValue ?? this.targetValue,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      options: options ?? this.options,
      isEnabled: isEnabled ?? this.isEnabled,
      isPinned: isPinned ?? this.isPinned,
      priority: priority ?? this.priority,
      aiReason: aiReason ?? this.aiReason,
      linkedIllnessId: linkedIllnessId ?? this.linkedIllnessId,
      metricCategory: metricCategory ?? this.metricCategory,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// ============================================
/// 指标记录 (每次完成的记录)
/// ============================================

class MetricLog {
  final String id;
  final String metricId;
  final String petId;
  final DateTime loggedAt;
  
  /// 布尔值 (完成/未完成)
  final bool? boolValue;
  
  /// 数值
  final double? numberValue;
  
  /// 范围值 (1-5)
  final int? rangeValue;
  
  /// 选择值
  final String? selectionValue;
  
  /// 文本值/备注
  final String? textValue;
  
  /// 附加备注
  final String? notes;
  
  /// 附加图片URLs
  final List<String>? imageUrls;

  const MetricLog({
    required this.id,
    required this.metricId,
    required this.petId,
    required this.loggedAt,
    this.boolValue,
    this.numberValue,
    this.rangeValue,
    this.selectionValue,
    this.textValue,
    this.notes,
    this.imageUrls,
  });

  factory MetricLog.fromJson(Map<String, dynamic> json) {
    return MetricLog(
      id: json['id'] as String,
      metricId: json['metric_id'] as String,
      petId: json['pet_id'] as String,
      loggedAt: DateTime.parse(json['logged_at'] as String),
      boolValue: json['bool_value'] as bool?,
      numberValue: (json['number_value'] as num?)?.toDouble(),
      rangeValue: json['range_value'] as int?,
      selectionValue: json['selection_value'] as String?,
      textValue: json['text_value'] as String?,
      notes: json['notes'] as String?,
      imageUrls: json['image_urls'] != null 
          ? List<String>.from(json['image_urls'] as List)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'metric_id': metricId,
    'pet_id': petId,
    'logged_at': loggedAt.toIso8601String(),
    'bool_value': boolValue,
    'number_value': numberValue,
    'range_value': rangeValue,
    'selection_value': selectionValue,
    'text_value': textValue,
    'notes': notes,
    'image_urls': imageUrls,
  };
}

/// ============================================
/// 每日护理计划任务
/// ============================================

class DailyTask {
  final CareMetric metric;
  final DateTime scheduledDate;
  final MetricLog? completedLog;
  final int? scheduledTime; // 小时 (0-23)，null 表示任意时间

  const DailyTask({
    required this.metric,
    required this.scheduledDate,
    this.completedLog,
    this.scheduledTime,
  });

  bool get isCompleted => completedLog != null;
  
  String get timeLabel {
    if (scheduledTime == null) return 'Anytime';
    if (scheduledTime! < 12) return 'Morning';
    if (scheduledTime! < 17) return 'Afternoon';
    return 'Evening';
  }
}

/// ============================================
/// 综合健康评分
/// ============================================

class WellnessScore {
  final double overall; // 0-100
  final double wellnessScore;
  final double nutritionScore;
  final double enrichmentScore;
  final double careScore;
  final DateTime calculatedAt;
  final String? aiSummary;
  final List<String> improvements;

  const WellnessScore({
    required this.overall,
    required this.wellnessScore,
    required this.nutritionScore,
    required this.enrichmentScore,
    required this.careScore,
    required this.calculatedAt,
    this.aiSummary,
    this.improvements = const [],
  });

  String get grade {
    if (overall >= 90) return 'A';
    if (overall >= 80) return 'B';
    if (overall >= 70) return 'C';
    if (overall >= 60) return 'D';
    return 'F';
  }

  String get label {
    if (overall >= 90) return 'Excellent';
    if (overall >= 80) return 'Very Good';
    if (overall >= 70) return 'Good';
    if (overall >= 60) return 'Fair';
    return 'Needs Attention';
  }

  Color get color {
    if (overall >= 80) return const Color(0xFF10B981);
    if (overall >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}

/// ============================================
/// AI 基础指标模板 (按物种)
/// ============================================

class SpeciesMetricTemplates {
  static List<CareMetric> getBaseMetrics(PetSpecies species, String petId) {
    final now = DateTime.now();
    
    switch (species) {
      case PetSpecies.dog:
        return _dogMetrics(petId, now);
      case PetSpecies.cat:
        return _catMetrics(petId, now);
      case PetSpecies.bird:
        return _birdMetrics(petId, now);
      case PetSpecies.rabbit:
        return _rabbitMetrics(petId, now);
      case PetSpecies.fish:
        return _fishMetrics(petId, now);
      default:
        return _defaultMetrics(petId, now);
    }
  }

  static List<CareMetric> _dogMetrics(String petId, DateTime now) {
    return [
      // Wellness
      CareMetric(
        id: '${petId}_weight', petId: petId,
        category: CareCategory.wellness, source: MetricSource.aiBase,
        name: 'Weight Check', emoji: '⚖️',
        description: 'Monitor weight to track health trends',
        frequency: MetricFrequency.weekly,
        valueType: MetricValueType.number,
        unit: 'kg', isPinned: true, priority: 1,
        createdAt: now, updatedAt: now,
      ),
      CareMetric(
        id: '${petId}_mood', petId: petId,
        category: CareCategory.wellness, source: MetricSource.aiBase,
        name: 'Mood & Energy', emoji: '😊',
        description: 'How is your dog feeling today?',
        frequency: MetricFrequency.daily,
        valueType: MetricValueType.range,
        minValue: 1, maxValue: 5, isPinned: true, priority: 2,
        createdAt: now, updatedAt: now,
      ),
      
      // Nutrition
      CareMetric(
        id: '${petId}_breakfast', petId: petId,
        category: CareCategory.nutrition, source: MetricSource.aiBase,
        name: 'Morning Meal', emoji: '🌅',
        description: 'First meal of the day',
        frequency: MetricFrequency.daily,
        valueType: MetricValueType.boolean,
        isPinned: true, priority: 1,
        createdAt: now, updatedAt: now,
      ),
      CareMetric(
        id: '${petId}_dinner', petId: petId,
        category: CareCategory.nutrition, source: MetricSource.aiBase,
        name: 'Evening Meal', emoji: '🌙',
        description: 'Second meal of the day',
        frequency: MetricFrequency.daily,
        valueType: MetricValueType.boolean,
        isPinned: true, priority: 2,
        createdAt: now, updatedAt: now,
      ),
      CareMetric(
        id: '${petId}_water', petId: petId,
        category: CareCategory.nutrition, source: MetricSource.aiBase,
        name: 'Fresh Water', emoji: '💧',
        description: 'Ensure fresh water is available',
        frequency: MetricFrequency.daily,
        valueType: MetricValueType.boolean,
        isPinned: true, priority: 3,
        createdAt: now, updatedAt: now,
      ),
      
      // Enrichment
      CareMetric(
        id: '${petId}_walk', petId: petId,
        category: CareCategory.enrichment, source: MetricSource.aiBase,
        name: 'Daily Walk', emoji: '🚶',
        description: 'Dogs need 30-60 min of walking daily',
        frequency: MetricFrequency.daily,
        valueType: MetricValueType.number,
        unit: 'min', targetValue: 45, isPinned: true, priority: 1,
        createdAt: now, updatedAt: now,
      ),
      CareMetric(
        id: '${petId}_play', petId: petId,
        category: CareCategory.enrichment, source: MetricSource.aiBase,
        name: 'Play Time', emoji: '🎾',
        description: 'Interactive play and mental stimulation',
        frequency: MetricFrequency.daily,
        valueType: MetricValueType.number,
        unit: 'min', targetValue: 20, priority: 2,
        createdAt: now, updatedAt: now,
      ),
      
      // Care
      CareMetric(
        id: '${petId}_teeth', petId: petId,
        category: CareCategory.care, source: MetricSource.aiBase,
        name: 'Dental Care', emoji: '🦷',
        description: 'Brush teeth or use dental chews',
        frequency: MetricFrequency.twiceWeekly,
        valueType: MetricValueType.boolean,
        priority: 1,
        createdAt: now, updatedAt: now,
      ),
      CareMetric(
        id: '${petId}_grooming', petId: petId,
        category: CareCategory.care, source: MetricSource.aiBase,
        name: 'Brushing', emoji: '✨',
        description: 'Brush coat to maintain health',
        frequency: MetricFrequency.weekly,
        valueType: MetricValueType.boolean,
        priority: 2,
        createdAt: now, updatedAt: now,
      ),
    ];
  }

  static List<CareMetric> _catMetrics(String petId, DateTime now) {
    return [
      // Wellness
      CareMetric(
        id: '${petId}_weight', petId: petId,
        category: CareCategory.wellness, source: MetricSource.aiBase,
        name: 'Weight Check', emoji: '⚖️',
        description: 'Monitor weight weekly',
        frequency: MetricFrequency.weekly,
        valueType: MetricValueType.number,
        unit: 'kg', isPinned: true, priority: 1,
        createdAt: now, updatedAt: now,
      ),
      CareMetric(
        id: '${petId}_litter', petId: petId,
        category: CareCategory.wellness, source: MetricSource.aiBase,
        name: 'Litter Box Check', emoji: '🚽',
        description: 'Monitor elimination habits',
        frequency: MetricFrequency.daily,
        valueType: MetricValueType.boolean,
        isPinned: true, priority: 2,
        createdAt: now, updatedAt: now,
      ),
      
      // Nutrition
      CareMetric(
        id: '${petId}_meal', petId: petId,
        category: CareCategory.nutrition, source: MetricSource.aiBase,
        name: 'Meals', emoji: '🍽️',
        description: 'Regular feeding schedule',
        frequency: MetricFrequency.twiceDaily,
        valueType: MetricValueType.boolean,
        isPinned: true, priority: 1,
        createdAt: now, updatedAt: now,
      ),
      CareMetric(
        id: '${petId}_water', petId: petId,
        category: CareCategory.nutrition, source: MetricSource.aiBase,
        name: 'Fresh Water', emoji: '💧',
        description: 'Cats need encouragement to drink',
        frequency: MetricFrequency.daily,
        valueType: MetricValueType.boolean,
        isPinned: true, priority: 2,
        createdAt: now, updatedAt: now,
      ),
      
      // Enrichment
      CareMetric(
        id: '${petId}_play', petId: petId,
        category: CareCategory.enrichment, source: MetricSource.aiBase,
        name: 'Interactive Play', emoji: '🪶',
        description: 'Hunting games and toys',
        frequency: MetricFrequency.daily,
        valueType: MetricValueType.number,
        unit: 'min', targetValue: 15, isPinned: true, priority: 1,
        createdAt: now, updatedAt: now,
      ),
      CareMetric(
        id: '${petId}_scratch', petId: petId,
        category: CareCategory.enrichment, source: MetricSource.aiBase,
        name: 'Scratching Post', emoji: '🐱',
        description: 'Ensure access to scratching surfaces',
        frequency: MetricFrequency.daily,
        valueType: MetricValueType.boolean,
        priority: 2,
        createdAt: now, updatedAt: now,
      ),
      
      // Care
      CareMetric(
        id: '${petId}_brush', petId: petId,
        category: CareCategory.care, source: MetricSource.aiBase,
        name: 'Coat Brushing', emoji: '✨',
        description: 'Regular grooming prevents hairballs',
        frequency: MetricFrequency.twiceWeekly,
        valueType: MetricValueType.boolean,
        priority: 1,
        createdAt: now, updatedAt: now,
      ),
      CareMetric(
        id: '${petId}_nails', petId: petId,
        category: CareCategory.care, source: MetricSource.aiBase,
        name: 'Nail Check', emoji: '✂️',
        description: 'Trim if needed',
        frequency: MetricFrequency.monthly,
        valueType: MetricValueType.boolean,
        priority: 2,
        createdAt: now, updatedAt: now,
      ),
    ];
  }

  static List<CareMetric> _birdMetrics(String petId, DateTime now) {
    return [
      // Wellness
      CareMetric(
        id: '${petId}_feathers', petId: petId,
        category: CareCategory.wellness, source: MetricSource.aiBase,
        name: 'Feather Condition', emoji: '🪶',
        description: 'Check for healthy plumage',
        frequency: MetricFrequency.daily,
        valueType: MetricValueType.range,
        minValue: 1, maxValue: 5, isPinned: true, priority: 1,
        createdAt: now, updatedAt: now,
      ),
      CareMetric(
        id: '${petId}_droppings', petId: petId,
        category: CareCategory.wellness, source: MetricSource.aiBase,
        name: 'Droppings Check', emoji: '💩',
        description: 'Monitor for health issues',
        frequency: MetricFrequency.daily,
        valueType: MetricValueType.boolean,
        isPinned: true, priority: 2,
        createdAt: now, updatedAt: now,
      ),
      
      // Nutrition
      CareMetric(
        id: '${petId}_seeds', petId: petId,
        category: CareCategory.nutrition, source: MetricSource.aiBase,
        name: 'Seeds & Pellets', emoji: '🌾',
        description: 'Main food source',
        frequency: MetricFrequency.daily,
        valueType: MetricValueType.boolean,
        isPinned: true, priority: 1,
        createdAt: now, updatedAt: now,
      ),
      CareMetric(
        id: '${petId}_fresh_food', petId: petId,
        category: CareCategory.nutrition, source: MetricSource.aiBase,
        name: 'Fresh Fruits/Veggies', emoji: '🥬',
        description: 'Variety is important',
        frequency: MetricFrequency.daily,
        valueType: MetricValueType.boolean,
        priority: 2,
        createdAt: now, updatedAt: now,
      ),
      CareMetric(
        id: '${petId}_water', petId: petId,
        category: CareCategory.nutrition, source: MetricSource.aiBase,
        name: 'Fresh Water', emoji: '💧',
        description: 'Clean water daily',
        frequency: MetricFrequency.daily,
        valueType: MetricValueType.boolean,
        isPinned: true, priority: 3,
        createdAt: now, updatedAt: now,
      ),
      
      // Enrichment
      CareMetric(
        id: '${petId}_out_time', petId: petId,
        category: CareCategory.enrichment, source: MetricSource.aiBase,
        name: 'Out-of-Cage Time', emoji: '🦜',
        description: 'Supervised flight and exploration',
        frequency: MetricFrequency.daily,
        valueType: MetricValueType.number,
        unit: 'min', targetValue: 30, isPinned: true, priority: 1,
        createdAt: now, updatedAt: now,
      ),
      CareMetric(
        id: '${petId}_social', petId: petId,
        category: CareCategory.enrichment, source: MetricSource.aiBase,
        name: 'Social Interaction', emoji: '💬',
        description: 'Talk and interact with your bird',
        frequency: MetricFrequency.daily,
        valueType: MetricValueType.boolean,
        priority: 2,
        createdAt: now, updatedAt: now,
      ),
      
      // Care
      CareMetric(
        id: '${petId}_cage_clean', petId: petId,
        category: CareCategory.care, source: MetricSource.aiBase,
        name: 'Cage Cleaning', emoji: '🧹',
        description: 'Clean cage and perches',
        frequency: MetricFrequency.weekly,
        valueType: MetricValueType.boolean,
        isPinned: true, priority: 1,
        createdAt: now, updatedAt: now,
      ),
      CareMetric(
        id: '${petId}_nails', petId: petId,
        category: CareCategory.care, source: MetricSource.aiBase,
        name: 'Nail & Beak Check', emoji: '✂️',
        description: 'Monitor growth',
        frequency: MetricFrequency.monthly,
        valueType: MetricValueType.boolean,
        priority: 2,
        createdAt: now, updatedAt: now,
      ),
    ];
  }

  static List<CareMetric> _rabbitMetrics(String petId, DateTime now) {
    return [
      // Wellness
      CareMetric(
        id: '${petId}_weight', petId: petId,
        category: CareCategory.wellness, source: MetricSource.aiBase,
        name: 'Weight Check', emoji: '⚖️',
        description: 'Monitor weekly',
        frequency: MetricFrequency.weekly,
        valueType: MetricValueType.number,
        unit: 'kg', isPinned: true, priority: 1,
        createdAt: now, updatedAt: now,
      ),
      CareMetric(
        id: '${petId}_poop', petId: petId,
        category: CareCategory.wellness, source: MetricSource.aiBase,
        name: 'Droppings Check', emoji: '💩',
        description: 'GI health indicator',
        frequency: MetricFrequency.daily,
        valueType: MetricValueType.boolean,
        isPinned: true, priority: 2,
        createdAt: now, updatedAt: now,
      ),
      
      // Nutrition
      CareMetric(
        id: '${petId}_hay', petId: petId,
        category: CareCategory.nutrition, source: MetricSource.aiBase,
        name: 'Unlimited Hay', emoji: '🌾',
        description: '80% of diet - always available',
        frequency: MetricFrequency.daily,
        valueType: MetricValueType.boolean,
        isPinned: true, priority: 1,
        createdAt: now, updatedAt: now,
      ),
      CareMetric(
        id: '${petId}_veggies', petId: petId,
        category: CareCategory.nutrition, source: MetricSource.aiBase,
        name: 'Fresh Vegetables', emoji: '🥬',
        description: 'Leafy greens daily',
        frequency: MetricFrequency.daily,
        valueType: MetricValueType.boolean,
        isPinned: true, priority: 2,
        createdAt: now, updatedAt: now,
      ),
      CareMetric(
        id: '${petId}_water', petId: petId,
        category: CareCategory.nutrition, source: MetricSource.aiBase,
        name: 'Fresh Water', emoji: '💧',
        description: 'Clean water always',
        frequency: MetricFrequency.daily,
        valueType: MetricValueType.boolean,
        isPinned: true, priority: 3,
        createdAt: now, updatedAt: now,
      ),
      
      // Enrichment
      CareMetric(
        id: '${petId}_exercise', petId: petId,
        category: CareCategory.enrichment, source: MetricSource.aiBase,
        name: 'Exercise Time', emoji: '🐰',
        description: 'Free roam time outside enclosure',
        frequency: MetricFrequency.daily,
        valueType: MetricValueType.number,
        unit: 'hours', targetValue: 3, isPinned: true, priority: 1,
        createdAt: now, updatedAt: now,
      ),
      CareMetric(
        id: '${petId}_enrichment', petId: petId,
        category: CareCategory.enrichment, source: MetricSource.aiBase,
        name: 'Toys & Tunnels', emoji: '🎪',
        description: 'Mental stimulation',
        frequency: MetricFrequency.daily,
        valueType: MetricValueType.boolean,
        priority: 2,
        createdAt: now, updatedAt: now,
      ),
      
      // Care
      CareMetric(
        id: '${petId}_grooming', petId: petId,
        category: CareCategory.care, source: MetricSource.aiBase,
        name: 'Brushing', emoji: '✨',
        description: 'Especially during shedding',
        frequency: MetricFrequency.twiceWeekly,
        valueType: MetricValueType.boolean,
        priority: 1,
        createdAt: now, updatedAt: now,
      ),
      CareMetric(
        id: '${petId}_nails', petId: petId,
        category: CareCategory.care, source: MetricSource.aiBase,
        name: 'Nail Trim', emoji: '✂️',
        description: 'Check monthly',
        frequency: MetricFrequency.monthly,
        valueType: MetricValueType.boolean,
        priority: 2,
        createdAt: now, updatedAt: now,
      ),
      CareMetric(
        id: '${petId}_enclosure', petId: petId,
        category: CareCategory.care, source: MetricSource.aiBase,
        name: 'Enclosure Clean', emoji: '🧹',
        description: 'Deep clean weekly',
        frequency: MetricFrequency.weekly,
        valueType: MetricValueType.boolean,
        isPinned: true, priority: 3,
        createdAt: now, updatedAt: now,
      ),
    ];
  }

  static List<CareMetric> _fishMetrics(String petId, DateTime now) {
    return [
      // Wellness
      CareMetric(
        id: '${petId}_behavior', petId: petId,
        category: CareCategory.wellness, source: MetricSource.aiBase,
        name: 'Behavior Check', emoji: '🐟',
        description: 'Active and swimming normally?',
        frequency: MetricFrequency.daily,
        valueType: MetricValueType.range,
        minValue: 1, maxValue: 5, isPinned: true, priority: 1,
        createdAt: now, updatedAt: now,
      ),
      CareMetric(
        id: '${petId}_appearance', petId: petId,
        category: CareCategory.wellness, source: MetricSource.aiBase,
        name: 'Appearance', emoji: '👀',
        description: 'Check fins, scales, color',
        frequency: MetricFrequency.daily,
        valueType: MetricValueType.boolean,
        priority: 2,
        createdAt: now, updatedAt: now,
      ),
      
      // Nutrition
      CareMetric(
        id: '${petId}_feeding', petId: petId,
        category: CareCategory.nutrition, source: MetricSource.aiBase,
        name: 'Feeding', emoji: '🍽️',
        description: 'Small amounts 1-2x daily',
        frequency: MetricFrequency.daily,
        valueType: MetricValueType.boolean,
        isPinned: true, priority: 1,
        createdAt: now, updatedAt: now,
      ),
      CareMetric(
        id: '${petId}_variety', petId: petId,
        category: CareCategory.nutrition, source: MetricSource.aiBase,
        name: 'Food Variety', emoji: '🦐',
        description: 'Alternate food types',
        frequency: MetricFrequency.weekly,
        valueType: MetricValueType.boolean,
        priority: 2,
        createdAt: now, updatedAt: now,
      ),
      
      // Enrichment (Environment for fish)
      CareMetric(
        id: '${petId}_temp', petId: petId,
        category: CareCategory.enrichment, source: MetricSource.aiBase,
        name: 'Temperature Check', emoji: '🌡️',
        description: 'Maintain stable temp',
        frequency: MetricFrequency.daily,
        valueType: MetricValueType.number,
        unit: '°C', isPinned: true, priority: 1,
        createdAt: now, updatedAt: now,
      ),
      CareMetric(
        id: '${petId}_water_quality', petId: petId,
        category: CareCategory.enrichment, source: MetricSource.aiBase,
        name: 'Water Parameters', emoji: '🧪',
        description: 'Test pH, ammonia, nitrites',
        frequency: MetricFrequency.weekly,
        valueType: MetricValueType.boolean,
        isPinned: true, priority: 2,
        createdAt: now, updatedAt: now,
      ),
      CareMetric(
        id: '${petId}_light', petId: petId,
        category: CareCategory.enrichment, source: MetricSource.aiBase,
        name: 'Light Cycle', emoji: '💡',
        description: '8-12 hours light daily',
        frequency: MetricFrequency.daily,
        valueType: MetricValueType.boolean,
        priority: 3,
        createdAt: now, updatedAt: now,
      ),
      
      // Care
      CareMetric(
        id: '${petId}_water_change', petId: petId,
        category: CareCategory.care, source: MetricSource.aiBase,
        name: 'Water Change', emoji: '💧',
        description: '10-25% weekly',
        frequency: MetricFrequency.weekly,
        valueType: MetricValueType.boolean,
        isPinned: true, priority: 1,
        createdAt: now, updatedAt: now,
      ),
      CareMetric(
        id: '${petId}_filter', petId: petId,
        category: CareCategory.care, source: MetricSource.aiBase,
        name: 'Filter Check', emoji: '🔧',
        description: 'Clean/replace as needed',
        frequency: MetricFrequency.monthly,
        valueType: MetricValueType.boolean,
        priority: 2,
        createdAt: now, updatedAt: now,
      ),
      CareMetric(
        id: '${petId}_tank_clean', petId: petId,
        category: CareCategory.care, source: MetricSource.aiBase,
        name: 'Tank Maintenance', emoji: '🧹',
        description: 'Clean glass, trim plants',
        frequency: MetricFrequency.monthly,
        valueType: MetricValueType.boolean,
        priority: 3,
        createdAt: now, updatedAt: now,
      ),
    ];
  }

  static List<CareMetric> _defaultMetrics(String petId, DateTime now) {
    return [
      // Basic wellness
      CareMetric(
        id: '${petId}_health_check', petId: petId,
        category: CareCategory.wellness, source: MetricSource.aiBase,
        name: 'Health Check', emoji: '❤️',
        description: 'General health observation',
        frequency: MetricFrequency.daily,
        valueType: MetricValueType.range,
        minValue: 1, maxValue: 5, isPinned: true, priority: 1,
        createdAt: now, updatedAt: now,
      ),
      
      // Basic nutrition
      CareMetric(
        id: '${petId}_feeding', petId: petId,
        category: CareCategory.nutrition, source: MetricSource.aiBase,
        name: 'Feeding', emoji: '🍽️',
        description: 'Regular feeding',
        frequency: MetricFrequency.daily,
        valueType: MetricValueType.boolean,
        isPinned: true, priority: 1,
        createdAt: now, updatedAt: now,
      ),
      CareMetric(
        id: '${petId}_water', petId: petId,
        category: CareCategory.nutrition, source: MetricSource.aiBase,
        name: 'Fresh Water', emoji: '💧',
        description: 'Clean water available',
        frequency: MetricFrequency.daily,
        valueType: MetricValueType.boolean,
        isPinned: true, priority: 2,
        createdAt: now, updatedAt: now,
      ),
      
      // Basic enrichment
      CareMetric(
        id: '${petId}_interaction', petId: petId,
        category: CareCategory.enrichment, source: MetricSource.aiBase,
        name: 'Interaction', emoji: '💕',
        description: 'Quality time with pet',
        frequency: MetricFrequency.daily,
        valueType: MetricValueType.boolean,
        isPinned: true, priority: 1,
        createdAt: now, updatedAt: now,
      ),
      
      // Basic care
      CareMetric(
        id: '${petId}_habitat_clean', petId: petId,
        category: CareCategory.care, source: MetricSource.aiBase,
        name: 'Habitat Clean', emoji: '🧹',
        description: 'Clean living space',
        frequency: MetricFrequency.weekly,
        valueType: MetricValueType.boolean,
        isPinned: true, priority: 1,
        createdAt: now, updatedAt: now,
      ),
    ];
  }
}
