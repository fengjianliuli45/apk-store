import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Stick-figure pose used as the training-list glyph.
/// Each family of moves (squat, bench, pull-up, …) gets its own drawing so
/// the 动作库 no longer shows the same dumbbell for every row.
enum ExercisePose {
  squat,
  lunge,
  deadlift,
  hipThrust,
  calfRaise,
  benchPress,
  pushUp,
  dip,
  fly,
  overheadPress,
  lateralRaise,
  pullUp,
  pulldown,
  row,
  facePull,
  curl,
  tricep,
  plank,
  crunch,
  twist,
  carry,
  run,
  jumpRope,
  kettlebell,
  machine,
}

ExercisePose resolveExerciseGlyph({String? id, required String name}) {
  final hay = '${id ?? ''} $name'.toLowerCase();
  bool has(String token) => hay.contains(token);

  if (has('jump') || has('跳绳')) return ExercisePose.jumpRope;
  if (has('run') || has('jog') || has('慢跑') || has('跑步')) return ExercisePose.run;
  if (has('farmer') || has('carry') || has('suitcase') || has('农夫') || has('手提箱')) {
    return ExercisePose.carry;
  }
  if (has('kettlebell') || has('壶铃') || has('medicine_ball') || has('药球')) {
    return ExercisePose.kettlebell;
  }

  if (has('pull_up') || has('chin_up') || has('引体') || has('toes_to_bar') || has('脚触杠')) {
    return ExercisePose.pullUp;
  }
  if (has('pulldown') || has('下拉')) return ExercisePose.pulldown;
  if (has('push_up') || has('俯卧撑')) return ExercisePose.pushUp;
  if (has('dip') || has('臂屈伸')) return ExercisePose.dip;

  if (has('lunge') || has('split_squat') || has('箭步') || has('分腿') || has('保加利亚')) {
    return ExercisePose.lunge;
  }
  if (has('hip_thrust') || has('glute_bridge') || has('臀推') || has('臀桥')) {
    return ExercisePose.hipThrust;
  }
  if (has('calf') || has('提踵')) return ExercisePose.calfRaise;
  if (has('squat') || has('深蹲') || has('腿举') || has('leg_press') || has('hack_squat')) {
    return ExercisePose.squat;
  }
  if (has('deadlift') ||
      has('rdl') ||
      has('good_morning') ||
      has('硬拉') ||
      has('早安')) {
    return ExercisePose.deadlift;
  }

  if (has('bench') || has('卧推') || has('floor_press')) return ExercisePose.benchPress;
  if ((has('incline') || has('decline') || has('上斜') || has('下斜')) &&
      (has('press') || has('推举'))) {
    return ExercisePose.benchPress;
  }
  if (has('fly') || has('pec_deck') || has('飞鸟') || has('夹胸') || has('蝴蝶')) {
    return ExercisePose.fly;
  }
  if (has('face_pull') || has('面拉')) return ExercisePose.facePull;
  if (has('row') || has('划船')) return ExercisePose.row;

  if (has('lateral') || has('side_delt') || has('侧平举') || has('前平举') || has('front_raise')) {
    return ExercisePose.lateralRaise;
  }
  if (has('overhead') ||
      has('shoulder_press') ||
      has('push_press') ||
      has('推举')) {
    return ExercisePose.overheadPress;
  }

  if (has('leg_curl') || has('leg_extension') || has('腿弯举') || has('腿屈伸')) {
    return ExercisePose.machine;
  }
  if (has('curl') || has('弯举')) return ExercisePose.curl;
  if (has('tricep') ||
      has('pushdown') ||
      has('skull') ||
      has('french') ||
      has('三头') ||
      has('下压') ||
      has('臂屈伸')) {
    return ExercisePose.tricep;
  }

  if (has('twist') ||
      has('woodchop') ||
      has('wiper') ||
      has('转体') ||
      has('砍柴') ||
      has('雨刷')) {
    return ExercisePose.twist;
  }
  if (has('plank') ||
      has('bird_dog') ||
      has('ab_wheel') ||
      has('平板') ||
      has('鸟狗') ||
      has('腹肌轮')) {
    return ExercisePose.plank;
  }
  if (has('crunch') ||
      has('leg_raise') ||
      has('knee_raise') ||
      has('dead_bug') ||
      has('卷腹') ||
      has('举腿') ||
      has('屈膝') ||
      has('死虫')) {
    return ExercisePose.crunch;
  }

  if (has('machine') || has('leg_extension') || has('leg_curl') || has('preacher') || has('机')) {
    return ExercisePose.machine;
  }

  return ExercisePose.squat;
}

class ExerciseGlyphAvatar extends StatelessWidget {
  const ExerciseGlyphAvatar({
    super.key,
    this.id,
    required this.name,
    this.size = 36,
  });

  final String? id;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.brandGreen.withValues(alpha: 0.4),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: ExerciseGlyph(id: id, name: name, size: size * 0.58),
    );
  }
}

class ExerciseGlyph extends StatelessWidget {
  const ExerciseGlyph({
    super.key,
    this.id,
    required this.name,
    this.size = 20,
    this.color = AppColors.ink,
  });

  final String? id;
  final String name;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: ExerciseGlyphPainter(
        pose: resolveExerciseGlyph(id: id, name: name),
        color: color,
      ),
    );
  }
}

class ExerciseGlyphPainter extends CustomPainter {
  ExerciseGlyphPainter({required this.pose, required this.color});

  final ExercisePose pose;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.085
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    Offset p(double x, double y) => Offset(x * size.width, y * size.height);

    void head(double x, double y, [double r = 0.09]) {
      canvas.drawCircle(p(x, y), size.width * r, fill);
    }

    void line(double x1, double y1, double x2, double y2) {
      canvas.drawLine(p(x1, y1), p(x2, y2), stroke);
    }

    void poly(List<(double, double)> pts) {
      final path = Path()..moveTo(pts.first.$1 * size.width, pts.first.$2 * size.height);
      for (final pt in pts.skip(1)) {
        path.lineTo(pt.$1 * size.width, pt.$2 * size.height);
      }
      canvas.drawPath(path, stroke);
    }

    switch (pose) {
      case ExercisePose.squat:
        head(0.50, 0.20);
        line(0.50, 0.30, 0.50, 0.48);
        line(0.50, 0.48, 0.28, 0.68);
        line(0.50, 0.48, 0.72, 0.68);
        line(0.28, 0.68, 0.22, 0.92);
        line(0.72, 0.68, 0.78, 0.92);
        line(0.22, 0.34, 0.78, 0.34);
        break;
      case ExercisePose.lunge:
        head(0.46, 0.16);
        line(0.46, 0.26, 0.48, 0.50);
        line(0.48, 0.50, 0.28, 0.92);
        line(0.48, 0.50, 0.78, 0.62);
        line(0.78, 0.62, 0.82, 0.92);
        line(0.32, 0.38, 0.62, 0.32);
        break;
      case ExercisePose.deadlift:
        head(0.62, 0.22);
        line(0.56, 0.30, 0.42, 0.52);
        line(0.42, 0.52, 0.30, 0.92);
        line(0.42, 0.52, 0.58, 0.92);
        line(0.50, 0.44, 0.22, 0.78);
        line(0.18, 0.80, 0.78, 0.80);
        break;
      case ExercisePose.hipThrust:
        line(0.12, 0.42, 0.42, 0.42);
        line(0.12, 0.42, 0.12, 0.78);
        head(0.28, 0.30);
        line(0.34, 0.38, 0.62, 0.42);
        line(0.62, 0.42, 0.78, 0.78);
        line(0.62, 0.42, 0.92, 0.48);
        break;
      case ExercisePose.calfRaise:
        head(0.50, 0.14);
        line(0.50, 0.24, 0.50, 0.62);
        line(0.50, 0.62, 0.38, 0.86);
        line(0.50, 0.62, 0.62, 0.86);
        line(0.32, 0.88, 0.42, 0.88);
        line(0.58, 0.88, 0.68, 0.88);
        line(0.38, 0.78, 0.38, 0.86);
        line(0.62, 0.78, 0.62, 0.86);
        break;
      case ExercisePose.benchPress:
        line(0.16, 0.62, 0.84, 0.62);
        line(0.22, 0.62, 0.22, 0.86);
        line(0.78, 0.62, 0.78, 0.86);
        head(0.28, 0.50);
        line(0.36, 0.52, 0.70, 0.52);
        line(0.50, 0.52, 0.50, 0.32);
        line(0.28, 0.32, 0.72, 0.32);
        break;
      case ExercisePose.pushUp:
        head(0.16, 0.42);
        line(0.24, 0.46, 0.78, 0.50);
        line(0.36, 0.48, 0.30, 0.78);
        line(0.68, 0.50, 0.74, 0.80);
        line(0.78, 0.50, 0.90, 0.80);
        break;
      case ExercisePose.dip:
        line(0.18, 0.22, 0.18, 0.78);
        line(0.82, 0.22, 0.82, 0.78);
        head(0.50, 0.28);
        line(0.50, 0.38, 0.50, 0.62);
        line(0.50, 0.44, 0.22, 0.38);
        line(0.50, 0.44, 0.78, 0.38);
        line(0.50, 0.62, 0.42, 0.86);
        line(0.50, 0.62, 0.58, 0.86);
        break;
      case ExercisePose.fly:
        line(0.18, 0.70, 0.82, 0.70);
        head(0.28, 0.54);
        line(0.36, 0.58, 0.70, 0.58);
        line(0.48, 0.58, 0.18, 0.38);
        line(0.62, 0.58, 0.88, 0.38);
        break;
      case ExercisePose.overheadPress:
        head(0.50, 0.28);
        line(0.50, 0.38, 0.50, 0.62);
        line(0.50, 0.62, 0.36, 0.92);
        line(0.50, 0.62, 0.64, 0.92);
        line(0.50, 0.44, 0.32, 0.22);
        line(0.50, 0.44, 0.68, 0.22);
        line(0.24, 0.18, 0.76, 0.18);
        break;
      case ExercisePose.lateralRaise:
        head(0.50, 0.20);
        line(0.50, 0.30, 0.50, 0.62);
        line(0.50, 0.62, 0.36, 0.92);
        line(0.50, 0.62, 0.64, 0.92);
        line(0.50, 0.42, 0.14, 0.38);
        line(0.50, 0.42, 0.86, 0.38);
        canvas.drawCircle(p(0.12, 0.38), size.width * 0.05, fill);
        canvas.drawCircle(p(0.88, 0.38), size.width * 0.05, fill);
        break;
      case ExercisePose.pullUp:
        line(0.12, 0.16, 0.88, 0.16);
        line(0.22, 0.16, 0.34, 0.38);
        line(0.78, 0.16, 0.66, 0.38);
        head(0.50, 0.34);
        line(0.50, 0.44, 0.50, 0.68);
        line(0.50, 0.68, 0.38, 0.90);
        line(0.50, 0.68, 0.62, 0.90);
        break;
      case ExercisePose.pulldown:
        line(0.18, 0.12, 0.82, 0.12);
        line(0.28, 0.12, 0.38, 0.36);
        line(0.72, 0.12, 0.62, 0.36);
        head(0.50, 0.32);
        line(0.50, 0.42, 0.50, 0.66);
        line(0.38, 0.66, 0.62, 0.66);
        line(0.38, 0.66, 0.34, 0.90);
        line(0.62, 0.66, 0.66, 0.90);
        break;
      case ExercisePose.row:
        head(0.70, 0.20);
        line(0.64, 0.28, 0.42, 0.50);
        line(0.42, 0.50, 0.30, 0.90);
        line(0.42, 0.50, 0.58, 0.90);
        line(0.52, 0.40, 0.22, 0.48);
        line(0.16, 0.50, 0.48, 0.50);
        break;
      case ExercisePose.facePull:
        line(0.12, 0.18, 0.12, 0.86);
        head(0.62, 0.28);
        line(0.56, 0.38, 0.50, 0.68);
        line(0.50, 0.68, 0.38, 0.92);
        line(0.50, 0.68, 0.62, 0.92);
        line(0.54, 0.40, 0.22, 0.28);
        line(0.54, 0.40, 0.28, 0.42);
        break;
      case ExercisePose.curl:
        head(0.50, 0.16);
        line(0.50, 0.26, 0.50, 0.60);
        line(0.50, 0.60, 0.36, 0.92);
        line(0.50, 0.60, 0.64, 0.92);
        line(0.50, 0.42, 0.28, 0.58);
        line(0.28, 0.58, 0.38, 0.34);
        canvas.drawCircle(p(0.40, 0.30), size.width * 0.055, fill);
        break;
      case ExercisePose.tricep:
        head(0.42, 0.22);
        line(0.44, 0.32, 0.48, 0.62);
        line(0.48, 0.62, 0.34, 0.92);
        line(0.48, 0.62, 0.62, 0.92);
        line(0.46, 0.40, 0.58, 0.18);
        line(0.58, 0.18, 0.70, 0.40);
        canvas.drawCircle(p(0.72, 0.44), size.width * 0.055, fill);
        break;
      case ExercisePose.plank:
        head(0.16, 0.46);
        line(0.24, 0.50, 0.82, 0.50);
        line(0.30, 0.50, 0.26, 0.78);
        line(0.26, 0.78, 0.38, 0.78);
        line(0.82, 0.50, 0.88, 0.78);
        break;
      case ExercisePose.crunch:
        head(0.30, 0.34);
        poly([(0.36, 0.42), (0.58, 0.58), (0.82, 0.52)]);
        line(0.58, 0.58, 0.70, 0.82);
        line(0.18, 0.86, 0.88, 0.86);
        break;
      case ExercisePose.twist:
        head(0.50, 0.16);
        line(0.50, 0.26, 0.50, 0.52);
        line(0.38, 0.52, 0.62, 0.52);
        line(0.38, 0.52, 0.32, 0.82);
        line(0.62, 0.52, 0.68, 0.82);
        line(0.50, 0.36, 0.18, 0.28);
        line(0.50, 0.36, 0.82, 0.44);
        break;
      case ExercisePose.carry:
        head(0.50, 0.16);
        line(0.50, 0.26, 0.50, 0.58);
        line(0.50, 0.58, 0.38, 0.90);
        line(0.50, 0.58, 0.66, 0.90);
        line(0.50, 0.40, 0.28, 0.62);
        line(0.50, 0.40, 0.72, 0.62);
        canvas.drawCircle(p(0.26, 0.68), size.width * 0.06, fill);
        canvas.drawCircle(p(0.74, 0.68), size.width * 0.06, fill);
        break;
      case ExercisePose.run:
        head(0.58, 0.16);
        line(0.54, 0.26, 0.42, 0.52);
        line(0.42, 0.52, 0.22, 0.78);
        line(0.42, 0.52, 0.70, 0.86);
        line(0.50, 0.34, 0.78, 0.28);
        line(0.50, 0.34, 0.28, 0.46);
        break;
      case ExercisePose.jumpRope:
        head(0.50, 0.18);
        line(0.50, 0.28, 0.50, 0.56);
        line(0.50, 0.56, 0.36, 0.82);
        line(0.50, 0.56, 0.64, 0.82);
        line(0.50, 0.40, 0.22, 0.52);
        line(0.50, 0.40, 0.78, 0.52);
        final arc = Path()
          ..moveTo(0.22 * size.width, 0.52 * size.height)
          ..quadraticBezierTo(
            0.50 * size.width,
            0.98 * size.height,
            0.78 * size.width,
            0.52 * size.height,
          );
        canvas.drawPath(arc, stroke);
        break;
      case ExercisePose.kettlebell:
        head(0.58, 0.18);
        line(0.52, 0.28, 0.42, 0.52);
        line(0.42, 0.52, 0.30, 0.88);
        line(0.42, 0.52, 0.58, 0.88);
        line(0.48, 0.38, 0.28, 0.58);
        canvas.drawCircle(p(0.24, 0.66), size.width * 0.08, stroke);
        canvas.drawArc(
          Rect.fromCircle(center: p(0.24, 0.58), radius: size.width * 0.06),
          math.pi,
          math.pi,
          false,
          stroke,
        );
        break;
      case ExercisePose.machine:
        line(0.18, 0.86, 0.86, 0.86);
        line(0.28, 0.86, 0.28, 0.42);
        line(0.28, 0.42, 0.52, 0.42);
        head(0.62, 0.22);
        line(0.58, 0.32, 0.50, 0.52);
        line(0.50, 0.52, 0.42, 0.52);
        line(0.50, 0.52, 0.62, 0.78);
        line(0.70, 0.18, 0.70, 0.86);
        line(0.62, 0.28, 0.70, 0.28);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant ExerciseGlyphPainter oldDelegate) {
    return oldDelegate.pose != pose || oldDelegate.color != color;
  }
}
