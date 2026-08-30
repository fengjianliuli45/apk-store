import 'package:flutter_test/flutter_test.dart';
import 'package:rest_pod_hud/planner/planner_gateway.dart';

/// 交付 2：休息日轻日 / 补练（Dart 端口，对齐 fitness-planner）。

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PlannerGateway gateway;
  setUpAll(() async {
    gateway = await PlannerGateway.instance();
  });

  Map<String, dynamic> plan({
    String level = 'intermediate',
    String goal = 'hypertrophy',
    int minutes = 60,
  }) =>
      gateway.generate({
        'gender': 'M', 'age': 28, 'height_cm': 175.0, 'weight_kg': 75.0,
        'level': level, 'goal': goal, 'minutes_per_session': minutes,
        'equipment': const ['barbell', 'dumbbell', 'cable', 'machine'],
      }).toJson()['training'] as Map<String, dynamic>;

  test('every rest day has a recovery-day entry', () {
    final t = plan();
    final rest = {
      for (final s in t['schedule'] as List)
        if (s['type'] == 'rest') s['day'] as String,
    };
    final covered = {for (final r in t['recovery_days'] as List) r['day'] as String};
    expect(covered, rest);
  });

  test('keeps one full rest day', () {
    final kinds = [for (final r in plan()['recovery_days'] as List) r['kind']];
    expect(kinds, contains('rest'));
  });

  test('fat_loss gets cardio', () {
    final kinds = [
      for (final r in plan(goal: 'fat_loss')['recovery_days'] as List) r['kind']
    ];
    expect(kinds, contains('cardio'));
  });

  test('beginner never gets a pump day', () {
    final kinds = [
      for (final r in plan(level: 'beginner', minutes: 50)['recovery_days'] as List)
        r['kind']
    ];
    expect(kinds, isNot(contains('pump')));
  });

  test('intermediate under target gets a pump day', () {
    final t = plan(level: 'intermediate', goal: 'hypertrophy', minutes: 60);
    if ((t['volume_coverage_pct'] as int) < 96) {
      final kinds = [for (final r in t['recovery_days'] as List) r['kind']];
      expect(kinds, contains('pump'));
    }
  });
}
