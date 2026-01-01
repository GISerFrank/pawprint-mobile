import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
import 'ai_service.dart';
import 'impl/gemini_direct_service.dart';
import 'impl/gemini_edge_service.dart';
import 'impl/qwen_service.dart';

export 'ai_service.dart';
export 'ai_types.dart';
export 'impl/gemini_direct_service.dart';
export 'impl/gemini_edge_service.dart';
export 'impl/qwen_service.dart';

/// AI 服务工厂
/// 根据配置创建合适的 AI 服务实例
class AIServiceFactory {
  AIServiceFactory._();

  /// 创建 AI 服务实例
  /// 
  /// 选择逻辑：
  /// - useLocalMode = false → GeminiEdgeService（生产环境，通过 Supabase Edge Function）
  /// - useLocalMode = true + 中国 → QwenService
  /// - useLocalMode = true + 海外 → GeminiDirectService
  static AIService? create({SupabaseClient? supabaseClient}) {
    try {
      if (!AppConfig.useLocalMode) {
        // 生产环境：使用 Supabase Edge Function
        final client = supabaseClient ?? Supabase.instance.client;
        return GeminiEdgeService(client);
      }

      // 本地开发模式：根据地理位置选择
      if (AppConfig.aiProvider == AIProvider.qwen) {
        if (AppConfig.qwenApiKey.isEmpty) {
          print('Qwen API key not configured');
          return null;
        }
        return QwenService();
      } else {
        if (AppConfig.geminiApiKey.isEmpty) {
          print('Gemini API key not configured');
          return null;
        }
        return GeminiDirectService();
      }
    } catch (e) {
      print('Failed to create AI service: $e');
      return null;
    }
  }

  /// 检查 AI 服务是否可用
  static bool get isConfigured {
    if (!AppConfig.useLocalMode) {
      return true; // Edge Function 不需要本地配置
    }
    return AppConfig.isAIConfigured;
  }

  /// 获取当前使用的提供商名称
  static String get providerName {
    if (!AppConfig.useLocalMode) {
      return 'Gemini (Edge)';
    }
    return AppConfig.aiProviderName;
  }
}

/// AI 服务 Riverpod Provider
/// 
/// 使用方式：
/// ```dart
/// final aiService = ref.watch(aiServiceProvider);
/// if (aiService != null) {
///   final result = await aiService.analyzePetHealth(...);
/// }
/// ```
final aiServiceProvider = Provider<AIService?>((ref) {
  return AIServiceFactory.create();
});

/// AI 服务是否可用
final isAIServiceAvailableProvider = Provider<bool>((ref) {
  return AIServiceFactory.isConfigured;
});

/// AI 服务提供商名称
final aiProviderNameProvider = Provider<String>((ref) {
  return AIServiceFactory.providerName;
});
