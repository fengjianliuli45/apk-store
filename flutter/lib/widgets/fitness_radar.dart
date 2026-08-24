import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/workout_log.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Five-axis radar driven by [FitnessRadarScores] — replaces the static
/// `fitness-radar.png` placeholder on 我的.
class FitnessRadar extends StatelessWidget {
  const FitnessRadar({super.key, required this.scores});

  final FitnessRadarScores scores;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            painter: _RadarPainter(values: scores.values),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 2,
          children: [
            for (var i = 0; i < FitnessRadarScores.labels.length; i++)
              Text(
                '${FitnessRadarScores.labels[i]} ${(scores.values[i] * 100).round()}',
                style: const TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _RadarPainter extends CustomPainter {
  const _RadarPainter({required this.values});

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final n = values.length;
    if (n < 3) return;
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 4;

    Offset point(int i, double t) {
      final angle = -math.pi / 2 + (2 * math.pi * i) / n;
      return center + Offset(math.cos(angle), math.sin(angle)) * radius * t;
    }

    final grid = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final ring in const [0.35, 0.7, 1.0]) {
      final path = Path()..moveTo(point(0, ring).dx, point(0, ring).dy);
      for (var i = 1; i < n; i++) {
        path.lineTo(point(i, ring).dx, point(i, ring).dy);
      }
      path.close();
      canvas.drawPath(path, grid);
    }
    for (var i = 0; i < n; i++) {
      canvas.drawLine(center, point(i, 1), grid);
    }

    final fill = Paint()
      ..color = AppColors.brandGreen.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = const Color(0xFF6B9E00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round;
    final data = Path()..moveTo(point(0, values[0].clamp(0, 1)).dx, point(0, values[0].clamp(0, 1)).dy);
    for (var i = 1; i < n; i++) {
      final p = point(i, values[i].clamp(0.0, 1.0));
      data.lineTo(p.dx, p.dy);
    }
    data.close();
    canvas.drawPath(data, fill);
    canvas.drawPath(data, stroke);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    if (oldDelegate.values.length != values.length) return true;
    for (var i = 0; i < values.length; i++) {
      if (oldDelegate.values[i] != values[i]) return true;
    }
    return false;
  }
}
