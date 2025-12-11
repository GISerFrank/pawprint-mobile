import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'service_providers.dart';
import 'pet_provider.dart';
import 'auth_provider.dart';

/// 当前宠物的健康记录列表
final healthRecordsProvider = FutureProvider<List<HealthRecord>>((ref) async {
  final petId = ref.watch(selectedPetIdProvider);
  if (petId == null) return [];

  if (AppConfig.useLocalMode) {
    final localStorage = ref.watch(localStorageServiceProvider);
    return localStorage.getHealthRecords(petId);
  } else {
    final db = ref.watch(databaseServiceProvider);
    return db.getHealthRecords(petId);
  }
});

/// 体重记录（用于图表）
final weightRecordsProvider = FutureProvider<List<HealthRecord>>((ref) async {
  final petId = ref.watch(selectedPetIdProvider);
  if (petId == null) return [];

  if (AppConfig.useLocalMode) {
    final localStorage = ref.watch(localStorageServiceProvider);
    return localStorage.getWeightRecords(petId);
  } else {
    final db = ref.watch(databaseServiceProvider);
    return db.getWeightRecords(petId);
  }
});

/// 当前宠物的提醒列表
final remindersProvider = FutureProvider<List<Reminder>>((ref) async {
  final petId = ref.watch(selectedPetIdProvider);
  if (petId == null) return [];

  if (AppConfig.useLocalMode) {
    final localStorage = ref.watch(localStorageServiceProvider);
    return localStorage.getReminders(petId);
  } else {
    final db = ref.watch(databaseServiceProvider);
    return db.getReminders(petId);
  }
});

/// 未完成的预约（Appointment 类型且未完成）
final upcomingAppointmentsProvider = FutureProvider<List<Reminder>>((ref) async {
  final reminders = await ref.watch(remindersProvider.future);
  return reminders
      .where((r) => r.reminderType == ReminderType.appointment && !r.isCompleted)
      .toList()
    ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
});

/// 其他提醒（非 Appointment 或已完成）
final otherRemindersProvider = FutureProvider<List<Reminder>>((ref) async {
  final reminders = await ref.watch(remindersProvider.future);
  return reminders
      .where((r) => r.reminderType != ReminderType.appointment || r.isCompleted)
      .toList()
    ..sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      return a.scheduledAt.compareTo(b.scheduledAt);
    });
});

/// 健康记录管理 Notifier
class HealthRecordsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  HealthRecordsNotifier(this._ref) : super(const AsyncValue.data(null));

  /// 添加健康记录
  Future<HealthRecord> addRecord(HealthRecord record) async {
    state = const AsyncValue.loading();

    try {
      HealthRecord created;

      if (AppConfig.useLocalMode) {
        final localStorage = _ref.read(localStorageServiceProvider);
        created = await localStorage.createHealthRecord(record);
      } else {
        final db = _ref.read(databaseServiceProvider);
        created = await db.createHealthRecord(record);
      }

      _ref.invalidate(healthRecordsProvider);
      _ref.invalidate(weightRecordsProvider);

      state = const AsyncValue.data(null);
      return created;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// 删除健康记录
  Future<void> deleteRecord(String recordId) async {
    if (AppConfig.useLocalMode) {
      final localStorage = _ref.read(localStorageServiceProvider);
      await localStorage.deleteHealthRecord(recordId);
    } else {
      final db = _ref.read(databaseServiceProvider);
      await db.deleteHealthRecord(recordId);
    }
    _ref.invalidate(healthRecordsProvider);
    _ref.invalidate(weightRecordsProvider);
  }
}

/// 健康记录管理 Provider
final healthRecordsNotifierProvider = StateNotifierProvider<HealthRecordsNotifier, AsyncValue<void>>((ref) {
  return HealthRecordsNotifier(ref);
});

/// 提醒管理 Notifier
class RemindersNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  RemindersNotifier(this._ref) : super(const AsyncValue.data(null));

  /// 添加提醒
  Future<Reminder> addReminder(Reminder reminder) async {
    Reminder created;

    if (AppConfig.useLocalMode) {
      final localStorage = _ref.read(localStorageServiceProvider);
      created = await localStorage.createReminder(reminder);
    } else {
      final db = _ref.read(databaseServiceProvider);
      created = await db.createReminder(reminder);
    }

    _ref.invalidate(remindersProvider);
    return created;
  }

  /// 切换完成状态
  Future<void> toggleComplete(String reminderId, bool isCompleted) async {
    if (AppConfig.useLocalMode) {
      final localStorage = _ref.read(localStorageServiceProvider);
      await localStorage.toggleReminderComplete(reminderId, isCompleted);
    } else {
      final db = _ref.read(databaseServiceProvider);
      await db.toggleReminderComplete(reminderId, isCompleted);
    }
    _ref.invalidate(remindersProvider);
  }

  /// 删除提醒
  Future<void> deleteReminder(String reminderId) async {
    if (AppConfig.useLocalMode) {
      final localStorage = _ref.read(localStorageServiceProvider);
      await localStorage.deleteReminder(reminderId);
    } else {
      final db = _ref.read(databaseServiceProvider);
      await db.deleteReminder(reminderId);
    }
    _ref.invalidate(remindersProvider);
  }
}

/// 提醒管理 Provider
final remindersNotifierProvider = StateNotifierProvider<RemindersNotifier, AsyncValue<void>>((ref) {
  return RemindersNotifier(ref);
});