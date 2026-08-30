import 'package:flutter_test/flutter_test.dart';
import 'package:rest_pod_hud/planner/planner_gateway.dart';

/// 任务 A/④：中周期（Dart 端口，对齐 fitness-planner）。

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PlannerGateway gateway;
  setUpAll(() async {
    gateway = await PlannerGateway.instance();
  });

  Map<String, dynamic> meso({
    String level = 'intermediate',
    String goal = 'hypertrophy',
    int minutes = 75,
  }) =>
      (gateway.generate({
        'gender': 'M', 'age': 28, 'height_cm': 178.0, 'weight_kg': 80.0,
        'level': level, 'goal': goal, 'minutes_per_session': minutes,
        'equipment': const ['barbell', 'dumbbell', 'cable', 'machine'],
      }).toJson()['training'] as Map)['mesocycle'] as Map<String, dynamic>;

  test('structure: build weeks + one deload', () {
    final m = meso();
    expect(m['length_weeks'], 5);
    expect(m['current_week'], 1);
    expect((m['weeks'] as List).length, 5);
    expect((m['weeks'] as List).last['phase'], 'deload');
    expect((m['weeks'] as List).last['is_deload'], isTrue);
  });

  test('RIR decreases across build weeks, deload relaxes', () {
    final weeks = meso()['weeks'] as List;
    final build = [
      for (final w in weeks)
        if (w['is_deload'] == false) w['rir_target'] as int,
    ];
    expect(build.first, 3);
    expect(build.last, 0);
    for (var i = 1; i < build.length; i++) {
      expect(build[i], lessThanOrEqualTo(build[i - 1]));
    }
    expect(weeks.last['rir_target'], greaterThanOrEqualTo(2));
  });

  test('volume ramps up then deload drops', () {
    final weeks = meso()['weeks'] as List;
    final build = [
      for (final w in weeks)
        if (w['is_deload'] == false) w['week_total_sets'] as int,
    ];
    for (var i = 1; i < build.length; i++) {
      expect(build[i], greaterThanOrEqualTo(build[i - 1]));
    }
    expect(build.first, lessThan(build.last));
    expect(weeks.last['week_total_sets'], lessThan(build.last));
  });
}
