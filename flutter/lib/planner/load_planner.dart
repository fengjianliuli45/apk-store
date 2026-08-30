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

/// 自重动作举起的「体重占比」——研究实测（JSCR / Suprak 2011 PMID 20179649；ExRx）。
const _bodymassFraction = <String, double>{
  'push_up': 0.64, 'wide_push_up': 0.64, 'close_grip_push_up': 0.64,
  'diamond_push_up': 0.64, 'incline_push_up': 0.45, 'decline_push_up': 0.75,
  'archer_push_up': 0.80, 'knee_push_up': 0.49, 'bench_dips': 0.40,
  'pike_push_up': 0.60, 'elevated_pike_push_up': 0.70, 'handstand_push_up': 1.0,
  'pull_up': 1.0, 'chin_up': 1.0, 'assisted_pull_up': 0.55,
  'inverted_row': 0.60, 'feet_elevated_inverted_row': 0.75,
  'bodyweight_squat': 0.68, 'split_squat': 0.85, 'reverse_lunge': 0.85,
  'lunges': 0.85, 'step_up': 0.85, 'sissy_squat': 0.75, 'single_leg_squat': 1.0,
  'single_leg_rdl_bw': 0.55, 'glute_bridge': 0.40, 'single_leg_glute_bridge': 0.55,
  'bodyweight_hip_thrust': 0.55, 'single_leg_hip_thrust': 0.75, 'frog_pump': 0.35,
  'sliding_leg_curl': 0.50, 'nordic_curl': 0.65,
  'bodyweight_calf_raise': 0.95, 'single_leg_calf_raise': 1.0,
};

const _bwPatternFraction = <String, double>{
  'horizontal_push': 0.60, 'vertical_push': 0.60,
  'vertical_pull': 0.95, 'horizontal_pull': 0.60,
  'squat': 0.70, 'hip_hinge': 0.55, 'hip_extension': 0.45,
  'knee_flexion': 0.50, 'calf_raise': 0.90,
};

const _bwRepCap = 20;

double estimate1rm(double weightKg, int reps) {
  final r = reps < 1 ? 1 : (reps > 12 ? 12 : reps);
  return (weightKg * (1 + r / 30) * 10 + 0.5).floor() / 10;
}

/// 徒手动作：体重 × 体重占比 × Epley → 等效负荷 e1RM（kg）。占比查不到 → null。
double? bodyweightE1rm(double bodyweightKg, Exercise ex, int reps) {
  var frac = _bodymassFraction[ex.id];
  if (frac == null &&
      ex.equipmentRequired.length == 1 &&
      ex.equipmentRequired.first == 'bodyweight') {
    frac = _bwPatternFraction[ex.movementPattern];
  }
  if (frac == null || frac == 0 || bodyweightKg == 0 || reps == 0) return null;
  final r = reps < 1 ? 1 : (reps > _bwRepCap ? _bwRepCap : reps);
  return (bodyweightKg * frac * (1 + r / 30) * 10 + 0.5).floor() / 10;
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
