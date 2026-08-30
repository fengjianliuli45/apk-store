import 'package:flutter_test/flutter_test.dart';
import 'package:rest_pod_hud/planner/exercise_library.dart';
import 'package:rest_pod_hud/planner/frequency_planner.dart';
import 'package:rest_pod_hud/planner/models.dart';
import 'package:rest_pod_hud/planner/planner_gateway.dart';
import 'package:rest_pod_hud/planner/profile_validator.dart';

/// 任务 ①.5：引擎决定训练天数（Dart 端口，对齐 fitness-planner）。

UserProfile _p({
  String level = 'beginner',
  String goal = 'hypertrophy',
  int minutes = 60,
  int? days,
}) =>
    validateProfile({
      'gender': 'M', 'age': 28, 'height_cm': 175.0, 'weight_kg': 72.0,
      'level': level, 'goal': goal, 'minutes_per_session': minutes,
      'equipment': const ['dumbbell', 'bodyweight'],
      'days_per_week': ?days,
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ExerciseLibrary lib;
  setUpAll(() async {
    lib = await ExerciseLibrary.load();
  });

  test('days_per_week is optional in validation', () {
    expect(_p().daysPerWeek, isNull);
    expect(_p(days: 4).daysPerWeek, 4);
  });

  test('explicit days are respected', () {
    final fp = planFrequency(_p(days: 4), lib);
    expect(fp.daysPerWeek, 4);
    expect(fp.minutesRaised, isFalse);
  });

  test('engine picks days within the level range', () {
    for (final level in const ['beginner', 'intermediate', 'advanced']) {
      final range = levelDayRange[level]!;
      final fp = planFrequency(_p(level: level, minutes: 60), lib);
      expect(fp.daysPerWeek, greaterThanOrEqualTo(range[0]));
      expect(fp.daysPerWeek, lessThanOrEqualTo(range[1]));
    }
  });

  test('below the minimum session length raises minutes', () {
    final fp = planFrequency(_p(minutes: 30), lib);
    expect(fp.minutesRaised, isTrue);
    expect(fp.minutesPerSession, greaterThanOrEqualTo(fp.minSessionMinutes));
    expect(fp.note, contains('至少'));
  });

  test('enough time hits the coverage target', () {
    final fp = planFrequency(_p(minutes: 80), lib);
    expect(fp.minutesRaised, isFalse);
    expect(fp.coveragePct, greaterThanOrEqualTo(coverageTarget));
  });

  test('more time means fewer or equal days', () {
    final short = planFrequency(_p(level: 'intermediate', minutes: 55), lib);
    final long = planFrequency(_p(level: 'intermediate', minutes: 90), lib);
    expect(long.daysPerWeek, lessThanOrEqualTo(short.daysPerWeek));
  });

  test('fat_loss minimum is not above hypertrophy minimum', () {
    final fl = planFrequency(_p(goal: 'fat_loss', minutes: 30), lib);
    final hy = planFrequency(_p(goal: 'hypertrophy', minutes: 30), lib);
    expect(fl.minSessionMinutes, lessThanOrEqualTo(hy.minSessionMinutes));
  });

  test('minSessionMinutesFor matches the planner and gates the selector', () {
    const equip = ['dumbbell', 'bodyweight'];
    final m = minSessionMinutesFor('beginner', 'hypertrophy', equip, lib);
    final atMin = planFrequency(_p(minutes: m), lib);
    expect(atMin.minSessionMinutes, m);
    expect(atMin.minutesRaised, isFalse);
    final below = planFrequency(_p(minutes: m - 5), lib);
    expect(below.minutesRaised, isTrue);
  });

  test('gateway exposes minSessionMinutes for onboarding', () async {
    final gateway = await PlannerGateway.instance();
    final m = gateway.minSessionMinutes(
      level: 'beginner', goal: 'hypertrophy', equipment: const ['dumbbell'],
    );
    expect(m, greaterThanOrEqualTo(30));
    expect(m % 5, 0);
  });

  test('gateway resolves frequency into the plan', () async {
    final gateway = await PlannerGateway.instance();
    final plan = gateway.generate({
      'gender': 'M', 'age': 28, 'height_cm': 175.0, 'weight_kg': 72.0,
      'level': 'beginner', 'goal': 'hypertrophy', 'minutes_per_session': 60,
      'equipment': const ['dumbbell', 'bodyweight'],
    });
    expect(plan.profile.daysPerWeek, isNotNull);
    expect(plan.frequencyPlan['days_per_week'], plan.profile.daysPerWeek);
    expect((plan.toJson()['meta'] as Map)['version'], '1.3');
  });
}
