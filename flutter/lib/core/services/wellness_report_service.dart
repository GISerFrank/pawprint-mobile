import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';

/// 健康报告导出服务
class WellnessReportService {
  /// 导出健康报告为图片并分享
  static Future<void> shareReport({
    required BuildContext context,
    required Pet pet,
    required WellnessReportData data,
  }) async {
    try {
      // 显示加载指示器
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // 生成报告图片
      final imageBytes = await _generateReportImage(pet, data);

      // 保存到临时文件
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'wellness_report_${pet.name}_${DateFormat('yyyyMMdd').format(DateTime.now())}.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(imageBytes);

      // 关闭加载指示器
      if (context.mounted) {
        Navigator.pop(context);
      }

      // 获取分享位置（iPad需要）- 使用屏幕尺寸计算中心位置
      Rect? sharePositionOrigin;
      if (context.mounted) {
        final size = MediaQuery.of(context).size;
        // 在屏幕顶部中心显示分享弹窗
        sharePositionOrigin = Rect.fromCenter(
          center: Offset(size.width / 2, 100),
          width: 1,
          height: 1,
        );
      }

      // 分享文件
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            '${pet.name}\'s Wellness Report - ${DateFormat('MMM d, yyyy').format(DateTime.now())}',
        subject: 'Pet Health Report',
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      // 关闭加载指示器
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 生成报告图片
  static Future<Uint8List> _generateReportImage(
      Pet pet, WellnessReportData data) async {
    // 创建一个 Picture Recorder 来记录绘制
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    const width = 800.0;
    const height = 1200.0;

    // 绘制背景
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(const Rect.fromLTWH(0, 0, width, height), bgPaint);

    // 绘制报告内容
    _drawReport(canvas, pet, data, width, height);

    // 结束记录
    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  static void _drawReport(Canvas canvas, Pet pet, WellnessReportData data,
      double width, double height) {
    double yOffset = 40;

    // 标题区域背景
    final headerPaint = Paint()..color = const Color(0xFF6366F1); // Indigo
    canvas.drawRect(Rect.fromLTWH(0, 0, width, 160), headerPaint);

    // 标题
    _drawText(
      canvas,
      '🐾 Wellness Report',
      const Offset(40, 40),
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );

    // 宠物名称
    _drawText(
      canvas,
      pet.name,
      const Offset(40, 90),
      fontSize: 24,
      color: Colors.white.withOpacity(0.9),
    );

    // 日期
    _drawText(
      canvas,
      DateFormat('MMMM d, yyyy').format(DateTime.now()),
      const Offset(40, 125),
      fontSize: 16,
      color: Colors.white.withOpacity(0.7),
    );

    yOffset = 200;

    // 综合评分
    _drawSectionTitle(canvas, 'Overall Wellness Score', yOffset);
    yOffset += 50;

    _drawScoreCircle(
        canvas, data.overallScore, Offset(width / 2, yOffset + 60));
    yOffset += 150;

    _drawText(
      canvas,
      data.scoreLabel,
      Offset(width / 2 - 50, yOffset),
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: _getScoreColor(data.overallScore),
    );
    yOffset += 60;

    // 体重
    _drawSectionTitle(canvas, 'Weight', yOffset);
    yOffset += 45;

    if (data.weight != null) {
      _drawMetricRow(canvas, '⚖️', 'Current Weight',
          '${data.weight!.toStringAsFixed(1)} kg', yOffset);
      yOffset += 35;
      _drawMetricRow(canvas, '', 'Trend', data.weightTrend ?? 'N/A', yOffset);
    } else {
      _drawText(canvas, 'Not recorded', Offset(60, yOffset),
          fontSize: 16, color: Colors.grey);
    }
    yOffset += 50;

    // BCS & MCS
    _drawSectionTitle(canvas, 'Body Condition', yOffset);
    yOffset += 45;

    _drawMetricRow(canvas, '🏋️', 'BCS (Body Condition)',
        data.bcs != null ? '${data.bcs}/9' : 'N/A', yOffset);
    yOffset += 35;
    _drawMetricRow(canvas, '💪', 'MCS (Muscle Condition)',
        data.mcs != null ? '${data.mcs}/3' : 'N/A', yOffset);
    yOffset += 50;

    // Daily Checks
    _drawSectionTitle(canvas, 'Daily Health Checks', yOffset);
    yOffset += 45;

    final dailyChecks = [
      ('👄', 'Gum Color', data.dailyScores['gum_color']),
      ('✨', 'Coat', data.dailyScores['coat_condition']),
      ('👁️', 'Eyes', data.dailyScores['eye_clarity']),
      ('🌬️', 'Breathing', data.dailyScores['breathing']),
      ('⚡', 'Energy', data.dailyScores['energy']),
      ('💩', 'Stool', data.dailyScores['stool']),
      ('💧', 'Hydration', data.dailyScores['hydration']),
    ];

    for (final check in dailyChecks) {
      final scoreText = check.$3 != null ? '${check.$3}/5' : 'N/A';
      _drawMetricRow(canvas, check.$1, check.$2, scoreText, yOffset);
      yOffset += 32;
    }

    yOffset += 30;

    // 页脚
    _drawText(
      canvas,
      'Generated by PawPrint',
      Offset(width / 2 - 80, height - 40),
      fontSize: 12,
      color: Colors.grey,
    );
  }

  static void _drawSectionTitle(Canvas canvas, String title, double y) {
    _drawText(
      canvas,
      title,
      Offset(40, y),
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF1F2937),
    );

    // 下划线
    final linePaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(40, y + 30), Offset(760, y + 30), linePaint);
  }

  static void _drawMetricRow(
      Canvas canvas, String emoji, String label, String value, double y) {
    if (emoji.isNotEmpty) {
      _drawText(canvas, emoji, Offset(60, y), fontSize: 16);
    }
    _drawText(
      canvas,
      label,
      Offset(emoji.isNotEmpty ? 100 : 60, y),
      fontSize: 15,
      color: const Color(0xFF4B5563),
    );
    _drawText(
      canvas,
      value,
      Offset(600, y),
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF1F2937),
    );
  }

  static void _drawScoreCircle(Canvas canvas, int score, Offset center) {
    const radius = 50.0;

    // 背景圆
    final bgPaint = Paint()
      ..color = const Color(0xFFF3F4F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    canvas.drawCircle(center, radius, bgPaint);

    // 进度圆
    final progressPaint = Paint()
      ..color = _getScoreColor(score)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (score / 100) * 2 * 3.14159;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );

    // 分数文字
    _drawText(
      canvas,
      '$score',
      Offset(center.dx - 20, center.dy - 15),
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: _getScoreColor(score),
    );
  }

  static void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color color = Colors.black,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, offset);
  }

  static Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF10B981); // Green
    if (score >= 60) return const Color(0xFFF59E0B); // Amber
    if (score >= 40) return const Color(0xFFF97316); // Orange
    return const Color(0xFFEF4444); // Red
  }
}

/// 健康报告数据
class WellnessReportData {
  final int overallScore;
  final String scoreLabel;
  final double? weight;
  final String? weightTrend;
  final int? bcs;
  final int? mcs;
  final Map<String, int?> dailyScores;

  const WellnessReportData({
    required this.overallScore,
    required this.scoreLabel,
    this.weight,
    this.weightTrend,
    this.bcs,
    this.mcs,
    this.dailyScores = const {},
  });
}
