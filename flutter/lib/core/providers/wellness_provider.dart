import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../models/metrics/wellness_metrics.dart';
import '../services/services.dart';
import '../services/ai/ai_service_provider.dart';
import 'pet_provider.dart';
import 'service_providers.dart';

/// ============================================
/// Body Score Images Provider
/// ============================================

/// BCS/MCS 图像生成状态
class BodyScoreImageState {
  final bool isGenerating;
  final int? currentScore; // 正在生成的分数
  final String? error;
  final Map<int, String> bcsImages; // score -> imageUrl/base64
  final Map<int, String> mcsImages; // score -> imageUrl/base64

  const BodyScoreImageState({
    this.isGenerating = false,
    this.currentScore,
    this.error,
    this.bcsImages = const {},
    this.mcsImages = const {},
  });

  BodyScoreImageState copyWith({
    bool? isGenerating,
    int? currentScore,
    String? error,
    Map<int, String>? bcsImages,
    Map<int, String>? mcsImages,
  }) {
    return BodyScoreImageState(
      isGenerating: isGenerating ?? this.isGenerating,
      currentScore: currentScore,
      error: error,
      bcsImages: bcsImages ?? this.bcsImages,
      mcsImages: mcsImages ?? this.mcsImages,
    );
  }

  bool hasBCSImage(int score) => bcsImages.containsKey(score);
  bool hasMCSImage(int score) => mcsImages.containsKey(score);
  bool get hasAllBCSImages => bcsImages.length == 9;
  bool get hasAllMCSImages => mcsImages.length == 4;
}

/// BCS/MCS 图像生成 Notifier
class BodyScoreImageNotifier extends StateNotifier<BodyScoreImageState> {
  final Ref _ref;
  final String _petId;

  BodyScoreImageNotifier(this._ref, this._petId)
      : super(const BodyScoreImageState()) {
    _loadCachedImages();
  }

  /// 从缓存加载图片
  Future<void> _loadCachedImages() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 加载 BCS 图片
      final bcsJson = prefs.getString('bcs_images_$_petId');
      if (bcsJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(bcsJson);
        final bcsImages =
            decoded.map((k, v) => MapEntry(int.parse(k), v as String));
        state = state.copyWith(bcsImages: bcsImages);
      }

      // 加载 MCS 图片
      final mcsJson = prefs.getString('mcs_images_$_petId');
      if (mcsJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(mcsJson);
        final mcsImages =
            decoded.map((k, v) => MapEntry(int.parse(k), v as String));
        state = state.copyWith(mcsImages: mcsImages);
      }
    } catch (e) {
      print('Error loading cached body score images: $e');
    }
  }

  /// 保存图片到缓存
  Future<void> _saveCachedImages() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (state.bcsImages.isNotEmpty) {
        final bcsJson = jsonEncode(
            state.bcsImages.map((k, v) => MapEntry(k.toString(), v)));
        await prefs.setString('bcs_images_$_petId', bcsJson);
      }

      if (state.mcsImages.isNotEmpty) {
        final mcsJson = jsonEncode(
            state.mcsImages.map((k, v) => MapEntry(k.toString(), v)));
        await prefs.setString('mcs_images_$_petId', mcsJson);
      }
    } catch (e) {
      print('Error saving cached body score images: $e');
    }
  }

  /// 生成单个 BCS 图片
  Future<String?> generateBCSImage(int score) async {
    print('🔵 generateBCSImage called for score: $score');

    // 如果已有缓存，直接返回
    if (state.hasBCSImage(score)) {
      print('🟢 Using cached BCS image for score: $score');
      return state.bcsImages[score];
    }

    final aiService = _ref.read(aiServiceProvider);
    if (aiService == null) {
      print('🔴 AI service not available');
      state = state.copyWith(error: 'AI service not available');
      return null;
    }
    print('🟢 AI service: ${aiService.providerName}');

    // 获取宠物信息
    final pet = await _ref.read(currentPetProvider.future);
    if (pet == null || pet.avatarUrl == null) {
      print('🔴 Pet or avatar not found');
      state = state.copyWith(error: 'Pet avatar required');
      return null;
    }
    print('🟢 Pet: ${pet.name}, avatar: ${pet.avatarUrl?.substring(0, 50)}...');

    state =
        state.copyWith(isGenerating: true, currentScore: score, error: null);

    try {
      final bodyScoreService = BodyScoreImageService(aiService);

      // 获取宠物头像 base64
      final petImageBase64 = await _getPetImageBase64(pet.avatarUrl!);
      if (petImageBase64 == null) {
        print('🔴 Failed to load pet image base64');
        throw Exception('Failed to load pet image');
      }
      print('🟢 Pet image loaded, length: ${petImageBase64.length}');

      print('🔵 Calling AI to generate BCS image...');
      final imageUrl = await bodyScoreService.generateBCSImage(
        petImageBase64: petImageBase64,
        species: pet.species,
        score: score,
      );

      if (imageUrl != null) {
        print(
            '🟢 BCS image generated successfully, length: ${imageUrl.length}');
        final newBcsImages = Map<int, String>.from(state.bcsImages);
        newBcsImages[score] = imageUrl;
        state = state.copyWith(
          isGenerating: false,
          currentScore: null,
          bcsImages: newBcsImages,
        );
        await _saveCachedImages();
        return imageUrl;
      } else {
        print('🔴 AI returned null for BCS image');
        state = state.copyWith(
          isGenerating: false,
          currentScore: null,
          error: 'Failed to generate BCS image',
        );
        return null;
      }
    } catch (e) {
      print('🔴 Error generating BCS image: $e');
      state = state.copyWith(
        isGenerating: false,
        currentScore: null,
        error: e.toString(),
      );
      return null;
    }
  }

  /// 生成单个 MCS 图片
  Future<String?> generateMCSImage(int score) async {
    if (state.hasMCSImage(score)) {
      return state.mcsImages[score];
    }

    final aiService = _ref.read(aiServiceProvider);
    if (aiService == null) {
      state = state.copyWith(error: 'AI service not available');
      return null;
    }

    final pet = await _ref.read(currentPetProvider.future);
    if (pet == null || pet.avatarUrl == null) {
      state = state.copyWith(error: 'Pet avatar required');
      return null;
    }

    state =
        state.copyWith(isGenerating: true, currentScore: score, error: null);

    try {
      final bodyScoreService = BodyScoreImageService(aiService);

      final petImageBase64 = await _getPetImageBase64(pet.avatarUrl!);
      if (petImageBase64 == null) {
        throw Exception('Failed to load pet image');
      }

      final imageUrl = await bodyScoreService.generateMCSImage(
        petImageBase64: petImageBase64,
        species: pet.species,
        score: score,
      );

      if (imageUrl != null) {
        final newMcsImages = Map<int, String>.from(state.mcsImages);
        newMcsImages[score] = imageUrl;
        state = state.copyWith(
          isGenerating: false,
          currentScore: null,
          mcsImages: newMcsImages,
        );
        await _saveCachedImages();
        return imageUrl;
      } else {
        state = state.copyWith(
          isGenerating: false,
          currentScore: null,
          error: 'Failed to generate MCS image',
        );
        return null;
      }
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        currentScore: null,
        error: e.toString(),
      );
      return null;
    }
  }

  /// 生成所有 BCS 图片
  Future<void> generateAllBCSImages() async {
    for (int score = 1; score <= 9; score++) {
      if (!state.hasBCSImage(score)) {
        await generateBCSImage(score);
        // 添加延迟避免 API 限流
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  /// 生成所有 MCS 图片
  Future<void> generateAllMCSImages() async {
    for (int score = 0; score <= 3; score++) {
      if (!state.hasMCSImage(score)) {
        await generateMCSImage(score);
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  /// 获取宠物图片的 base64
  Future<String?> _getPetImageBase64(String avatarUrl) async {
    try {
      // 如果已经是 base64
      if (avatarUrl.startsWith('data:image')) {
        return avatarUrl;
      }

      // 如果是本地文件路径
      if (avatarUrl.startsWith('/') || avatarUrl.startsWith('file://')) {
        final path = avatarUrl.startsWith('file://')
            ? avatarUrl.substring(7)
            : avatarUrl;
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          return 'data:image/jpeg;base64,${base64Encode(bytes)}';
        }
      }

      // 如果是网络 URL，需要下载
      // TODO: 实现网络图片下载

      return null;
    } catch (e) {
      print('Error getting pet image base64: $e');
      return null;
    }
  }

  /// 清除缓存
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('bcs_images_$_petId');
    await prefs.remove('mcs_images_$_petId');
    state = const BodyScoreImageState();
  }
}

/// Body Score Image Provider (per pet)
final bodyScoreImageProvider = StateNotifierProvider.family<
    BodyScoreImageNotifier, BodyScoreImageState, String>(
  (ref, petId) => BodyScoreImageNotifier(ref, petId),
);

/// ============================================
/// Wellness Metrics Value Providers
/// ============================================

/// 获取所有日志的日期范围（过去一年到未来一天）
DateTime get _logsStartDate =>
    DateTime.now().subtract(const Duration(days: 365));
DateTime get _logsEndDate => DateTime.now().add(const Duration(days: 1));

/// 当前宠物的 BCS 值
final currentBCSProvider = FutureProvider<int?>((ref) async {
  final petId = ref.watch(selectedPetIdProvider);
  if (petId == null) return null;

  final localStorage = ref.watch(localStorageProvider);
  final allLogs = await localStorage.getMetricLogs(
    petId,
    _logsStartDate,
    _logsEndDate,
  );

  final bcsLogs = allLogs
      .where((log) =>
          log.metricId == '${petId}_wellness_bcs' && log.rangeValue != null)
      .toList()
    ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));

  if (bcsLogs.isEmpty) return null;
  return bcsLogs.first.rangeValue;
});

/// 当前宠物的 MCS 值
final currentMCSProvider = FutureProvider<int?>((ref) async {
  final petId = ref.watch(selectedPetIdProvider);
  if (petId == null) return null;

  final localStorage = ref.watch(localStorageProvider);
  final allLogs = await localStorage.getMetricLogs(
    petId,
    _logsStartDate,
    _logsEndDate,
  );

  final mcsLogs = allLogs
      .where((log) =>
          log.metricId == '${petId}_wellness_mcs' && log.rangeValue != null)
      .toList()
    ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));

  if (mcsLogs.isEmpty) return null;
  return mcsLogs.first.rangeValue;
});

/// 当前宠物的体重历史
final weightHistoryProvider = FutureProvider<List<MetricLog>>((ref) async {
  final petId = ref.watch(selectedPetIdProvider);
  if (petId == null) return [];

  final localStorage = ref.watch(localStorageProvider);
  final allLogs = await localStorage.getMetricLogs(
    petId,
    _logsStartDate,
    _logsEndDate,
  );

  return allLogs
      .where((log) =>
          log.metricId == '${petId}_wellness_weight' && log.numberValue != null)
      .toList()
    ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
});

/// ============================================
/// Wellness Daily Scores Provider
/// ============================================

/// 今日健康评分记录
class TodayWellnessScores {
  final Map<String, int> scores; // metricId -> score (1-5)
  final DateTime date;

  const TodayWellnessScores({
    required this.scores,
    required this.date,
  });

  int? getScore(String metricId) => scores[metricId];

  bool hasScore(String metricId) => scores.containsKey(metricId);

  int get completedCount => scores.length;

  /// 总共需要记录的日常评分指标数量（不包括体重、BCS、MCS）
  static const int totalDailyMetrics = 7;

  double get completionRate => completedCount / totalDailyMetrics;

  TodayWellnessScores copyWith({
    Map<String, int>? scores,
    DateTime? date,
  }) {
    return TodayWellnessScores(
      scores: scores ?? this.scores,
      date: date ?? this.date,
    );
  }
}

/// 今日健康评分 Provider
final todayWellnessScoresProvider =
    FutureProvider<TodayWellnessScores>((ref) async {
  final petId = ref.watch(selectedPetIdProvider);
  if (petId == null) {
    return TodayWellnessScores(scores: {}, date: DateTime.now());
  }

  final localStorage = ref.watch(localStorageProvider);
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);

  // 获取今日所有 wellness 记录
  final dailyMetricIds = [
    'wellness_gum_color',
    'wellness_coat_condition',
    'wellness_eye_clarity',
    'wellness_breathing',
    'wellness_energy_level',
    'wellness_stool',
    'wellness_hydration',
  ];

  final scores = <String, int>{};

  // 获取所有metric logs
  final allLogs = await localStorage.getMetricLogs(
    petId,
    startOfDay,
    DateTime.now().add(const Duration(days: 1)),
  );

  for (final metricId in dailyMetricIds) {
    final fullMetricId = '${petId}_$metricId';
    final todayLogs = allLogs
        .where((log) =>
            log.metricId == fullMetricId && log.loggedAt.isAfter(startOfDay))
        .toList();

    if (todayLogs.isNotEmpty && todayLogs.first.rangeValue != null) {
      scores[metricId] = todayLogs.first.rangeValue!;
    }
  }

  return TodayWellnessScores(scores: scores, date: today);
});

/// ============================================
/// Wellness Score Notifier - 管理评分保存
/// ============================================

class WellnessScoreNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  WellnessScoreNotifier(this._ref) : super(const AsyncValue.data(null));

  /// 保存每日健康检查评分 (1-5)
  Future<bool> saveDailyScore({
    required String petId,
    required String indicatorId,
    required int score,
    String? notes,
    List<String>? imageUrls,
  }) async {
    state = const AsyncValue.loading();

    try {
      final localStorage = _ref.read(localStorageProvider);
      final metricId = '${petId}_wellness_$indicatorId';

      final log = MetricLog(
        id: _generateId(),
        metricId: metricId,
        petId: petId,
        loggedAt: DateTime.now(),
        rangeValue: score,
        notes: notes,
        imageUrls: imageUrls,
      );

      await localStorage.createMetricLog(log);

      // 刷新今日评分
      _ref.invalidate(todayWellnessScoresProvider);

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// 保存 BCS 评分 (1-9)
  Future<bool> saveBCSScore({
    required String petId,
    required int score,
    String? notes,
    List<String>? imageUrls,
  }) async {
    state = const AsyncValue.loading();

    try {
      final localStorage = _ref.read(localStorageProvider);
      final metricId = '${petId}_wellness_bcs';

      final log = MetricLog(
        id: _generateId(),
        metricId: metricId,
        petId: petId,
        loggedAt: DateTime.now(),
        rangeValue: score,
        notes: notes,
        imageUrls: imageUrls,
      );

      await localStorage.createMetricLog(log);

      // 刷新 BCS provider
      _ref.invalidate(currentBCSProvider);
      _ref.invalidate(bcsHistoryProvider);

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// 保存 MCS 评分 (0-3)
  Future<bool> saveMCSScore({
    required String petId,
    required int score,
    String? notes,
    List<String>? imageUrls,
  }) async {
    state = const AsyncValue.loading();

    try {
      final localStorage = _ref.read(localStorageProvider);
      final metricId = '${petId}_wellness_mcs';

      final log = MetricLog(
        id: _generateId(),
        metricId: metricId,
        petId: petId,
        loggedAt: DateTime.now(),
        rangeValue: score,
        notes: notes,
        imageUrls: imageUrls,
      );

      await localStorage.createMetricLog(log);

      // 刷新 MCS provider
      _ref.invalidate(currentMCSProvider);
      _ref.invalidate(mcsHistoryProvider);

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// 保存体重记录
  Future<bool> saveWeight({
    required String petId,
    required double weightKg,
    String? notes,
    List<String>? imageUrls,
  }) async {
    state = const AsyncValue.loading();

    try {
      final localStorage = _ref.read(localStorageProvider);
      final metricId = '${petId}_wellness_weight';

      final log = MetricLog(
        id: _generateId(),
        metricId: metricId,
        petId: petId,
        loggedAt: DateTime.now(),
        numberValue: weightKg,
        notes: notes,
        imageUrls: imageUrls,
      );

      await localStorage.createMetricLog(log);

      // 同时更新 Pet 的体重字段
      final pet = await _ref.read(currentPetProvider.future);
      if (pet != null) {
        await localStorage.updatePet(
          pet.id,
          pet.copyWith(weightKg: weightKg).toJson(),
        );
        _ref.invalidate(currentPetProvider);
      }

      // 刷新体重历史
      _ref.invalidate(weightHistoryProvider);
      _ref.invalidate(latestWeightProvider);

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        '_${(1000 + (DateTime.now().microsecond % 9000))}';
  }

  /// 创建自定义指标
  Future<bool> createCustomMetric({
    required String petId,
    required String name,
    required String description,
    required String emoji,
    required MetricValueType valueType,
    MetricCategory? metricCategory,
  }) async {
    state = const AsyncValue.loading();

    try {
      final localStorage = _ref.read(localStorageProvider);
      final now = DateTime.now();
      final metricId = '${petId}_custom_${now.millisecondsSinceEpoch}';

      final metric = CareMetric(
        id: metricId,
        petId: petId,
        category: CareCategory.wellness, // 自定义指标默认归类到健康
        source: MetricSource.userCustom,
        name: name,
        description:
            description.isNotEmpty ? description : 'Custom health metric',
        emoji: emoji,
        frequency: MetricFrequency.daily,
        valueType: valueType,
        isEnabled: true,
        isPinned: false,
        priority: 10,
        metricCategory: metricCategory,
        createdAt: now,
        updatedAt: now,
      );

      await localStorage.createCareMetric(metric);

      // 刷新自定义指标列表
      _ref.invalidate(customMetricsProvider);

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// 保存自定义指标的记录
  Future<bool> saveCustomMetricLog({
    required String petId,
    required String metricId,
    int? rangeValue,
    double? numberValue,
    bool? boolValue,
    String? textValue,
    String? notes,
    List<String>? imageUrls,
  }) async {
    state = const AsyncValue.loading();

    try {
      final localStorage = _ref.read(localStorageProvider);

      final log = MetricLog(
        id: _generateId(),
        metricId: metricId,
        petId: petId,
        loggedAt: DateTime.now(),
        rangeValue: rangeValue,
        numberValue: numberValue,
        boolValue: boolValue,
        textValue: textValue,
        notes: notes,
        imageUrls: imageUrls,
      );

      await localStorage.createMetricLog(log);

      // 刷新自定义指标历史
      _ref.invalidate(customMetricHistoryProvider(metricId));

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// 保存图片类型指标的记录（Eye/Ear Condition）
  Future<bool> saveImageMetricLog({
    required String petId,
    required String metricId,
    required List<String> imageUrls,
    String? notes,
  }) async {
    state = const AsyncValue.loading();

    try {
      final localStorage = _ref.read(localStorageProvider);

      final log = MetricLog(
        id: _generateId(),
        metricId: metricId,
        petId: petId,
        loggedAt: DateTime.now(),
        imageUrls: imageUrls,
        notes: notes,
      );

      await localStorage.createMetricLog(log);

      // 刷新图片指标历史
      _ref.invalidate(imageMetricHistoryProvider(metricId));

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// 更新自定义指标
  Future<bool> updateCustomMetric({
    required String metricId,
    required String name,
    required String description,
    required String emoji,
  }) async {
    state = const AsyncValue.loading();

    try {
      final localStorage = _ref.read(localStorageProvider);

      // 更新指标
      await localStorage.updateCareMetric(metricId, {
        'name': name,
        'description': description,
        'emoji': emoji,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // 刷新自定义指标列表
      _ref.invalidate(customMetricsProvider);

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// 删除自定义指标
  Future<bool> deleteCustomMetric({
    required String metricId,
  }) async {
    state = const AsyncValue.loading();

    try {
      final localStorage = _ref.read(localStorageProvider);

      // 删除指标（这也应该删除相关的日志记录）
      await localStorage.deleteCareMetric(metricId);

      // 刷新自定义指标列表
      _ref.invalidate(customMetricsProvider);

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

/// Wellness Score Notifier Provider
final wellnessScoreNotifierProvider =
    StateNotifierProvider<WellnessScoreNotifier, AsyncValue<void>>(
  (ref) => WellnessScoreNotifier(ref),
);

/// ============================================
/// Additional History Providers
/// ============================================

/// BCS 历史记录
final bcsHistoryProvider = FutureProvider<List<MetricLog>>((ref) async {
  final petId = ref.watch(selectedPetIdProvider);
  if (petId == null) return [];

  final localStorage = ref.watch(localStorageProvider);
  final allLogs = await localStorage.getMetricLogs(
    petId,
    _logsStartDate,
    _logsEndDate,
  );

  return allLogs
      .where((log) => log.metricId == '${petId}_wellness_bcs')
      .toList()
    ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
});

/// MCS 历史记录
final mcsHistoryProvider = FutureProvider<List<MetricLog>>((ref) async {
  final petId = ref.watch(selectedPetIdProvider);
  if (petId == null) return [];

  final localStorage = ref.watch(localStorageProvider);
  final allLogs = await localStorage.getMetricLogs(
    petId,
    _logsStartDate,
    _logsEndDate,
  );

  return allLogs
      .where((log) => log.metricId == '${petId}_wellness_mcs')
      .toList()
    ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
});

/// 最新体重
final latestWeightProvider = FutureProvider<double?>((ref) async {
  final petId = ref.watch(selectedPetIdProvider);
  if (petId == null) return null;

  final localStorage = ref.watch(localStorageProvider);
  final allLogs = await localStorage.getMetricLogs(
    petId,
    _logsStartDate,
    _logsEndDate,
  );

  final weightLogs = allLogs
      .where((log) =>
          log.metricId == '${petId}_wellness_weight' && log.numberValue != null)
      .toList()
    ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));

  if (weightLogs.isEmpty) return null;
  return weightLogs.first.numberValue;
});

/// 体重趋势（最近两次记录的变化）
final weightTrendProvider = FutureProvider<WeightTrend>((ref) async {
  final history = await ref.watch(weightHistoryProvider.future);

  if (history.length < 2) {
    return WeightTrend.stable;
  }

  final latest = history.first.numberValue;
  final previous = history[1].numberValue;

  if (latest == null || previous == null) {
    return WeightTrend.stable;
  }

  final diff = latest - previous;
  final percentChange = (diff / previous) * 100;

  if (percentChange > 2) return WeightTrend.increasing;
  if (percentChange < -2) return WeightTrend.decreasing;
  return WeightTrend.stable;
});

enum WeightTrend { increasing, decreasing, stable }

/// ============================================
/// Daily Check History Provider
/// ============================================

/// 单个 Daily Check 指标的历史记录
final dailyCheckHistoryProvider =
    FutureProvider.family<List<MetricLog>, String>((ref, indicatorId) async {
  final petId = ref.watch(selectedPetIdProvider);
  if (petId == null) return [];

  final localStorage = ref.watch(localStorageProvider);
  final allLogs = await localStorage.getMetricLogs(
    petId,
    _logsStartDate,
    _logsEndDate,
  );

  // 查找匹配的 metric ID
  // indicatorId 格式: "gum_color", "coat_condition" 等
  // metricId 格式: "${petId}_wellness_${indicatorId}"
  final fullMetricId = '${petId}_wellness_$indicatorId';

  return allLogs
      .where((log) => log.metricId == fullMetricId && log.rangeValue != null)
      .toList()
    ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt)); // 最新的在前面
});

/// ============================================
/// Custom Metrics Providers
/// ============================================

/// 获取用户自定义的指标列表
final customMetricsProvider = FutureProvider<List<CareMetric>>((ref) async {
  final petId = ref.watch(selectedPetIdProvider);
  if (petId == null) return [];

  final localStorage = ref.watch(localStorageProvider);
  final allMetrics = await localStorage.getCareMetrics(petId);

  // 筛选出自定义指标（source = manual）
  return allMetrics
      .where((m) => m.source == MetricSource.userCustom && m.isEnabled)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // 最新创建的在前
});

/// 单个自定义指标的历史记录
final customMetricHistoryProvider =
    FutureProvider.family<List<MetricLog>, String>((ref, metricId) async {
  final petId = ref.watch(selectedPetIdProvider);
  if (petId == null) return [];

  final localStorage = ref.watch(localStorageProvider);
  final allLogs = await localStorage.getMetricLogs(
    petId,
    _logsStartDate,
    _logsEndDate,
  );

  return allLogs.where((log) => log.metricId == metricId).toList()
    ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
});

/// 自定义指标今日是否已记录
final customMetricTodayLogProvider =
    FutureProvider.family<MetricLog?, String>((ref, metricId) async {
  final petId = ref.watch(selectedPetIdProvider);
  if (petId == null) return null;

  final localStorage = ref.watch(localStorageProvider);
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = todayStart.add(const Duration(days: 1));

  final allLogs = await localStorage.getMetricLogs(petId, todayStart, todayEnd);

  try {
    return allLogs.firstWhere((log) => log.metricId == metricId);
  } catch (_) {
    return null;
  }
});

/// ============================================
/// Pinned Metrics (Quick Log on Care Page)
/// ============================================

/// 获取当前宠物的 pinned metric IDs
final pinnedMetricIdsProvider = FutureProvider<List<String>>((ref) async {
  final petId = ref.watch(selectedPetIdProvider);
  if (petId == null) return [];

  final localStorage = ref.watch(localStorageProvider);
  return localStorage.getPinnedMetricIds(petId);
});

/// 检查指标是否已 pin
final isMetricPinnedProvider =
    FutureProvider.family<bool, String>((ref, metricId) async {
  final petId = ref.watch(selectedPetIdProvider);
  if (petId == null) return false;

  final localStorage = ref.watch(localStorageProvider);
  return localStorage.isMetricPinned(petId, metricId);
});

/// Pinned Metrics Notifier - 管理 pin/unpin 操作
class PinnedMetricsNotifier extends StateNotifier<AsyncValue<List<String>>> {
  final Ref _ref;

  PinnedMetricsNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadPinnedMetrics();
  }

  Future<void> _loadPinnedMetrics() async {
    final petId = _ref.read(selectedPetIdProvider);
    if (petId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      final localStorage = _ref.read(localStorageProvider);
      final ids = await localStorage.getPinnedMetricIds(petId);
      state = AsyncValue.data(ids);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> pinMetric(String metricId) async {
    final petId = _ref.read(selectedPetIdProvider);
    if (petId == null) return false;

    try {
      final localStorage = _ref.read(localStorageProvider);
      await localStorage.addPinnedMetric(petId, metricId);

      // 更新状态
      final currentIds = state.valueOrNull ?? [];
      if (!currentIds.contains(metricId)) {
        state = AsyncValue.data([...currentIds, metricId]);
      }

      // 刷新相关 provider
      _ref.invalidate(pinnedMetricIdsProvider);
      _ref.invalidate(isMetricPinnedProvider(metricId));

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> unpinMetric(String metricId) async {
    final petId = _ref.read(selectedPetIdProvider);
    if (petId == null) return false;

    try {
      final localStorage = _ref.read(localStorageProvider);
      await localStorage.removePinnedMetric(petId, metricId);

      // 更新状态
      final currentIds = state.valueOrNull ?? [];
      state =
          AsyncValue.data(currentIds.where((id) => id != metricId).toList());

      // 刷新相关 provider
      _ref.invalidate(pinnedMetricIdsProvider);
      _ref.invalidate(isMetricPinnedProvider(metricId));

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> togglePin(String metricId) async {
    final currentIds = state.valueOrNull ?? [];
    if (currentIds.contains(metricId)) {
      return unpinMetric(metricId);
    } else {
      return pinMetric(metricId);
    }
  }
}

final pinnedMetricsNotifierProvider =
    StateNotifierProvider<PinnedMetricsNotifier, AsyncValue<List<String>>>(
        (ref) {
  return PinnedMetricsNotifier(ref);
});

/// ============================================
/// Image Metric History Provider
/// ============================================

/// 图片类型指标的历史记录（Eye/Ear Condition）
final imageMetricHistoryProvider =
    FutureProvider.family<List<MetricLog>, String>((ref, metricId) async {
  final petId = ref.watch(selectedPetIdProvider);
  if (petId == null) return [];

  final localStorage = ref.watch(localStorageProvider);
  final allLogs = await localStorage.getMetricLogs(
    petId,
    _logsStartDate,
    _logsEndDate,
  );

  return allLogs.where((log) => log.metricId == metricId).toList()
    ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
});
