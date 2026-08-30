import 'package:flutter_test/flutter_test.dart';
import 'package:rest_pod_hud/planner/exercise_library.dart';
import 'package:rest_pod_hud/planner/load_planner.dart';
import 'package:rest_pod_hud/planner/planner_gateway.dart';

/// 任务 ②：起始重量 / 1RM（Dart 端口，对齐 fitness-planner）。

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ExerciseLibrary lib;
  setUpAll(() async {
    lib = await ExerciseLibrary.load();
  });

  test('epley', () {
    expect(estimate1rm(100, 1), 103.3);
    expect(estimate1rm(100, 5), 116.7);
    expect(estimate1rm(50, 20), estimate1rm(50, 12));
  });

  test('buildOneRmMap', () {
    final m = buildOneRmMap({
      'squat': {'weight_kg': 100, 'reps': 5},
      'bench': {'one_rm_kg': 90},
      'bogus': {'weight_kg': 10, 'reps': 5},
    });
    expect(m['squat'], 116.7);
    expect(m['bench'], 90.0);
    expect(m.containsKey('bogus'), isFalse);
  });

  test('barbell bench gets a kg number', () {
    final ex = lib.all().firstWhere((e) => e.id == 'barbell_bench_press');
    final (text, kg) = suggestLoad(ex, {'bench': 90.0}, 0.72, '65-80% 1RM');
    expect(kg, greaterThan(0));
    expect(text, contains('kg'));
  });

  test('bodyweight move has no kg', () {
    final ex = lib.all().firstWhere((e) => e.id == 'push_up');
    final (text, kg) = suggestLoad(ex, {'bench': 90.0}, 0.72, '65-80% 1RM');
    expect(kg, 0);
    expect(text, contains('自重'));
  });

  test('no baseline falls back to RPE', () {
    final ex = lib.all().firstWhere((e) => e.id == 'barbell_bench_press');
    final (text, kg) = suggestLoad(ex, const {}, 0.72, '65-80% 1RM');
    expect(kg, 0);
    expect(text, contains('RPE'));
  });

  test('dumbbell labelled per hand', () {
    final ex = lib.all().firstWhere((e) => e.id == 'dumbbell_bench_press');
    final (text, _) = suggestLoad(ex, {'bench': 90.0}, 0.72, '65-80% 1RM');
    expect(text, contains('kg/只'));
  });

  test('gateway: plan carries 1RM estimates + baseline lifts + load_kg', () async {
    final g = await PlannerGateway.instance();
    final plan = g.generate({
      'gender': 'M', 'age': 28, 'height_cm': 178.0, 'weight_kg': 80.0,
      'level': 'intermediate', 'goal': 'hypertrophy', 'minutes_per_session': 75,
      'equipment': const ['barbell', 'dumbbell', 'cable', 'machine'],
      'strength_baseline': const {
        'squat': {'weight_kg': 100, 'reps': 5},
        'bench': {'weight_kg': 70, 'reps': 8},
        'hinge': {'weight_kg': 120, 'reps': 5},
        'row': {'weight_kg': 60, 'reps': 10},
      },
    }).toJson();
    expect((plan['meta'] as Map)['version'], '1.8');
    expect(((plan['profile'] as Map)['one_rm_estimates'] as Map)['squat'], isNotNull);
    expect((plan['stage_goal'] as Map)['baseline_lifts'], isNotEmpty);
    final loads = [
      for (final s in (plan['training'] as Map)['schedule'])
        for (final e in s['exercises']) e['load_kg'],
    ];
    expect(loads.any((v) => v != null), isTrue);
  });

  test('gateway: bodyweight plan has no kg and an RPE note', () async {
    final g = await PlannerGateway.instance();
    final plan = g.generate({
      'gender': 'M', 'age': 25, 'height_cm': 178.0, 'weight_kg': 75.0,
      'level': 'beginner', 'goal': 'hypertrophy', 'minutes_per_session': 55,
      'equipment': const ['bodyweight'],
    }).toJson();
    final loads = [
      for (final s in (plan['training'] as Map)['schedule'])
        for (final e in s['exercises']) e['load_kg'],
    ];
    expect(loads.every((v) => v == null), isTrue);
  });
}
