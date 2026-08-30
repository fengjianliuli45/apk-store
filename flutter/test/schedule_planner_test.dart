import 'package:flutter_test/flutter_test.dart';
import 'package:rest_pod_hud/planner/models.dart';
import 'package:rest_pod_hud/planner/profile_validator.dart';
import 'package:rest_pod_hud/planner/schedule_planner.dart';
import 'package:rest_pod_hud/planner/session_builder.dart' show sessionMuscles;
import 'package:rest_pod_hud/planner/split_selector.dart';

/// 交付 2b：按肌群恢复窗口排日历（Dart 端口）。

UserProfile _p(int days, {String level = 'intermediate'}) => validateProfile({
      'gender': 'M', 'age': 28, 'height_cm': 175.0, 'weight_kg': 75.0,
      'level': level, 'goal': 'hypertrophy', 'days_per_week': days,
      'minutes_per_session': 60,
      'equipment': const ['barbell', 'dumbbell', 'cable', 'machine'],
    });

Map<String, List<int>> _muscleDays(List<ScheduleDay> s) {
  final md = <String, List<int>>{};
  for (var i = 0; i < s.length; i++) {
    if (s[i].type == 'rest') continue;
    for (final m in sessionMuscles[s[i].type] ?? const []) {
      md.putIfAbsent(m, () => []).add(i);
    }
  }
  return md;
}

void _assertRecoveryOk(List<ScheduleDay> s) {
  _muscleDays(s).forEach((m, dd) {
    if (dd.length < 2) return;
    dd.sort();
    final gaps = <int>[
      for (var i = 1; i < dd.length; i++) dd[i] - dd[i - 1],
      dd.first + 7 - dd.last,
    ];
    final minGap = gaps.reduce((a, b) => a < b ? a : b);
    expect(minGap, greaterThanOrEqualTo(recoveryMinGap[m] ?? 2),
        reason: '$m gaps $gaps');
  });
}

void main() {
  for (final days in const [3, 4, 5, 6]) {
    test('$days-day schedule respects muscle recovery windows', () {
      final p = _p(days, level: days <= 3 ? 'beginner' : 'advanced');
      final s = reschedule(p, selectSplit(p)).weeklySchedule;
      expect(s.length, 7);
      expect(s.where((d) => d.type != 'rest').length, days);
      _assertRecoveryOk(s);
    });
  }

  test('big muscles are never on consecutive days (3-day full body)', () {
    final s = reschedule(_p(3, level: 'beginner'), selectSplit(_p(3, level: 'beginner')))
        .weeklySchedule;
    final train = [
      for (var i = 0; i < s.length; i++)
        if (s[i].type != 'rest') i,
    ];
    for (var i = 1; i < train.length; i++) {
      expect(train[i] - train[i - 1], greaterThanOrEqualTo(2));
    }
  });
}
