import 'package:flutter_dotenv/flutter_dotenv.dart';

/// AI 服务提供商
enum AIProvider {
  gemini,
  qwen,
}

/// 应用配置
///
/// API Key 等敏感信息从 .env 文件读取
/// .env 文件应添加到 .gitignore 中，不要提交到版本控制
class AppConfig {
  AppConfig._();

  // ============================================
  // 开发模式开关
  // ============================================

  /// 设为 true 启用本地模拟模式（不需要 Supabase）
  /// 设为 false 连接真实的 Supabase 后端
  static const bool useLocalMode = true;

  // ============================================
  // AI 服务配置
  // ============================================

  /// 当前 AI 提供商（由 GeoService 在启动时设置）
  static AIProvider _currentProvider = AIProvider.gemini;

  /// 获取当前 AI 提供商
  static AIProvider get aiProvider => _currentProvider;

  /// 设置 AI 提供商（由 GeoService 调用）
  static void setAIProvider(AIProvider provider) {
    _currentProvider = provider;
  }

  /// 根据是否在中国设置 AI 提供商
  static void setAIProviderByRegion(bool isChina) {
    _currentProvider = isChina ? AIProvider.qwen : AIProvider.gemini;
  }

  /// Gemini API Key - 从 .env 文件读取
  /// 获取地址: https://aistudio.google.com/app/apikey
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  /// Qwen API Key - 从 .env 文件读取
  /// 获取地址: https://dashscope.console.aliyun.com/
  static String get qwenApiKey => dotenv.env['QWEN_API_KEY'] ?? '';

  /// 获取当前配置的 AI API Key
  static String get currentAIApiKey {
    return aiProvider == AIProvider.qwen ? qwenApiKey : geminiApiKey;
  }

  /// 检查 AI 服务是否已配置
  /// 本地模式：检查对应的 API Key
  /// 生产模式：始终返回 true（使用 Edge Function）
  static bool get isAIConfigured {
    if (!useLocalMode) return true;
    return currentAIApiKey.isNotEmpty;
  }

  /// 获取当前 AI 提供商名称
  static String get aiProviderName {
    if (!useLocalMode) return 'Gemini (Edge)';
    return aiProvider == AIProvider.qwen ? 'Qwen' : 'Gemini';
  }

  // ============================================
  // Supabase 配置（从 .env 文件读取）
  // ============================================

  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? 'https://your-project-ref.supabase.co';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // Edge Function URL
  static String get geminiApiUrl => '$supabaseUrl/functions/v1/gemini-api';

  // ============================================
  // 应用配置
  // ============================================

  static const String appName = 'PawPrint';
  static const String appVersion = '1.0.0';

  // 功能开关
  static const bool enableAnalytics = false;
  static const bool enableCrashlytics = false;

  // 分页配置
  static const int defaultPageSize = 20;

  // 图片配置
  static const int maxImageWidth = 800;
  static const int imageQuality = 70;

  // 初始金币数
  static const int initialCoins = 200;
}
