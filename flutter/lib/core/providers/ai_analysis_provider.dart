import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../models/models.dart';
import 'service_providers.dart';
import 'pet_provider.dart';
import 'auth_provider.dart';

/// AI 分析历史记录
final aiAnalysisHistoryProvider = FutureProvider<List<AIAnalysisSession>>((ref) async {
  final petId = ref.watch(selectedPetIdProvider);
  if (petId == null) return [];

  if (AppConfig.useLocalMode) {
    final localStorage = ref.watch(localStorageServiceProvider);
    return localStorage.getAIAnalysisSessions(petId);
  } else {
    final db = ref.watch(databaseServiceProvider);
    return db.getAIAnalysisSessions(petId);
  }
});

/// AI 分析状态
class AIAnalysisState {
  final bool isLoading;
  final String? result;
  final String? error;

  const AIAnalysisState({
    this.isLoading = false,
    this.result,
    this.error,
  });

  AIAnalysisState copyWith({
    bool? isLoading,
    String? result,
    String? error,
  }) {
    return AIAnalysisState(
      isLoading: isLoading ?? this.isLoading,
      result: result,
      error: error,
    );
  }
}

/// AI 分析 Notifier
class AIAnalysisNotifier extends StateNotifier<AIAnalysisState> {
  final Ref _ref;

  AIAnalysisNotifier(this._ref) : super(const AIAnalysisState());

  /// 执行健康分析
  Future<void> analyzeHealth({
    required String petId,
    required String symptoms,
    required BodyPart bodyPart,
    Uint8List? currentImageBytes,
    String? baselineImageBase64,
    bool useBaseline = false,
  }) async {
    state = const AIAnalysisState(isLoading: true);

    try {
      String result;
      String? imageUrl;

      // 转换当前图片为 base64
      String? currentImageBase64;
      if (currentImageBytes != null) {
        currentImageBase64 = 'data:image/jpeg;base64,${base64Encode(currentImageBytes)}';
      }

      if (AppConfig.useLocalMode) {
        // 本地模式：检查是否有 API Key，有则调用真实 API
        if (AppConfig.geminiApiKey.isNotEmpty) {
          // 使用 Gemini Direct Service
          final gemini = _ref.read(geminiDirectServiceProvider);
          result = await gemini.analyzePetHealth(
            symptoms: symptoms,
            bodyPart: bodyPart,
            currentImageBase64: currentImageBase64,
            baselineImageBase64: useBaseline ? baselineImageBase64 : null,
          );
        } else {
          // 无 API Key，使用模拟结果
          await Future.delayed(const Duration(seconds: 2));
          result = _getMockAnalysisResult(symptoms, bodyPart);
        }
        
        // 保存图片到本地
        if (currentImageBytes != null) {
          final localStorage = _ref.read(localStorageServiceProvider);
          final key = '${petId}_analysis_${DateTime.now().millisecondsSinceEpoch}';
          imageUrl = await localStorage.saveImageLocally(key, currentImageBytes);
        }

        // 保存分析会话
        final localStorage = _ref.read(localStorageServiceProvider);
        await localStorage.createAIAnalysisSession(AIAnalysisSession(
          id: '',
          petId: petId,
          symptoms: symptoms,
          bodyPart: bodyPart,
          imageUrl: imageUrl,
          analysisResult: result,
          createdAt: DateTime.now(),
        ));
      } else {
        // Supabase 模式：调用 Edge Function
        final gemini = _ref.read(geminiServiceProvider);
        final storage = _ref.read(storageServiceProvider);
        final db = _ref.read(databaseServiceProvider);

        result = await gemini.analyzePetHealth(
          symptoms: symptoms,
          bodyPart: bodyPart,
          currentImageBase64: currentImageBase64,
          baselineImageBase64: useBaseline ? baselineImageBase64 : null,
        );

        // 保存分析图片
        if (currentImageBytes != null) {
          final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
          imageUrl = await storage.uploadAnalysisImage(
            petId: petId,
            sessionId: sessionId,
            fileBytes: currentImageBytes,
          );
        }

        // 保存分析会话
        await db.createAIAnalysisSession(AIAnalysisSession(
          id: '',
          petId: petId,
          symptoms: symptoms,
          bodyPart: bodyPart,
          imageUrl: imageUrl,
          analysisResult: result,
          createdAt: DateTime.now(),
        ));
      }

      _ref.invalidate(aiAnalysisHistoryProvider);
      state = AIAnalysisState(result: result);
    } catch (e) {
      state = AIAnalysisState(error: e.toString());
    }
  }

  /// 清除结果
  void clearResult() {
    state = const AIAnalysisState();
  }

  /// 本地模式的模拟分析结果
  String _getMockAnalysisResult(String symptoms, BodyPart bodyPart) {
    return '''
## Observation

Based on your description of the ${bodyPart.displayName.toLowerCase()} issue with symptoms: "$symptoms", here's my assessment:

The described symptoms suggest possible irritation or inflammation in the affected area. This could be due to various factors including environmental allergens, parasites, or localized infection.

## Potential Causes

1. **Allergic Reaction** - Contact with irritants or seasonal allergens
2. **Parasites** - Fleas, mites, or other external parasites
3. **Bacterial/Fungal Infection** - Secondary infection from scratching

## Recommendations

### Immediate Care
- Keep the area clean and dry
- Prevent your pet from scratching or licking excessively
- Monitor for any changes in the next 24-48 hours

### When to See a Vet
- If symptoms worsen or spread
- If there's discharge, bleeding, or strong odor
- If your pet shows signs of pain or distress
- If home care doesn't improve the condition within 2-3 days

---

**Disclaimer:** I am an AI assistant, not a veterinarian. This analysis is for informational purposes only and does not replace professional veterinary advice. If you're concerned about your pet's health, please consult a licensed veterinarian.
''';
  }
}

/// AI 分析 Provider
final aiAnalysisNotifierProvider = StateNotifierProvider<AIAnalysisNotifier, AIAnalysisState>((ref) {
  return AIAnalysisNotifier(ref);
});