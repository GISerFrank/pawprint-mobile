import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../config/app_config.dart';
import 'service_providers.dart';
import 'pet_provider.dart';

/// 今日喂食记录
final todayFeedingLogsProvider = FutureProvider<List<FeedingLog>>((ref) async {
  final petId = ref.watch(selectedPetIdProvider);
  if (petId == null) return [];

  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  if (AppConfig.useLocalMode) {
    final localStorage = ref.watch(localStorageProvider);
    return localStorage.getFeedingLogs(petId, startOfDay, endOfDay);
  } else {
    final db = ref.watch(databaseServiceProvider);
    return db.getFeedingLogs(petId, startOfDay, endOfDay);
  }
});

/// 最近喂食记录 (7天)
final recentFeedingLogsProvider = FutureProvider<List<FeedingLog>>((ref) async {
  final petId = ref.watch(selectedPetIdProvider);
  if (petId == null) return [];

  final today = DateTime.now();
  final startDate = today.subtract(const Duration(days: 7));
  final endDate = today.add(const Duration(days: 1));

  if (AppConfig.useLocalMode) {
    final localStorage = ref.watch(localStorageProvider);
    return localStorage.getFeedingLogs(petId, startDate, endDate);
  } else {
    final db = ref.watch(databaseServiceProvider);
    return db.getFeedingLogs(petId, startDate, endDate);
  }
});

/// 今日饮水记录
final todayWaterLogsProvider = FutureProvider<List<WaterLog>>((ref) async {
  final petId = ref.watch(selectedPetIdProvider);
  if (petId == null) return [];

  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  if (AppConfig.useLocalMode) {
    final localStorage = ref.watch(localStorageProvider);
    return localStorage.getWaterLogs(petId, startOfDay, endOfDay);
  } else {
    final db = ref.watch(databaseServiceProvider);
    return db.getWaterLogs(petId, startOfDay, endOfDay);
  }
});

/// 今日饮水总量
final todayWaterTotalProvider = FutureProvider<double>((ref) async {
  final logs = await ref.watch(todayWaterLogsProvider.future);
  double total = 0.0;
  for (final log in logs) {
    total += log.amount;
  }
  return total;
});

/// Diet Notifier
class DietNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  DietNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> logFeeding({
    required String petId,
    required MealType mealType,
    required FoodType foodType,
    String? foodName,
    double? amount,
    String? note,
    DateTime? feedingTime,
  }) async {
    try {
      final log = FeedingLog(
        id: '',
        petId: petId,
        mealType: mealType,
        foodType: foodType,
        foodName: foodName,
        amount: amount,
        note: note,
        feedingTime: feedingTime ?? DateTime.now(),
        createdAt: DateTime.now(),
      );

      if (AppConfig.useLocalMode) {
        final localStorage = _ref.read(localStorageProvider);
        await localStorage.createFeedingLog(log);
      } else {
        final db = _ref.read(databaseServiceProvider);
        await db.createFeedingLog(log);
      }

      _ref.invalidate(todayFeedingLogsProvider);
      _ref.invalidate(recentFeedingLogsProvider);
    } catch (_) {}
  }

  Future<void> logWater({
    required String petId,
    required double amount,
  }) async {
    try {
      final log = WaterLog(
        id: '',
        petId: petId,
        amount: amount,
        logTime: DateTime.now(),
        createdAt: DateTime.now(),
      );

      if (AppConfig.useLocalMode) {
        final localStorage = _ref.read(localStorageProvider);
        await localStorage.createWaterLog(log);
      } else {
        final db = _ref.read(databaseServiceProvider);
        await db.createWaterLog(log);
      }

      _ref.invalidate(todayWaterLogsProvider);
      _ref.invalidate(todayWaterTotalProvider);
    } catch (_) {}
  }

  Future<void> deleteFeedingLog(String logId) async {
    try {
      if (AppConfig.useLocalMode) {
        final localStorage = _ref.read(localStorageProvider);
        await localStorage.deleteFeedingLog(logId);
      } else {
        final db = _ref.read(databaseServiceProvider);
        await db.deleteFeedingLog(logId);
      }
      _ref.invalidate(todayFeedingLogsProvider);
      _ref.invalidate(recentFeedingLogsProvider);
    } catch (_) {}
  }
}

final dietNotifierProvider =
    StateNotifierProvider<DietNotifier, AsyncValue<void>>((ref) {
  return DietNotifier(ref);
});
