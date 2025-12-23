import 'package:equatable/equatable.dart';

/// 活动类型
enum ActivityType {
  walk,
  run,
  play,
  training,
  swim,
  grooming,
  other;

  String get displayName {
    switch (this) {
      case ActivityType.walk:
        return 'Walk';
      case ActivityType.run:
        return 'Run';
      case ActivityType.play:
        return 'Play';
      case ActivityType.training:
        return 'Training';
      case ActivityType.swim:
        return 'Swim';
      case ActivityType.grooming:
        return 'Grooming';
      case ActivityType.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case ActivityType.walk:
        return '🚶';
      case ActivityType.run:
        return '🏃';
      case ActivityType.play:
        return '🎾';
      case ActivityType.training:
        return '🎓';
      case ActivityType.swim:
        return '🏊';
      case ActivityType.grooming:
        return '✂️';
      case ActivityType.other:
        return '📝';
    }
  }

  static ActivityType fromString(String value) {
    return ActivityType.values.firstWhere(
      (e) => e.displayName.toLowerCase() == value.toLowerCase(),
      orElse: () => ActivityType.other,
    );
  }
}

/// 活动强度
enum ActivityIntensity {
  light,
  moderate,
  intense;

  String get displayName {
    switch (this) {
      case ActivityIntensity.light:
        return 'Light';
      case ActivityIntensity.moderate:
        return 'Moderate';
      case ActivityIntensity.intense:
        return 'Intense';
    }
  }

  String get emoji {
    switch (this) {
      case ActivityIntensity.light:
        return '🟢';
      case ActivityIntensity.moderate:
        return '🟡';
      case ActivityIntensity.intense:
        return '🔴';
    }
  }

  static ActivityIntensity fromString(String value) {
    return ActivityIntensity.values.firstWhere(
      (e) => e.displayName.toLowerCase() == value.toLowerCase(),
      orElse: () => ActivityIntensity.moderate,
    );
  }
}

/// 活动记录
class ActivityLog extends Equatable {
  final String id;
  final String petId;
  final ActivityType activityType;
  final ActivityIntensity intensity;
  final int durationMinutes;
  final double? distanceKm;
  final String? note;
  final DateTime activityTime;
  final DateTime createdAt;

  const ActivityLog({
    required this.id,
    required this.petId,
    required this.activityType,
    required this.intensity,
    required this.durationMinutes,
    this.distanceKm,
    this.note,
    required this.activityTime,
    required this.createdAt,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id']?.toString() ?? '',
      petId: json['pet_id']?.toString() ?? '',
      activityType: ActivityType.fromString(json['activity_type']?.toString() ?? 'Other'),
      intensity: ActivityIntensity.fromString(json['intensity']?.toString() ?? 'Moderate'),
      durationMinutes: int.tryParse(json['duration_minutes']?.toString() ?? '0') ?? 0,
      distanceKm: json['distance_km'] != null ? double.tryParse(json['distance_km'].toString()) : null,
      note: json['note']?.toString(),
      activityTime: json['activity_time'] != null
          ? DateTime.parse(json['activity_time'].toString())
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
      'activity_type': activityType.displayName,
      'intensity': intensity.displayName,
      'duration_minutes': durationMinutes,
      'distance_km': distanceKm,
      'note': note,
      'activity_time': activityTime.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// 格式化时长显示
  String get formattedDuration {
    if (durationMinutes < 60) {
      return '$durationMinutes min';
    }
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
  }

  @override
  List<Object?> get props => [id, petId, activityType, intensity, durationMinutes, distanceKm, note, activityTime, createdAt];
}
