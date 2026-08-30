import 'models.dart';

/// Port of fitness-planner's `mesocycle_planner.py`.
/// 把「一份周计划」展开成 4–6 周中周期：积累期容量爬到 MAV / RIR 递减，末周减载。

const _volStart = 0.7, _volEnd = 1.0;
const _rirStart = 3, _rirEnd = 0;

int _round(double x) => (x + 0.5).floor();

WeekPlan _weekPlan(
  int num,
  String phase,
  int rir,
  double vmult,
  List<SessionResult> sessions,
  bool isDeload, {
  bool dietBreak = false,
  int dietKcalDelta = 0,
  String note = '',
}) {
  final overrides = <String, Map<String, int>>{};
  var total = 0;
  for (final s in sessions) {
    if (s.type == 'rest' || s.exercises.isEmpty) continue;
    final dayOv = <String, int>{};
    for (final e in s.exercises) {
      final scaled = _round(e.sets * vmult);
      final v = scaled < 2 ? 2 : scaled;
      dayOv[e.exerciseId] = v;
      total += v;
    }
    overrides[s.day] = dayOv;
  }
  return WeekPlan(
    week: num,
    phase: phase,
    rirTarget: rir,
    isDeload: isDeload,
    volumeMult: vmult,
    setOverrides: overrides,
    weekTotalSets: total,
    dietBreak: dietBreak,
    dietKcalDelta: dietKcalDelta,
    note: note,
  );
}

Mesocycle planMesocycle(
  UserProfile profile,
  List<SessionResult> sessions,
  ProgressionResult progression, {
  int currentWeek = 1,
  int surplusKcal = 0,
}) {
  final buildWeeks =
      progression.nextCheckWeek < 3 ? 3 : progression.nextCheckWeek;
  final weeks = <WeekPlan>[];
  for (var w = 1; w <= buildWeeks; w++) {
    final frac = (w - 1) / (buildWeeks - 1 < 1 ? 1 : buildWeeks - 1);
    final vmult = _volStart + (_volEnd - _volStart) * frac;
    final rir = _round(_rirStart - (_rirStart - _rirEnd) * frac);
    weeks.add(_weekPlan(w, 'accumulation', rir, vmult, sessions, false));
  }
  final deloadMult =
      (progression.deloadVolumePct / 100) < 0.4 ? 0.4 : progression.deloadVolumePct / 100;
  // 减脂：减载周热量回到维持量（MATADOR / Byrne 2018）。其它目标饮食不变。
  final isDietBreak = profile.goal == 'fat_loss' && surplusKcal < 0;
  weeks.add(_weekPlan(
    buildWeeks + 1, 'deload', 3, deloadMult, sessions, true,
    dietBreak: isDietBreak,
    dietKcalDelta: isDietBreak ? -surplusKcal : 0,
    note: isDietBreak
        ? '减载周：训练量减半的同时，热量提到维持量（约 +${-surplusKcal} kcal），缓解代谢适应、保肌'
        : '',
  ));
  final cw = currentWeek < 1
      ? 1
      : (currentWeek > buildWeeks + 1 ? buildWeeks + 1 : currentWeek);
  return Mesocycle(lengthWeeks: buildWeeks + 1, currentWeek: cw, weeks: weeks);
}
