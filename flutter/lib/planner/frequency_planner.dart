import 'exercise_library.dart';
import 'models.dart';
import 'session_builder.dart';
import 'split_selector.dart';

/// Port of fitness-planner's `frequency_planner.py`.
///
/// 用户只填「每次能练多久」，训练频率是结果：在该水平允许的天数范围里，
/// 挑最少的、能兑现每周训练量的天数。低于最低训练时长 → 上调时长（科学优先）。

const levelDayRange = {
  'beginner': [3, 4],
  'intermediate': [3, 5],
  'advanced': [3, 6],
};

const coverageTarget = 92;

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
    required this.minutesRaised,
    this.note = '',
  });

  final int daysPerWeek;
  final int minutesPerSession;
  final int minSessionMinutes;
  final int coveragePct;
  final bool minutesRaised;
  final String note;

  Map<String, dynamic> toJson() => {
    'days_per_week': daysPerWeek,
    'minutes_per_session': minutesPerSession,
    'min_session_minutes': minSessionMinutes,
    'coverage_pct': coveragePct,
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
      dietaryRestrictions: p.dietaryRestrictions, cookingAccess: p.cookingAccess,
      warnings: p.warnings, notes: p.notes,
    );

UserProfile _withMinutes(UserProfile p, int minutes) => UserProfile(
      gender: p.gender, age: p.age, heightCm: p.heightCm, weightKg: p.weightKg,
      level: p.level, goal: p.goal, minutesPerSession: minutes,
      equipment: p.equipment, daysPerWeek: p.daysPerWeek, bodyFatPct: p.bodyFatPct,
      mealsPerDay: p.mealsPerDay, supplements: p.supplements,
      targetWeightKg: p.targetWeightKg, injuries: p.injuries,
      dietaryRestrictions: p.dietaryRestrictions, cookingAccess: p.cookingAccess,
      warnings: p.warnings, notes: p.notes,
    );

int _coverageAt(UserProfile profile, int days, ExerciseLibrary library) {
  final trial = _withDays(profile, days);
  final sp = selectSplit(trial);
  final sessions = buildSessions(trial, sp, library);
  return analyzeVolume(trial, sp, sessions)['coverage_pct'] as int;
}

/// 返回 [days, coverage, hit]。
List<Object> _fewestDaysHittingTarget(
  UserProfile profile,
  int minutes,
  ExerciseLibrary library,
) {
  final range = levelDayRange[profile.level] ?? const [3, 5];
  final lo = range[0], hi = range[1];
  final trial = _withMinutes(profile, minutes);
  var bestDays = hi, bestCov = -1;
  for (var d = lo; d <= hi; d++) {
    final cov = _coverageAt(trial, d, library);
    if (cov >= coverageTarget) return [d, cov, true];
    if (cov > bestCov) {
      bestDays = d;
      bestCov = cov;
    }
  }
  return [bestDays, bestCov, false];
}

int minSessionMinutes(UserProfile profile, ExerciseLibrary library) {
  for (var m = _minScan; m <= _maxScan; m += _scanStep) {
    final r = _fewestDaysHittingTarget(profile, m, library);
    if (r[2] as bool) return m;
  }
  return _maxScan;
}

FrequencyPlan planFrequency(UserProfile profile, ExerciseLibrary library) {
  final requested = profile.minutesPerSession;
  final minMinutes = minSessionMinutes(profile, library);

  if (profile.daysPerWeek != null) {
    final days = profile.daysPerWeek!;
    final coverage = days > 0 ? _coverageAt(profile, days, library) : 0;
    return FrequencyPlan(
      daysPerWeek: days,
      minutesPerSession: requested,
      minSessionMinutes: minMinutes,
      coveragePct: coverage,
      minutesRaised: false,
      note: '按你指定的每周 $days 天安排。',
    );
  }

  final minutes = requested > minMinutes ? requested : minMinutes;
  final raised = minutes > requested;

  final r = _fewestDaysHittingTarget(profile, minutes, library);
  final days = r[0] as int;
  final coverage = r[1] as int;
  final hit = r[2] as bool;

  final String note;
  if (raised) {
    note = '${_goalCn[profile.goal] ?? profile.goal}每次至少练 $minMinutes 分钟才能保证每周训练量，'
        '已按 $minMinutes 分钟安排（你填的是 $requested 分钟）。';
  } else if (!hit) {
    note = '即使每次 $minutes 分钟、每周 $days 天，周训练量也只到约 $coverage%。把每次时间再加长可完整兑现。';
  } else {
    note = '按你每次 $minutes 分钟，安排每周 $days 天即可兑现目标训练量。';
  }

  return FrequencyPlan(
    daysPerWeek: days,
    minutesPerSession: minutes,
    minSessionMinutes: minMinutes,
    coveragePct: coverage,
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
    cookingAccess: profile.cookingAccess, warnings: profile.warnings,
    notes: notes,
  );
  return (resolved, fp);
}
