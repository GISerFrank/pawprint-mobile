import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/pet_theme.dart';
import '../../../../../core/models/models.dart';
import '../../../../../core/models/metrics/base_metrics.dart';
import '../../../../../core/providers/wellness_provider.dart';
import 'metric_attachment_input.dart';

/// BCS 评分选择器底部弹窗
class BCSelectorSheet extends ConsumerStatefulWidget {
  final Pet pet;
  final PetTheme theme;

  const BCSelectorSheet({
    super.key,
    required this.pet,
    required this.theme,
  });

  @override
  ConsumerState<BCSelectorSheet> createState() => _BCSelectorSheetState();
}

class _BCSelectorSheetState extends ConsumerState<BCSelectorSheet> {
  int _selectedScore = 5;
  bool _isSaving = false;
  final PageController _pageController =
      PageController(initialPage: 4); // 从 BCS 5 开始
  final _notesController = TextEditingController();
  final List<String> _imageUrls = [];

  @override
  void initState() {
    super.initState();
    // 加载当前 BCS 值
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentBCS();
    });
  }

  Future<void> _loadCurrentBCS() async {
    final currentBCS = await ref.read(currentBCSProvider.future);
    if (currentBCS != null && mounted) {
      setState(() => _selectedScore = currentBCS);
      _pageController.jumpToPage(currentBCS - 1);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final levels =
        widget.pet.species == PetSpecies.dog ? BCSLevels.dog : BCSLevels.cat;
    final imageState = ref.watch(bodyScoreImageProvider(widget.pet.id));

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 拖动指示器
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.stone300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 标题
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.amber50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('🏋️', style: TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Body Condition Score',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Select ${widget.pet.name}\'s current body condition',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.stone500,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // 分数选择条
          _ScoreSelector(
            selectedScore: _selectedScore,
            onScoreChanged: (score) {
              setState(() => _selectedScore = score);
              _pageController.animateToPage(
                score - 1,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          ),

          const SizedBox(height: 16),

          // 卡片页面
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: 9,
              onPageChanged: (index) {
                setState(() => _selectedScore = index + 1);
              },
              itemBuilder: (context, index) {
                final score = index + 1;
                final level = levels[index];
                return _BCSScoreCard(
                  score: score,
                  level: level,
                  pet: widget.pet,
                  theme: widget.theme,
                  generatedImage: imageState.bcsImages[score],
                  isGenerating: imageState.isGenerating &&
                      imageState.currentScore == score,
                  onGenerateImage: () => _generateImage(score),
                );
              },
            ),
          ),

          // 附件输入
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: MetricAttachmentInput(
              notesController: _notesController,
              imageUrls: _imageUrls,
              onImagesChanged: (urls) => setState(() {
                _imageUrls.clear();
                _imageUrls.addAll(urls);
              }),
            ),
          ),
          const SizedBox(height: 12),

          // 底部按钮
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveBCS,
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.theme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Save BCS $_selectedScore',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveBCS() async {
    setState(() => _isSaving = true);

    final success =
        await ref.read(wellnessScoreNotifierProvider.notifier).saveBCSScore(
              petId: widget.pet.id,
              score: _selectedScore,
              notes: _notesController.text.isNotEmpty
                  ? _notesController.text
                  : null,
              imageUrls: _imageUrls.isNotEmpty ? _imageUrls : null,
            );

    setState(() => _isSaving = false);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('BCS $_selectedScore saved!'),
          backgroundColor: AppColors.green500,
        ),
      );
    }
  }

  Future<void> _generateImage(int score) async {
    await ref
        .read(bodyScoreImageProvider(widget.pet.id).notifier)
        .generateBCSImage(score);
  }
}

/// 分数选择条
class _ScoreSelector extends StatelessWidget {
  final int selectedScore;
  final ValueChanged<int> onScoreChanged;

  const _ScoreSelector({
    required this.selectedScore,
    required this.onScoreChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.stone100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(9, (index) {
          final score = index + 1;
          final isSelected = score == selectedScore;
          final color = _getScoreColor(score);

          return Expanded(
            child: GestureDetector(
              onTap: () => onScoreChanged(score),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$score',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : AppColors.stone600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score <= 2) return AppColors.orange500;
    if (score <= 4) return AppColors.amber500;
    if (score == 5) return AppColors.green500;
    if (score <= 7) return AppColors.amber500;
    return AppColors.red500;
  }
}

/// BCS 分数卡片
class _BCSScoreCard extends StatelessWidget {
  final int score;
  final ScoreLevel level;
  final Pet pet;
  final PetTheme theme;
  final String? generatedImage;
  final bool isGenerating;
  final VoidCallback onGenerateImage;

  const _BCSScoreCard({
    required this.score,
    required this.level,
    required this.pet,
    required this.theme,
    this.generatedImage,
    required this.isGenerating,
    required this.onGenerateImage,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getScoreColor();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 状态标签
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  level.label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (score == 5) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.check_circle, size: 16, color: color),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 图片区域
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.stone100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.stone200),
            ),
            child: generatedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: _buildImage(generatedImage!),
                  )
                : _PlaceholderImage(
                    score: score,
                    isGenerating: isGenerating,
                    onGenerate: onGenerateImage,
                    petName: pet.name,
                  ),
          ),
          const SizedBox(height: 16),

          // 描述
          Text(
            'Characteristics',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.stone800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            level.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.stone600,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 16),

          // 中文描述
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.stone50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🇨🇳', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    level.descriptionZh,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.stone600,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// 根据图片数据类型构建 Image widget
  Widget _buildImage(String imageData) {
    // 如果是 URL（http 或 https 开头）
    if (imageData.startsWith('http://') || imageData.startsWith('https://')) {
      return Image.network(
        imageData,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: AppColors.red400, size: 32),
                const SizedBox(height: 8),
                Text('Failed to load',
                    style: TextStyle(color: AppColors.stone500, fontSize: 12)),
              ],
            ),
          );
        },
      );
    }

    // 如果是 base64 data URI
    if (imageData.startsWith('data:')) {
      final base64Data = imageData.split(',').last;
      return Image.memory(
        base64Decode(base64Data),
        fit: BoxFit.cover,
      );
    }

    // 尝试直接作为 base64 解析
    try {
      return Image.memory(
        base64Decode(imageData),
        fit: BoxFit.cover,
      );
    } catch (e) {
      return Center(
        child: Text('Invalid image data',
            style: TextStyle(color: AppColors.stone500)),
      );
    }
  }

  Color _getScoreColor() {
    if (score <= 2) return AppColors.orange500;
    if (score <= 4) return AppColors.amber500;
    if (score == 5) return AppColors.green500;
    if (score <= 7) return AppColors.amber500;
    return AppColors.red500;
  }
}

/// 占位图片
class _PlaceholderImage extends StatelessWidget {
  final int score;
  final bool isGenerating;
  final VoidCallback onGenerate;
  final String petName;

  const _PlaceholderImage({
    required this.score,
    required this.isGenerating,
    required this.onGenerate,
    required this.petName,
  });

  @override
  Widget build(BuildContext context) {
    if (isGenerating) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Generating $petName\'s image...',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.stone500,
                ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: onGenerate,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.stone200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome,
              size: 32,
              color: AppColors.stone500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Generate ${petName}\'s BCS $score image',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.stone600,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap to create personalized reference',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.stone400,
                ),
          ),
        ],
      ),
    );
  }
}
