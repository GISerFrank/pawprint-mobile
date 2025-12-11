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

/// Gemini AI 服务 Provider
final geminiServiceProvider = Provider<GeminiService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return GeminiService(client);
});
