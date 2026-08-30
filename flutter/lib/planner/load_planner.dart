import 'models.dart';

/// Port of fitness-planner's `load_planner.py`.
/// 把「65-80% 1RM」这种百分比转成具体重量（kg）。哑铃系数按「每只手」计。

const baselineLifts = ['squat', 'bench', 'hinge', 'row'];

const baselineCn = {
  'squat': '深蹲', 'bench': '卧推', 'hinge': '硬拉/罗马尼亚硬拉', 'row': '划船',
};

const _patternBasis = <String, List<Object>>{
  'squat': ['squat', 1.0],
  'hip_hinge': ['hinge', 1.0],
  'knee_flexion': ['hinge', 0.35],
  'hip_extension': ['hinge', 0.5],
  'calf_raise': ['squat', 0.55],
  'horizontal_push': ['bench', 1.0],
  'vertical_push': ['bench', 0.62],
  'horizontal_pull': ['row', 1.0],
  'vertical_pull': ['row', 0.9],
  'elbow_flexion': ['bench', 0.28],
  'elbow_extension': ['bench', 0.32],
};

const _exerciseCoef = <String, List<Object?>>{
  'goblet_squat': ['squat', 0.35],
  'bodyweight_squat': [null, 0.0],
  'front_squat': ['squat', 0.85],
  'leg_press': ['squat', 2.0],
  'bulgarian_split_squat': ['squat', 0.32],
  'walking_lunges': ['squat', 0.28],
  'dumbbell_rdl': ['hinge', 0.38],
  'romanian_deadlift': ['hinge', 0.85],
  'hip_thrust': ['hinge', 1.1],
  'incline_barbell_press': ['bench', 0.85],
  'incline_dumbbell_press': ['bench', 0.34],
  'dumbbell_bench_press': ['bench', 0.42],
  'overhead_press': ['bench', 0.62],
  'dumbbell_shoulder_press': ['bench', 0.26],
  'seated_dumbbell_press': ['bench', 0.26],
  'dumbbell_row': ['row', 0.45],
  'seated_cable_row': ['row', 1.0],
  'lat_pulldown': ['row', 0.9],
  'barbell_curl': ['bench', 0.3],
  'dumbbell_curl': ['bench', 0.14],
};

const _noLoadPatterns = {
  'core', 'trunk_flexion', 'trunk_rotation', 'anti_extension',
};

double estimate1rm(double weightKg, int reps) {
  final r = reps < 1 ? 1 : (reps > 12 ? 12 : reps);
  return (weightKg * (1 + r / 30) * 10 + 0.5).floor() / 10;
}

Map<String, double> buildOneRmMap(Map<String, dynamic> strengthBaseline) {
  final out = <String, double>{};
  strengthBaseline.forEach((basis, v) {
    if (!baselineLifts.contains(basis) || v is! Map) return;
    if (v['one_rm_kg'] != null) {
      out[basis] = (v['one_rm_kg'] as num).toDouble();
    } else if (v['weight_kg'] != null && v['reps'] != null) {
      out[basis] = estimate1rm(
          (v['weight_kg'] as num).toDouble(), (v['reps'] as num).toInt());
    }
  });
  return out;
}

(String?, double) _basisAndCoef(Exercise ex) {
  final o = _exerciseCoef[ex.id];
  if (o != null) return (o[0] as String?, (o[1] as num).toDouble());
  if (_noLoadPatterns.contains(ex.movementPattern)) return (null, 0.0);
  final p = _patternBasis[ex.movementPattern];
  if (p == null) return (null, 0.0);
  return (p[0] as String, (p[1] as num).toDouble());
}

double _round2p5(double x) => (x / 2.5 + 0.5).floor() * 2.5;

String _fmt(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString();

/// 返回 (显示文本, 建议重量kg 或 0 表示无)。
(String, double) suggestLoad(
  Exercise ex,
  Map<String, double> oneRmMap,
  double loadPctMid,
  String loadPctLabel,
) {
  if (ex.equipmentRequired.length == 1 &&
      ex.equipmentRequired.first == 'bodyweight') {
    return ('自重（按次数 / 难度递进）', 0);
  }
  if (ex.equipmentRequired.length == 1 &&
      ex.equipmentRequired.first == 'band') {
    return ('弹力带 · 选阻力做到目标次数、末组留 1-2 次；变强了换更粗的带或缩短带长', 0);
  }
  final (basis, coef) = _basisAndCoef(ex);
  if (basis == null || coef <= 0) {
    return ('首周按 RPE 找重量（目标 $loadPctLabel）', 0);
  }
  final oneRm = oneRmMap[basis];
  if (oneRm == null) {
    return ('首周按 RPE 找重量（目标 $loadPctLabel）', 0);
  }
  final working = _round2p5(oneRm * coef * loadPctMid);
  if (working < 2.5) {
    return ('首周按 RPE 找重量（目标 $loadPctLabel）', 0);
  }
  final perHand = ex.equipmentRequired.contains('dumbbell') &&
      !ex.equipmentRequired.contains('barbell');
  final unit = perHand ? ' kg/只' : ' kg';
  return ('${_fmt(working)}$unit（$loadPctLabel）', working);
}
