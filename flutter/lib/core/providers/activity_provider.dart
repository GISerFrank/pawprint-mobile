import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../config/app_config.dart';
import 'service_providers.dart';
import 'pet_provider.dart';

/// 今日活动记录
final todayActivityLogsProvider =
    FutureProvider<List<ActivityLog>>((ref) async {
  final petId = ref.watch(selectedPetIdProvider);
  if (petId == null) return [];

  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  if (AppConfig.useLocalMode) {
    final localStorage = ref.watch(localStorageProvider);
    return localStorage.getActivityLogs(petId, startOfDay, endOfDay);
  } else {
    final db = ref.watch(databaseServiceProvider);
    return db.getActivityLogs(petId, startOfDay, endOfDay);
  }
});

/// 最近活动记录 (7天)
final recentActivityLogsProvider =
    FutureProvider<List<ActivityLog>>((ref) async {
  final petId = ref.watch(selectedPetIdProvider);
  if (petId == null) return [];

  final today = DateTime.now();
  final startDate = today.subtract(const Duration(days: 7));
  final endDate = today.add(const Duration(days: 1));

  if (AppConfig.useLocalMode) {
    final localStorage = ref.watch(localStorageProvider);
    return localStorage.getActivityLogs(petId, startDate, endDate);
  } else {
    final db = ref.watch(databaseServiceProvider);
    return db.getActivityLogs(petId, startDate, endDate);
  }
});

/// 今日活动总时长 (分钟)
final todayActivityTotalProvider = FutureProvider<int>((ref) async {
  final logs = await ref.watch(todayActivityLogsProvider.future);
  int total = 0;
  for (final log in logs) {
    total += log.durationMinutes;
  }
  return total;
});

/// 本周活动统计
final weeklyActivityStatsProvider =
    FutureProvider<Map<String, int>>((ref) async {
  final logs = await ref.watch(recentActivityLogsProvider.future);

  final Map<String, int> stats = {};
  for (final type in ActivityType.values) {
    stats[type.displayName] = 0;
  }

  for (final log in logs) {
    stats[log.activityType.displayName] =
        (stats[log.activityType.displayName] ?? 0) + log.durationMinutes;
  }

  return stats;
});

/// Activity Notifier
class ActivityNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  ActivityNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> logActivity({
    required String petId,
    required ActivityType activityType,
    required ActivityIntensity intensity,
    required int durationMinutes,
    double? distanceKm,
    String? note,
    DateTime? activityTime,
  }) async {
    try {
      final log = ActivityLog(
        id: '',
        petId: petId,
        activityType: activityType,
        intensity: intensity,
        durationMinutes: durationMinutes,
        distanceKm: distanceKm,
        note: note,
        activityTime: activityTime ?? DateTime.now(),
        createdAt: DateTime.now(),
      );

      if (AppConfig.useLocalMode) {
        final localStorage = _ref.read(localStorageProvider);
        await localStorage.createActivityLog(log);
      } else {
        final db = _ref.read(databaseServiceProvider);
        await db.createActivityLog(log);
      }

      _ref.invalidate(todayActivityLogsProvider);
      _ref.invalidate(recentActivityLogsProvider);
      _ref.invalidate(todayActivityTotalProvider);
      _ref.invalidate(weeklyActivityStatsProvider);
    } catch (_) {}
  }

  Future<void> deleteActivityLog(String logId) async {
    try {
      if (AppConfig.useLocalMode) {
        final localStorage = _ref.read(localStorageProvider);
        await localStorage.deleteActivityLog(logId);
      } else {
        final db = _ref.read(databaseServiceProvider);
        await db.deleteActivityLog(logId);
      }
      _ref.invalidate(todayActivityLogsProvider);
      _ref.invalidate(recentActivityLogsProvider);
      _ref.invalidate(todayActivityTotalProvider);
      _ref.invalidate(weeklyActivityStatsProvider);
    } catch (_) {}
  }
}

final activityNotifierProvider =
    StateNotifierProvider<ActivityNotifier, AsyncValue<void>>((ref) {
  return ActivityNotifier(ref);
});
