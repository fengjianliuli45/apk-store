import 'load_planner.dart' show baselineLifts;
import 'models.dart';
import 'progress_tracker.dart';
import 'response_profiler.dart';
import 'stage_assessor.dart';

/// Port of fitness-planner's `check_in_engine.py`.
/// 中周期边界：评估上一个周期 → 调整 → 产出喂回引擎的下一份输入。

const _lower = {'squat', 'hinge'};

// 体重周变化率的目标带（%/周）——超出就按 ±150 kcal 微调。
// fat_loss 0.5–1%/周保肌（Helms 2014, PMC4033492）；增肌 0.25–0.5%/周控脂。
const _kcalStep = 150;
const _dietBands = <String, (double, double)>{
  'fat_loss': (-1.1, -0.3),
  'hypertrophy': (0.1, 0.6),
  'recomposition': (-0.35, 0.35),
  'strength': (-0.35, 0.5),
};

String _signed2(double x) => (x >= 0 ? '+' : '') + x.toStringAsFixed(2);

/// 按体重趋势返回 (kcal 增量, 说明)。数据不足或在目标带内 → (0, '')。
(int, String) _dietAdjust(String goal, double? weeklyPct) {
  final band = _dietBands[goal];
  if (band == null || weeklyPct == null) return (0, '');
  final (low, high) = band;
  if (weeklyPct < low) {
    return (
      _kcalStep,
      '体重周变化 ${_signed2(weeklyPct)}%，低于目标带 $low~$high%/周，热量上调 $_kcalStep'
    );
  }
  if (weeklyPct > high) {
    return (
      -_kcalStep,
      '体重周变化 ${_signed2(weeklyPct)}%，高于目标带 $low~$high%/周，热量下调 $_kcalStep'
    );
  }
  return (0, '');
}

const _basisKeywords = {
  'squat': ['squat', '深蹲', 'lunge', '箭步'],
  'bench': ['bench', 'press', '卧推', '推举', 'dip', 'chest'],
  'hinge': ['deadlift', 'rdl', 'hinge', '硬拉', 'thrust', '臀'],
  'row': ['row', 'pull', 'chin', '划船', '引体', '下拉'],
};

String? _basisOf(String exerciseId) {
  final eid = exerciseId.toLowerCase();
  for (final entry in _basisKeywords.entries) {
    if (entry.value.any(eid.contains)) return entry.key;
  }
  return null;
}

class LoadChange {
  LoadChange(this.exerciseId, this.basis, this.fromKg, this.toKg, this.reason);
  final String exerciseId;
  final String? basis;
  final double fromKg;
  final double toKg;
  final String reason;

  Map<String, dynamic> toJson() => {
        'exercise_id': exerciseId,
        'basis': basis,
        'from_kg': fromKg,
        'to_kg': toKg,
        'reason': reason,
      };
}

class CycleReview {
  CycleReview({
    required this.verdict,
    required this.summary,
    required this.assessment,
    required this.responseProfile,
    required this.volumeChange,
    required this.makeupSessions,
    required this.loadChanges,
    required this.unlockReward,
    required this.nextRaw,
    this.kcalChange = 0,
    this.dietNote = '',
  });

  final String verdict;
  final String summary;
  final Map<String, dynamic> assessment;
  final Map<String, dynamic> responseProfile;
  final String volumeChange;
  final int makeupSessions;
  final List<LoadChange> loadChanges;
  final String? unlockReward;
  final int kcalChange; // 下一周期热量增量（相对上一周期），0 = 不变
  final String dietNote;
  final Map<String, dynamic> nextRaw;

  Map<String, dynamic> toJson() => {
        'verdict': verdict,
        'summary': summary,
        'assessment': assessment,
        'response_profile': responseProfile,
        'volume_change': volumeChange,
        'makeup_sessions': makeupSessions,
        'load_changes': loadChanges.map((c) => c.toJson()).toList(),
        'unlock_reward': unlockReward,
        'kcal_change': kcalChange,
        'diet_note': dietNote,
        'next_raw': nextRaw,
      };
}

double _round2p5(double x) => (x / 2.5 + 0.5).floor() * 2.5;

List<LoadChange> _loadChanges(
    Map plan, Map<String, Map<String, dynamic>> perEx) {
  final changes = <LoadChange>[];
  final lifts = <String, Map>{
    for (final b in ((plan['stage_goal'] as Map?)?['baseline_lifts'] as List? ?? const []))
      b['exercise_id'] as String: b as Map,
  };
  perEx.forEach((eid, sig) {
    final lift = lifts[eid];
    final start = (lift?['start_load_kg'] as num?)?.toDouble();
    if (lift == null || start == null) return;
    final basis = _basisOf(eid);
    final inc = _lower.contains(basis) ? 5.0 : 2.5;
    if (sig['last_all_top_range'] == true && ((sig['avg_rir'] as double?) ?? 3) <= 2) {
      changes.add(LoadChange(eid, basis, start,
          double.parse((start + inc).toStringAsFixed(1)), '达到次数上限、留力≤2'));
    } else if ((sig['consecutive_below_bottom'] as int? ?? 0) >= 2) {
      changes.add(LoadChange(
          eid, basis, start, _round2p5(start * 0.9), '连续 2 次未达次数下限'));
    } else if (sig['e1rm_declining'] == true) {
      changes.add(
          LoadChange(eid, basis, start, _round2p5(start * 0.9), '估算 1RM 连降'));
    }
  });
  return changes;
}

Map<String, dynamic> _nextRaw(Map plan, List<LoadChange> loadChanges,
    String volumeChange, int kcalDelta) {
  final prof = plan['profile'] as Map;
  final oneRm = (prof['one_rm_estimates'] as Map?) ?? const {};
  final raw = <String, dynamic>{
    'gender': prof['gender'],
    'age': prof['age'],
    'height_cm': prof['height_cm'],
    'weight_kg': prof['weight_kg'],
    'level': prof['level'],
    'goal': prof['goal'],
    'minutes_per_session': prof['minutes_per_session'],
    'days_per_week': prof['days_per_week'],
    'equipment': List<String>.from(prof['equipment'] as List? ?? const []),
    'body_fat_pct': prof['body_fat_pct'],
    'injuries': List<String>.from(prof['injuries'] as List? ?? const []),
    'dietary_restrictions':
        List<String>.from(prof['dietary_restrictions'] as List? ?? const []),
    'cooking_access': prof['cooking_access'],
    'meals_per_day': prof['meals_per_day'],
  };
  final prevKcal = (prof['kcal_adjust'] as num?)?.toInt() ?? 0;
  raw['kcal_adjust'] = (prevKcal + kcalDelta).clamp(-500, 500);
  final ratio = <String, double>{};
  final heaviest = <String, double>{};
  for (final c in loadChanges) {
    if (c.basis == null || c.fromKg == 0) continue;
    if (c.fromKg >= (heaviest[c.basis] ?? 0)) {
      heaviest[c.basis!] = c.fromKg;
      ratio[c.basis!] = c.toKg / c.fromKg;
    }
  }
  final sb = <String, dynamic>{};
  for (final basis in baselineLifts) {
    final cur = ((oneRm[basis] as Map?)?['kg'] as num?)?.toDouble();
    if (cur != null) {
      sb[basis] = {
        'one_rm_kg':
            double.parse((cur * (ratio[basis] ?? 1.0)).toStringAsFixed(1)),
      };
    }
  }
  if (sb.isNotEmpty) raw['strength_baseline'] = sb;
  final cur = (prof['volume_cycle_offset'] as num?)?.toInt() ?? 0;
  if (volumeChange == 'up_one_step') {
    raw['volume_cycle_offset'] = cur + 1;
  } else if (volumeChange == 'down_10pct') {
    raw['volume_cycle_offset'] = (cur - 1) < -2 ? -2 : cur - 1;
  } else {
    raw['volume_cycle_offset'] = cur;
  }
  raw.removeWhere((k, v) => v == null);
  return raw;
}

CycleReview reviewCycle(
  Map<String, dynamic> planJson,
  List<Map<String, dynamic>> workoutLog, {
  List<Map<String, dynamic>> bodyLog = const [],
  int completedCycles = 0,
}) {
  final sg = (planJson['stage_goal'] as Map).cast<String, dynamic>();
  final goal = StageGoal(
    stageType: sg['stage_type'] as String? ?? 'adaptation',
    goalType: sg['goal_type'] as String? ?? 'hypertrophy',
    cycleWeeks: (sg['cycle_weeks'] as num?)?.toInt() ?? 4,
    plannedSessions: (sg['planned_sessions'] as num?)?.toInt() ?? 12,
    requiredSessions: (sg['required_sessions'] as num?)?.toInt() ?? 10,
    adherenceTargetPct: (sg['adherence_target_pct'] as num?)?.toInt() ?? 80,
    minimumActiveWeeks: (sg['minimum_active_weeks'] as num?)?.toInt() ?? 3,
    minimumComparableMeasurements:
        (sg['minimum_comparable_measurements'] as num?)?.toInt() ?? 2,
    outcomeTargets: [
      for (final t in (sg['outcome_targets'] as List? ?? const []))
        OutcomeTarget(
          metric: t['metric'] as String,
          threshold: (t['threshold'] as num).toDouble(),
          unit: t['unit'] as String,
          description: t['description'] as String,
          required: (t['required'] as bool?) ?? false,
        ),
    ],
    completionRule: sg['completion_rule'] as String? ?? '',
    unlockReward: sg['unlock_reward'] as String? ?? 'pet_hatchling',
    baselineLifts: [
      for (final b in (sg['baseline_lifts'] as List? ?? const []))
        Map<String, dynamic>.from(b as Map),
    ],
  );

  final evidence = aggregateEvidence(planJson, workoutLog, bodyLog);
  final assessment = assessStage(goal, evidence);
  final obs = aggregateObservation(
      planJson, workoutLog, bodyLog, completedCycles + 1);
  final response = profileResponse(obs);
  final perEx = perExerciseProgress(planJson, workoutLog);
  final loadChanges = _loadChanges(planJson, perEx);

  String verdict, vol, summary;
  int makeup;
  if (!assessment.safetyMet) {
    verdict = 'address_safety';
    vol = 'hold';
    summary = '先处理疼痛 / 伤病，患处动作降负荷，再评估';
    makeup = 0;
  } else if (assessment.achieved) {
    verdict = 'advance';
    vol = 'up_one_step';
    makeup = 0;
    summary = '阶段达成：进入下一中周期，训练量往 MRV 推一档，达标动作加重';
  } else if (evidence.completedSessions < goal.requiredSessions) {
    verdict = 'extend';
    vol = 'hold';
    makeup = goal.requiredSessions - evidence.completedSessions;
    summary =
        '出勤未达标（${evidence.completedSessions}/${goal.requiredSessions}），延长 2 周并补 $makeup 次';
  } else if (!assessment.outcomeMet && evidence.activeWeeks >= 3) {
    verdict = 'deload_then_retry';
    vol = 'down_10pct';
    makeup = 0;
    summary = '出勤够但表现停滞：额外减载 1 周，容量下调 10%，再冲一个中周期';
  } else {
    verdict = 'extend';
    vol = 'hold';
    makeup = 0;
    summary = '接近达成：同容量再跑一个中周期，数据攒够即达标';
  }

  // 饮食微调：安全问题优先处理时不动饮食；其余按体重趋势调 ±150 kcal
  var kcalDelta = 0;
  var dietNote = '';
  if (verdict != 'address_safety') {
    final goalStr =
        (planJson['profile'] as Map?)?['goal'] as String? ?? 'hypertrophy';
    final r = _dietAdjust(goalStr, weeklyWeightPct(bodyLog));
    kcalDelta = r.$1;
    dietNote = r.$2;
  }

  return CycleReview(
    verdict: verdict,
    summary: summary,
    assessment: assessment.toJson(),
    responseProfile: response.toJson(),
    volumeChange: vol,
    makeupSessions: makeup,
    loadChanges: loadChanges,
    unlockReward: verdict == 'advance' ? goal.unlockReward : null,
    kcalChange: kcalDelta,
    dietNote: dietNote,
    nextRaw: _nextRaw(planJson, loadChanges, vol, kcalDelta),
  );
}
