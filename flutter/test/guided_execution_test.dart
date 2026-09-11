import 'package:flutter_test/flutter_test.dart';
import 'package:rest_pod_hud/state/workout_session_controller.dart';
import 'package:rest_pod_hud/state/workout_log_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('skip advances stages without awarding a completed set', () async {
    final log = WorkoutLogController();
    await log.load();
    final session = WorkoutSessionController()
      ..attachLog(log)
      ..awaitCoachPreparation = true
      ..plans = const [
        SetPlan('push_up', '俯卧撑', 8, plannedSets: 3),
        SetPlan('push_up', '俯卧撑', 8, exerciseSetIndex: 2, plannedSets: 3),
        SetPlan('push_up', '俯卧撑', 8, exerciseSetIndex: 3, plannedSets: 3),
      ]
      ..startSession()
      ..startSet();
    addTearDown(session.dispose);
    session.togglePause();
    session.skipCurrentSet();
    expect(session.currentSet, 2);
    expect(session.completedSets, 0);
    expect(session.phase, WorkoutPhase.ready);
    session.skipCurrentSet(); // A duplicate cannot skip the new ready set.
    expect(session.currentSet, 2);
    session.startSet();
    session.completeSet(const SetCompletionEvidence(actualReps: 8));
    session.skipRest();
    expect(session.currentSet, 3);
    expect(session.phase, WorkoutPhase.ready);
    session.startSet();
    session.skipCurrentSet();
    expect(session.justFinished, true);
    expect(log.recent.single.completedSets, 1);
    expect(log.recent.single.totalSets, 3);
    expect(log.recent.single.aborted, true);
    expect(log.recent.single.exercises.single.sets.length, 1);
  });
  test(
    'guided repetitions complete every planned set without an evidence form',
    () async {
      final log = WorkoutLogController();
      await log.load();
      final session =
          WorkoutSessionController(
              resumeCountdownStep: const Duration(milliseconds: 1),
            )
            ..attachLog(log)
            ..guidedPlayback = true
            ..awaitCoachPreparation = true
            ..plans = const [
              SetPlan(
                'bodyweight_squat',
                '深蹲',
                2,
                tempo: '0-0-1-0',
                exerciseSetIndex: 1,
                plannedSets: 2,
              ),
              SetPlan(
                'bodyweight_squat',
                '深蹲',
                2,
                tempo: '0-0-1-0',
                exerciseSetIndex: 2,
                plannedSets: 2,
              ),
            ]
            ..startSession()
            ..startSet();
      addTearDown(session.dispose);
      expect(session.workRemainingMs, 2000);
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      expect(session.completedReps, 1);
      expect(session.workRemainingMs, lessThan(1000));
      session.togglePause();
      final remaining = session.workRemainingMs;
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(session.workRemainingMs, remaining);
      session.togglePause();
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      expect(session.phase, WorkoutPhase.rest);
      expect(session.currentSet, 1);
      expect(session.completedSets, 1);
      session.startNextSetNow();
      expect(session.currentSet, 2);
      expect(session.phase, WorkoutPhase.ready);
      expect(session.setElapsedMs, 0);
      session.startSet();
      await Future<void>.delayed(const Duration(milliseconds: 2150));
      expect(session.justFinished, true);
      final sets = log.recent.single.exercises.single.sets;
      expect(sets.map((s) => s.reps), [2, 2]);
      expect(sets.map((s) => s.completionSource), ['guided', 'guided']);
      expect(log.recent.single.completedSets, 2);
    },
  );
  test(
    'non-numeric tempo has a separate playback cadence and holds use seconds',
    () {
      const movement = SetPlan('lunges', '箭步蹲', 8, tempo: '受控');
      expect(movement.estimatedWorkMs, null);
      expect(movement.guidedWorkMs, 48000);
      const hold = SetPlan('plank', '平板支撑', 45, repsPrescription: '30-45秒');
      expect(hold.isHold, true);
      expect(hold.guidedWorkMs, 45000);
    },
  );

  test('engine timing fields override legacy execution fallbacks', () {
    const controlled = SetPlan(
      'lunges',
      '箭步蹲',
      5,
      tempo: '受控',
      prescribedRepDurationSeconds: 4,
    );
    expect(controlled.guidedCycleMs, 4000);
    expect(controlled.guidedWorkMs, 20000);

    const hold = SetPlan(
      'plank',
      '平板支撑',
      99,
      repsPrescription: '旧计划无秒数',
      prescribedHoldSeconds: 35,
    );
    expect(hold.isHold, true);
    expect(hold.holdSeconds, 35);
    expect(hold.guidedWorkMs, 35000);
  });
}
