import '../models/workout_log.dart';
import 'check_in.dart';
import 'models.dart';
import 'plan_adapter.dart';
import 'plan_copy.dart';
import 'stage_assessor.dart';

class WeekDayStatus {
  const WeekDayStatus({
    required this.weekday,
    required this.label,
    required this.typeLabel,
    required this.isRest,
    required this.isToday,
  });

  final int weekday;
  final String label;
  final String typeLabel;
  final bool isRest;
  final bool isToday;
}

class PlanReason {
  const PlanReason({required this.text, this.caution = false});

  final String text;
  final bool caution;
}

class NextStageChange {
  const NextStageChange({
    required this.label,
    required this.value,
    this.caution = false,
  });

  final String label;
  final String value;
  final bool caution;
}

class CycleReviewSnapshot {
  const CycleReviewSnapshot({
    required this.weekLabel,
    required this.completionPct,
    required this.completionKnown,
    required this.intensityLabel,
    required this.recoveryLabel,
    required this.painLabel,
    required this.painCaution,
    required this.weightTrendLabel,
    required this.weightTrendKnown,
    required this.conclusionTitle,
    required this.conclusionBody,
    required this.cautionBody,
    required this.changes,
    required this.reviewDue,
    required this.adoptEnabled,
  });

  final String weekLabel;
  final int completionPct;
  final bool completionKnown;
  final String intensityLabel;
  final String recoveryLabel;
  final String painLabel;
  final bool painCaution;
  final String weightTrendLabel;
  final bool weightTrendKnown;
  final String conclusionTitle;
  final String conclusionBody;
  final String? cautionBody;
  final List<NextStageChange> changes;
  final bool reviewDue;
  final bool adoptEnabled;
}

class TodaySessionSnapshot {
  const TodaySessionSnapshot({
    required this.title,
    required this.sessionIndexLabel,
    required this.durationMin,
    required this.exerciseCount,
    required this.totalSets,
    required this.intensityLabel,
    required this.primaryLoadLabel,
    required this.isRest,
  });

  final String title;
  final String sessionIndexLabel;
  final int durationMin;
  final int exerciseCount;
  final int totalSets;
  final String intensityLabel;
  final String primaryLoadLabel;
  final bool isRest;
}

/// Presentation snapshot for the planner v2 Plan tab and cycle-review page.
/// Built from the generated engine plan plus local workout logs — never from
/// placeholder HUD copy.
class PlanOverview {
  PlanOverview({
    required this.currentWeek,
    required this.cycleWeeks,
    required this.stageTitle,
    required this.stageSummary,
    required this.mesocycleLabel,
    required this.volumeSummary,
    required this.cycleTargetLabel,
    required this.reviewDateLabel,
    required this.weekDays,
    required this.today,
    required this.reasons,
    required this.review,
  });

  final int currentWeek;
  final int cycleWeeks;
  final String stageTitle;
  final String stageSummary;
  final String mesocycleLabel;
  final String volumeSummary;
  final String cycleTargetLabel;
  final String reviewDateLabel;
  final List<WeekDayStatus> weekDays;
  final TodaySessionSnapshot today;
  final List<PlanReason> reasons;
  final CycleReviewSnapshot review;

  String get weekChipLabel => '第 $currentWeek / $cycleWeeks 周';

  factory PlanOverview.from({
    required GeneratedPlan plan,
    List<WorkoutLogEntry> logs = const [],
    DateTime? now,
  }) {
    if (plan.sessions.isEmpty) {
      throw ArgumentError('GeneratedPlan.sessions must cover a 7-day week');
    }
    final moment = now ?? DateTime.now();
    final stage = plan.stageGoal;
    final cycleWeeks = plan.mesocycle?.lengthWeeks ??
        stage?.cycleWeeks ??
        plan.progression.nextCheckWeek.clamp(1, 24);
    final rawWeek = planWeekNumber(plan.generatedAt, moment);
    final currentWeek = rawWeek.clamp(1, cycleWeeks);
    final mesocycleWeek = plan.mesocycle?.weeks
        .where((week) => week.week == currentWeek)
        .firstOrNull;
    final deloadWeek = plan.mesocycle?.weeks
        .where((week) => week.isDeload)
        .firstOrNull;
    final reviewDate = DateTime(
      plan.generatedAt.year,
      plan.generatedAt.month,
      plan.generatedAt.day,
    ).add(Duration(days: cycleWeeks * 7));
    final todaySession = sessionForDate(plan, moment);
    final trainingDays = plan.sessions.where((session) => !session.isRest).toList();
    final todayIndex = todaySession.isRest
        ? trainingDays.length
        : trainingDays.indexWhere((session) => session.day == todaySession.day) + 1;

    return PlanOverview(
      currentWeek: currentWeek,
      cycleWeeks: cycleWeeks,
      stageTitle: mesocycleWeek == null
          ? stageTypeLabel(stage?.stageType ?? 'adaptation')
          : '${_phaseLabel(mesocycleWeek.phase)} · RIR ${mesocycleWeek.rirTarget}',
      stageSummary: mesocycleWeek == null
          ? stageGoalSummary(plan.profile.goal)
          : (mesocycleWeek.note.isEmpty
                ? stageGoalSummary(plan.profile.goal)
                : mesocycleWeek.note),
      mesocycleLabel: '中周期 $currentWeek / $cycleWeeks · '
          '${_phaseShortLabel(mesocycleWeek?.phase ?? stage?.stageType ?? 'adaptation')}',
      volumeSummary: deloadWeek == null
          ? '容量 ${plan.vsOptimalPct}%'
          : '容量 ${plan.vsOptimalPct}% · 第 ${deloadWeek.week} 周减载至 '
              '${(deloadWeek.volumeMult * 100).round()}%',
      cycleTargetLabel: _cycleTargetLabel(plan),
      reviewDateLabel: '复评 ${reviewDate.month}/${reviewDate.day}',
      weekDays: [
        for (var i = 0; i < 7; i++)
          _weekDay(
            plan,
            weekday: i + 1,
            todayWeekday: moment.weekday,
          ),
      ],
      today: TodaySessionSnapshot(
        title: _sessionTitle(todaySession),
        sessionIndexLabel: todaySession.isRest
            ? 'REST'
            : 'SESSION ${todayIndex.toString().padLeft(2, '0')}',
        durationMin: todaySession.durationMin,
        exerciseCount: todaySession.exercises.length,
        totalSets: todaySession.totalSets,
        intensityLabel: _intensityLabel(todaySession),
        primaryLoadLabel: _primaryLoadLabel(todaySession),
        isRest: todaySession.isRest,
      ),
      reasons: _reasons(plan),
      review: _review(
        plan: plan,
        logs: logs,
        now: moment,
        cycleWeeks: cycleWeeks,
        currentWeek: currentWeek,
      ),
    );
  }
}

String _phaseLabel(String phase) => switch (phase) {
  'accumulation' => '累积期',
  'deload' => '减载期',
  'intensification' => '强化期',
  _ => stageTypeLabel(phase),
};

String _phaseShortLabel(String phase) => switch (phase) {
  'accumulation' => '累积',
  'deload' => '减载',
  'intensification' => '强化',
  'adaptation' => '适应',
  _ => phase,
};

WeekDayStatus _weekDay(
  GeneratedPlan plan, {
  required int weekday,
  required int todayWeekday,
}) {
  final session = plan.sessions[(weekday - 1) % plan.sessions.length];
  final isRest = session.isRest;
  return WeekDayStatus(
    weekday: weekday,
    label: weekdayShortLabel(weekday),
    typeLabel: isRest ? '休息' : (sessionTypeLabels[session.type] ?? '力量'),
    isRest: isRest,
    isToday: weekday == todayWeekday,
  );
}

String _sessionTitle(SessionResult session) {
  if (session.isRest) return '休息日';
  return switch (session.type) {
    'upper' => '上肢力量',
    'lower' => '下肢力量',
    'full_body' => '全身力量',
    _ => '${sessionTypeLabels[session.type] ?? session.type}训练',
  };
}

String _cycleTargetLabel(GeneratedPlan plan) {
  final exercises = plan.sessions.expand((session) => session.exercises).toList();
  final lift = exercises.where((exercise) => exercise.compound).firstOrNull ??
      (exercises.isEmpty ? null : exercises.first);
  if (lift == null) {
    return '${trainingGoalLabel(plan.profile.goal)} · ${plan.profile.daysPerWeek} 天/周';
  }
  return '${lift.name} ${lift.sets} 组 × ${lift.reps}';
}

String _intensityLabel(SessionResult session) {
  if (session.isRest || session.exercises.isEmpty) return '—';
  final rpe =
      session.exercises.map((exercise) => exercise.rpe).reduce((a, b) => a + b) /
      session.exercises.length;
  final rir = (10 - rpe).round().clamp(0, 5);
  return 'RIR $rir';
}

String _primaryLoadLabel(SessionResult session) {
  if (session.isRest || session.exercises.isEmpty) return '—';
  final primary = session.exercises.where((exercise) => exercise.compound).firstOrNull ??
      session.exercises.first;
  final kg = primary.loadKg;
  if (kg == null) return primary.load;
  final value = kg == kg.roundToDouble()
      ? kg.toStringAsFixed(0)
      : kg.toStringAsFixed(1);
  return '$value kg';
}

List<PlanReason> _reasons(GeneratedPlan plan) {
  final reasons = <PlanReason>[
    PlanReason(text: '每周 ${plan.profile.daysPerWeek} 次力量，匹配你的可用时间'),
  ];
  if (plan.profile.injuries.isNotEmpty) {
    reasons.add(const PlanReason(text: '已按你的伤病记录避开禁忌动作', caution: true));
  } else {
    reasons.add(const PlanReason(text: '当前没有未处理伤病，保留完整动作选择'));
  }
  reasons.add(
    PlanReason(
      text: '按「${progressionStrategyLabel(plan.progression.strategy)}」安排本周负荷',
    ),
  );
  return reasons;
}

CycleReviewSnapshot _review({
  required GeneratedPlan plan,
  required List<WorkoutLogEntry> logs,
  required DateTime now,
  required int cycleWeeks,
  required int currentWeek,
}) {
  final stage = plan.stageGoal;
  final cycleStart = DateTime(
    plan.generatedAt.year,
    plan.generatedAt.month,
    plan.generatedAt.day,
  );
  final cycleEnd = cycleStart.add(Duration(days: cycleWeeks * 7));
  final cycleLogs = logs
      .where((entry) => !entry.at.isBefore(cycleStart) && entry.at.isBefore(cycleEnd))
      .toList();
  final plannedSessions = stage?.plannedSessions ??
      plan.sessions.where((session) => !session.isRest).length * cycleWeeks;
  final completed = cycleLogs.length;
  final completionKnown = plannedSessions > 0;
  final completionPct = !completionKnown
      ? 0
      : ((completed / plannedSessions) * 100).round().clamp(0, 100);
  final activeWeeks = cycleLogs
      .map((entry) => planWeekNumber(plan.generatedAt, entry.at))
      .toSet()
      .length;
  final pain = plan.profile.injuries.isNotEmpty;
  final assessment = stage == null
      ? null
      : assessStage(
          stage,
          StageEvidence(
            completedSessions: completed,
            activeWeeks: activeWeeks,
            comparableMeasurements: 0,
            unresolvedSafetyIssue: pain,
          ),
        );
  final insufficient = assessment == null || !assessment.dataQualityMet;
  final title = assessment == null
      ? '继续观察'
      : (assessment.achieved
            ? '继续推进'
            : (assessment.safetyMet ? '继续观察' : '先处理安全问题'));
  final body = assessment == null
      ? '本周期还没有足够的可比较训练证据，先按当前计划完成训练。'
      : (assessment.achieved
            ? '执行已达到门槛，下一阶段按既定进阶提高负荷。'
            : (insufficient
                  ? '数据还不够，继续观察，先按当前计划训练。'
                  : assessment.reasons.first));
  final surplus = plan.macros.surplusKcal;
  final energyValue = surplus == 0
      ? '维持热量'
      : (surplus > 0 ? '+$surplus kcal' : '$surplus kcal');

  return CycleReviewSnapshot(
    weekLabel: 'CYCLE ${currentWeek.toString().padLeft(2, '0')} · $cycleWeeks 周',
    completionPct: completionPct,
    completionKnown: completionKnown,
    intensityLabel: '继续观察',
    recoveryLabel: '继续观察',
    painLabel: pain ? '有伤病记录' : '未报告',
    painCaution: pain,
    weightTrendLabel: '继续观察',
    weightTrendKnown: false,
    conclusionTitle: title,
    conclusionBody: body,
    cautionBody: pain ? '存在伤病记录，避免突然增加相关动作容量。' : null,
    changes: [
      NextStageChange(
        label: '上肢主组',
        value: '+${_trimKg(plan.progression.incrementUpperKg)} kg',
      ),
      NextStageChange(
        label: '下肢主组',
        value: '+${_trimKg(plan.progression.incrementLowerKg)} kg',
      ),
      NextStageChange(label: '每日能量建议', value: energyValue),
    ],
    reviewDue: checkInDue(plan, now: now),
    adoptEnabled: checkInDue(plan, now: now) || (assessment?.achieved ?? false),
  );
}

String _trimKg(double kg) {
  if (kg == kg.roundToDouble()) return kg.toStringAsFixed(0);
  return kg.toStringAsFixed(1);
}
