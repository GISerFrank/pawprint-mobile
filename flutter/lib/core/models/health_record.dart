import 'package:equatable/equatable.dart';
import 'enums.dart';

/// 健康记录模型
class HealthRecord extends Equatable {
  final String id;
  final String petId;
  final HealthRecordType recordType;
  final DateTime recordDate;
  final String? value;
  final String? note;
  final DateTime createdAt;

  const HealthRecord({
    required this.id,
    required this.petId,
    required this.recordType,
    required this.recordDate,
    this.value,
    this.note,
    required this.createdAt,
  });

  factory HealthRecord.fromJson(Map<String, dynamic> json) {
    DateTime? recordDate;
    if (json['record_date'] != null) {
      try {
        recordDate = DateTime.parse(json['record_date'].toString());
      } catch (_) {}
    }
    
    DateTime? createdAt;
    if (json['created_at'] != null) {
      try {
        createdAt = DateTime.parse(json['created_at'].toString());
      } catch (_) {}
    }
    
    return HealthRecord(
      id: json['id']?.toString() ?? '',
      petId: json['pet_id']?.toString() ?? '',
      recordType: HealthRecordType.fromString(json['record_type']?.toString() ?? 'Weight'),
      recordDate: recordDate ?? DateTime.now(),
      value: json['value']?.toString(),
      note: json['note']?.toString(),
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'record_type': recordType.displayName,
      'record_date': recordDate.toIso8601String().split('T').first,
      'value': value,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  HealthRecord copyWith({
    String? id,
    String? petId,
    HealthRecordType? recordType,
    DateTime? recordDate,
    String? value,
    String? note,
    DateTime? createdAt,
  }) {
    return HealthRecord(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      recordType: recordType ?? this.recordType,
      recordDate: recordDate ?? this.recordDate,
      value: value ?? this.value,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, petId, recordType, recordDate, value, note, createdAt];
}

/// 提醒模型
class Reminder extends Equatable {
  final String id;
  final String petId;
  final String title;
  final ReminderType reminderType;
  final DateTime scheduledAt;
  final bool isCompleted;
  final DateTime createdAt;

  const Reminder({
    required this.id,
    required this.petId,
    required this.title,
    required this.reminderType,
    required this.scheduledAt,
    this.isCompleted = false,
    required this.createdAt,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    DateTime? scheduledAt;
    if (json['scheduled_at'] != null) {
      try {
        scheduledAt = DateTime.parse(json['scheduled_at'].toString());
      } catch (_) {}
    }
    
    DateTime? createdAt;
    if (json['created_at'] != null) {
      try {
        createdAt = DateTime.parse(json['created_at'].toString());
      } catch (_) {}
    }
    
    return Reminder(
      id: json['id']?.toString() ?? '',
      petId: json['pet_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      reminderType: ReminderType.fromString(json['reminder_type']?.toString() ?? 'Other'),
      scheduledAt: scheduledAt ?? DateTime.now(),
      isCompleted: json['is_completed'] as bool? ?? false,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'title': title,
      'reminder_type': reminderType.displayName,
      'scheduled_at': scheduledAt.toIso8601String(),
      'is_completed': isCompleted,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Reminder copyWith({
    String? id,
    String? petId,
    String? title,
    ReminderType? reminderType,
    DateTime? scheduledAt,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      title: title ?? this.title,
      reminderType: reminderType ?? this.reminderType,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// 是否已过期
  bool get isOverdue => !isCompleted && scheduledAt.isBefore(DateTime.now());

  /// 是否是今天
  bool get isToday {
    final now = DateTime.now();
    return scheduledAt.year == now.year &&
        scheduledAt.month == now.month &&
        scheduledAt.day == now.day;
  }

  @override
  List<Object?> get props => [id, petId, title, reminderType, scheduledAt, isCompleted, createdAt];
}

/// AI 分析会话模型
class AIAnalysisSession extends Equatable {
  final String id;
  final String petId;
  final String symptoms;
  final BodyPart bodyPart;
  final String? imageUrl;
  final String analysisResult;
  final DateTime createdAt;

  const AIAnalysisSession({
    required this.id,
    required this.petId,
    required this.symptoms,
    required this.bodyPart,
    this.imageUrl,
    required this.analysisResult,
    required this.createdAt,
  });

  factory AIAnalysisSession.fromJson(Map<String, dynamic> json) {
    return AIAnalysisSession(
      id: json['id'] as String? ?? '',
      petId: json['pet_id'] as String? ?? '',
      symptoms: json['symptoms'] as String? ?? '',
      bodyPart: BodyPart.fromString(json['body_part'] as String? ?? 'Other'),
      imageUrl: json['image_url'] as String?,
      analysisResult: json['analysis_result'] as String? ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'symptoms': symptoms,
      'body_part': bodyPart.displayName,
      'image_url': imageUrl,
      'analysis_result': analysisResult,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, petId, symptoms, bodyPart, imageUrl, analysisResult, createdAt];
}