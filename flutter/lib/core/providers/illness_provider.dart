import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../config/app_config.dart';
import 'service_providers.dart';
import 'pet_provider.dart';

/// 当前活跃的生病记录
final activeIllnessProvider = FutureProvider<IllnessRecord?>((ref) async {
  final pet = await ref.watch(currentPetProvider.future);
  if (pet == null || pet.currentIllnessId == null) return null;

  if (AppConfig.useLocalMode) {
    final localStorage = ref.watch(localStorageProvider);
    return localStorage.getIllnessRecord(pet.currentIllnessId!);
  } else {
    final db = ref.watch(databaseServiceProvider);
    return db.getIllnessRecord(pet.currentIllnessId!);
  }
});

/// 宠物的所有生病历史记录
final illnessHistoryProvider = FutureProvider<List<IllnessRecord>>((ref) async {
  final petId = ref.watch(selectedPetIdProvider);
  if (petId == null) return [];

  if (AppConfig.useLocalMode) {
    final localStorage = ref.watch(localStorageProvider);
    return localStorage.getIllnessRecords(petId);
  } else {
    final db = ref.watch(databaseServiceProvider);
    return db.getIllnessRecords(petId);
  }
});

/// 当前生病记录的用药列表
final medicationsProvider = FutureProvider<List<Medication>>((ref) async {
  final illness = await ref.watch(activeIllnessProvider.future);
  if (illness == null) return [];

  if (AppConfig.useLocalMode) {
    final localStorage = ref.watch(localStorageProvider);
    return localStorage.getMedications(illness.id);
  } else {
    final db = ref.watch(databaseServiceProvider);
    return db.getMedications(illness.id);
  }
});

/// 今日的用药打卡记录
final todayMedicationLogsProvider =
    FutureProvider<List<MedicationLog>>((ref) async {
  final petId = ref.watch(selectedPetIdProvider);
  if (petId == null) return [];

  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  if (AppConfig.useLocalMode) {
    final localStorage = ref.watch(localStorageProvider);
    return localStorage.getMedicationLogs(petId, startOfDay, endOfDay);
  } else {
    final db = ref.watch(databaseServiceProvider);
    return db.getMedicationLogs(petId, startOfDay, endOfDay);
  }
});

/// 当前生病记录的每日症状追踪
final dailySymptomLogsProvider =
    FutureProvider<List<DailySymptomLog>>((ref) async {
  final illness = await ref.watch(activeIllnessProvider.future);
  if (illness == null) return [];

  if (AppConfig.useLocalMode) {
    final localStorage = ref.watch(localStorageProvider);
    return localStorage.getDailySymptomLogs(illness.id);
  } else {
    final db = ref.watch(databaseServiceProvider);
    return db.getDailySymptomLogs(illness.id);
  }
});

/// 生病模式 Notifier
class IllnessNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  IllnessNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> startIllness({
    required String petId,
    required SickType sickType,
    required String symptoms,
    String? diagnosis,
    String? vetNotes,
    DateTime? followUpDate,
  }) async {
    state = const AsyncValue.loading();
    try {
      final now = DateTime.now();
      final illness = IllnessRecord(
        id: '',
        petId: petId,
        startDate: now,
        sickType: sickType,
        symptoms: symptoms,
        diagnosis: diagnosis,
        vetNotes: vetNotes,
        followUpDate: followUpDate,
        createdAt: now,
      );

      IllnessRecord created;
      if (AppConfig.useLocalMode) {
        final localStorage = _ref.read(localStorageProvider);
        created = await localStorage.createIllnessRecord(illness);
        await localStorage.updatePet(petId, {
          'health_status': HealthStatus.sick.displayName,
          'current_illness_id': created.id,
        });
      } else {
        final db = _ref.read(databaseServiceProvider);
        created = await db.createIllnessRecord(illness);
        await db.updatePet(petId, {
          'health_status': HealthStatus.sick.displayName,
          'current_illness_id': created.id,
        });
      }

      _ref.invalidate(currentPetProvider);
      _ref.invalidate(activeIllnessProvider);
      _ref.invalidate(illnessHistoryProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateIllness({
    required String illnessId,
    SickType? sickType,
    String? symptoms,
    String? diagnosis,
    String? vetNotes,
    DateTime? followUpDate,
  }) async {
    state = const AsyncValue.loading();
    try {
      final updates = <String, dynamic>{};
      if (sickType != null) updates['sick_type'] = sickType.displayName;
      if (symptoms != null) updates['symptoms'] = symptoms;
      if (diagnosis != null) updates['diagnosis'] = diagnosis;
      if (vetNotes != null) updates['vet_notes'] = vetNotes;
      if (followUpDate != null)
        updates['follow_up_date'] = followUpDate.toIso8601String();

      if (AppConfig.useLocalMode) {
        final localStorage = _ref.read(localStorageProvider);
        await localStorage.updateIllnessRecord(illnessId, updates);
      } else {
        final db = _ref.read(databaseServiceProvider);
        await db.updateIllnessRecord(illnessId, updates);
      }

      _ref.invalidate(activeIllnessProvider);
      _ref.invalidate(illnessHistoryProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markRecovered({
    required String petId,
    required String illnessId,
    String? recoveryNote,
  }) async {
    state = const AsyncValue.loading();
    try {
      final now = DateTime.now();
      if (AppConfig.useLocalMode) {
        final localStorage = _ref.read(localStorageProvider);
        await localStorage.updateIllnessRecord(illnessId, {
          'end_date': now.toIso8601String(),
          'recovery_note': recoveryNote,
        });
        await localStorage.updatePet(petId, {
          'health_status': HealthStatus.healthy.displayName,
          'current_illness_id': null,
        });
      } else {
        final db = _ref.read(databaseServiceProvider);
        await db.updateIllnessRecord(illnessId, {
          'end_date': now.toIso8601String(),
          'recovery_note': recoveryNote,
        });
        await db.updatePet(petId, {
          'health_status': HealthStatus.healthy.displayName,
          'current_illness_id': null,
        });
      }

      _ref.invalidate(currentPetProvider);
      _ref.invalidate(activeIllnessProvider);
      _ref.invalidate(illnessHistoryProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addMedication({
    required String illnessId,
    required String petId,
    required String name,
    String? dosage,
    required String frequency,
    required int timesPerDay,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    try {
      final medication = Medication(
        id: '',
        illnessId: illnessId,
        petId: petId,
        name: name,
        dosage: dosage,
        frequency: frequency,
        timesPerDay: timesPerDay,
        startDate: startDate,
        endDate: endDate,
        createdAt: DateTime.now(),
      );

      if (AppConfig.useLocalMode) {
        final localStorage = _ref.read(localStorageProvider);
        await localStorage.createMedication(medication);
      } else {
        final db = _ref.read(databaseServiceProvider);
        await db.createMedication(medication);
      }
      _ref.invalidate(medicationsProvider);
    } catch (_) {}
  }

  Future<void> deleteMedication(String medicationId) async {
    try {
      if (AppConfig.useLocalMode) {
        final localStorage = _ref.read(localStorageProvider);
        await localStorage.deleteMedication(medicationId);
      } else {
        final db = _ref.read(databaseServiceProvider);
        await db.deleteMedication(medicationId);
      }
      _ref.invalidate(medicationsProvider);
    } catch (_) {}
  }

  Future<void> logMedicationTaken({
    required String medicationId,
    required String petId,
    required DateTime scheduledTime,
  }) async {
    try {
      final log = MedicationLog(
        id: '',
        medicationId: medicationId,
        petId: petId,
        scheduledTime: scheduledTime,
        takenTime: DateTime.now(),
        isTaken: true,
        createdAt: DateTime.now(),
      );

      if (AppConfig.useLocalMode) {
        final localStorage = _ref.read(localStorageProvider);
        await localStorage.createMedicationLog(log);
      } else {
        final db = _ref.read(databaseServiceProvider);
        await db.createMedicationLog(log);
      }
      _ref.invalidate(todayMedicationLogsProvider);
    } catch (_) {}
  }

  /// 原有的底层方法，保留以兼容其他可能的调用
  Future<void> logDailySymptom({
    required String illnessId,
    required String petId,
    required SymptomLevel level,
    String? note,
  }) async {
    try {
      final today = DateTime.now();
      final log = DailySymptomLog(
        id: '',
        illnessId: illnessId,
        petId: petId,
        date: DateTime(today.year, today.month, today.day),
        level: level,
        note: note,
        createdAt: today,
      );

      if (AppConfig.useLocalMode) {
        final localStorage = _ref.read(localStorageProvider);
        await localStorage.createDailySymptomLog(log);
      } else {
        final db = _ref.read(databaseServiceProvider);
        await db.createDailySymptomLog(log);
      }
      _ref.invalidate(dailySymptomLogsProvider);
    } catch (_) {}
  }

  /// 新增：适配 UI 调用的添加症状日志方法
  Future<void> addSymptomLog({
    required String illnessId,
    required int overallFeeling,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      // 获取当前选中的宠物ID
      final pet = _ref.read(currentPetProvider).value;
      if (pet == null) throw Exception('No pet selected');

      // 将 UI 的 1-5 评分映射到 SymptomLevel 枚举
      // 假设 SymptomLevel 顺序对应评分，或者根据你的 models.dart 调整逻辑
      final levelIndex =
          (overallFeeling - 1).clamp(0, SymptomLevel.values.length - 1);
      final level = SymptomLevel.values[levelIndex];

      await logDailySymptom(
        illnessId: illnessId,
        petId: pet.id,
        level: level,
        note: notes,
      );

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      // 必须 rethrow 才能让 UI 层的 try-catch 捕获到错误并显示 SnackBar
      rethrow;
    }
  }
}

final illnessNotifierProvider =
    StateNotifierProvider<IllnessNotifier, AsyncValue<void>>((ref) {
  return IllnessNotifier(ref);
});
