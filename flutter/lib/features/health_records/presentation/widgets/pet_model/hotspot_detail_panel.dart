import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/pet_theme.dart';
import '../../../../../core/models/models.dart';
import '../../../../../core/providers/wellness_provider.dart';
import 'pet_model_viewer.dart';

/// 热点详情面板 - 显示关联指标的详细信息
class HotspotDetailPanel extends ConsumerWidget {
  final ModelHotspot hotspot;
  final PetTheme theme;
  final VoidCallback? onClose;
  final Function(String metricId)? onMetricTap;

  const HotspotDetailPanel({
    super.key,
    required this.hotspot,
    required this.theme,
    this.onClose,
    this.onMetricTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(hotspot.emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hotspot.label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${hotspot.metricIds.length} related metrics',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.stone500,
                      ),
                    ),
                  ],
                ),
              ),
              if (onClose != null)
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          
          // 关联指标列表
          ...hotspot.metricIds.map((metricId) => _MetricRow(
            metricId: metricId,
            theme: theme,
            onTap: onMetricTap != null ? () => onMetricTap!(metricId) : null,
          )),
        ],
      ),
    );
  }
}

/// 单个指标行
class _MetricRow extends ConsumerWidget {
  final String metricId;
  final PetTheme theme;
  final VoidCallback? onTap;

  const _MetricRow({
    required this.metricId,
    required this.theme,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricInfo = _getMetricInfo(metricId);
    // TODO: 从 provider 获取实际分数
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Text(metricInfo.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metricInfo.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    metricInfo.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.stone500,
                    ),
                  ),
                ],
              ),
            ),
            // 分数/状态
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.stone100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'N/A',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.stone600,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: AppColors.stone400),
          ],
        ),
      ),
    );
  }

  _MetricInfo _getMetricInfo(String metricId) {
    switch (metricId) {
      case 'bcs':
        return _MetricInfo('🏋️', 'Body Condition', 'Overall body shape');
      case 'weight':
        return _MetricInfo('⚖️', 'Weight', 'Current weight');
      case 'mcs':
        return _MetricInfo('💪', 'Muscle Condition', 'Muscle mass score');
      case 'appetite':
        return _MetricInfo('🍽️', 'Appetite', 'Interest in food');
      case 'vomiting':
        return _MetricInfo('🤮', 'Vomiting', 'Any vomiting today');
      case 'diarrhea':
        return _MetricInfo('💩', 'Diarrhea', 'Stool condition');
      case 'coughing':
        return _MetricInfo('😷', 'Coughing', 'Coughing episodes');
      case 'sneezing':
        return _MetricInfo('🤧', 'Sneezing', 'Sneezing frequency');
      case 'itching':
        return _MetricInfo('🐾', 'Itching', 'Scratching behavior');
      case 'limping':
        return _MetricInfo('🦵', 'Limping', 'Mobility issues');
      case 'mood':
        return _MetricInfo('😊', 'Mood', 'Overall mood');
      case 'energy':
        return _MetricInfo('⚡', 'Energy', 'Activity level');
      case 'sleep_quality':
        return _MetricInfo('😴', 'Sleep Quality', 'How well they sleep');
      default:
        return _MetricInfo('📊', metricId, 'Custom metric');
    }
  }
}

class _MetricInfo {
  final String emoji;
  final String name;
  final String description;

  _MetricInfo(this.emoji, this.name, this.description);
}
