import 'exercise_library.dart';
import 'models.dart';
import 'session_builder.dart';
import 'split_selector.dart';

/// Port of fitness-planner's `frequency_planner.py`.
///
/// 用户只填「每次能练多久」，训练频率是结果：在该水平允许的天数范围里，
/// 挑最少的、能兑现每周训练量的天数。低于最低训练时长 → 上调时长（科学优先）。

const levelDayRange = {
  'beginner': [3, 3],
  'intermediate': [3, 5],
  'advanced': [3, 6],
};

/// 训练量「完成」= 每个肌群 ≥ MEV（自适应 coverage_pct 达 100）
const coverageTarget = 100;
/// 训练量「到最优」= 相当于 MAV 的百分比达到即不必再加天数
const optimalTarget = 98;

const _minScan = 30;
const _maxScan = 120;
const _scanStep = 5;

const _goalCn = {
  'hypertrophy': '增肌',
  'fat_loss': '减脂',
  'strength': '力量',
  'recomposition': '增肌减脂',
};

class FrequencyPlan {
  FrequencyPlan({
    required this.daysPerWeek,
    required this.minutesPerSession,
    required this.minSessionMinutes,
    required this.coveragePct,
    required this.vsOptimalPct,
    required this.minutesRaised,
    this.note = '',
  });

  final int daysPerWeek;
  final int minutesPerSession;
  final int minSessionMinutes;
  final int coveragePct;
  final int vsOptimalPct;
  final bool minutesRaised;
  final String note;

  Map<String, dynamic> toJson() => {
    'days_per_week': daysPerWeek,
    'minutes_per_session': minutesPerSession,
    'min_session_minutes': minSessionMinutes,
    'coverage_pct': coveragePct,
    'vs_optimal_pct': vsOptimalPct,
    'minutes_raised': minutesRaised,
    'note': note,
  };
}

UserProfile _withDays(UserProfile p, int days) => UserProfile(
      gender: p.gender, age: p.age, heightCm: p.heightCm, weightKg: p.weightKg,
      level: p.level, goal: p.goal, minutesPerSession: p.minutesPerSession,
      equipment: p.equipment, daysPerWeek: days, bodyFatPct: p.bodyFatPct,
      mealsPerDay: p.mealsPerDay, supplements: p.supplements,
      targetWeightKg: p.targetWeightKg, injuries: p.injuries,
      dietaryRestrictions: p.dietaryRestrictions, cookingAccess: p.cookingAccess, strengthBaseline: p.strengthBaseline,
      warnings: p.warnings, notes: p.notes,
    );

UserProfile _withMinutes(UserProfile p, int minutes) => UserProfile(
      gender: p.gender, age: p.age, heightCm: p.heightCm, weightKg: p.weightKg,
      level: p.level, goal: p.goal, minutesPerSession: minutes,
      equipment: p.equipment, daysPerWeek: p.daysPerWeek, bodyFatPct: p.bodyFatPct,
      mealsPerDay: p.mealsPerDay, supplements: p.supplements,
      targetWeightKg: p.targetWeightKg, injuries: p.injuries,
      dietaryRestrictions: p.dietaryRestrictions, cookingAccess: p.cookingAccess, strengthBaseline: p.strengthBaseline,
      warnings: p.warnings, notes: p.notes,
    );

/// 返回 [coveragePct, vsOptimalPct]。
List<int> _analyzeAt(
    UserProfile profile, int days, int minutes, ExerciseLibrary library) {
  final trial = _withMinutes(_withDays(profile, days), minutes);
  final sp = selectSplit(trial);
  final sessions = buildSessions(trial, sp, library);
  final rep = analyzeVolume(trial, sp, sessions);
  return [rep['coverage_pct'] as int, rep['vs_optimal_pct'] as int];
}

/// 返回 [days, coveragePct, vsOptimalPct]。
List<int> _pickDays(UserProfile profile, int minutes, ExerciseLibrary library) {
  final range = levelDayRange[profile.level] ?? const [3, 5];
  final lo = range[0], hi = range[1];
  List<int>? best;
  for (var d = lo; d <= hi; d++) {
    final r = _analyzeAt(profile, d, minutes, library);
    if (r[1] >= optimalTarget) return [d, r[0], r[1]];
    if (best == null || r[1] > best[2]) best = [d, r[0], r[1]];
  }
  return best!;
}

int minSessionMinutes(UserProfile profile, ExerciseLibrary library) {
  final range = levelDayRange[profile.level] ?? const [3, 5];
  final lo = range[0], hi = range[1];
  for (var m = _minScan; m <= _maxScan; m += _scanStep) {
    for (var d = lo; d <= hi; d++) {
      if (_analyzeAt(profile, d, m, library)[0] >= coverageTarget) return m;
    }
  }
  return _maxScan;
}

/// onboarding 用：用户选完 目标/水平/器械 后、还没选时长时算「每次至少练多少分钟」，
/// 让时长选项从这里起步，而不是给更短的选项再事后上调。
int minSessionMinutesFor(
  String level,
  String goal,
  List<String> equipment,
  ExerciseLibrary library,
) {
  final probe = UserProfile(
    gender: 'M', age: 30, heightCm: 175, weightKg: 75,
    level: level, goal: goal, minutesPerSession: 60,
    equipment: equipment.isEmpty ? const ['bodyweight'] : equipment,
  );
  return minSessionMinutes(probe, library);
}

FrequencyPlan planFrequency(UserProfile profile, ExerciseLibrary library) {
  final requested = profile.minutesPerSession;
  final minMinutes = minSessionMinutes(profile, library);

  if (profile.daysPerWeek != null) {
    final days = profile.daysPerWeek!;
    final r = days > 0
        ? _analyzeAt(profile, days, requested, library)
        : const [0, 0];
    return FrequencyPlan(
      daysPerWeek: days,
      minutesPerSession: requested,
      minSessionMinutes: minMinutes,
      coveragePct: r[0],
      vsOptimalPct: r[1],
      minutesRaised: false,
      note: '按你指定的每周 $days 天安排。',
    );
  }

  final minutes = requested > minMinutes ? requested : minMinutes;
  final raised = minutes > requested;

  final r = _pickDays(profile, minutes, library);
  final days = r[0], coverage = r[1], vsOpt = r[2];

  final String note;
  if (raised) {
    note = '${_goalCn[profile.goal] ?? profile.goal}每次至少练 $minMinutes 分钟才能完成每周训练量，'
        '已按 $minMinutes 分钟安排（你填的是 $requested 分钟）。';
  } else if (coverage < coverageTarget) {
    note = '每次 $minutes 分钟 / 每周 $days 天，训练量约 $coverage%（略欠最低有效量）。每次再加长一点可补上。';
  } else if (vsOpt < optimalTarget) {
    note = '每次 $minutes 分钟 / 每周 $days 天，训练量已完成（相当于最优的 $vsOpt%）。想冲最大增速：每次加约 15 分钟。';
  } else {
    note = '每次 $minutes 分钟 / 每周 $days 天，训练量到位（已接近最优）。';
  }

  return FrequencyPlan(
    daysPerWeek: days,
    minutesPerSession: minutes,
    minSessionMinutes: minMinutes,
    coveragePct: coverage,
    vsOptimalPct: vsOpt,
    minutesRaised: raised,
    note: note,
  );
}

/// 把「引擎定频率」的结果落到一个新的 UserProfile 上。
(UserProfile, FrequencyPlan) resolveFrequency(
  UserProfile profile,
  ExerciseLibrary library,
) {
  final fp = planFrequency(profile, library);
  final notes = [...profile.notes];
  if (fp.note.isNotEmpty && !notes.contains(fp.note)) notes.add(fp.note);
  final resolved = UserProfile(
    gender: profile.gender, age: profile.age, heightCm: profile.heightCm,
    weightKg: profile.weightKg, level: profile.level, goal: profile.goal,
    minutesPerSession: fp.minutesPerSession, equipment: profile.equipment,
    daysPerWeek: fp.daysPerWeek, bodyFatPct: profile.bodyFatPct,
    mealsPerDay: profile.mealsPerDay, supplements: profile.supplements,
    targetWeightKg: profile.targetWeightKg, injuries: profile.injuries,
    dietaryRestrictions: profile.dietaryRestrictions,
    cookingAccess: profile.cookingAccess,
    strengthBaseline: profile.strengthBaseline, warnings: profile.warnings,
    notes: notes,
  );
  return (resolved, fp);
}
