import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/services.dart';
import 'auth_provider.dart';

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

/// Gemini AI 服务 Provider（通过 Supabase Edge Function）
final geminiServiceProvider = Provider<GeminiService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return GeminiService(client);
});

/// Gemini Direct 服务 Provider（直接调用 API，用于本地开发）
final geminiDirectServiceProvider = Provider<GeminiDirectService>((ref) {
  return GeminiDirectService();
});