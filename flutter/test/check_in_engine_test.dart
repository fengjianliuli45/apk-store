import 'package:flutter_test/flutter_test.dart';
import 'package:rest_pod_hud/models/workout_log.dart';
import 'package:rest_pod_hud/planner/exercise_library.dart';
import 'package:rest_pod_hud/planner/planner_gateway.dart';
import 'package:rest_pod_hud/planner/progress_tracker.dart';

/// 任务 A：闭环（Dart 端口，对齐 fitness-planner）。

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PlannerGateway gateway;
  late ExerciseLibrary lib;
  late Map<String, dynamic> plan;
  setUpAll(() async {
    gateway = await PlannerGateway.instance();
    lib = await ExerciseLibrary.load();
    plan = gateway.generate({
      'gender': 'M', 'age': 28, 'height_cm': 178.0, 'weight_kg': 80.0,
      'level': 'intermediate', 'goal': 'hypertrophy', 'minutes_per_session': 75,
      'equipment': const ['barbell', 'dumbbell', 'cable', 'machine'],
      'strength_baseline': const {
        'squat': {'weight_kg': 100, 'reps': 5}, 'bench': {'weight_kg': 70, 'reps': 8},
        'hinge': {'weight_kg': 120, 'reps': 5}, 'row': {'weight_kg': 60, 'reps': 10},
      },
    }).toJson();
  });

  List<Map<String, dynamic>> log(int weeks, double progress,
      {double adh = 1.0, bool painLast = false}) {
    final sched = [
      for (final s in (plan['training'] as Map)['schedule'])
        if (s['type'] != 'rest') s,
    ];
    final out = <Map<String, dynamic>>[];
    final start = DateTime.utc(2026, 9, 1);
    for (var w = 0; w < weeks; w++) {
      for (var di = 0; di < sched.length; di++) {
        final s = sched[di];
        if (adh < 1.0 && ((w * sched.length + di) % 3 == 0)) continue;
        final dt = start.add(Duration(days: w * 7 + di * 2));
        final exs = <WorkoutExerciseLog>[
          for (final e in s['exercises'])
            WorkoutExerciseLog(
              exerciseId: e['exercise_id'] as String,
              plannedSets: e['sets'] as int,
              sets: [
                for (var i = 0; i < (e['sets'] as int); i++)
                  WorkoutSetLog(
                    setNumber: i + 1,
                    reps: 12,
                    durationMs: 30000,
                    weightKg: e['load_kg'] != null
                        ? double.parse(((e['load_kg'] as num) *
                                (1 + progress * w / weeks))
                            .toStringAsFixed(1))
                        : null,
                    rir: 1,
                  ),
              ],
            ),
        ];
        out.add(WorkoutLogEntry(
          id: 'week-$w-session-$di',
          title: s['type'] as String,
          timestampMs: dt.millisecondsSinceEpoch,
          durationMs: 60 * 60 * 1000,
          completedSets: s['total_sets'] as int,
          totalSets: s['total_sets'] as int,
          estimatedKcal: 300,
          planDay: s['day'] as String,
          sessionType: s['type'] as String,
          painFlag: painLast && w == weeks - 1 && di >= sched.length - 1,
          recoveryScore: 4,
          exercises: exs,
        ).toEngineJson());
      }
    }
    return out;
  }

  test('epley + RIR', () {
    expect(epleyE1rm(100, 5, 0), 116.7);
    expect(epleyE1rm(100, 3, 2), epleyE1rm(100, 5, 0));
    expect(epleyE1rm(100, 5, 5), isNull);
  });

  test('evidence aggregation from a good 4-week log', () {
    final ev = aggregateEvidence(plan, log(4, 0.06), const [], lib);
    expect(ev.completedSessions, greaterThanOrEqualTo(12));
    expect(ev.activeWeeks, greaterThanOrEqualTo(3));
    expect(ev.comparableMeasurements, greaterThanOrEqualTo(2));
    expect(ev.performanceImprovementPct, greaterThanOrEqualTo(2.5));
  });

  test('advance when progressed', () {
    final out = gateway.runCheckIn(plan, log(4, 0.06));
    final r = out['review'] as Map;
    expect(r['verdict'], 'advance');
    expect(r['volume_change'], 'up_one_step');
    expect((r['load_changes'] as List), isNotEmpty);
    expect(r['unlock_reward'], 'pet_hatchling');
    expect(out['next_plan'], isNotNull);
    expect(((out['next_plan'] as Map)['profile'] as Map)['volume_cycle_offset'], 1);
  });

  test('extend + makeup when sessions missed', () {
    final r = gateway.runCheckIn(plan, log(2, 0.03))['review'] as Map;
    expect(r['verdict'], 'extend');
    expect(r['makeup_sessions'], greaterThan(0));
  });

  test('deload when stalled', () {
    final r = gateway.runCheckIn(plan, log(4, 0.0))['review'] as Map;
    expect(r['verdict'], 'deload_then_retry');
    expect(r['volume_change'], 'down_10pct');
  });

  test('address safety on recent pain', () {
    final out = gateway.runCheckIn(plan, log(4, 0.06, painLast: true));
    expect((out['review'] as Map)['verdict'], 'address_safety');
    expect(out['next_plan'], isNull);
  });
}
