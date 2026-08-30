import 'package:flutter_test/flutter_test.dart';
import 'package:rest_pod_hud/planner/cohort_compare.dart';

void main() {
  const stats = {'p25': 6.0, 'p50': 12.0, 'p75': 18.0};

  test('bands match Python', () {
    expect(cohortCompare(20, stats)['band'], 'ahead');
    expect(cohortCompare(14, stats)['band'], 'above');
    expect(cohortCompare(8, stats)['band'], 'normal');
    expect(cohortCompare(3, stats)['band'], 'behind');
  });

  test('vs_median_pct', () {
    expect(cohortCompare(9, stats)['vs_median_pct'], -25.0);
    expect(cohortCompare(12, stats)['vs_median_pct'], 0.0);
  });

  test('query params from plan', () {
    final plan = {
      'profile': {
        'gender': 'M', 'age': 27, 'bmi': 24.6, 'level': 'beginner',
        'goal': 'hypertrophy', 'equipment': ['dumbbell'],
      }
    };
    final q = cohortQueryParams(plan, 8);
    expect(q['sex'], 'M');
    expect(q['age'], 27);
    expect(q['weeks_elapsed'], 8.0);
    expect(q['equipment'], ['dumbbell']);
  });

  test('hint text', () {
    final h = cohortHint('卧推进步', 8, stats);
    expect(h.contains('+8%'), isTrue);
    expect(h.contains('同类中位数 +12%'), isTrue);
  });
}
