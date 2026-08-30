import 'models.dart';
import 'split_selector.dart';

/// Port of fitness-planner's `recovery_planner.py`.
///
/// 把日程里的 rest 日填成有内容的「轻日」，不抢主课的恢复：
/// 减脂 → 有氧；增肌/增肌减脂且主课没排满且非新手 → 快恢复肌群泵感课；
/// 新手 → 只给主动恢复；至少保留 1 天完全休息（rest 日 ≥ 2 或硬练 ≥ 5 天）。

const _pumpMoves = {
  'biceps': ['二头弯举', '哑铃 / 弹力带，3 组 × 15 次，慢放'],
  'triceps': ['三头下压 / 窄距俯卧撑', '3 组 × 15–20 次'],
  'calves': ['站姿提踵', '3 组 × 20 次，顶峰停 1 秒'],
  'core': ['卷腹 + 侧支撑', '卷腹 3×15，侧支撑 3×30 秒/侧'],
  'shoulders': ['哑铃侧平举', '3 组 × 15 次，轻重量'],
};

const _mobilityItems = [
  '动态拉伸 / 关节活动 8 分钟',
  '6000 步，或散步 15 分钟',
  '泡沫轴放松 5 分钟',
];

const _cardioItems = [
  '快走 / 椭圆机 / 单车 25–35 分钟，心率 60–70% 最大',
  '结束后静态拉伸 5 分钟',
];

List<RecoveryDay> planRecovery(
  UserProfile profile,
  SplitResult split,
  Map<String, dynamic> volumeReport,
) {
  final restDays = [
    for (final d in split.weeklySchedule)
      if (d.type == 'rest') d.day,
  ];
  if (restDays.isEmpty) return const [];

  final goal = profile.goal;
  final level = profile.level;
  final vsOpt = (volumeReport['vs_optimal_pct'] as num?)?.toInt() ?? 100;
  final nRest = restDays.length;

  final wantFull = level == 'beginner' ? 2 : 1;
  final wantCardio = goal == 'fat_loss'
      ? (nRest - 1 < 0 ? 0 : (nRest - 1 < 2 ? nRest - 1 : 2))
      : 0;
  final wantPump = ((goal == 'hypertrophy' || goal == 'recomposition') &&
          level != 'beginner' &&
          vsOpt < 92 &&
          nRest - wantCardio - 1 >= 1)
      ? 1
      : 0;
  var keepFull = wantFull < (nRest - wantCardio - wantPump)
      ? wantFull
      : (nRest - wantCardio - wantPump);
  final minKeep = nRest > 0 ? 1 : 0;
  if (keepFull < minKeep) keepFull = minKeep;
  if (keepFull > nRest) keepFull = nRest;

  final keepFullDays =
      keepFull > 0 ? restDays.sublist(nRest - keepFull) : <String>[];
  final fillable = restDays.sublist(0, nRest - keepFull);

  final days = <RecoveryDay>[];
  var i = 0;

  if (wantCardio > 0) {
    final n = wantCardio < fillable.length ? wantCardio : fillable.length;
    for (var k = 0; k < n; k++) {
      days.add(RecoveryDay(
        day: fillable[i++], kind: 'cardio', durationMin: 30,
        title: '低强度有氧',
        focus: '减脂靠热量缺口，有氧日直接补上这部分',
        items: List.of(_cardioItems),
      ));
    }
  } else if (wantPump > 0 && i < fillable.length) {
    final delivered = (volumeReport['delivered'] as Map?) ?? const {};
    final optimal = (volumeReport['optimal'] as Map?) ?? const {};
    var targets = [
      for (final m in const ['biceps', 'triceps', 'calves', 'core'])
        if (((delivered[m] as num?) ?? 0) < ((optimal[m] as num?) ?? 999)) m,
    ];
    if (targets.isEmpty) targets = ['biceps', 'triceps', 'calves'];
    targets = targets.take(4).toList();
    days.add(RecoveryDay(
      day: fillable[i++], kind: 'pump', durationMin: 20,
      title: '快恢复肌群泵感课',
      focus: '主课相当于最优的 $vsOpt%，这 20 分钟补上手臂/小腿/核心，往最优推一点，不抢大动作的恢复',
      items: [
        for (final m in targets)
          if (_pumpMoves.containsKey(m))
            '${_pumpMoves[m]![0]} — ${_pumpMoves[m]![1]}',
      ],
    ));
  }

  for (final d in fillable.sublist(i)) {
    days.add(RecoveryDay(
      day: d, kind: 'mobility', durationMin: 12,
      title: '主动恢复',
      focus: '拉伸 + 走路，保持每天的训练习惯',
      items: List.of(_mobilityItems),
    ));
  }

  for (final d in keepFullDays) {
    days.add(RecoveryDay(
      day: d, kind: 'rest', durationMin: 0,
      title: '完全休息',
      focus: '睡够，让肌肉和神经系统恢复',
      items: const [],
    ));
  }

  final order = {for (var k = 0; k < dayNames.length; k++) dayNames[k]: k};
  days.sort((a, b) => (order[a.day] ?? 99).compareTo(order[b.day] ?? 99));
  return days;
}
