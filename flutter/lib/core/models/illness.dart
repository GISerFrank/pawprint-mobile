import 'package:equatable/equatable.dart';
import 'enums.dart';

/// 生病记录模型
class IllnessRecord extends Equatable {
  final String id;
  final String petId;
  final DateTime startDate;
  final DateTime? endDate;
  final SickType sickType;
  final String symptoms;
  final String? diagnosis;
  final String? vetNotes;
  final DateTime? followUpDate;
  final String? recoveryNote;
  final DateTime createdAt;

  const IllnessRecord({
    required this.id,
    required this.petId,
    required this.startDate,
    this.endDate,
    required this.sickType,
    required this.symptoms,
    this.diagnosis,
    this.vetNotes,
    this.followUpDate,
    this.recoveryNote,
    required this.createdAt,
  });

  bool get isActive => endDate == null;

  int get daysSick {
    final end = endDate ?? DateTime.now();
    return end.difference(startDate).inDays + 1;
  }

  factory IllnessRecord.fromJson(Map<String, dynamic> json) {
    return IllnessRecord(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      sickType: SickType.fromString(json['sick_type'] as String),
      symptoms: json['symptoms'] as String,
      diagnosis: json['diagnosis'] as String?,
      vetNotes: json['vet_notes'] as String?,
      followUpDate: json['follow_up_date'] != null ? DateTime.parse(json['follow_up_date'] as String) : null,
      recoveryNote: json['recovery_note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'sick_type': sickType.displayName,
      'symptoms': symptoms,
      'diagnosis': diagnosis,
      'vet_notes': vetNotes,
      'follow_up_date': followUpDate?.toIso8601String(),
      'recovery_note': recoveryNote,
      'created_at': createdAt.toIso8601String(),
    };
  }

  IllnessRecord copyWith({
    String? id,
    String? petId,
    DateTime? startDate,
    DateTime? endDate,
    SickType? sickType,
    String? symptoms,
    String? diagnosis,
    String? vetNotes,
    DateTime? followUpDate,
    String? recoveryNote,
    DateTime? createdAt,
    bool clearEndDate = false,
  }) {
    return IllnessRecord(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      sickType: sickType ?? this.sickType,
      symptoms: symptoms ?? this.symptoms,
      diagnosis: diagnosis ?? this.diagnosis,
      vetNotes: vetNotes ?? this.vetNotes,
      followUpDate: followUpDate ?? this.followUpDate,
      recoveryNote: recoveryNote ?? this.recoveryNote,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, petId, startDate, endDate, sickType, symptoms, diagnosis, vetNotes, followUpDate, recoveryNote, createdAt];
}

/// 用药记录模型
class Medication extends Equatable {
  final String id;
  final String illnessId;
  final String petId;
  final String name;
  final String? dosage;
  final String frequency;
  final int timesPerDay;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime createdAt;

  const Medication({
    required this.id,
    required this.illnessId,
    required this.petId,
    required this.name,
    this.dosage,
    required this.frequency,
    required this.timesPerDay,
    required this.startDate,
    this.endDate,
    required this.createdAt,
  });

  bool get isActive {
    if (endDate == null) return true;
    return DateTime.now().isBefore(endDate!);
  }

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'] as String,
      illnessId: json['illness_id'] as String,
      petId: json['pet_id'] as String,
      name: json['name'] as String,
      dosage: json['dosage'] as String?,
      frequency: json['frequency'] as String,
      timesPerDay: json['times_per_day'] as int? ?? 1,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'illness_id': illnessId,
      'pet_id': petId,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'times_per_day': timesPerDay,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, illnessId, petId, name, dosage, frequency, timesPerDay, startDate, endDate, createdAt];
}

/// 用药打卡记录
class MedicationLog extends Equatable {
  final String id;
  final String medicationId;
  final String petId;
  final DateTime scheduledTime;
  final DateTime? takenTime;
  final bool isTaken;
  final bool isSkipped;
  final String? note;
  final DateTime createdAt;

  const MedicationLog({
    required this.id,
    required this.medicationId,
    required this.petId,
    required this.scheduledTime,
    this.takenTime,
    this.isTaken = false,
    this.isSkipped = false,
    this.note,
    required this.createdAt,
  });

  factory MedicationLog.fromJson(Map<String, dynamic> json) {
    return MedicationLog(
      id: json['id'] as String,
      medicationId: json['medication_id'] as String,
      petId: json['pet_id'] as String,
      scheduledTime: DateTime.parse(json['scheduled_time'] as String),
      takenTime: json['taken_time'] != null ? DateTime.parse(json['taken_time'] as String) : null,
      isTaken: json['is_taken'] as bool? ?? false,
      isSkipped: json['is_skipped'] as bool? ?? false,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medication_id': medicationId,
      'pet_id': petId,
      'scheduled_time': scheduledTime.toIso8601String(),
      'taken_time': takenTime?.toIso8601String(),
      'is_taken': isTaken,
      'is_skipped': isSkipped,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, medicationId, petId, scheduledTime, takenTime, isTaken, isSkipped, note, createdAt];
}

/// 每日症状追踪记录
class DailySymptomLog extends Equatable {
  final String id;
  final String illnessId;
  final String petId;
  final DateTime date;
  final SymptomLevel level;
  final String? note;
  final DateTime createdAt;

  const DailySymptomLog({
    required this.id,
    required this.illnessId,
    required this.petId,
    required this.date,
    required this.level,
    this.note,
    required this.createdAt,
  });

  factory DailySymptomLog.fromJson(Map<String, dynamic> json) {
    return DailySymptomLog(
      id: json['id'] as String,
      illnessId: json['illness_id'] as String,
      petId: json['pet_id'] as String,
      date: DateTime.parse(json['date'] as String),
      level: SymptomLevel.fromString(json['level'] as String),
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'illness_id': illnessId,
      'pet_id': petId,
      'date': date.toIso8601String(),
      'level': level.displayName,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  DailySymptomLog copyWith({
    String? id,
    String? illnessId,
    String? petId,
    DateTime? date,
    SymptomLevel? level,
    String? note,
    DateTime? createdAt,
  }) {
    return DailySymptomLog(
      id: id ?? this.id,
      illnessId: illnessId ?? this.illnessId,
      petId: petId ?? this.petId,
      date: date ?? this.date,
      level: level ?? this.level,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, illnessId, petId, date, level, note, createdAt];
}
