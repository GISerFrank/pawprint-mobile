import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/app_config.dart';
import '../../../models/models.dart';
import '../ai_service.dart';
import '../ai_types.dart';

/// Gemini via Supabase Edge Function 实现
/// 用于生产环境，API Key 存储在服务端
class GeminiEdgeService extends BaseAIService {
  final SupabaseClient _client;

  GeminiEdgeService(this._client);

  @override
  String get providerName => 'Gemini (Edge)';

  @override
  bool get isAvailable => true;

  Future<Map<String, dynamic>> _invokeFunction(
    String functionName,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.functions.invoke(
      functionName,
      body: body,
    );

    if (response.status != 200) {
      throw Exception('Edge function error: ${response.status}');
    }

    return response.data as Map<String, dynamic>;
  }

  @override
  Future<String> analyzePetHealth({
    required String symptoms,
    required BodyPart bodyPart,
    String? currentImageBase64,
    String? baselineImageBase64,
  }) async {
    final response = await _invokeFunction('gemini-api', {
      'action': 'analyzePetHealth',
      'symptoms': symptoms,
      'bodyPart': bodyPart.name,
      'currentImage': currentImageBase64,
      'baselineImage': baselineImageBase64,
    });

    return response['result'] as String? ??
        'Unable to analyze. Please try again.';
  }

  @override
  Future<PetPersonality> generatePetPersonality({
    required String imageBase64,
  }) async {
    try {
      final response = await _invokeFunction('gemini-api', {
        'action': 'generatePersonality',
        'image': imageBase64,
      });

      return PetPersonality(
        tags: List<String>.from(
            response['tags'] ?? ['Mystery', 'Cute', 'Unknown']),
        description:
            response['description'] ?? 'A mysterious and lovely friend.',
      );
    } catch (e) {
      print('Error generating personality via Edge Function: $e');
      return PetPersonality.empty();
    }
  }

  @override
  Future<List<GeneratedMetricData>> generateInitialCareMetrics({
    required PetInfoForMetrics petInfo,
  }) async {
    try {
      final response = await _invokeFunction('gemini-api', {
        'action': 'generateCareMetrics',
        'petInfo': petInfo.toPromptContext(),
      });

      final List<dynamic> metrics = response['metrics'] ?? [];
      return metrics
          .map((item) =>
              GeneratedMetricData.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error generating care metrics via Edge Function: $e');
      rethrow;
    }
  }

  @override
  Future<String?> generateCartoonAvatar({
    required String imageBase64,
    required IDCardStyle style,
  }) async {
    try {
      final response = await _invokeFunction('gemini-api', {
        'action': 'generateCartoonAvatar',
        'image': imageBase64,
        'style': style.name,
      });

      return response['imageUrl'] as String?;
    } catch (e) {
      print('Error generating cartoon avatar via Edge Function: $e');
      return null;
    }
  }

  @override
  Future<GeneratedCardData?> generateCollectibleCard({
    required String imageBase64,
    required PackTheme theme,
    required String species,
  }) async {
    try {
      final response = await _invokeFunction('gemini-api', {
        'action': 'generateCollectibleCard',
        'image': imageBase64,
        'theme': theme.name,
        'species': species,
      });

      if (response['card'] == null) return null;

      final card = response['card'] as Map<String, dynamic>;
      return GeneratedCardData(
        name: card['name'] ?? 'Mystery Card',
        description: card['description'] ?? 'A mysterious collectible card.',
        rarity: parseRarity(card['rarity']),
        tags: List<String>.from(card['tags'] ?? ['Mystery']),
        imageBase64: card['imageUrl'] ?? '',
      );
    } catch (e) {
      print('Error generating collectible card via Edge Function: $e');
      return null;
    }
  }

  @override
  Future<String?> generateBodyScoreImage({
    required String petImageBase64,
    required String referenceImageBase64,
    required String prompt,
  }) async {
    try {
      final response = await _invokeFunction('gemini-api', {
        'action': 'generateBodyScoreImage',
        'petImage': petImageBase64,
        'referenceImage': referenceImageBase64,
        'prompt': prompt,
      });

      return response['imageUrl'] as String?;
    } catch (e) {
      print('Error generating body score image via Edge Function: $e');
      return null;
    }
  }
}
