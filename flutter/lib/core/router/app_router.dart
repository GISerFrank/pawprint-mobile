import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/health_records/presentation/pages/health_records_page.dart';
import '../../features/ai_analysis/presentation/pages/ai_analysis_page.dart';
import '../../features/forum/presentation/pages/forum_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/cards/presentation/pages/card_shop_page.dart';
import '../shell/main_shell.dart';
import '../providers/auth_provider.dart';
import '../providers/pet_provider.dart';

/// 路由名称常量
class AppRoutes {
  AppRoutes._();

  // Auth
  static const String login = '/login';
  static const String register = '/register';

  // Onboarding
  static const String onboarding = '/onboarding';

  // Main tabs
  static const String home = '/';
  static const String records = '/records';
  static const String analysis = '/analysis';
  static const String forum = '/forum';
  static const String profile = '/profile';

  // Sub pages
  static const String cardShop = '/cards';
}

/// 路由配置 Provider
final appRouterProvider = Provider<GoRouter>((ref) {
  final isLoggedIn = ref.watch(isLoggedInProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,

    // 重定向逻辑
    redirect: (context, state) async {
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;
      final isOnboarding = state.matchedLocation == AppRoutes.onboarding;

      // 未登录 -> 登录页
      if (!isLoggedIn && !isAuthRoute) {
        return AppRoutes.login;
      }

      // 已登录但在登录页
      if (isLoggedIn && isAuthRoute) {
        // 检查是否已完成 onboarding (有宠物)
        try {
          final pets = await ref.read(petsListProvider.future);
          if (pets.isEmpty) {
            return AppRoutes.onboarding;
          }
        } catch (_) {
          return AppRoutes.onboarding;
        }
        return AppRoutes.home;
      }

      return null;
    },

    routes: [
      // Auth routes
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),

      // Onboarding
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),

      // Main shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomePage(),
            ),
          ),
          GoRoute(
            path: AppRoutes.records,
            name: 'records',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HealthRecordsPage(),
            ),
          ),
          GoRoute(
            path: AppRoutes.analysis,
            name: 'analysis',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AIAnalysisPage(),
            ),
          ),
          GoRoute(
            path: AppRoutes.forum,
            name: 'forum',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ForumPage(),
            ),
          ),
          GoRoute(
            path: AppRoutes.profile,
            name: 'profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfilePage(),
            ),
          ),
        ],
      ),

      // Standalone pages (outside of shell)
      GoRoute(
        path: AppRoutes.cardShop,
        name: 'cardShop',
        builder: (context, state) => const CardShopPage(),
      ),
    ],

    // 错误页面
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.matchedLocation}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});