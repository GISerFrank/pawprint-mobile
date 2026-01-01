import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/pet_theme.dart';
import '../../../../../core/models/models.dart';

/// 记录详情弹窗
/// 通用组件，可用于 Daily Check、BCS、MCS、Custom Metrics 等
class LogDetailSheet extends StatelessWidget {
  final MetricLog log;
  final PetTheme theme;
  final String? metricName;
  final String? emoji;
  final int? maxScore; // 用于显示 x/maxScore，如 BCS 是 9，Daily Check 是 5

  const LogDetailSheet({
    super.key,
    required this.log,
    required this.theme,
    this.metricName,
    this.emoji,
    this.maxScore,
  });

  @override
  Widget build(BuildContext context) {
    final displayMaxScore = maxScore ?? 5;
    final hasRangeValue = log.rangeValue != null;
    final hasNumberValue = log.numberValue != null;
    final hasBoolValue = log.boolValue != null;
    final hasTextValue = log.textValue != null && log.textValue!.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 拖动指示器
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.stone300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 标题和时间
              Row(
                children: [
                  if (hasRangeValue)
                    _ScoreBadge(
                      score: log.rangeValue!,
                      maxScore: displayMaxScore,
                    )
                  else if (hasNumberValue)
                    _NumberBadge(value: log.numberValue!)
                  else if (hasBoolValue)
                    _BoolBadge(value: log.boolValue!)
                  else
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(emoji ?? '📊', style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (metricName != null)
                          Text(
                            metricName!,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else if (hasRangeValue)
                          Text(
                            'Score: ${log.rangeValue}/$displayMaxScore',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else if (hasNumberValue)
                          Text(
                            'Value: ${log.numberValue}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else if (hasBoolValue)
                          Text(
                            log.boolValue! ? 'Yes ✓' : 'No ✗',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEEE, MMMM d, yyyy • h:mm a').format(log.loggedAt),
                          style: TextStyle(
                            color: AppColors.stone500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // 文本值（如果有）
              if (hasTextValue) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Icon(Icons.text_fields, size: 18, color: AppColors.stone500),
                    const SizedBox(width: 8),
                    Text(
                      'Value',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.stone600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.stone50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    log.textValue!,
                    style: TextStyle(
                      color: AppColors.stone700,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],

              // 备注
              if (log.notes != null && log.notes!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Icon(Icons.notes, size: 18, color: AppColors.stone500),
                    const SizedBox(width: 8),
                    Text(
                      'Notes',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.stone600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.stone50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    log.notes!,
                    style: TextStyle(
                      color: AppColors.stone700,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],

              // 图片
              if (log.imageUrls != null && log.imageUrls!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Icon(Icons.photo_library, size: 18, color: AppColors.stone500),
                    const SizedBox(width: 8),
                    Text(
                      'Photos (${log.imageUrls!.length})',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.stone600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: log.imageUrls!.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final url = log.imageUrls![index];
                      return GestureDetector(
                        onTap: () => _showFullImage(context, url),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildImage(url),
                        ),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // 关闭按钮
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: AppColors.stone300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildErrorPlaceholder(),
      );
    } else {
      return Image.file(
        File(path),
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildErrorPlaceholder(),
      );
    }
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      width: 120,
      height: 120,
      color: AppColors.stone200,
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }

  void _showFullImage(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildFullImage(path),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullImage(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(path, fit: BoxFit.contain);
    } else {
      return Image.file(File(path), fit: BoxFit.contain);
    }
  }
}

/// 分数徽章
class _ScoreBadge extends StatelessWidget {
  final int score;
  final int maxScore;

  const _ScoreBadge({
    required this.score,
    required this.maxScore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _getScoreColor(score, maxScore).withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          '$score',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _getScoreColor(score, maxScore),
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(int score, int maxScore) {
    if (maxScore == 9) {
      // BCS scoring
      if (score <= 2) return AppColors.orange500;
      if (score <= 4) return AppColors.amber500;
      if (score == 5) return AppColors.green500;
      if (score <= 7) return AppColors.amber500;
      return AppColors.red500;
    } else if (maxScore == 3) {
      // MCS scoring
      if (score == 0) return AppColors.green500;
      if (score == 1) return AppColors.amber500;
      if (score == 2) return AppColors.orange500;
      return AppColors.red500;
    } else {
      // Default 1-5 scoring
      if (score == 1) return AppColors.red500;
      if (score == 2) return AppColors.orange500;
      if (score == 3) return AppColors.amber500;
      if (score == 4) return AppColors.lime500;
      return AppColors.green500;
    }
  }
}

/// 数值徽章
class _NumberBadge extends StatelessWidget {
  final double value;

  const _NumberBadge({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.blue100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1),
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.blue600,
        ),
      ),
    );
  }
}

/// 布尔值徽章
class _BoolBadge extends StatelessWidget {
  final bool value;

  const _BoolBadge({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: value ? AppColors.green100 : AppColors.red100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Icon(
          value ? Icons.check : Icons.close,
          color: value ? AppColors.green600 : AppColors.red600,
          size: 28,
        ),
      ),
    );
  }
}

/// 显示记录详情的辅助函数
void showLogDetailSheet(
  BuildContext context, {
  required MetricLog log,
  required PetTheme theme,
  String? metricName,
  String? emoji,
  int? maxScore,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => LogDetailSheet(
      log: log,
      theme: theme,
      metricName: metricName,
      emoji: emoji,
      maxScore: maxScore,
    ),
  );
}
