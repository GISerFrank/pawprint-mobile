import '../config/app_config.dart';
import '../models/models.dart';
import 'gemini_direct_service.dart';
import 'qwen_service.dart';

/// 统一的 AI 服务接口
/// 根据配置自动选择使用 Gemini 或 Qwen
class AIService {
  GeminiDirectService? _geminiService;
  QwenService? _qwenService;

  AIService() {
    _initService();
  }

  void _initService() {
    if (!AppConfig.isAIConfigured) {
      return;
    }

    try {
      if (AppConfig.aiProvider == AIProvider.qwen) {
        _qwenService = QwenService();
      } else {
        _geminiService = GeminiDirectService();
      }
    } catch (e) {
      print('Failed to initialize AI service: $e');
    }
  }

  /// 检查服务是否可用
  bool get isAvailable => _geminiService != null || _qwenService != null;

  /// 获取当前使用的提供商名称
  String get providerName => AppConfig.aiProviderName;

  /// 分析宠物健康状况
  Future<String> analyzePetHealth({
    required String symptoms,
    required BodyPart bodyPart,
    String? currentImageBase64,
    String? baselineImageBase64,
  }) async {
    if (_qwenService != null) {
      return _qwenService!.analyzePetHealth(
        symptoms: symptoms,
        bodyPart: bodyPart,
        currentImageBase64: currentImageBase64,
        baselineImageBase64: baselineImageBase64,
      );
    } else if (_geminiService != null) {
      return _geminiService!.analyzePetHealth(
        symptoms: symptoms,
        bodyPart: bodyPart,
        currentImageBase64: currentImageBase64,
        baselineImageBase64: baselineImageBase64,
      );
    }
    throw Exception('AI service not configured');
  }

  /// 生成宠物性格描述
  Future<PetPersonality> generatePetPersonality({
    required String imageBase64,
  }) async {
    if (_qwenService != null) {
      return _qwenService!.generatePetPersonality(imageBase64: imageBase64);
    } else if (_geminiService != null) {
      return _geminiService!.generatePetPersonality(imageBase64: imageBase64);
    }
    throw Exception('AI service not configured');
  }

  /// 根据宠物信息生成个性化的护理指标
  Future<List<GeneratedMetricData>> generateInitialCareMetrics({
    required PetInfoForMetrics petInfo,
  }) async {
    if (_qwenService != null) {
      return _qwenService!.generateInitialCareMetrics(petInfo: petInfo);
    } else if (_geminiService != null) {
      return _geminiService!.generateInitialCareMetrics(petInfo: petInfo);
    }
    throw Exception('AI service not configured');
  }

  /// 生成卡通头像
  Future<String?> generateCartoonAvatar({
    required String imageBase64,
    required IDCardStyle style,
  }) async {
    if (_qwenService != null) {
      return _qwenService!.generateCartoonAvatar(
        imageBase64: imageBase64,
        style: style,
      );
    } else if (_geminiService != null) {
      return _geminiService!.generateCartoonAvatar(
        imageBase64: imageBase64,
        style: style,
      );
    }
    return null;
  }

  /// 生成收藏卡牌
  Future<GeneratedCardData?> generateCollectibleCard({
    required String imageBase64,
    required PackTheme theme,
    required String species,
  }) async {
    if (_qwenService != null) {
      return _qwenService!.generateCollectibleCard(
        imageBase64: imageBase64,
        theme: theme,
        species: species,
      );
    } else if (_geminiService != null) {
      return _geminiService!.generateCollectibleCard(
        imageBase64: imageBase64,
        theme: theme,
        species: species,
      );
    }
    return null;
  }
}