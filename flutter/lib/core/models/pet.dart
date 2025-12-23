import 'package:equatable/equatable.dart';
import 'enums.dart';

/// 宠物档案模型
class Pet extends Equatable {
  final String id;
  final String userId;
  final String name;
  final PetSpecies species;
  final String breed;
  final DateTime? birthday;
  final DateTime? gotchaDay;
  final PetGender gender;
  final double weightKg;
  final WeightUnit weightUnit;
  final bool isNeutered;
  final String? allergies;
  final String? avatarUrl;
  final int coins;
  final HealthStatus healthStatus;
  final String? currentIllnessId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // 关联数据（可选，按需加载）
  final Map<BodyPart, String?>? bodyPartImages;
  final PetIDCard? idCard;
  final List<CollectibleCard>? collection;

  const Pet({
    required this.id,
    required this.userId,
    required this.name,
    required this.species,
    this.breed = 'Unknown',
    this.birthday,
    this.gotchaDay,
    this.gender = PetGender.male,
    this.weightKg = 0,
    this.weightUnit = WeightUnit.kg,
    this.isNeutered = false,
    this.allergies,
    this.avatarUrl,
    this.coins = 200,
    this.healthStatus = HealthStatus.healthy,
    this.currentIllnessId,
    required this.createdAt,
    required this.updatedAt,
    this.bodyPartImages,
    this.idCard,
    this.collection,
  });

  bool get isSick => healthStatus == HealthStatus.sick;

  /// 从 JSON 创建
  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      species: PetSpecies.fromString(json['species'] as String? ?? 'Other'),
      breed: json['breed'] as String? ?? 'Unknown',
      birthday: json['birthday'] != null
          ? DateTime.parse(json['birthday'] as String)
          : null,
      gotchaDay: json['gotcha_day'] != null
          ? DateTime.parse(json['gotcha_day'] as String)
          : null,
      gender: PetGender.fromString(json['gender'] as String? ?? 'Male'),
      weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 0,
      weightUnit: WeightUnit.fromString(json['weight_unit'] as String? ?? 'kg'),
      isNeutered: json['is_neutered'] as bool? ?? false,
      allergies: json['allergies'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      coins: json['coins'] as int? ?? 200,
      healthStatus: HealthStatus.fromString(
          json['health_status'] as String? ?? 'Healthy'),
      currentIllnessId: json['current_illness_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      idCard: json['id_card'] != null
          ? PetIDCard.fromJson(json['id_card'] as Map<String, dynamic>)
          : null,
      collection: json['collection'] != null
          ? (json['collection'] as List<dynamic>)
              .map((e) => CollectibleCard.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'species': species.displayName,
      'breed': breed,
      'birthday': birthday?.toIso8601String(),
      'gotcha_day': gotchaDay?.toIso8601String(),
      'gender': gender.displayName,
      'weight_kg': weightKg,
      'weight_unit': weightUnit.displayName,
      'is_neutered': isNeutered,
      'allergies': allergies,
      'avatar_url': avatarUrl,
      'coins': coins,
      'health_status': healthStatus.displayName,
      'current_illness_id': currentIllnessId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'id_card': idCard?.toJson(),
      'collection': collection?.map((c) => c.toJson()).toList(),
    };
  }

  /// 用于插入新记录的 JSON（不含 id 和时间戳）
  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'name': name,
      'species': species.displayName,
      'breed': breed,
      'birthday': birthday?.toIso8601String(),
      'gotcha_day': gotchaDay?.toIso8601String(),
      'gender': gender.displayName,
      'weight_kg': weightKg,
      'weight_unit': weightUnit.displayName,
      'is_neutered': isNeutered,
      'allergies': allergies,
      'avatar_url': avatarUrl,
      'coins': coins,
      'health_status': healthStatus.displayName,
      'current_illness_id': currentIllnessId,
    };
  }

  /// 复制并修改
  Pet copyWith({
    String? id,
    String? userId,
    String? name,
    PetSpecies? species,
    String? breed,
    DateTime? birthday,
    DateTime? gotchaDay,
    PetGender? gender,
    double? weightKg,
    WeightUnit? weightUnit,
    bool? isNeutered,
    String? allergies,
    String? avatarUrl,
    int? coins,
    HealthStatus? healthStatus,
    String? currentIllnessId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<BodyPart, String?>? bodyPartImages,
    PetIDCard? idCard,
    List<CollectibleCard>? collection,
    bool clearCurrentIllnessId = false,
    bool clearBirthday = false,
    bool clearGotchaDay = false,
  }) {
    return Pet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      birthday: clearBirthday ? null : (birthday ?? this.birthday),
      gotchaDay: clearGotchaDay ? null : (gotchaDay ?? this.gotchaDay),
      gender: gender ?? this.gender,
      weightKg: weightKg ?? this.weightKg,
      weightUnit: weightUnit ?? this.weightUnit,
      isNeutered: isNeutered ?? this.isNeutered,
      allergies: allergies ?? this.allergies,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coins: coins ?? this.coins,
      healthStatus: healthStatus ?? this.healthStatus,
      currentIllnessId: clearCurrentIllnessId
          ? null
          : (currentIllnessId ?? this.currentIllnessId),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      bodyPartImages: bodyPartImages ?? this.bodyPartImages,
      idCard: idCard ?? this.idCard,
      collection: collection ?? this.collection,
    );
  }

  /// 计算年龄（月数）
  int get ageMonths {
    if (birthday == null) return 0;
    final now = DateTime.now();
    int months =
        (now.year - birthday!.year) * 12 + (now.month - birthday!.month);
    if (now.day < birthday!.day) months--;
    return months < 0 ? 0 : months;
  }

  /// 年龄格式化显示
  String get ageDisplay {
    if (birthday == null) return 'Unknown';
    final months = ageMonths;
    if (months < 12) {
      return '$months ${months == 1 ? 'month' : 'months'}';
    } else {
      final years = months ~/ 12;
      final remainingMonths = months % 12;
      if (remainingMonths == 0) {
        return '$years ${years == 1 ? 'year' : 'years'}';
      }
      return '$years ${years == 1 ? 'year' : 'years'}, $remainingMonths months';
    }
  }

  /// 到家时长格式化显示
  String get homeTimeDisplay {
    if (gotchaDay == null) return 'Unknown';
    final now = DateTime.now();
    final days = now.difference(gotchaDay!).inDays;
    if (days < 30) {
      return '$days ${days == 1 ? 'day' : 'days'}';
    } else if (days < 365) {
      final months = days ~/ 30;
      return '$months ${months == 1 ? 'month' : 'months'}';
    } else {
      final years = days ~/ 365;
      final remainingMonths = (days % 365) ~/ 30;
      if (remainingMonths == 0) {
        return '$years ${years == 1 ? 'year' : 'years'}';
      }
      return '$years ${years == 1 ? 'year' : 'years'}, $remainingMonths months';
    }
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        species,
        breed,
        birthday,
        gotchaDay,
        gender,
        weightKg,
        weightUnit,
        isNeutered,
        allergies,
        avatarUrl,
        coins,
        healthStatus,
        currentIllnessId,
        createdAt,
        updatedAt,
      ];
}

/// 宠物 ID 卡片模型
class PetIDCard extends Equatable {
  final String id;
  final String petId;
  final IDCardStyle style;
  final String cartoonImageUrl;
  final List<String> tags;
  final String? description;
  final DateTime generatedAt;

  const PetIDCard({
    required this.id,
    required this.petId,
    required this.style,
    required this.cartoonImageUrl,
    this.tags = const [],
    this.description,
    required this.generatedAt,
  });

  factory PetIDCard.fromJson(Map<String, dynamic> json) {
    return PetIDCard(
      id: json['id'] as String? ?? '',
      petId: json['pet_id'] as String? ?? '',
      style: IDCardStyle.fromString(json['style'] as String? ?? 'Cute'),
      cartoonImageUrl: json['cartoon_image_url'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      description: json['description'] as String?,
      generatedAt: json['generated_at'] != null
          ? DateTime.parse(json['generated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'style': style.displayName,
      'cartoon_image_url': cartoonImageUrl,
      'tags': tags,
      'description': description,
      'generated_at': generatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props =>
      [id, petId, style, cartoonImageUrl, tags, description, generatedAt];
}

/// 收藏卡牌模型
class CollectibleCard extends Equatable {
  final String id;
  final String petId;
  final String name;
  final String imageUrl;
  final String? description;
  final Rarity rarity;
  final PackTheme theme;
  final List<String> tags;
  final DateTime obtainedAt;

  const CollectibleCard({
    required this.id,
    required this.petId,
    required this.name,
    required this.imageUrl,
    this.description,
    required this.rarity,
    required this.theme,
    this.tags = const [],
    required this.obtainedAt,
  });

  factory CollectibleCard.fromJson(Map<String, dynamic> json) {
    return CollectibleCard(
      id: json['id'] as String? ?? '',
      petId: json['pet_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown Card',
      imageUrl: json['image_url'] as String? ?? '',
      description: json['description'] as String?,
      rarity: Rarity.fromString(json['rarity'] as String? ?? 'Common'),
      theme: PackTheme.fromString(json['theme'] as String? ?? 'Daily'),
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      obtainedAt: json['obtained_at'] != null
          ? DateTime.parse(json['obtained_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'name': name,
      'image_url': imageUrl,
      'description': description,
      'rarity': rarity.displayName,
      'theme': theme.displayName,
      'tags': tags,
      'obtained_at': obtainedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props =>
      [id, petId, name, imageUrl, description, rarity, theme, tags, obtainedAt];
}

/// 身体部位图片模型
class PetBodyImage extends Equatable {
  final String id;
  final String petId;
  final BodyPart bodyPart;
  final String imageUrl;
  final DateTime createdAt;

  const PetBodyImage({
    required this.id,
    required this.petId,
    required this.bodyPart,
    required this.imageUrl,
    required this.createdAt,
  });

  factory PetBodyImage.fromJson(Map<String, dynamic> json) {
    return PetBodyImage(
      id: json['id'] as String? ?? '',
      petId: json['pet_id'] as String? ?? '',
      bodyPart: BodyPart.fromString(json['body_part'] as String? ?? 'Other'),
      imageUrl: json['image_url'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'body_part': bodyPart.displayName,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, petId, bodyPart, imageUrl, createdAt];
}
