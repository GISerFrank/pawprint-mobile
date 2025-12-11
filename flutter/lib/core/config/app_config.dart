/// 应用配置
///
/// 注意：在实际项目中，这些值应该通过环境变量或 --dart-define 注入
/// 不要将真实的密钥提交到版本控制
class AppConfig {
  AppConfig._();

  // ============================================
  // 开发模式开关
  // ============================================

  /// 设为 true 启用本地模拟模式（不需要 Supabase）
  /// 设为 false 连接真实的 Supabase 后端
  static const bool useLocalMode = true;

  // ============================================
  // Supabase 配置
  // ============================================

  // TODO: 替换为你的 Supabase 项目配置
  static const String supabaseUrl = 'https://your-project-ref.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key';

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