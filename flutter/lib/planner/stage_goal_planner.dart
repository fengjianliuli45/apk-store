import 'dart:math' as math;

import 'models.dart';

List<OutcomeTarget> _targetsFor(String goal) {
  final targets = <OutcomeTarget>[
    const OutcomeTarget(
      metric: 'same_load_rep_gain',
      threshold: 2,
      unit: 'reps',
      description: '同一标准化动作在相同负荷下增加至少 2 次规范重复',
    ),
    const OutcomeTarget(
      metric: 'performance_improvement_pct',
      threshold: 2.5,
      unit: 'percent',
      description: '标准化动作表现相对基线提高至少 2.5%，并由两次可比较训练确认',
    ),
  ];
  if (goal == 'fat_loss') {
    targets.add(
      const OutcomeTarget(
        metric: 'body_trend_target_met',
        threshold: 1,
        unit: 'boolean',
        description: '多日体重趋势或标准化腰围达到个体阶段目标',
      ),
    );
  } else if (goal == 'hypertrophy' || goal == 'recomposition') {
    targets.add(
      const OutcomeTarget(
        metric: 'body_trend_target_met',
        threshold: 1,
        unit: 'boolean',
        description: '围度、体重或可选体成分趋势支持正向适应',
      ),
    );
  }
  return targets;
}

StageGoal planStageGoal(
  UserProfile profile,
  ProgressionResult progression,
  List<SessionResult> sessions,
) {
  final cycleWeeks = math.max(4, progression.nextCheckWeek);
  final weeklySessions = sessions.where((session) => !session.isRest).length;
  final plannedSessions = weeklySessions * cycleWeeks;
  final requiredSessions = (plannedSessions * 0.8).ceil();
  return StageGoal(
    stageType: 'adaptation',
    goalType: profile.goal,
    cycleWeeks: cycleWeeks,
    plannedSessions: plannedSessions,
    requiredSessions: requiredSessions,
    adherenceTargetPct: 80,
    minimumActiveWeeks: math.min(3, cycleWeeks),
    minimumComparableMeasurements: 2,
    outcomeTargets: _targetsFor(profile.goal),
    completionRule:
        '完成执行与数据质量门槛，并满足至少一个能力或身体趋势结果；百分比表现提升必须由两次可比较训练确认；存在未处理安全问题时不得自动达成',
  );
}
