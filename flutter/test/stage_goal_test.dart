import 'package:flutter_test/flutter_test.dart';
import 'package:rest_pod_hud/planner/models.dart';
import 'package:rest_pod_hud/planner/response_profiler.dart';
import 'package:rest_pod_hud/planner/stage_assessor.dart';
import 'package:rest_pod_hud/planner/stage_goal_planner.dart';

UserProfile _profile({String goal = 'hypertrophy'}) => UserProfile(
  gender: 'M',
  age: 25,
  heightCm: 175,
  weightKg: 70,
  level: 'beginner',
  goal: goal,
  daysPerWeek: 3,
  minutesPerSession: 45,
  equipment: const ['bodyweight'],
);

ProgressionResult _progression() => ProgressionResult(
  strategy: 'linear_weekly',
  incrementUpperKg: 2.5,
  incrementLowerKg: 5,
  progressionFreq: '每周',
  doubleProgression: 'reps_then_load',
  nextCheckWeek: 4,
  triggers: const [],
);

List<SessionResult> _sessions() => [
  for (var i = 0; i < 7; i++)
    SessionResult(
      day: 'd$i',
      type: i < 3 ? 'full_body' : 'rest',
      durationMin: i < 3 ? 45 : 0,
      exercises: const [],
      totalSets: 0,
    ),
];

void main() {
  test('planner creates the four-week adaptation goal', () {
    final goal = planStageGoal(_profile(), _progression(), _sessions());
    expect(goal.stageType, 'adaptation');
    expect(goal.cycleWeeks, 4);
    expect(goal.plannedSessions, 12);
    expect(goal.requiredSessions, 10);
    expect(goal.unlockReward, 'pet_hatchling');
  });

  test('training performance can unlock without body measurements', () {
    final goal = planStageGoal(_profile(), _progression(), _sessions());
    final result = assessStage(
      goal,
      const StageEvidence(
        completedSessions: 10,
        activeWeeks: 4,
        comparableMeasurements: 2,
        sameLoadRepGain: 2,
        bodyTrendTargetMet: false,
      ),
    );
    expect(result.achieved, isTrue);
    expect(result.status, 'achieved');
  });

  test('percentage improvement requires two comparable confirmations', () {
    final goal = planStageGoal(_profile(), _progression(), _sessions());
    final single = assessStage(
      goal,
      const StageEvidence(
        completedSessions: 10,
        activeWeeks: 4,
        comparableMeasurements: 2,
        performanceImprovementPct: 5,
        performanceConfirmations: 1,
      ),
    );
    final confirmed = assessStage(
      goal,
      const StageEvidence(
        completedSessions: 10,
        activeWeeks: 4,
        comparableMeasurements: 2,
        performanceImprovementPct: 2.5,
        performanceConfirmations: 2,
      ),
    );
    expect(single.achieved, isFalse);
    expect(confirmed.achieved, isTrue);
  });

  test('first cycle response remains preliminary', () {
    final result = profileResponse(
      const ResponseObservation(
        completedCycles: 1,
        adherencePct: 90,
        performanceImprovementPct: 8,
        weightTrendPct: -1,
      ),
    );
    expect(result.maturity, 'preliminary');
    expect(result.metabolismResponse, 'unknown');
  });
}
