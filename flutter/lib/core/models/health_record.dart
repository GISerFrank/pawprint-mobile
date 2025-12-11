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
    return HealthRecord(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      recordType: HealthRecordType.fromString(json['record_type'] as String),
      recordDate: DateTime.parse(json['record_date'] as String),
      value: json['value'] as String?,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pet_id': petId,
      'record_type': recordType.displayName,
      'record_date': recordDate.toIso8601String().split('T').first,
      'value': value,
      'note': note,
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
    return Reminder(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      title: json['title'] as String,
      reminderType: ReminderType.fromString(json['reminder_type'] as String),
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      isCompleted: json['is_completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pet_id': petId,
      'title': title,
      'reminder_type': reminderType.displayName,
      'scheduled_at': scheduledAt.toIso8601String(),
      'is_completed': isCompleted,
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
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      symptoms: json['symptoms'] as String,
      bodyPart: BodyPart.fromString(json['body_part'] as String),
      imageUrl: json['image_url'] as String?,
      analysisResult: json['analysis_result'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pet_id': petId,
      'symptoms': symptoms,
      'body_part': bodyPart.displayName,
      'image_url': imageUrl,
      'analysis_result': analysisResult,
    };
  }

  @override
  List<Object?> get props => [id, petId, symptoms, bodyPart, imageUrl, analysisResult, createdAt];
}
