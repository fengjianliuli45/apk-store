import 'exercise_library.dart';
import 'models.dart';

/// Port of fitness-planner's `injury_planner.py`.
/// 伤病 → 硬禁高风险动作、软提示自带禁忌动作（排后 + 无痛幅度），而不是删整块肌肉。

const _injuryAliases = <String, String>{
  'knee': 'knee', 'knees': 'knee', '膝': 'knee', '膝盖': 'knee', '膝关节': 'knee',
  'patella': 'knee', 'patellofemoral': 'knee', 'meniscus': 'knee', '半月板': 'knee',
  'shoulder': 'shoulder', 'shoulders': 'shoulder', '肩': 'shoulder', '肩膀': 'shoulder',
  '肩关节': 'shoulder', 'impingement': 'shoulder', '肩峰': 'shoulder', 'rotator_cuff': 'shoulder',
  '肩袖': 'shoulder', 'ac_joint': 'shoulder',
  'lower_back': 'lower_back', 'low_back': 'lower_back', 'back': 'lower_back',
  'lumbar': 'lower_back', '腰': 'lower_back', '腰椎': 'lower_back', '下背': 'lower_back',
  '腰痛': 'lower_back', '腰肌': 'lower_back', 'disc': 'lower_back', '椎间盘': 'lower_back',
  'sciatica': 'lower_back', '坐骨神经': 'lower_back',
  'wrist': 'wrist', 'wrists': 'wrist', '手腕': 'wrist', '腕': 'wrist', '腕关节': 'wrist',
  'elbow': 'elbow', 'elbows': 'elbow', '肘': 'elbow', '手肘': 'elbow', '肘关节': 'elbow',
  'tennis_elbow': 'elbow', 'golfer_elbow': 'elbow', '网球肘': 'elbow', '高尔夫球肘': 'elbow',
  'epicondylitis': 'elbow',
  'hip': 'hip', 'hips': 'hip', '髋': 'hip', '髋关节': 'hip', '胯': 'hip',
  'ankle': 'ankle', 'ankles': 'ankle', '踝': 'ankle', '脚踝': 'ankle', '踝关节': 'ankle',
  'achilles': 'ankle', '跟腱': 'ankle',
  'neck': 'neck', '颈': 'neck', '颈椎': 'neck', '脖子': 'neck', 'cervical': 'neck',
};

class _Rule {
  const _Rule(this.avoidPatterns, this.avoidExercises, this.note);
  final Set<String> avoidPatterns;
  final Set<String> avoidExercises;
  final String note;
}

const _injuryRules = <String, _Rule>{
  'knee': _Rule({}, {
    'single_leg_squat', 'sissy_squat', 'nordic_curl', 'walking_lunges', 'lunges',
    'reverse_lunge', 'bulgarian_split_squat', 'step_up', 'box_squat',
  }, '膝伤：深蹲只到大腿平行、控制膝盖前移；多用髋主导（罗马尼亚硬拉、臀推）'
      '和器械支撑（腿举、高脚杯深蹲）；不做弓步 / 跳跃 / 单腿蹲。'),
  'shoulder': _Rule({}, {
    'overhead_press', 'push_press', 'barbell_front_raise', 'upright_row',
    'cable_upright_row', 'dumbbell_upright_row', 'dips', 'assisted_dips',
    'decline_barbell_press', 'decline_dumbbell_press', 'lateral_raise',
    'cable_lateral_raise', 'lateral_raise_machine', 'band_lateral_raise',
    'pike_push_up', 'elevated_pike_push_up',
  }, '肩伤 / 撞击：不做杠铃过顶推举、直立划船、侧平举过肩、双杠臂屈伸；'
      '哑铃推举 / 卧推 / 俯卧撑控制在无痛幅度，多做面拉 / 肩胛稳定。'),
  'lower_back': _Rule({}, {
    'deadlift', 'sumo_deadlift', 'trap_bar_deadlift', 'dumbbell_deadlift',
    'barbell_row', 'pendlay_row', 'good_morning', 'romanian_deadlift',
    'barbell_back_squat', 'front_squat', 'overhead_press', 'push_press',
    'russian_twist', 'cable_woodchop', 'cable_russian_twists', 'kettlebell_swing',
    'kettlebell_clean', 'superman_push_up', 'back_extension', 'hanging_windshield_wiper',
  }, '下背伤：不做大重量轴向负荷（杠铃深蹲 / 硬拉 / 站姿推举）和负重脊柱屈曲 / 旋转；'
      '用胸垫划船、腿举、高脚杯深蹲、臀推，核心练死虫 / 鸟狗 / 平板。'),
  'wrist': _Rule({}, {
    'front_squat', 'barbell_curl', 'ez_bar_curl', 'upright_row', 'push_up',
    'wide_push_up', 'diamond_push_up', 'close_grip_push_up', 'archer_push_up',
    'decline_push_up', 'incline_push_up', 'band_wrist_curl', 'dead_hang',
  }, '手腕伤：避免手腕背屈负重；用哑铃中立握、器械、助力带 / 俯卧撑握把，弯举改锤式 / 绳索。'),
  'elbow': _Rule({}, {
    'skull_crusher', 'french_press', 'overhead_triceps_extension',
    'cable_overhead_extension', 'band_overhead_triceps_extension', 'barbell_curl',
    'ez_bar_curl', 'close_grip_bench_press', 'diamond_push_up', 'close_grip_push_up',
  }, '肘部肌腱炎：直臂 / 孤立臂部动作减量、用中立握、别练到力竭；大肌群复合动作正常练。'),
  'hip': _Rule({}, {
    'single_leg_squat', 'sissy_squat', 'bulgarian_split_squat', 'box_squat', 'sumo_deadlift',
  }, '髋伤 / 撞击：避免深屈髋和大开脚硬拉；深蹲减幅度，多做臀推 / 臀桥 / 腿举。'),
  'ankle': _Rule({'calf_raise'}, {
    'walking_lunges', 'lunges', 'reverse_lunge', 'single_leg_squat', 'step_up',
  }, '踝伤 / 跟腱：不做提踵和跳跃、弓步；下肢用腿举 / 臀推等踝关节负荷小的动作，小腿暂时不直接练。'),
  'neck': _Rule({}, {
    'overhead_press', 'push_press', 'barbell_shrug', 'dumbbell_shrug', 'upright_row',
    'band_shrug', 'band_y_raise',
  }, '颈椎伤：不做过顶推举、耸肩、直立划船；划船 / 下拉保持颈部中立。'),
};

const _contraindToCanonical = <String, String>{
  'shoulder_impingement': 'shoulder', 'shoulder_injury': 'shoulder',
  'knee_injury': 'knee', 'knee_pain': 'knee',
  'lower_back_injury': 'lower_back', 'lower_back_pain': 'lower_back',
  'wrist_injury': 'wrist', 'elbow_injury': 'elbow',
  'hip_impingement': 'hip', 'hip_injury': 'hip',
  'achilles_injury': 'ankle', 'ankle_injury': 'ankle', 'neck_injury': 'neck',
};

Set<String> normalizeInjuries(List<String>? raw) {
  final out = <String>{};
  for (final item in raw ?? const <String>[]) {
    final s = item.trim().toLowerCase();
    if (s.isEmpty) continue;
    final exact = _injuryAliases[s];
    if (exact != null) {
      out.add(exact);
      continue;
    }
    _injuryAliases.forEach((alias, canon) {
      if (alias.length >= 2 && s.contains(alias)) out.add(canon);
    });
  }
  return out;
}

bool isContraindicated(Exercise ex, Set<String> injuries) {
  if (injuries.isEmpty) return false;
  for (final inj in injuries) {
    final rule = _injuryRules[inj];
    if (rule == null) continue;
    if (rule.avoidPatterns.contains(ex.movementPattern)) return true;
    if (rule.avoidExercises.contains(ex.id)) return true;
  }
  return false;
}

bool isCautioned(Exercise ex, Set<String> injuries) {
  if (injuries.isEmpty) return false;
  for (final c in ex.injuryContraindications) {
    final canon = _contraindToCanonical[c.trim().toLowerCase()];
    if (canon != null && injuries.contains(canon)) return true;
  }
  return false;
}

List<Map<String, String>> injuryAccommodations(Set<String> injuries) {
  final sorted = injuries.toList()..sort();
  return [
    for (final inj in sorted)
      {'injury': inj, 'note': _injuryRules[inj]?.note ?? '在无痛范围内训练，痛就换动作。'},
  ];
}

/// Port of `plan_output._injury_block`.
Map<String, dynamic> injuryBlock(
  UserProfile profile,
  Map<String, dynamic> volumeReport,
  List<SessionResult> sessions,
  ExerciseLibrary library,
) {
  final inj = normalizeInjuries(profile.injuries);
  if (inj.isEmpty) {
    return {
      'injuries': const <String>[],
      'notes': const [],
      'under_covered_muscles': const <String>[],
      'pain_free_range_exercises': const <String>[],
    };
  }

  final delivered = (volumeReport['delivered'] as Map?) ?? const {};
  final target = (volumeReport['target'] as Map?) ?? const {};
  final starved = <String>[];
  for (final e in target.entries) {
    final t = (e.value as num).toInt();
    if (t < 2 || ((delivered[e.key] as num?)?.toInt() ?? 0) > 0) continue;
    final healthy = library.queryByMuscle(e.key as String, profile.equipment,
        level: profile.level);
    final safe = library.queryByMuscle(e.key as String, profile.equipment,
        level: profile.level, injuries: profile.injuries);
    if (healthy.isNotEmpty && safe.isEmpty) starved.add(e.key as String);
  }
  starved.sort();

  final caution = <String>[];
  final seen = <String>{};
  for (final s in sessions) {
    for (final ex in s.exercises) {
      if (!seen.add(ex.exerciseId)) continue;
      final exObj = library.getById(ex.exerciseId);
      if (exObj != null && isCautioned(exObj, inj)) caution.add(ex.name);
    }
  }

  return {
    'injuries': inj.toList()..sort(),
    'notes': injuryAccommodations(inj),
    'under_covered_muscles': starved,
    'pain_free_range_exercises': caution,
  };
}
