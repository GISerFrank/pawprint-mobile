import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/config/app_config.dart';
import 'core/services/geo_service.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 加载 .env 文件（如果存在）
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Warning: .env file not found, using default values');
  }

  // 检测地理位置，设置 AI 提供商
  await _initAIProvider();

  // 设置状态栏样式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // 初始化 Hive (本地存储)
  await Hive.initFlutter();

  // 仅在非本地模式下初始化 Supabase
  if (!AppConfig.useLocalMode) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }

  runApp(
    const ProviderScope(
      child: PawPrintApp(),
    ),
  );
}

/// 初始化 AI 提供商
/// 根据地理位置自动选择 Qwen（中国）或 Gemini（其他地区）
Future<void> _initAIProvider() async {
  try {
    final geoService = GeoService();
    final isChina = await geoService.isInChina();
    AppConfig.setAIProviderByRegion(isChina);
    debugPrint(
        'AI Provider set to: ${AppConfig.aiProviderName} (isChina: $isChina)');
  } catch (e) {
    debugPrint('Failed to detect region, using default AI provider: $e');
    // 默认使用 Gemini
    AppConfig.setAIProvider(AIProvider.gemini);
  }
}

class PawPrintApp extends ConsumerWidget {
  const PawPrintApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'PawPrint',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      // 全局点击空白区域收起键盘
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            // 点击空白区域收起键盘
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: child,
        );
      },
    );
  }
}
