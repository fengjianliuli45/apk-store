import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest_pod_hud/data/workout_database.dart';
import 'package:rest_pod_hud/state/workout_session_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('SQLite schema saves and restores an interrupted workout', () async {
    SharedPreferences.setMockInitialValues({});
    final database = WorkoutDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    await database.saveSession(
      id: 'session-1',
      title: '力量训练',
      status: 'paused',
      effectiveDurationMs: 42000,
      setElapsedMs: 9000,
      restRemainingMs: 17000,
      completedSets: 2,
      totalSets: 4,
      currentSet: 3,
      currentRep: 6,
      targetReps: 12,
      phase: 'active',
      isPaused: true,
      planJson:
          '[{"exerciseId":"bodyweight_squat","name":"徒手深蹲",'
          '"targetReps":12,"restMs":30000}]',
      eventType: 'session_paused',
    );
    await database.saveExercise(
      sessionId: 'session-1',
      exerciseId: 'bodyweight_squat',
      label: '徒手深蹲',
      sequence: 1,
      status: 'paused',
      completedSets: 2,
      totalSets: 4,
    );
    await database.saveSet(
      sessionId: 'session-1',
      exerciseId: 'bodyweight_squat',
      setNumber: 2,
      targetReps: 12,
      actualReps: 12,
      effectiveDurationMs: 18000,
      status: 'completed',
    );

    final draft = await database.loadResumableSession();
    expect(draft, isNotNull);
    expect(draft!.id, 'session-1');
    expect(draft.currentSet, 3);
    expect(draft.currentRep, 6);
    expect(draft.setElapsedMs, 9000);
    expect(draft.planJson, contains('bodyweight_squat'));
    expect(draft.restRemainingMs, 17000);
    expect(draft.isPaused, isTrue);
    expect(await WorkoutDatabase.hasResumableMarker(), isTrue);

    final schemaRows = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name IN ('workout_sessions', 'exercise_performances', "
          "'set_performances', 'workout_events')",
        )
        .get();
    expect(schemaRows, hasLength(4));

    await database.saveSession(
      id: 'session-1',
      title: '力量训练',
      status: 'stopped',
      effectiveDurationMs: 43000,
      setElapsedMs: 10000,
      restRemainingMs: 17000,
      completedSets: 2,
      totalSets: 4,
      currentSet: 3,
      currentRep: 6,
      targetReps: 12,
      phase: 'active',
      isPaused: true,
      planJson:
          '[{"exerciseId":"bodyweight_squat","name":"徒手深蹲",'
          '"targetReps":12,"restMs":30000}]',
      eventType: 'session_stopped',
      stopReason: 'user_requested',
    );

    expect(await database.loadResumableSession(), isNull);
    expect(await WorkoutDatabase.hasResumableMarker(), isFalse);
  });

  test('persisted queue restores even when today has no workout', () async {
    SharedPreferences.setMockInitialValues({});
    final database = WorkoutDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    await database.saveSession(
      id: 'rest-day-resume',
      title: '力量训练',
      status: 'paused',
      effectiveDurationMs: 15000,
      setElapsedMs: 7000,
      restRemainingMs: 0,
      completedSets: 0,
      totalSets: 1,
      currentSet: 1,
      currentRep: 4,
      targetReps: 12,
      phase: 'active',
      isPaused: true,
      planJson:
          '[{"exerciseId":"bodyweight_squat","name":"徒手深蹲",'
          '"targetReps":12,"restMs":30000}]',
      eventType: 'session_paused',
    );

    final controller = WorkoutSessionController()..plans = const [];
    addTearDown(controller.dispose);
    controller.attachStore(database);

    expect(await controller.restoreResumableSession(), isTrue);
    expect(controller.isRestDay, isFalse);
    expect(controller.exerciseName, '徒手深蹲');
    expect(controller.completedReps, 4);
    expect(controller.setElapsedMs, 7000);
    expect(controller.isPaused, isTrue);
  });
}
