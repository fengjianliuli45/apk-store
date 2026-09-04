import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorkoutSessionDraft {
  const WorkoutSessionDraft({
    required this.id,
    required this.title,
    required this.phase,
    required this.currentSet,
    required this.currentRep,
    required this.targetReps,
    required this.effectiveDurationMs,
    required this.setElapsedMs,
    required this.restRemainingMs,
    required this.completedSets,
    required this.totalSets,
    required this.isPaused,
    required this.planJson,
    required this.exerciseId,
    required this.exerciseLabel,
  });

  final String id;
  final String title;
  final String phase;
  final int currentSet;
  final int currentRep;
  final int targetReps;
  final int effectiveDurationMs;
  final int setElapsedMs;
  final int restRemainingMs;
  final int completedSets;
  final int totalSets;
  final bool isPaused;
  final String planJson;
  final String exerciseId;
  final String exerciseLabel;
}

/// Drift-backed local event store. Tables are intentionally created with SQL
/// so the frozen first-release schema can evolve without generated source.
class WorkoutDatabase extends GeneratedDatabase {
  static const resumableMarkerKey = 'workout_has_resumable_v1';
  WorkoutDatabase._()
    : super.connect(driftDatabase(name: 'stopwatch_workouts'));

  WorkoutDatabase.forTesting(super.executor);

  static final WorkoutDatabase instance = WorkoutDatabase._();

  static Future<bool> hasResumableMarker() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(resumableMarkerKey) ?? false;
  }

  @override
  int get schemaVersion => 3;

  @override
  Iterable<TableInfo> get allTables => const [];

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (_) => _createSchema(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await customStatement(
          'ALTER TABLE workout_sessions '
          'ADD COLUMN set_elapsed_ms INTEGER NOT NULL DEFAULT 0',
        );
      }
      if (from < 3) {
        await customStatement(
          "ALTER TABLE workout_sessions "
          "ADD COLUMN plan_json TEXT NOT NULL DEFAULT '[]'",
        );
      }
    },
    beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
  );

  Future<void> _createSchema() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS workout_sessions (
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
    await customStatement('''
      CREATE TABLE IF NOT EXISTS exercise_performances (
        id TEXT PRIMARY KEY NOT NULL,
        session_id TEXT NOT NULL REFERENCES workout_sessions(id) ON DELETE CASCADE,
        exercise_id TEXT NOT NULL,
        exercise_label TEXT NOT NULL,
        sequence_number INTEGER NOT NULL,
        status TEXT NOT NULL,
        completed_sets INTEGER NOT NULL DEFAULT 0,
        total_sets INTEGER NOT NULL,
        UNIQUE(session_id, exercise_id)
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS set_performances (
        id TEXT PRIMARY KEY NOT NULL,
        session_id TEXT NOT NULL REFERENCES workout_sessions(id) ON DELETE CASCADE,
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
    await customStatement('''
      CREATE TABLE IF NOT EXISTS workout_events (
        event_id TEXT PRIMARY KEY NOT NULL,
        session_id TEXT NOT NULL REFERENCES workout_sessions(id) ON DELETE CASCADE,
        event_type TEXT NOT NULL,
        occurred_at_utc TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        synced_at_utc TEXT
      )
    ''');
    await customStatement(
      'CREATE INDEX IF NOT EXISTS workout_sessions_status_updated '
      'ON workout_sessions(status, updated_at_utc)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS workout_events_session_time '
      'ON workout_events(session_id, occurred_at_utc)',
    );
  }

  Future<void> saveSession({
    required String id,
    required String title,
    required String status,
    required int effectiveDurationMs,
    required int setElapsedMs,
    required int restRemainingMs,
    required int completedSets,
    required int totalSets,
    required int currentSet,
    required int currentRep,
    required int targetReps,
    required String phase,
    required bool isPaused,
    required String planJson,
    required String eventType,
    String? stopReason,
    Map<String, Object?> payload = const {},
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await transaction(() async {
      await customInsert(
        '''
        INSERT INTO workout_sessions (
          id, title, status, started_at_utc, ended_at_utc,
          effective_duration_ms, set_elapsed_ms, rest_remaining_ms, completed_sets, total_sets, current_set,
          current_rep, target_reps, phase, is_paused, plan_json, stop_reason,
          updated_at_utc
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
          title = excluded.title,
          status = excluded.status,
          ended_at_utc = excluded.ended_at_utc,
          effective_duration_ms = excluded.effective_duration_ms,
          set_elapsed_ms = excluded.set_elapsed_ms,
          rest_remaining_ms = excluded.rest_remaining_ms,
          completed_sets = excluded.completed_sets,
          total_sets = excluded.total_sets,
          current_set = excluded.current_set,
          current_rep = excluded.current_rep,
          target_reps = excluded.target_reps,
          phase = excluded.phase,
          is_paused = excluded.is_paused,
          plan_json = excluded.plan_json,
          stop_reason = excluded.stop_reason,
          updated_at_utc = excluded.updated_at_utc
        ''',
        variables: [
          Variable.withString(id),
          Variable.withString(title),
          Variable.withString(status),
          Variable.withString(now),
          status == 'completed' || status == 'stopped'
              ? Variable.withString(now)
              : const Variable<String>(null),
          Variable.withInt(effectiveDurationMs),
          Variable.withInt(setElapsedMs),
          Variable.withInt(restRemainingMs),
          Variable.withInt(completedSets),
          Variable.withInt(totalSets),
          Variable.withInt(currentSet),
          Variable.withInt(currentRep),
          Variable.withInt(targetReps),
          Variable.withString(phase),
          Variable.withInt(isPaused ? 1 : 0),
          Variable.withString(planJson),
          Variable<String>(stopReason),
          Variable.withString(now),
        ],
      );
      final eventId = '$id-${DateTime.now().microsecondsSinceEpoch}';
      await customInsert(
        'INSERT OR IGNORE INTO workout_events '
        '(event_id, session_id, event_type, occurred_at_utc, payload_json) '
        'VALUES (?, ?, ?, ?, ?)',
        variables: [
          Variable.withString(eventId),
          Variable.withString(id),
          Variable.withString(eventType),
          Variable.withString(now),
          Variable.withString(jsonEncode(payload)),
        ],
      );
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      resumableMarkerKey,
      status == 'active' || status == 'paused',
    );
  }

  Future<void> saveExercise({
    required String sessionId,
    required String exerciseId,
    required String label,
    required int sequence,
    required String status,
    required int completedSets,
    required int totalSets,
  }) {
    return customInsert(
      '''
      INSERT INTO exercise_performances (
        id, session_id, exercise_id, exercise_label, sequence_number,
        status, completed_sets, total_sets
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(session_id, exercise_id) DO UPDATE SET
        status = excluded.status,
        completed_sets = excluded.completed_sets,
        total_sets = excluded.total_sets
      ''',
      variables: [
        Variable.withString('$sessionId-$exerciseId'),
        Variable.withString(sessionId),
        Variable.withString(exerciseId),
        Variable.withString(label),
        Variable.withInt(sequence),
        Variable.withString(status),
        Variable.withInt(completedSets),
        Variable.withInt(totalSets),
      ],
    );
  }

  Future<void> saveSet({
    required String sessionId,
    required String exerciseId,
    required int setNumber,
    required int targetReps,
    required int actualReps,
    required int effectiveDurationMs,
    required String status,
  }) {
    final completedAt = status == 'completed'
        ? DateTime.now().toUtc().toIso8601String()
        : null;
    return customInsert(
      '''
      INSERT INTO set_performances (
        id, session_id, exercise_id, set_number, target_reps, actual_reps,
        effective_duration_ms, status, completed_at_utc
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(session_id, set_number) DO UPDATE SET
        actual_reps = excluded.actual_reps,
        effective_duration_ms = excluded.effective_duration_ms,
        status = excluded.status,
        completed_at_utc = excluded.completed_at_utc
      ''',
      variables: [
        Variable.withString('$sessionId-set-$setNumber'),
        Variable.withString(sessionId),
        Variable.withString(exerciseId),
        Variable.withInt(setNumber),
        Variable.withInt(targetReps),
        Variable.withInt(actualReps),
        Variable.withInt(effectiveDurationMs),
        Variable.withString(status),
        Variable<String>(completedAt),
      ],
    );
  }

  Future<WorkoutSessionDraft?> loadResumableSession() async {
    final rows = await customSelect(
      "SELECT ws.*, "
      "(SELECT ep.exercise_id FROM exercise_performances ep "
      " WHERE ep.session_id = ws.id ORDER BY ep.sequence_number DESC LIMIT 1) "
      "AS exercise_id, "
      "(SELECT ep.exercise_label FROM exercise_performances ep "
      " WHERE ep.session_id = ws.id ORDER BY ep.sequence_number DESC LIMIT 1) "
      "AS exercise_label "
      "FROM workout_sessions ws WHERE status IN ('active', 'paused') "
      'ORDER BY updated_at_utc DESC LIMIT 1',
    ).get();
    if (rows.isEmpty) return null;
    final row = rows.single;
    return WorkoutSessionDraft(
      id: row.read<String>('id'),
      title: row.read<String>('title'),
      phase: row.read<String>('phase'),
      currentSet: row.read<int>('current_set'),
      currentRep: row.read<int>('current_rep'),
      targetReps: row.read<int>('target_reps'),
      effectiveDurationMs: row.read<int>('effective_duration_ms'),
      setElapsedMs: row.read<int>('set_elapsed_ms'),
      restRemainingMs: row.read<int>('rest_remaining_ms'),
      completedSets: row.read<int>('completed_sets'),
      totalSets: row.read<int>('total_sets'),
      isPaused: row.read<int>('is_paused') == 1,
      planJson: row.read<String>('plan_json'),
      exerciseId: row.readNullable<String>('exercise_id') ?? '',
      exerciseLabel: row.readNullable<String>('exercise_label') ?? '',
    );
  }
}
