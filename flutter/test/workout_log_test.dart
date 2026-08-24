import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rest_pod_hud/models/workout_log.dart';
import 'package:rest_pod_hud/state/workout_log_controller.dart';
import 'package:rest_pod_hud/state/workout_session_controller.dart';

WorkoutLogEntry _entry({
  required int daysAgo,
  int durationMs = 40 * 60 * 1000,
  int kcal = 200,
  String title = '全身',
}) {
  final at = DateTime(2026, 8, 21).subtract(Duration(days: daysAgo));
  return WorkoutLogEntry(
    id: '$daysAgo',
    title: title,
    timestampMs: at.millisecondsSinceEpoch,
    durationMs: durationMs,
    completedSets: 8,
    totalSets: 8,
    estimatedKcal: kcal,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('streak counts consecutive days back from today', () async {
    final log = WorkoutLogController();
    await log.load();
    await log.record(_entry(daysAgo: 0));
    await log.record(_entry(daysAgo: 1));
    await log.record(_entry(daysAgo: 3));
    expect(log.streakDays(now: DateTime(2026, 8, 21)), 2);
  });

  test('week progress uses planned days, not a decorative fill', () async {
    final log = WorkoutLogController();
    await log.load();
    await log.record(_entry(daysAgo: 0));
    await log.record(_entry(daysAgo: 1));
    expect(log.weekProgress(plannedDays: 4, now: DateTime(2026, 8, 21)), 0.5);
    expect(log.sessionCount, 2);
    expect(formatWorkoutDuration(log.totalDurationMs), '1.3时');
  });

  test('finishing the last set writes a log entry; abort does not', () async {
    final log = WorkoutLogController();
    await log.load();
    final session = WorkoutSessionController()
      ..attachLog(log)
      ..startSession()
      ..startSet();

    // Four fallback sets (深蹲 x2, 俯卧撑 x2).
    for (var i = 0; i < 3; i++) {
      session.completeSet();
      session.startNextSetNow();
    }
    session.completeSet();

    expect(session.justFinished, isTrue);
    expect(log.sessionCount, 1);
    expect(log.recent.first.title, isNotEmpty);
    session.dispose();

    final abandoned = WorkoutSessionController()
      ..attachLog(log)
      ..startSession()
      ..startSet()
      ..abortWorkout();
    expect(abandoned.justFinished, isFalse);
    expect(log.sessionCount, 1);
    abandoned.dispose();
  });
}
