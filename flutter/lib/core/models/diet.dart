import 'package:equatable/equatable.dart';

/// 喂食类型
enum MealType {
  breakfast,
  lunch,
  dinner,
  snack,
  treat;

  String get displayName {
    switch (this) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
      case MealType.treat:
        return 'Treat';
    }
  }

  String get emoji {
    switch (this) {
      case MealType.breakfast:
        return '🌅';
      case MealType.lunch:
        return '☀️';
      case MealType.dinner:
        return '🌙';
      case MealType.snack:
        return '🍪';
      case MealType.treat:
        return '🦴';
    }
  }

  static MealType fromString(String value) {
    return MealType.values.firstWhere(
      (e) => e.displayName.toLowerCase() == value.toLowerCase(),
      orElse: () => MealType.snack,
    );
  }
}

/// 食物类型
enum FoodType {
  dryFood,
  wetFood,
  rawFood,
  homemade,
  treat,
  other;

  String get displayName {
    switch (this) {
      case FoodType.dryFood:
        return 'Dry Food';
      case FoodType.wetFood:
        return 'Wet Food';
      case FoodType.rawFood:
        return 'Raw Food';
      case FoodType.homemade:
        return 'Homemade';
      case FoodType.treat:
        return 'Treat';
      case FoodType.other:
        return 'Other';
    }
  }

  static FoodType fromString(String value) {
    return FoodType.values.firstWhere(
      (e) => e.displayName.toLowerCase() == value.toLowerCase(),
      orElse: () => FoodType.other,
    );
  }
}

/// 喂食记录
class FeedingLog extends Equatable {
  final String id;
  final String petId;
  final MealType mealType;
  final FoodType foodType;
  final String? foodName;
  final double? amount; // in grams
  final String? note;
  final DateTime feedingTime;
  final DateTime createdAt;

  const FeedingLog({
    required this.id,
    required this.petId,
    required this.mealType,
    required this.foodType,
    this.foodName,
    this.amount,
    this.note,
    required this.feedingTime,
    required this.createdAt,
  });

  factory FeedingLog.fromJson(Map<String, dynamic> json) {
    return FeedingLog(
      id: json['id']?.toString() ?? '',
      petId: json['pet_id']?.toString() ?? '',
      mealType: MealType.fromString(json['meal_type']?.toString() ?? 'Snack'),
      foodType: FoodType.fromString(json['food_type']?.toString() ?? 'Other'),
      foodName: json['food_name']?.toString(),
      amount: json['amount'] != null ? double.tryParse(json['amount'].toString()) : null,
      note: json['note']?.toString(),
      feedingTime: json['feeding_time'] != null
          ? DateTime.parse(json['feeding_time'].toString())
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'meal_type': mealType.displayName,
      'food_type': foodType.displayName,
      'food_name': foodName,
      'amount': amount,
      'note': note,
      'feeding_time': feedingTime.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, petId, mealType, foodType, foodName, amount, note, feedingTime, createdAt];
}

/// 饮水记录
class WaterLog extends Equatable {
  final String id;
  final String petId;
  final double amount; // in ml
  final DateTime logTime;
  final DateTime createdAt;

  const WaterLog({
    required this.id,
    required this.petId,
    required this.amount,
    required this.logTime,
    required this.createdAt,
  });

  factory WaterLog.fromJson(Map<String, dynamic> json) {
    return WaterLog(
      id: json['id']?.toString() ?? '',
      petId: json['pet_id']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      logTime: json['log_time'] != null
          ? DateTime.parse(json['log_time'].toString())
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'amount': amount,
      'log_time': logTime.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, petId, amount, logTime, createdAt];
}
