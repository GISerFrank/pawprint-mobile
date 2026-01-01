import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../config/app_config.dart';
import 'service_providers.dart';
import 'pet_provider.dart';

/// ============================================
/// Metric Providers
/// ============================================

/// 当前宠物的所有启用指标
final careMetricsProvider = FutureProvider<List<CareMetric>>((ref) async {
  final pet = await ref.watch(currentPetProvider.future);
  if (pet == null) return [];

  if (AppConfig.useLocalMode) {
    final localStorage = ref.watch(localStorageProvider);
    return localStorage.getCareMetrics(pet.id);
  } else {
    final db = ref.watch(databaseServiceProvider);
    return db.getCareMetrics(pet.id);
  }
});

/// 按分类分组的指标
final metricsByCategoryProvider =
    Provider<Map<CareCategory, List<CareMetric>>>((ref) {
  final metricsAsync = ref.watch(careMetricsProvider);

  return metricsAsync.maybeWhen(
    data: (metrics) {
      final map = <CareCategory, List<CareMetric>>{};
      for (final category in CareCategory.values) {
        map[category] = metrics
            .where((m) => m.category == category && m.isEnabled)
            .toList()
          ..sort((a, b) => a.priority.compareTo(b.priority));
      }
      return map;
    },
    orElse: () => {},
  );
});

/// 今日任务列表
final todayTasksProvider = FutureProvider<List<DailyTask>>((ref) async {
  final pet = await ref.watch(currentPetProvider.future);
  if (pet == null) return [];

  final metrics = await ref.watch(careMetricsProvider.future);
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  // 获取今日所有记录
  List<MetricLog> todayLogs;
  if (AppConfig.useLocalMode) {
    final localStorage = ref.watch(localStorageProvider);
    todayLogs = await localStorage.getMetricLogs(pet.id, startOfDay, endOfDay);
  } else {
    final db = ref.watch(databaseServiceProvider);
    todayLogs = await db.getMetricLogs(pet.id, startOfDay, endOfDay);
  }

  // 构建任务列表
  final tasks = <DailyTask>[];

  for (final metric in metrics.where((m) => m.isEnabled)) {
    // 检查该指标是否需要今日完成
    if (_shouldShowToday(metric, today)) {
      // 查找今日是否已完成
      final log = todayLogs.where((l) => l.metricId == metric.id).firstOrNull;

      tasks.add(DailyTask(
        metric: metric,
        scheduledDate: today,
        completedLog: log,
        scheduledTime: _getScheduledTime(metric),
      ));

      // 如果是每天多次的任务，添加多个
      if (metric.frequency == MetricFrequency.twiceDaily) {
        final secondLog =
            todayLogs.where((l) => l.metricId == metric.id).skip(1).firstOrNull;
        tasks.add(DailyTask(
          metric: metric,
          scheduledDate: today,
          completedLog: secondLog,
          scheduledTime: 18, // 下午6点
        ));
      } else if (metric.frequency == MetricFrequency.threeTimesDaily) {
        for (var i = 1; i < 3; i++) {
          final extraLog = todayLogs
              .where((l) => l.metricId == metric.id)
              .skip(i)
              .firstOrNull;
          tasks.add(DailyTask(
            metric: metric,
            scheduledDate: today,
            completedLog: extraLog,
            scheduledTime: i == 1 ? 12 : 18,
          ));
        }
      }
    }
  }

  // 按时间和优先级排序
  tasks.sort((a, b) {
    final timeA = a.scheduledTime ?? 99;
    final timeB = b.scheduledTime ?? 99;
    if (timeA != timeB) return timeA.compareTo(timeB);
    return a.metric.priority.compareTo(b.metric.priority);
  });

  return tasks;
});

/// 今日完成进度
final todayProgressProvider =
    Provider<({int completed, int total, double percentage})>((ref) {
  final tasksAsync = ref.watch(todayTasksProvider);

  return tasksAsync.maybeWhen(
    data: (tasks) {
      final completed = tasks.where((t) => t.isCompleted).length;
      final total = tasks.length;
      final percentage = total > 0 ? completed / total : 0.0;
      return (completed: completed, total: total, percentage: percentage);
    },
    orElse: () => (completed: 0, total: 0, percentage: 0.0),
  );
});

/// 计算综合健康评分
final wellnessScoreProvider = FutureProvider<WellnessScore>((ref) async {
  final pet = await ref.watch(currentPetProvider.future);
  if (pet == null) {
    return WellnessScore(
      overall: 100,
      wellnessScore: 100,
      nutritionScore: 100,
      enrichmentScore: 100,
      careScore: 100,
      calculatedAt: DateTime.now(),
    );
  }

  final metrics = await ref.watch(careMetricsProvider.future);
  final today = DateTime.now();
  final weekAgo = today.subtract(const Duration(days: 7));

  // 获取过去一周的记录
  List<MetricLog> weekLogs;
  if (AppConfig.useLocalMode) {
    final localStorage = ref.watch(localStorageProvider);
    weekLogs = await localStorage.getMetricLogs(pet.id, weekAgo, today);
  } else {
    final db = ref.watch(databaseServiceProvider);
    weekLogs = await db.getMetricLogs(pet.id, weekAgo, today);
  }

  // 如果没有任何记录，默认满分
  if (weekLogs.isEmpty) {
    return WellnessScore(
      overall: 100,
      wellnessScore: 100,
      nutritionScore: 100,
      enrichmentScore: 100,
      careScore: 100,
      calculatedAt: DateTime.now(),
    );
  }

  // 计算各分类得分
  double calculateCategoryScore(CareCategory category) {
    final categoryMetrics =
        metrics.where((m) => m.category == category && m.isEnabled).toList();
    if (categoryMetrics.isEmpty) return 100;

    // 检查该分类是否有记录
    final categoryLogs = weekLogs
        .where((l) => categoryMetrics.any((m) => m.id == l.metricId))
        .toList();

    // 该分类没有记录，默认满分
    if (categoryLogs.isEmpty) return 100;

    double totalScore = 0;
    int metricCount = 0;

    for (final metric in categoryMetrics) {
      final expectedCount = _getExpectedCountForWeek(metric.frequency);
      if (expectedCount == 0) continue;

      final actualCount = weekLogs.where((l) => l.metricId == metric.id).length;
      final completion = (actualCount / expectedCount).clamp(0.0, 1.0);

      // 权重：pinned 指标权重更高
      final weight = metric.isPinned ? 1.5 : 1.0;
      totalScore += completion * 100 * weight;
      metricCount++;
    }

    return metricCount > 0 ? totalScore / metricCount : 100;
  }

  final wellnessScore = calculateCategoryScore(CareCategory.wellness);
  final nutritionScore = calculateCategoryScore(CareCategory.nutrition);
  final enrichmentScore = calculateCategoryScore(CareCategory.enrichment);
  final careScore = calculateCategoryScore(CareCategory.care);

  // 考虑宠物是否生病
  final healthPenalty = pet.isSick ? 0.8 : 1.0;

  final overall =
      ((wellnessScore + nutritionScore + enrichmentScore + careScore) /
              4 *
              healthPenalty)
          .clamp(0.0, 100.0);

  // 生成改进建议
  final improvements = <String>[];
  if (wellnessScore < 70)
    improvements.add('Track health metrics more regularly');
  if (nutritionScore < 70) improvements.add('Log meals and water intake daily');
  if (enrichmentScore < 70)
    improvements.add('Increase activity and enrichment time');
  if (careScore < 70)
    improvements.add('Keep up with grooming and care routines');
  if (pet.isSick)
    improvements.add('Focus on recovery - follow vet recommendations');

  return WellnessScore(
    overall: overall,
    wellnessScore: wellnessScore,
    nutritionScore: nutritionScore,
    enrichmentScore: enrichmentScore,
    careScore: careScore,
    calculatedAt: DateTime.now(),
    improvements: improvements,
  );
});

/// ============================================
/// Care Plan Notifier
/// ============================================

class CarePlanNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  CarePlanNotifier(this._ref) : super(const AsyncValue.data(null));

  /// 初始化新宠物的基础指标
  Future<void> initializeBaseMetrics(String petId, PetSpecies species) async {
    state = const AsyncValue.loading();
    try {
      final baseMetrics = SpeciesMetricTemplates.getBaseMetrics(species, petId);

      if (AppConfig.useLocalMode) {
        final localStorage = _ref.read(localStorageProvider);
        for (final metric in baseMetrics) {
          await localStorage.createCareMetric(metric);
        }
      } else {
        final db = _ref.read(databaseServiceProvider);
        for (final metric in baseMetrics) {
          await db.createCareMetric(metric);
        }
      }

      _ref.invalidate(careMetricsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 添加用户自定义指标
  Future<CareMetric> addCustomMetric({
    required String petId,
    required CareCategory category,
    required String name,
    String? description,
    String? emoji,
    required MetricFrequency frequency,
    required MetricValueType valueType,
    String? unit,
    double? targetValue,
    double? minValue,
    double? maxValue,
    List<String>? options,
  }) async {
    final now = DateTime.now();
    final metric = CareMetric(
      id: '${petId}_custom_${now.millisecondsSinceEpoch}',
      petId: petId,
      category: category,
      source: MetricSource.userCustom,
      name: name,
      description: description,
      emoji: emoji,
      frequency: frequency,
      valueType: valueType,
      unit: unit,
      targetValue: targetValue,
      minValue: minValue,
      maxValue: maxValue,
      options: options,
      createdAt: now,
      updatedAt: now,
    );

    if (AppConfig.useLocalMode) {
      final localStorage = _ref.read(localStorageProvider);
      await localStorage.createCareMetric(metric);
    } else {
      final db = _ref.read(databaseServiceProvider);
      await db.createCareMetric(metric);
    }

    _ref.invalidate(careMetricsProvider);
    _ref.invalidate(todayTasksProvider);
    return metric;
  }

  /// 添加 AI 动态建议指标
  Future<CareMetric> addAIDynamicMetric({
    required String petId,
    required CareCategory category,
    required String name,
    required String aiReason,
    String? description,
    String? emoji,
    required MetricFrequency frequency,
    required MetricValueType valueType,
    String? unit,
    double? targetValue,
  }) async {
    final now = DateTime.now();
    final metric = CareMetric(
      id: '${petId}_ai_${now.millisecondsSinceEpoch}',
      petId: petId,
      category: category,
      source: MetricSource.aiDynamic,
      name: name,
      description: description,
      emoji: emoji,
      frequency: frequency,
      valueType: valueType,
      unit: unit,
      targetValue: targetValue,
      aiReason: aiReason,
      createdAt: now,
      updatedAt: now,
    );

    if (AppConfig.useLocalMode) {
      final localStorage = _ref.read(localStorageProvider);
      await localStorage.createCareMetric(metric);
    } else {
      final db = _ref.read(databaseServiceProvider);
      await db.createCareMetric(metric);
    }

    _ref.invalidate(careMetricsProvider);
    _ref.invalidate(todayTasksProvider);
    return metric;
  }

  /// 添加疾病后建议指标
  Future<CareMetric> addPostIllnessMetric({
    required String petId,
    required String illnessId,
    required CareCategory category,
    required String name,
    required String aiReason,
    String? description,
    String? emoji,
    required MetricFrequency frequency,
    required MetricValueType valueType,
    String? unit,
    double? targetValue,
  }) async {
    final now = DateTime.now();
    final metric = CareMetric(
      id: '${petId}_illness_${now.millisecondsSinceEpoch}',
      petId: petId,
      category: category,
      source: MetricSource.postIllness,
      name: name,
      description: description,
      emoji: emoji,
      frequency: frequency,
      valueType: valueType,
      unit: unit,
      targetValue: targetValue,
      aiReason: aiReason,
      linkedIllnessId: illnessId,
      createdAt: now,
      updatedAt: now,
    );

    if (AppConfig.useLocalMode) {
      final localStorage = _ref.read(localStorageProvider);
      await localStorage.createCareMetric(metric);
    } else {
      final db = _ref.read(databaseServiceProvider);
      await db.createCareMetric(metric);
    }

    _ref.invalidate(careMetricsProvider);
    _ref.invalidate(todayTasksProvider);
    return metric;
  }

  /// 更新指标
  Future<void> updateMetric(
      String metricId, Map<String, dynamic> updates) async {
    if (AppConfig.useLocalMode) {
      final localStorage = _ref.read(localStorageProvider);
      await localStorage.updateCareMetric(metricId, updates);
    } else {
      final db = _ref.read(databaseServiceProvider);
      await db.updateCareMetric(metricId, updates);
    }

    _ref.invalidate(careMetricsProvider);
    _ref.invalidate(todayTasksProvider);
  }

  /// 切换指标启用状态
  Future<void> toggleMetric(String metricId, bool isEnabled) async {
    await updateMetric(metricId, {
      'is_enabled': isEnabled,
      'updated_at': DateTime.now().toIso8601String()
    });
  }

  /// 删除指标 (只能删除非固定的)
  Future<void> deleteMetric(String metricId) async {
    if (AppConfig.useLocalMode) {
      final localStorage = _ref.read(localStorageProvider);
      await localStorage.deleteCareMetric(metricId);
    } else {
      final db = _ref.read(databaseServiceProvider);
      await db.deleteCareMetric(metricId);
    }

    _ref.invalidate(careMetricsProvider);
    _ref.invalidate(todayTasksProvider);
  }

  /// 记录指标完成
  Future<MetricLog> logMetric({
    required String metricId,
    required String petId,
    bool? boolValue,
    double? numberValue,
    int? rangeValue,
    String? selectionValue,
    String? textValue,
    String? notes,
  }) async {
    final now = DateTime.now();
    final log = MetricLog(
      id: '${petId}_log_${now.millisecondsSinceEpoch}',
      metricId: metricId,
      petId: petId,
      loggedAt: now,
      boolValue: boolValue,
      numberValue: numberValue,
      rangeValue: rangeValue,
      selectionValue: selectionValue,
      textValue: textValue,
      notes: notes,
    );

    if (AppConfig.useLocalMode) {
      final localStorage = _ref.read(localStorageProvider);
      await localStorage.createMetricLog(log);
    } else {
      final db = _ref.read(databaseServiceProvider);
      await db.createMetricLog(log);
    }

    _ref.invalidate(todayTasksProvider);
    _ref.invalidate(wellnessScoreProvider);
    return log;
  }

  /// 快速完成布尔类型任务
  Future<void> quickCompleteTask(CareMetric metric, String petId) async {
    await logMetric(
      metricId: metric.id,
      petId: petId,
      boolValue: true,
    );
  }
}

final carePlanNotifierProvider =
    StateNotifierProvider<CarePlanNotifier, AsyncValue<void>>((ref) {
  return CarePlanNotifier(ref);
});

/// ============================================
/// Helper Functions
/// ============================================

bool _shouldShowToday(CareMetric metric, DateTime today) {
  switch (metric.frequency) {
    case MetricFrequency.daily:
    case MetricFrequency.twiceDaily:
    case MetricFrequency.threeTimesDaily:
    case MetricFrequency.asNeeded:
      return true;
    case MetricFrequency.weekly:
    case MetricFrequency.twiceWeekly:
      // 简单实现：周一/周四显示 twiceWeekly，周日显示 weekly
      if (metric.frequency == MetricFrequency.weekly) {
        return today.weekday == DateTime.sunday;
      }
      return today.weekday == DateTime.monday ||
          today.weekday == DateTime.thursday;
    case MetricFrequency.monthly:
      return today.day == 1; // 每月1号
  }
}

int? _getScheduledTime(CareMetric metric) {
  // 根据指标名称推测时间
  final name = metric.name.toLowerCase();
  if (name.contains('morning') || name.contains('breakfast')) return 8;
  if (name.contains('evening') || name.contains('dinner')) return 18;
  if (name.contains('lunch') || name.contains('noon')) return 12;
  return null; // 任意时间
}

int _getExpectedCountForWeek(MetricFrequency frequency) {
  switch (frequency) {
    case MetricFrequency.daily:
      return 7;
    case MetricFrequency.twiceDaily:
      return 14;
    case MetricFrequency.threeTimesDaily:
      return 21;
    case MetricFrequency.weekly:
      return 1;
    case MetricFrequency.twiceWeekly:
      return 2;
    case MetricFrequency.monthly:
      return 0; // 不计入周评分
    case MetricFrequency.asNeeded:
      return 0;
  }
}
