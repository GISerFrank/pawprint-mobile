import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

/// Sparkline 迷你趋势图
/// 用于在卡片中展示简洁的历史趋势
class Sparkline extends StatelessWidget {
  /// 数据点列表（从旧到新）
  final List<double> data;
  
  /// 线条颜色
  final Color? lineColor;
  
  /// 填充颜色（渐变底部）
  final Color? fillColor;
  
  /// 线条宽度
  final double lineWidth;
  
  /// 是否显示最后一个点
  final bool showLastDot;
  
  /// 最后一个点的颜色
  final Color? lastDotColor;
  
  /// Y轴最小值（可选，默认自动计算）
  final double? minY;
  
  /// Y轴最大值（可选，默认自动计算）
  final double? maxY;

  const Sparkline({
    super.key,
    required this.data,
    this.lineColor,
    this.fillColor,
    this.lineWidth = 1.5,
    this.showLastDot = true,
    this.lastDotColor,
    this.minY,
    this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox.shrink();
    }

    return CustomPaint(
      painter: _SparklinePainter(
        data: data,
        lineColor: lineColor ?? AppColors.stone400,
        fillColor: fillColor,
        lineWidth: lineWidth,
        showLastDot: showLastDot,
        lastDotColor: lastDotColor ?? lineColor ?? AppColors.stone400,
        minY: minY,
        maxY: maxY,
      ),
      size: Size.infinite,
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;
  final Color? fillColor;
  final double lineWidth;
  final bool showLastDot;
  final Color lastDotColor;
  final double? minY;
  final double? maxY;

  _SparklinePainter({
    required this.data,
    required this.lineColor,
    this.fillColor,
    required this.lineWidth,
    required this.showLastDot,
    required this.lastDotColor,
    this.minY,
    this.maxY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final effectiveMinY = minY ?? data.reduce((a, b) => a < b ? a : b);
    final effectiveMaxY = maxY ?? data.reduce((a, b) => a > b ? a : b);
    final range = effectiveMaxY - effectiveMinY;
    
    // 防止除以零
    final normalizedRange = range == 0 ? 1.0 : range;
    
    // 计算点的位置
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = data.length == 1 
          ? size.width / 2 
          : (i / (data.length - 1)) * size.width;
      final normalizedY = (data[i] - effectiveMinY) / normalizedRange;
      final y = size.height - (normalizedY * size.height * 0.8) - (size.height * 0.1);
      points.add(Offset(x, y));
    }

    // 绘制填充区域
    if (fillColor != null && points.length > 1) {
      final fillPath = Path();
      fillPath.moveTo(points.first.dx, size.height);
      fillPath.lineTo(points.first.dx, points.first.dy);
      
      for (int i = 1; i < points.length; i++) {
        fillPath.lineTo(points[i].dx, points[i].dy);
      }
      
      fillPath.lineTo(points.last.dx, size.height);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            fillColor!.withOpacity(0.3),
            fillColor!.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(fillPath, fillPaint);
    }

    // 绘制线条
    if (points.length > 1) {
      final linePaint = Paint()
        ..color = lineColor
        ..strokeWidth = lineWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);

      // 使用贝塞尔曲线平滑连接
      for (int i = 1; i < points.length; i++) {
        final p0 = points[i - 1];
        final p1 = points[i];
        final controlX = (p0.dx + p1.dx) / 2;
        path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
      }

      canvas.drawPath(path, linePaint);
    }

    // 绘制最后一个点
    if (showLastDot && points.isNotEmpty) {
      final lastPoint = points.last;
      final dotPaint = Paint()
        ..color = lastDotColor
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(lastPoint, 3, dotPaint);
      
      // 白色边框
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      
      canvas.drawCircle(lastPoint, 3, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return data != oldDelegate.data ||
        lineColor != oldDelegate.lineColor ||
        fillColor != oldDelegate.fillColor ||
        lineWidth != oldDelegate.lineWidth ||
        showLastDot != oldDelegate.showLastDot;
  }
}

/// 带颜色编码的 Sparkline（用于 1-5 评分）
class ScoreSparkline extends StatelessWidget {
  final List<int> scores;
  final double height;

  const ScoreSparkline({
    super.key,
    required this.scores,
    this.height = 24,
  });

  @override
  Widget build(BuildContext context) {
    if (scores.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No data',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.stone400,
            ),
          ),
        ),
      );
    }

    // 计算平均分来决定颜色
    final avgScore = scores.reduce((a, b) => a + b) / scores.length;
    final color = _getScoreColor(avgScore);

    return SizedBox(
      height: height,
      child: Sparkline(
        data: scores.map((s) => s.toDouble()).toList(),
        lineColor: color,
        fillColor: color,
        minY: 1,
        maxY: 5,
        lastDotColor: color,
      ),
    );
  }

  Color _getScoreColor(double avgScore) {
    if (avgScore < 2.5) return AppColors.red400;
    if (avgScore < 3.5) return AppColors.amber400;
    return AppColors.green400;
  }
}

/// 体重趋势 Sparkline
class WeightSparkline extends StatelessWidget {
  final List<double> weights;
  final double height;
  final Color? color;

  const WeightSparkline({
    super.key,
    required this.weights,
    this.height = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (weights.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No data',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.stone400,
            ),
          ),
        ),
      );
    }

    // 计算趋势颜色
    Color trendColor = color ?? AppColors.stone400;
    if (weights.length >= 2) {
      final diff = weights.last - weights.first;
      final percentChange = weights.first != 0 ? (diff / weights.first) * 100 : 0;
      if (percentChange.abs() > 5) {
        // 体重变化超过5%可能需要注意
        trendColor = AppColors.amber500;
      } else {
        trendColor = AppColors.green500;
      }
    }

    return SizedBox(
      height: height,
      child: Sparkline(
        data: weights,
        lineColor: trendColor,
        fillColor: trendColor,
        lastDotColor: trendColor,
      ),
    );
  }
}

/// BCS/MCS Sparkline
class BodyScoreSparkline extends StatelessWidget {
  final List<int> scores;
  final int maxScore; // BCS: 9, MCS: 3
  final int idealScore; // BCS: 5, MCS: 3
  final double height;

  const BodyScoreSparkline({
    super.key,
    required this.scores,
    required this.maxScore,
    required this.idealScore,
    this.height = 24,
  });

  @override
  Widget build(BuildContext context) {
    if (scores.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No data',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.stone400,
            ),
          ),
        ),
      );
    }

    // 计算最近评分与理想值的偏差来决定颜色
    final latestScore = scores.last;
    final color = _getScoreColor(latestScore);

    return SizedBox(
      height: height,
      child: Sparkline(
        data: scores.map((s) => s.toDouble()).toList(),
        lineColor: color,
        fillColor: color,
        minY: maxScore == 9 ? 1 : 0,
        maxY: maxScore.toDouble(),
        lastDotColor: color,
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (maxScore == 9) {
      // BCS: 理想是5
      final diff = (score - idealScore).abs();
      if (diff == 0) return AppColors.green500;
      if (diff <= 1) return AppColors.lime500;
      if (diff <= 2) return AppColors.amber500;
      return AppColors.red500;
    } else {
      // MCS: 理想是3
      if (score == 3) return AppColors.green500;
      if (score == 2) return AppColors.amber500;
      if (score == 1) return AppColors.orange500;
      return AppColors.red500;
    }
  }
}
