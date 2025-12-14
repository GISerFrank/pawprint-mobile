import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/models/models.dart';
import '../../../../core/config/app_config.dart';
import '../../../../shared/widgets/widgets.dart';

class AIAnalysisPage extends ConsumerStatefulWidget {
  const AIAnalysisPage({super.key});

  @override
  ConsumerState<AIAnalysisPage> createState() => _AIAnalysisPageState();
}

class _AIAnalysisPageState extends ConsumerState<AIAnalysisPage> {
  BodyPart _selectedPart = BodyPart.skinFur;
  final _symptomsController = TextEditingController();
  Uint8List? _currentImage;
  bool _useBaseline = true;

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await ImagePickerHelper.showPicker(context);
    if (result != null) {
      setState(() => _currentImage = result.bytes);
      showAppNotification(context,
          message: 'Photo added', type: NotificationType.success);
    }
  }

  Future<void> _analyze() async {
    if (_symptomsController.text.isEmpty) {
      showAppNotification(context,
          message: 'Please describe the symptoms',
          type: NotificationType.error);
      return;
    }

    final pet = ref.read(currentPetProvider).valueOrNull;
    if (pet == null) return;

    // 获取 baseline 图片（如果启用了对比功能）
    String? baselineImageBase64;
    if (_useBaseline && pet.bodyPartImages != null) {
      baselineImageBase64 = pet.bodyPartImages![_selectedPart];
    }

    await ref.read(aiAnalysisNotifierProvider.notifier).analyzeHealth(
          petId: pet.id,
          symptoms: _symptomsController.text,
          bodyPart: _selectedPart,
          currentImageBytes: _currentImage,
          baselineImageBase64: baselineImageBase64,
          useBaseline: _useBaseline && baselineImageBase64 != null,
        );

    // 分析完成后显示通知
    final state = ref.read(aiAnalysisNotifierProvider);
    if (mounted) {
      if (state.error != null) {
        showAppNotification(context,
            message: state.error!, type: NotificationType.error);
      } else if (state.result != null) {
        showAppNotification(context,
            message: 'Analysis complete!', type: NotificationType.success);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final petAsync = ref.watch(currentPetProvider);
    final analysisState = ref.watch(aiAnalysisNotifierProvider);
    final historyAsync = ref.watch(aiAnalysisHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: petAsync.when(
          loading: () => const Center(child: AppLoadingIndicator()),
          error: (e, _) => ErrorStateWidget(
              message: 'Failed to load',
              onRetry: () => ref.invalidate(currentPetProvider)),
          data: (pet) {
            if (pet == null) {
              return const Center(child: Text('No pet selected'));
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(context),
                  const SizedBox(height: 24),

                  // Input Card
                  _buildInputCard(context, pet, analysisState),
                  const SizedBox(height: 24),

                  // Result
                  if (analysisState.result != null) ...[
                    _buildResultCard(context, analysisState.result!, pet.name),
                    const SizedBox(height: 24),
                  ],

                  // History
                  historyAsync.when(
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                    data: (history) {
                      if (history.isEmpty) return const SizedBox();
                      return _buildHistory(context, history);
                    },
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final hasApiKey = AppConfig.geminiApiKey.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.primary100, AppColors.sky100]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.auto_awesome,
                  color: AppColors.primary500, size: 28),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Health Assistant',
                    style: Theme.of(context).textTheme.headlineSmall),
                const Text('Describe symptoms for analysis',
                    style: TextStyle(color: AppColors.stone500)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 状态提示
        if (AppConfig.useLocalMode && !hasApiKey)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.peach100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.peach200),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.peach500, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Demo mode: Add Gemini API key for real AI analysis',
                    style: TextStyle(
                        color: AppColors.peach500,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          )
        else if (hasApiKey)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.mint100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.mint100),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.mint500, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI-powered analysis enabled via Gemini',
                    style: TextStyle(
                        color: AppColors.mint500,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildInputCard(BuildContext context, Pet pet, AIAnalysisState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Body Part Selector
          const Text('Where is the issue?',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.stone600,
                  fontSize: 12)),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: BodyPart.values.map((part) {
                final selected = _selectedPart == part;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedPart = part),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color:
                            selected ? AppColors.primary500 : AppColors.stone50,
                        borderRadius: BorderRadius.circular(20),
                        border: selected
                            ? null
                            : Border.all(color: AppColors.stone100),
                      ),
                      child: Text(
                        part.displayName,
                        style: TextStyle(
                          color: selected ? Color.fromARGB(255, 255, 146, 37) : AppColors.stone600,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Symptoms Input
          const Text('Describe the symptoms',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.stone600,
                  fontSize: 12)),
          const SizedBox(height: 8),
          TextField(
            controller: _symptomsController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText:
                  'e.g., ${pet.name} is scratching their ${_selectedPart.displayName.toLowerCase()} excessively...',
              filled: true,
              fillColor: AppColors.stone50,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),

          // Image Section
          const Text('Photos (Optional)',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.stone600,
                  fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            children: [
              // Current Image
              Expanded(
                child: _currentImage != null
                    ? _ImagePreview(
                        imageBytes: _currentImage,
                        label: 'Current',
                        onRemove: () => setState(() => _currentImage = null),
                      )
                    : _ImagePlaceholder(
                        label: 'Add Photo',
                        onTap: _pickImage,
                      ),
              ),
              const SizedBox(width: 12),
              // Baseline Image Display
              Expanded(
                child: _buildBaselineSection(pet),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Analyze Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: state.isLoading ? null : _analyze,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary500,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: state.isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white)),
                        SizedBox(width: 12),
                        Text('Analyzing...'),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Start Analysis'),
                        SizedBox(width: 8),
                        Icon(Icons.auto_awesome, size: 20),
                      ],
                    ),
            ),
          ),

          if (state.error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(state.error!,
                          style:
                              const TextStyle(color: AppColors.error, fontSize: 13))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建 Baseline 图片区域
  Widget _buildBaselineSection(Pet pet) {
    final baselineImage = pet.bodyPartImages?[_selectedPart];
    final hasBaseline = baselineImage != null && baselineImage.isNotEmpty;

    if (hasBaseline) {
      // 有 Baseline 图片时显示
      return Container(
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _useBaseline ? AppColors.primary300 : AppColors.stone200,
            width: _useBaseline ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            // 图片
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _buildBaselineImage(baselineImage),
            ),
            // 底部控制栏
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Compare',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.stone600,
                      ),
                    ),
                    SizedBox(
                      height: 24,
                      child: Transform.scale(
                        scale: 0.7,
                        child: Switch(
                          value: _useBaseline,
                          onChanged: (v) => setState(() => _useBaseline = v),
                          activeColor: AppColors.primary500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 标签
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Baseline',
                  style: TextStyle(
                      color: Color.fromARGB(255, 255, 146, 37),
                      fontSize: 9,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // 没有 Baseline 图片时显示提示
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.stone50,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: AppColors.stone200, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.photo_library_outlined,
                color: AppColors.stone400, size: 24),
            const SizedBox(height: 4),
            const Text(
              'No baseline for',
              style: TextStyle(fontSize: 10, color: AppColors.stone500),
            ),
            Text(
              _selectedPart.displayName,
              style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.stone500,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Add in Profile',
              style: TextStyle(fontSize: 9, color: AppColors.primary500),
            ),
          ],
        ),
      );
    }
  }

  /// 从 base64 或 URL 构建图片
  Widget _buildBaselineImage(String imageUrl) {
    if (imageUrl.startsWith('data:')) {
      try {
        final base64Data = imageUrl.split(',').last;
        final bytes = base64Decode(base64Data);
        return Image.memory(
          Uint8List.fromList(bytes),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      } catch (e) {
        return const Center(
            child: Icon(Icons.broken_image, color: AppColors.stone400));
      }
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) =>
          const Center(child: Icon(Icons.broken_image, color: AppColors.stone400)),
    );
  }

  Widget _buildResultCard(BuildContext context, String result, String petName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.peach100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lightbulb, color: AppColors.peach500),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Insight',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.stone800)),
                  Text('Generated Assessment',
                      style:
                          TextStyle(fontSize: 12, color: AppColors.stone500)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // Markdown Result
          MarkdownBody(
            data: result,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(color: AppColors.stone600, height: 1.6),
              strong: const TextStyle(
                  color: AppColors.stone800, fontWeight: FontWeight.bold),
              h1: const TextStyle(
                  color: AppColors.primary700, fontWeight: FontWeight.bold),
              h2: const TextStyle(
                  color: AppColors.primary700, fontWeight: FontWeight.bold),
              h3: const TextStyle(
                  color: AppColors.primary700, fontWeight: FontWeight.bold),
              listBullet: const TextStyle(color: AppColors.stone600),
            ),
          ),

          const SizedBox(height: 16),

          // Disclaimer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.peach50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.peach200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber, color: AppColors.peach500, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This is not a medical diagnosis. If $petName seems in pain or distress, please visit a real veterinarian immediately.',
                    style: const TextStyle(
                        color: AppColors.peach500,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Copy button
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: result));
              showAppNotification(context,
                  message: 'Copied to clipboard',
                  type: NotificationType.success);
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy Analysis'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.stone600,
              side: const BorderSide(color: AppColors.stone200),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistory(BuildContext context, List<AIAnalysisSession> history) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.history, color: AppColors.stone500, size: 20),
            SizedBox(width: 8),
            Text('Past Consultations',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.stone700)),
          ],
        ),
        const SizedBox(height: 12),
        ...history
            .take(5)
            .map((session) => _HistoryItem(session: session))
            ,
      ],
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ImagePlaceholder({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.primary50,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: AppColors.primary200, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt, color: AppColors.primary400),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary500)),
          ],
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final Uint8List? imageBytes;
  final String label;
  final VoidCallback onRemove;

  const _ImagePreview(
      {this.imageBytes, required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: imageBytes != null
                ? DecorationImage(
                    image: MemoryImage(imageBytes!), fit: BoxFit.cover)
                : null,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                  color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
        Positioned(
          bottom: 4,
          left: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                color: Colors.black54, borderRadius: BorderRadius.circular(8)),
            child: Text(label,
                style: const TextStyle(
                    color: Color.fromARGB(255, 255, 146, 37),
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

class _HistoryItem extends StatefulWidget {
  final AIAnalysisSession session;

  const _HistoryItem({required this.session});

  @override
  State<_HistoryItem> createState() => _HistoryItemState();
}

class _HistoryItemState extends State<_HistoryItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => setState(() => _expanded = !_expanded),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: AppColors.sky50,
                  borderRadius: BorderRadius.circular(10)),
              child:
                  const Icon(Icons.calendar_today, color: AppColors.sky500, size: 20),
            ),
            title: Text('${widget.session.bodyPart.displayName} Issue',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              _formatDate(widget.session.createdAt),
              style: const TextStyle(fontSize: 12, color: AppColors.stone500),
            ),
            trailing: Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                color: AppColors.stone400),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text('Symptoms:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.stone600,
                          fontSize: 12)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: AppColors.stone50,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(widget.session.symptoms,
                        style: const TextStyle(
                            color: AppColors.stone600,
                            fontSize: 13,
                            fontStyle: FontStyle.italic)),
                  ),
                  const SizedBox(height: 12),
                  const Text('Analysis:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.stone600,
                          fontSize: 12)),
                  const SizedBox(height: 4),
                  MarkdownBody(
                    data: widget.session.analysisResult,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(color: AppColors.stone600, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    return '${months[dt.month - 1]} ${dt.day} at $h:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }
}
