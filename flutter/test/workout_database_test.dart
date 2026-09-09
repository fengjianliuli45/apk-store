import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest_pod_hud/data/workout_database.dart';
import 'package:rest_pod_hud/state/workout_session_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('schema v3 migrates to structured evidence columns', () async {
    final database = WorkoutDatabase.forTesting(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute('''
          CREATE TABLE workout_sessions (
            id TEXT PRIMARY KEY NOT NULL,
            title TEXT NOT NULL,
            status TEXT NOT NULL,
            started_at_utc TEXT NOT NULL,
            ended_at_utc TEXT,
            effective_duration_ms INTEGER NOT NULL DEFAULT 0,
            set_elapsed_ms INTEGER NOT NULL DEFAULT 0,
            rest_remaining_ms INTEGER NOT NULL DEFAULT 0,
            completed_sets INTEGER NOT NULL DEFAULT 0,
            total_sets INTEGER NOT NULL,
            current_set INTEGER NOT NULL DEFAULT 1,
            current_rep INTEGER NOT NULL DEFAULT 0,
            target_reps INTEGER NOT NULL DEFAULT 0,
            phase TEXT NOT NULL,
            is_paused INTEGER NOT NULL DEFAULT 0,
            plan_json TEXT NOT NULL DEFAULT '[]',
            stop_reason TEXT,
            updated_at_utc TEXT NOT NULL
          )
        ''');
          raw.execute('''
          CREATE TABLE set_performances (
            id TEXT PRIMARY KEY NOT NULL,
            session_id TEXT NOT NULL,
            exercise_id TEXT NOT NULL,
            set_number INTEGER NOT NULL,
            target_reps INTEGER NOT NULL,
            actual_reps INTEGER NOT NULL,
            effective_duration_ms INTEGER NOT NULL,
            status TEXT NOT NULL,
            completed_at_utc TEXT,
            UNIQUE(session_id, set_number)
          )
        ''');
          raw.execute('PRAGMA user_version = 3');
        },
      ),
    );
    addTearDown(database.close);

    final sessionColumns = await database
        .customSelect('PRAGMA table_info(workout_sessions)')
        .get();
    final setColumns = await database
        .customSelect('PRAGMA table_info(set_performances)')
        .get();
    expect(
      sessionColumns.map((row) => row.read<String>('name')),
      containsAll(['session_type', 'plan_day', 'pain_flag', 'recovery_score']),
    );
    expect(
      setColumns.map((row) => row.read<String>('name')),
      containsAll([
        'actual_weight_kg',
        'actual_rir',
        'actual_rpe',
        'pain_flag',
        'pain_area',
        'exercise_set_index',
      ]),
    );
  });

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
      sessionType: 'upper',
      planDay: 'mon',
      painFlag: true,
      recoveryScore: 3.5,
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
      plannedRepsText: '8-12',
      plannedLoadText: '20 kg',
      plannedWeightKg: 20,
      actualWeightKg: 22.5,
      targetRpe: 8,
      actualRpe: 8.5,
      actualRir: 1,
      tempo: '3-1-1',
      painFlag: true,
      painArea: '右肩',
      formCues: const ['肩胛骨收紧'],
      exerciseSetIndex: 2,
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
    expect(draft.sessionType, 'upper');
    expect(draft.planDay, 'mon');
    expect(draft.painFlag, isTrue);
    expect(draft.recoveryScore, 3.5);
    expect(await WorkoutDatabase.hasResumableMarker(), isTrue);

    final completedSets = await database.loadCompletedSets('session-1');
    expect(completedSets, hasLength(1));
    expect(completedSets.single.exerciseSetIndex, 2);
    expect(completedSets.single.actualWeightKg, 22.5);
    expect(completedSets.single.actualRir, 1);
    expect(completedSets.single.actualRpe, 8.5);
    expect(completedSets.single.painFlag, isTrue);
    expect(completedSets.single.painArea, '右肩');

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

  test('full engine prescription survives a session restore', () async {
    SharedPreferences.setMockInitialValues({});
    final database = WorkoutDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final source = WorkoutSessionController()
      ..attachStore(database)
      ..sessionType = 'upper'
      ..planDay = 'thu'
      ..plans = const [
        SetPlan(
          'barbell_bench_press',
          '杠铃卧推',
          10,
          restMs: 90000,
          repsPrescription: '8-10',
          load: '70% 1RM',
          loadKg: 62.5,
          rpe: 8,
          tempo: '3-1-1',
          notes: '保留两次余力',
          formCues: ['肩胛骨收紧'],
          targetMuscle: 'chest',
          exerciseSequence: 1,
          exerciseSetIndex: 1,
          plannedSets: 1,
        ),
      ]
      ..startSession();
    addTearDown(source.dispose);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final restored = WorkoutSessionController()..attachStore(database);
    addTearDown(restored.dispose);
    expect(await restored.restoreResumableSession(), isTrue);
    final set = restored.plans.single;
    expect(set.repsPrescription, '8-10');
    expect(set.load, '70% 1RM');
    expect(set.loadKg, 62.5);
    expect(set.rpe, 8);
    expect(set.tempo, '3-1-1');
    expect(set.formCues, ['肩胛骨收紧']);
    expect(restored.sessionType, 'upper');
    expect(restored.planDay, 'thu');
  });
}
