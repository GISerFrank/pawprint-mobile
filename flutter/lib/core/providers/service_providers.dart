import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/services.dart';
import 'auth_provider.dart';

/// Local Storage 服务 Provider
final localStorageProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

/// Database 服务 Provider
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return DatabaseService(client);
});

/// Storage 服务 Provider
final storageServiceProvider = Provider<StorageService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return StorageService(client);
});

// AI 服务 Provider 已移至 ai/ai_service_provider.dart
// 使用: import '../services/ai/ai_service_provider.dart';
// - aiServiceProvider
// - isAIServiceAvailableProvider
// - aiProviderNameProvider