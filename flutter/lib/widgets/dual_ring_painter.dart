import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Outer dotted ring + inner progress ring behind the "开始训练" dumbbell
/// button, sampled from docs/figma-ref/home-with-fab.png.
class DualRingPainter extends CustomPainter {
  const DualRingPainter({required this.progress});

  /// 0..1 — set/rest progress. Idle shows a faint full track only.
  final double progress;

  static const _dotCount = 28;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius - 16;

    final outerTrack = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(center, outerRadius, outerTrack);

    final dotPaint = Paint()..color = AppColors.ink.withValues(alpha: 0.16);
    for (var i = 0; i < _dotCount; i++) {
      final angle = (2 * math.pi * i) / _dotCount;
      final dotCenter = center + Offset(math.cos(angle), math.sin(angle)) * outerRadius;
      canvas.drawCircle(dotCenter, 1.6, dotPaint);
    }

    final innerTrack = Paint()
      ..color = AppColors.brandGreen.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, innerRadius, innerTrack);

    final sweep = 2 * math.pi * (progress <= 0 ? 0.86 : progress.clamp(0.0, 1.0));
    final progressPaint = Paint()
      ..color = AppColors.brandGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: innerRadius),
      -math.pi / 2,
      sweep,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant DualRingPainter oldDelegate) => oldDelegate.progress != progress;
}
