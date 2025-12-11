import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../models/models.dart';

/// Gemini API 服务（通过 Supabase Edge Function 中转）
class GeminiService {
  final SupabaseClient _client;

  GeminiService(this._client);

  /// 调用 Edge Function
  Future<Map<String, dynamic>> _callEdgeFunction({
    required String action,
    required Map<String, dynamic> payload,
  }) async {
    final session = _client.auth.currentSession;
    if (session == null) throw Exception('User not authenticated');

    final response = await http.post(
      Uri.parse(AppConfig.geminiApiUrl),
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'action': action,
        'payload': payload,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('API call failed: ${response.body}');
    }

    final data = jsonDecode(response.body);
    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Unknown error');
    }

    return data['data'];
  }

  /// 分析宠物健康状况
  Future<String> analyzePetHealth({
    required String symptoms,
    required BodyPart bodyPart,
    String? currentImageBase64,
    String? baselineImageBase64,
  }) async {
    try {
      final result = await _callEdgeFunction(
        action: 'analyze_health',
        payload: {
          'symptoms': symptoms,
          'bodyPart': bodyPart.displayName,
          if (currentImageBase64 != null) 'currentImageBase64': currentImageBase64,
          if (baselineImageBase64 != null) 'baselineImageBase64': baselineImageBase64,
        },
      );

      return result as String? ?? 'Sorry, I could not generate an analysis at this time.';
    } catch (e) {
      return 'An error occurred while communicating with the AI. Please try again later.\n\nError: $e';
    }
  }

  /// 生成宠物性格描述
  Future<PetPersonality> generatePetPersonality({
    required String imageBase64,
  }) async {
    try {
      final result = await _callEdgeFunction(
        action: 'generate_personality',
        payload: {
          'imageBase64': imageBase64,
        },
      );

      return PetPersonality(
        tags: List<String>.from(result['tags'] ?? []),
        description: result['description'] ?? 'A mysterious and lovely friend.',
      );
    } catch (e) {
      return const PetPersonality(
        tags: ['Mystery', 'Cute', 'Unknown'],
        description: 'A mysterious and lovely friend.',
      );
    }
  }

  /// 生成卡通头像
  Future<Uint8List?> generateCartoonAvatar({
    required String imageBase64,
    required IDCardStyle style,
  }) async {
    try {
      final result = await _callEdgeFunction(
        action: 'generate_cartoon',
        payload: {
          'imageBase64': imageBase64,
          'style': style.displayName,
        },
      );

      if (result == null) return null;

      // 结果是 data:image/png;base64,... 格式
      final base64String = result as String;
      final base64Data = base64String.split(',').last;
      return base64Decode(base64Data);
    } catch (e) {
      return null;
    }
  }

  /// 生成收藏卡牌
  Future<GeneratedCard?> generateCollectibleCard({
    required String imageBase64,
    required PackTheme theme,
    required String species,
  }) async {
    try {
      final result = await _callEdgeFunction(
        action: 'generate_collectible_card',
        payload: {
          'imageBase64': imageBase64,
          'theme': theme.displayName,
          'species': species,
        },
      );

      if (result == null || result['image'] == null) return null;

      final imageBase64String = result['image'] as String;
      final imageData = base64Decode(imageBase64String.split(',').last);

      return GeneratedCard(
        name: result['name'] ?? '${theme.displayName} Card',
        description: result['description'] ?? 'A special card for your collection.',
        rarity: Rarity.fromString(result['rarity'] ?? 'Common'),
        tags: List<String>.from(result['tags'] ?? []),
        imageData: imageData,
      );
    } catch (e) {
      return null;
    }
  }
}

/// 宠物性格数据
class PetPersonality {
  final List<String> tags;
  final String description;

  const PetPersonality({
    required this.tags,
    required this.description,
  });
}

/// 生成的卡牌数据（带图片字节）
class GeneratedCard {
  final String name;
  final String description;
  final Rarity rarity;
  final List<String> tags;
  final Uint8List imageData;

  const GeneratedCard({
    required this.name,
    required this.description,
    required this.rarity,
    required this.tags,
    required this.imageData,
  });
}
