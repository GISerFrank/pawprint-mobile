/// 身体部位枚举
enum BodyPart {
  eyes('Eyes'),
  ears('Ears'),
  mouthTeeth('Mouth & Teeth'),
  paws('Paws'),
  skinFur('Skin & Fur'),
  other('Other');

  final String displayName;
  const BodyPart(this.displayName);

  static BodyPart fromString(String value) {
    return BodyPart.values.firstWhere(
      (e) => e.displayName == value || e.name == value,
      orElse: () => BodyPart.other,
    );
  }
}

/// 健康记录类型枚举
enum HealthRecordType {
  weight('Weight'),
  vaccine('Vaccine'),
  symptom('Symptom'),
  checkup('Checkup'),
  activity('Activity'),
  medication('Medication'),
  grooming('Grooming'),
  food('Food');

  final String displayName;
  const HealthRecordType(this.displayName);

  static HealthRecordType fromString(String value) {
    return HealthRecordType.values.firstWhere(
      (e) => e.displayName == value || e.name == value,
      orElse: () => HealthRecordType.other,
    );
  }

  static HealthRecordType get other => HealthRecordType.activity;
}

/// 提醒类型枚举
enum ReminderType {
  medication('Medication'),
  appointment('Appointment'),
  grooming('Grooming'),
  other('Other');

  final String displayName;
  const ReminderType(this.displayName);

  static ReminderType fromString(String value) {
    return ReminderType.values.firstWhere(
      (e) => e.displayName == value || e.name == value,
      orElse: () => ReminderType.other,
    );
  }
}

/// ID卡片风格枚举
enum IDCardStyle {
  cute('Cute'),
  cool('Cool'),
  pixel('Pixel');

  final String displayName;
  const IDCardStyle(this.displayName);

  static IDCardStyle fromString(String value) {
    return IDCardStyle.values.firstWhere(
      (e) => e.displayName == value || e.name == value,
      orElse: () => IDCardStyle.cute,
    );
  }
}

/// 稀有度枚举
enum Rarity {
  common('Common'),
  rare('Rare'),
  epic('Epic'),
  legendary('Legendary');

  final String displayName;
  const Rarity(this.displayName);

  static Rarity fromString(String value) {
    return Rarity.values.firstWhere(
      (e) => e.displayName == value || e.name == value,
      orElse: () => Rarity.common,
    );
  }
}

/// 卡包主题枚举
enum PackTheme {
  daily('Daily'),
  profile('Profile'),
  fun('Fun'),
  sticker('Sticker');

  final String displayName;
  const PackTheme(this.displayName);

  static PackTheme fromString(String value) {
    return PackTheme.values.firstWhere(
      (e) => e.displayName == value || e.name == value,
      orElse: () => PackTheme.daily,
    );
  }
}

/// 论坛分类枚举
enum ForumCategory {
  question('Question'),
  tip('Tip'),
  story('Story'),
  emergency('Emergency');

  final String displayName;
  const ForumCategory(this.displayName);

  static ForumCategory fromString(String value) {
    return ForumCategory.values.firstWhere(
      (e) => e.displayName == value || e.name == value,
      orElse: () => ForumCategory.question,
    );
  }
}

/// 宠物性别枚举
enum PetGender {
  male('Male'),
  female('Female');

  final String displayName;
  const PetGender(this.displayName);

  static PetGender fromString(String value) {
    return PetGender.values.firstWhere(
      (e) => e.displayName == value || e.name == value,
      orElse: () => PetGender.male,
    );
  }
}

/// 宠物种类枚举
enum PetSpecies {
  dog('Dog'),
  cat('Cat'),
  bird('Bird'),
  rabbit('Rabbit'),
  fish('Fish'),
  other('Other');

  final String displayName;
  const PetSpecies(this.displayName);

  static PetSpecies fromString(String value) {
    return PetSpecies.values.firstWhere(
      (e) => e.displayName == value || e.name == value,
      orElse: () => PetSpecies.other,
    );
  }
}

/// 宠物健康状态枚举
enum HealthStatus {
  healthy('Healthy'),
  sick('Sick');

  final String displayName;
  const HealthStatus(this.displayName);

  static HealthStatus fromString(String value) {
    return HealthStatus.values.firstWhere(
      (e) => e.displayName == value || e.name == value,
      orElse: () => HealthStatus.healthy,
    );
  }
}

/// 生病类型枚举（未就医/已就医）
enum SickType {
  undiagnosed('Undiagnosed'),
  diagnosed('Diagnosed');

  final String displayName;
  const SickType(this.displayName);

  static SickType fromString(String value) {
    return SickType.values.firstWhere(
      (e) => e.displayName == value || e.name == value,
      orElse: () => SickType.undiagnosed,
    );
  }
}

/// 症状程度枚举（每日追踪）
enum SymptomLevel {
  worse('Worse'),
  same('Same'),
  better('Better');

  final String displayName;
  const SymptomLevel(this.displayName);

  static SymptomLevel fromString(String value) {
    return SymptomLevel.values.firstWhere(
      (e) => e.displayName == value || e.name == value,
      orElse: () => SymptomLevel.same,
    );
  }

  String get emoji {
    switch (this) {
      case SymptomLevel.worse:
        return '😢';
      case SymptomLevel.same:
        return '😐';
      case SymptomLevel.better:
        return '😊';
    }
  }
}

/// 体重单位枚举
enum WeightUnit {
  kg('kg'),
  lb('lb');

  final String displayName;
  const WeightUnit(this.displayName);

  static WeightUnit fromString(String value) {
    return WeightUnit.values.firstWhere(
      (e) => e.displayName == value || e.name == value,
      orElse: () => WeightUnit.kg,
    );
  }

  /// kg 转换为 lb
  static double kgToLb(double kg) => kg * 2.20462;

  /// lb 转换为 kg
  static double lbToKg(double lb) => lb / 2.20462;
}
