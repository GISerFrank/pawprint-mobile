import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/pet_theme.dart';
import '../../../../../core/models/models.dart';

/// 热点配置
class ModelHotspot {
  final String id;
  final String label;
  final String emoji;
  final String position; // "x y z" 格式
  final String normal;   // 法线方向 "x y z"
  final List<String> metricIds; // 关联的指标ID
  
  const ModelHotspot({
    required this.id,
    required this.label,
    required this.emoji,
    required this.position,
    required this.normal,
    required this.metricIds,
  });
}

/// 猫模型热点配置
class CatModelHotspots {
  static const List<ModelHotspot> hotspots = [
    ModelHotspot(
      id: 'body',
      label: 'Body',
      emoji: '🏋️',
      position: '0 0.1 0',
      normal: '0 0 1',
      metricIds: ['bcs', 'weight'],
    ),
    ModelHotspot(
      id: 'muscle',
      label: 'Muscle',
      emoji: '💪',
      position: '0.05 0.08 0.02',
      normal: '0.5 0 0.5',
      metricIds: ['mcs'],
    ),
    ModelHotspot(
      id: 'belly',
      label: 'Belly',
      emoji: '🍽️',
      position: '0 0.02 0',
      normal: '0 -1 0',
      metricIds: ['appetite', 'vomiting', 'diarrhea'],
    ),
    ModelHotspot(
      id: 'chest',
      label: 'Chest',
      emoji: '🫁',
      position: '0.08 0.08 0',
      normal: '1 0 0',
      metricIds: ['coughing', 'sneezing'],
    ),
    ModelHotspot(
      id: 'skin',
      label: 'Skin & Coat',
      emoji: '✨',
      position: '0 0.12 0',
      normal: '0 1 0',
      metricIds: ['itching'],
    ),
    ModelHotspot(
      id: 'legs',
      label: 'Legs',
      emoji: '🦵',
      position: '-0.03 -0.02 0.02',
      normal: '0 0 1',
      metricIds: ['limping'],
    ),
    ModelHotspot(
      id: 'head',
      label: 'Head',
      emoji: '😺',
      position: '0.12 0.1 0',
      normal: '1 0.2 0',
      metricIds: ['mood', 'energy', 'sleep_quality'],
    ),
  ];
}

/// 3D 宠物模型查看器
class PetModelViewer extends StatefulWidget {
  final Pet pet;
  final PetTheme theme;
  final Map<String, dynamic>? metricScores; // 各指标的当前分数
  final Function(ModelHotspot hotspot)? onHotspotTap;

  const PetModelViewer({
    super.key,
    required this.pet,
    required this.theme,
    this.metricScores,
    this.onHotspotTap,
  });

  @override
  State<PetModelViewer> createState() => _PetModelViewerState();
}

class _PetModelViewerState extends State<PetModelViewer> {
  String? _selectedHotspotId;

  @override
  Widget build(BuildContext context) {
    final modelPath = _getModelPath();
    final hotspots = _getHotspots();

    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // 3D 模型
            ModelViewer(
              src: modelPath,
              alt: '${widget.pet.name} 3D Model',
              autoRotate: false,
              cameraControls: true,
              disableZoom: false,
              backgroundColor: widget.theme.background,
              // 热点HTML注入
              innerModelViewerHtml: _buildHotspotsHtml(hotspots),
              relatedJs: _buildHotspotJs(),
            ),
            
            // 顶部标签
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.touch_app, size: 14, color: AppColors.stone500),
                    const SizedBox(width: 4),
                    Text(
                      'Tap hotspots to view metrics',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.stone600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // 选中的热点信息
            if (_selectedHotspotId != null)
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: _buildSelectedHotspotInfo(),
              ),
          ],
        ),
      ),
    );
  }

  String _getModelPath() {
    // 根据宠物类型和体型选择模型
    if (widget.pet.species == PetSpecies.cat) {
      return 'assets/models/cat_model.glb';
    } else {
      return 'assets/models/dog_model.glb';
    }
  }

  List<ModelHotspot> _getHotspots() {
    if (widget.pet.species == PetSpecies.cat) {
      return CatModelHotspots.hotspots;
    }
    // TODO: 添加狗的热点配置
    return CatModelHotspots.hotspots;
  }

  String _buildHotspotsHtml(List<ModelHotspot> hotspots) {
    final buffer = StringBuffer();
    
    for (final hotspot in hotspots) {
      final status = _getHotspotStatus(hotspot);
      final color = _getStatusColor(status);
      
      buffer.writeln('''
        <button class="hotspot" slot="hotspot-${hotspot.id}"
                data-position="${hotspot.position}"
                data-normal="${hotspot.normal}"
                data-visibility-attribute="visible"
                style="
                  background: $color;
                  border: 2px solid white;
                  border-radius: 50%;
                  width: 28px;
                  height: 28px;
                  cursor: pointer;
                  display: flex;
                  align-items: center;
                  justify-content: center;
                  font-size: 14px;
                  box-shadow: 0 2px 8px rgba(0,0,0,0.2);
                  transition: transform 0.2s;
                "
                onclick="window.flutter_inappwebview.callHandler('hotspotTap', '${hotspot.id}')">
          ${hotspot.emoji}
        </button>
      ''');
    }
    
    return buffer.toString();
  }

  String _buildHotspotJs() {
    return '''
      document.querySelectorAll('.hotspot').forEach(btn => {
        btn.addEventListener('mouseenter', () => {
          btn.style.transform = 'scale(1.2)';
        });
        btn.addEventListener('mouseleave', () => {
          btn.style.transform = 'scale(1)';
        });
      });
    ''';
  }

  /// 获取热点状态：good, warning, alert, neutral
  String _getHotspotStatus(ModelHotspot hotspot) {
    if (widget.metricScores == null) return 'neutral';
    
    // 检查该热点关联的所有指标
    for (final metricId in hotspot.metricIds) {
      final score = widget.metricScores![metricId];
      if (score == null) continue;
      
      if (score is int) {
        if (score <= 2) return 'alert';
        if (score <= 3) return 'warning';
      } else if (score is double) {
        // 处理数值类型的指标
      } else if (score is bool && score == true) {
        // 布尔指标为 true 表示有问题（如呕吐、腹泻）
        return 'alert';
      }
    }
    
    return 'good';
  }

  String _getStatusColor(String status) {
    switch (status) {
      case 'good':
        return '#22c55e'; // green
      case 'warning':
        return '#f59e0b'; // amber
      case 'alert':
        return '#ef4444'; // red
      default:
        return '#94a3b8'; // gray
    }
  }

  Widget _buildSelectedHotspotInfo() {
    final hotspot = _getHotspots().firstWhere(
      (h) => h.id == _selectedHotspotId,
      orElse: () => CatModelHotspots.hotspots.first,
    );
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(hotspot.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hotspot.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Related: ${hotspot.metricIds.join(", ")}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.stone500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() => _selectedHotspotId = null);
            },
            icon: const Icon(Icons.close, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
