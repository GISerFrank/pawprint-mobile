import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/pet_theme.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/providers/wellness_provider.dart';
import '../../../../core/models/models.dart';
import '../../../../shared/widgets/widgets.dart';
import '../widgets/wellness/wellness_header.dart';
import '../widgets/wellness/wellness_score_card.dart';
import '../widgets/wellness/weight_card.dart';
import '../widgets/wellness/bcs_card.dart';
import '../widgets/wellness/mcs_card.dart';
import '../widgets/wellness/image_metric_card.dart';
import '../widgets/wellness/add_metric_card.dart';
import '../widgets/wellness/custom_metric_card.dart';
import '../widgets/pet_model/pet_model_widgets.dart';

/// Wellness 健康状态页面
///
/// 包含:
/// - Wellness 综合评分
/// - Daily Health Check:
///   - 体重追踪
///   - BCS 体况评分 (1-9)
///   - MCS 肌肉评分 (0-3)
///   - Eye/Ear 图片记录
///   - 自定义指标
class WellnessPage extends ConsumerWidget {
  const WellnessPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petAsync = ref.watch(currentPetProvider);
    final theme = ref.watch(currentPetThemeProvider);

    return Scaffold(
      backgroundColor: theme.background,
      body: petAsync.when(
        loading: () => const Center(child: AppLoadingIndicator()),
        error: (e, _) => ErrorStateWidget(
          message: 'Failed to load data',
          onRetry: () => ref.invalidate(currentPetProvider),
        ),
        data: (pet) {
          if (pet == null) {
            return const Center(child: Text('No pet selected'));
          }
          return _WellnessBody(pet: pet, theme: theme);
        },
      ),
    );
  }
}

class _WellnessBody extends ConsumerStatefulWidget {
  final Pet pet;
  final PetTheme theme;

  const _WellnessBody({
    required this.pet,
    required this.theme,
  });

  @override
  ConsumerState<_WellnessBody> createState() => _WellnessBodyState();
}

class _WellnessBodyState extends ConsumerState<_WellnessBody> {
  ModelHotspot? _selectedHotspot;

  @override
  Widget build(BuildContext context) {
    final customMetricsAsync = ref.watch(customMetricsProvider);

    return CustomScrollView(
      slivers: [
        // 顶部 Header
        WellnessHeader(pet: widget.pet, theme: widget.theme),

        // 内容区域
        SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Wellness 综合评分卡片
              WellnessScoreCard(pet: widget.pet, theme: widget.theme),
              const SizedBox(height: 20),

              // 3D 宠物模型
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 16),
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       _SectionTitle(
              //         title: '3D Health Map',
              //         subtitle: 'Tap body parts to view related metrics',
              //         theme: widget.theme,
              //       ),
              //       const SizedBox(height: 12),
              //       PetModelViewer(
              //         pet: widget.pet,
              //         theme: widget.theme,
              //         onHotspotTap: (hotspot) {
              //           setState(() => _selectedHotspot = hotspot);
              //           _showHotspotDetail(hotspot);
              //         },
              //       ),
              //       // 选中热点的详情面板
              //       if (_selectedHotspot != null) ...[
              //         const SizedBox(height: 12),
              //         HotspotDetailPanel(
              //           hotspot: _selectedHotspot!,
              //           theme: widget.theme,
              //           onClose: () => setState(() => _selectedHotspot = null),
              //           onMetricTap: (metricId) => _navigateToMetric(metricId),
              //         ),
              //       ],
              //     ],
              //   ),
              // ),
              // const SizedBox(height: 20),

              // 指标卡片区域
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Daily Health Check 标题
                    _SectionTitle(
                      title: 'Daily Health Check',
                      subtitle: 'Track your pet\'s health indicators',
                      theme: widget.theme,
                    ),
                    const SizedBox(height: 12),

                    // 体重卡片
                    WeightCard(pet: widget.pet, theme: widget.theme),
                    const SizedBox(height: 12),

                    // BCS & MCS 并排显示
                    SizedBox(
                      height: 120,
                      child: Row(
                        children: [
                          Expanded(
                            child:
                                BCSCard(pet: widget.pet, theme: widget.theme),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child:
                                MCSCard(pet: widget.pet, theme: widget.theme),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Eye & Ear 并排显示
                    SizedBox(
                      height: 120,
                      child: Row(
                        children: [
                          Expanded(
                            child: ImageMetricCard(
                              petId: widget.pet.id,
                              theme: widget.theme,
                              metricId: 'eye_condition',
                              name: 'Eye',
                              emoji: '👁️',
                              description: 'Clarity, discharge, tear stains',
                              metricCategory: MetricCategory.eyes,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ImageMetricCard(
                              petId: widget.pet.id,
                              theme: widget.theme,
                              metricId: 'ear_condition',
                              name: 'Ear',
                              emoji: '👂',
                              description: 'Cleanliness, odor, discharge',
                              metricCategory: MetricCategory.ears,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 自定义指标 + 添加按钮
                    customMetricsAsync.when(
                      loading: () => SizedBox(
                        height: 90,
                        child: AddMetricCard(
                          theme: widget.theme,
                          petId: widget.pet.id,
                        ),
                      ),
                      error: (_, __) => SizedBox(
                        height: 90,
                        child: AddMetricCard(
                          theme: widget.theme,
                          petId: widget.pet.id,
                        ),
                      ),
                      data: (customMetrics) {
                        return _CustomMetricsGrid(
                          metrics: customMetrics,
                          theme: widget.theme,
                          petId: widget.pet.id,
                        );
                      },
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  // void _showHotspotDetail(ModelHotspot hotspot) {
  //   // 热点点击时的处理（已在 setState 中更新 _selectedHotspot）
  // }

  // void _navigateToMetric(String metricId) {
  //   // TODO: 跳转到对应指标的详情页
  //   // 根据 metricId 决定跳转目标
  // }
}

/// 章节标题
class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final PetTheme theme;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.stone800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.stone500,
              ),
        ),
      ],
    );
  }
}

/// 每日健康检查指标网格
/// 自定义指标网格
class _CustomMetricsGrid extends StatelessWidget {
  final List<CareMetric> metrics;
  final PetTheme theme;
  final String petId;

  const _CustomMetricsGrid({
    required this.metrics,
    required this.theme,
    required this.petId,
  });

  @override
  Widget build(BuildContext context) {
    // 指标 + 添加按钮
    final itemCount = metrics.length + 1;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // 最后一个是添加按钮
        if (index == metrics.length) {
          return AddMetricCard(theme: theme, petId: petId);
        }

        return CustomMetricCard(
          metric: metrics[index],
          theme: theme,
        );
      },
    );
  }
}
