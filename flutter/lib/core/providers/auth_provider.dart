import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../services/local_storage_service.dart';

/// 本地存储服务 Provider
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

/// Supabase 客户端 Provider（仅在非本地模式下使用）
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  if (AppConfig.useLocalMode) {
    // 本地模式下返回一个不会被使用的 placeholder
    throw UnimplementedError('Supabase client not available in local mode');
  }
  return Supabase.instance.client;
});

/// 认证状态（本地用户 ID）
final localUserIdProvider = StateProvider<String?>((ref) => null);

/// 统一的用户模型
class AuthUser {
  final String id;
  final String email;
  final String? name;

  const AuthUser({
    required this.id,
    required this.email,
    this.name,
  });
}

/// 当前用户 Provider
final currentUserProvider = StateProvider<AuthUser?>((ref) => null);

/// 是否已登录
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

/// 认证服务 Provider
final authServiceProvider = Provider<AuthService>((ref) {
  if (AppConfig.useLocalMode) {
    return LocalAuthService(ref.watch(localStorageServiceProvider), ref);
  }
  return SupabaseAuthService(ref.watch(supabaseClientProvider), ref);
});

/// 认证服务抽象类
abstract class AuthService {
  Future<AuthUser> signUp({required String email, required String password});
  Future<AuthUser> signIn({required String email, required String password});
  Future<void> signOut();
  Future<void> resetPassword(String email);
  Future<void> checkSession();
  AuthUser? get currentUser;
}

/// 本地认证服务实现
class LocalAuthService implements AuthService {
  final LocalStorageService _localStorage;
  final Ref _ref;

  LocalAuthService(this._localStorage, this._ref);

  @override
  Future<AuthUser> signUp({required String email, required String password}) async {
    final user = await _localStorage.signUp(email: email, password: password);
    final authUser = AuthUser(id: user.id, email: user.email, name: user.name);
    _ref.read(currentUserProvider.notifier).state = authUser;
    return authUser;
  }

  @override
  Future<AuthUser> signIn({required String email, required String password}) async {
    final user = await _localStorage.signIn(email: email, password: password);
    final authUser = AuthUser(id: user.id, email: user.email, name: user.name);
    _ref.read(currentUserProvider.notifier).state = authUser;
    return authUser;
  }

  @override
  Future<void> signOut() async {
    await _localStorage.signOut();
    _ref.read(currentUserProvider.notifier).state = null;
  }

  @override
  Future<void> resetPassword(String email) async {
    // 本地模式下不需要真正的密码重置
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> checkSession() async {
    final user = await _localStorage.getCurrentUser();
    if (user != null) {
      _ref.read(currentUserProvider.notifier).state = AuthUser(
        id: user.id,
        email: user.email,
        name: user.name,
      );
    }
  }

  @override
  AuthUser? get currentUser => _ref.read(currentUserProvider);
}

/// Supabase 认证服务实现
class SupabaseAuthService implements AuthService {
  final SupabaseClient _client;
  final Ref _ref;

  SupabaseAuthService(this._client, this._ref);

  @override
  Future<AuthUser> signUp({required String email, required String password}) async {
    final response = await _client.auth.signUp(email: email, password: password);
    final user = response.user;
    if (user == null) throw Exception('Sign up failed');
    final authUser = AuthUser(id: user.id, email: user.email ?? email);
    _ref.read(currentUserProvider.notifier).state = authUser;
    return authUser;
  }

  @override
  Future<AuthUser> signIn({required String email, required String password}) async {
    final response = await _client.auth.signInWithPassword(email: email, password: password);
    final user = response.user;
    if (user == null) throw Exception('Sign in failed');
    final authUser = AuthUser(id: user.id, email: user.email ?? email);
    _ref.read(currentUserProvider.notifier).state = authUser;
    return authUser;
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
    _ref.read(currentUserProvider.notifier).state = null;
  }

  @override
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  @override
  Future<void> checkSession() async {
    final user = _client.auth.currentUser;
    if (user != null) {
      _ref.read(currentUserProvider.notifier).state = AuthUser(
        id: user.id,
        email: user.email ?? '',
      );
    }
  }

  @override
  AuthUser? get currentUser {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return AuthUser(id: user.id, email: user.email ?? '');
  }

  /// Google 登录（仅 Supabase 模式）
  Future<bool> signInWithGoogle() async {
    return await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.pawprint://callback',
    );
  }

  /// Apple 登录（仅 Supabase 模式）
  Future<bool> signInWithApple() async {
    return await _client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'io.supabase.pawprint://callback',
    );
  }
}