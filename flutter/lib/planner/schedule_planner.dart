import 'models.dart';
import 'session_builder.dart' show sessionMuscles;
import 'split_selector.dart' show dayNames;

/// Port of fitness-planner's `schedule_planner.py`.
///
/// split_selector 只定「训练日的类型序列」；本模块按肌群恢复窗口把 N 次训练
/// 摆到周一~周日：枚举所有摆法，挑一个让每个肌群相邻两次训练间隔 ≥ 恢复窗口、
/// 间隔越均匀、周末越轻越好。

const recoveryMinGap = {
  'quads': 2, 'hamstrings': 2, 'back': 2, 'glutes': 2, 'chest': 2,
  'shoulders': 2, 'biceps': 2, 'triceps': 2, 'rear_delt': 2,
  'calves': 1, 'core': 1, 'abs': 1,
};
const _recoveryIdealGap = {
  'quads': 3, 'hamstrings': 3, 'back': 3, 'glutes': 3, 'chest': 3,
  'shoulders': 2, 'biceps': 2, 'triceps': 2, 'rear_delt': 2,
  'calves': 2, 'core': 2, 'abs': 2,
};
const _defaultMin = 2;
const _defaultIdeal = 2;

int _maxConsecutive(List<int> days) {
  final s = [...days]..sort();
  var best = 1, run = 1;
  for (var i = 1; i < s.length; i++) {
    run = s[i] == s[i - 1] + 1 ? run + 1 : 1;
    if (run > best) best = run;
  }
  return best;
}

/// null = 不可行（大肌群间隔 < 最小值）。
double? _scorePlacement(List<int> placement, List<Set<String>> seqMuscles) {
  final muscleDays = <String, List<int>>{};
  for (var idx = 0; idx < placement.length; idx++) {
    for (final m in seqMuscles[idx]) {
      muscleDays.putIfAbsent(m, () => []).add(placement[idx]);
    }
  }

  var score = 0.0;
  for (final entry in muscleDays.entries) {
    final dd = [...entry.value]..sort();
    if (dd.length < 2) continue;
    final gaps = <int>[
      for (var i = 1; i < dd.length; i++) dd[i] - dd[i - 1],
      dd.first + 7 - dd.last,
    ];
    final minGap = gaps.reduce((a, b) => a < b ? a : b);
    if (minGap < (recoveryMinGap[entry.key] ?? _defaultMin)) return null;
    final ideal = _recoveryIdealGap[entry.key] ?? _defaultIdeal;
    for (final g in gaps) {
      score += (g - ideal) * (g - ideal);
    }
  }

  score += 0.5 * placement.where((d) => d >= 5).length;
  final consec = _maxConsecutive(placement);
  if (consec > 3) score += (consec - 3) * 3;
  return score;
}

/// 生成所有「n 个位置放 7 天里的哪几天」的组合（升序）。
Iterable<List<int>> _combinations(int n) sync* {
  final idx = List<int>.generate(n, (i) => i);
  while (true) {
    yield [...idx];
    var i = n - 1;
    while (i >= 0 && idx[i] == 7 - n + i) {
      i--;
    }
    if (i < 0) break;
    idx[i]++;
    for (var j = i + 1; j < n; j++) {
      idx[j] = idx[j - 1] + 1;
    }
  }
}

/// 返回同 splitName、但按恢复窗口重排日历的 SplitResult。
SplitResult reschedule(UserProfile profile, SplitResult split) {
  final sequence = [
    for (final d in split.weeklySchedule)
      if (d.type != 'rest') d.type,
  ];
  final n = sequence.length;
  if (n < 2 || n > 7) return split;

  final seqMuscles = [
    for (final t in sequence) (sessionMuscles[t] ?? const <String>[]).toSet(),
  ];

  double? bestScore;
  List<int>? bestCombo;
  for (final combo in _combinations(n)) {
    final s = _scorePlacement(combo, seqMuscles);
    if (s == null) continue;
    if (bestScore == null || s < bestScore) {
      bestScore = s;
      bestCombo = combo;
    }
  }
  if (bestCombo == null) return split;

  final dayType = List<String>.filled(7, 'rest');
  for (var idx = 0; idx < bestCombo.length; idx++) {
    dayType[bestCombo[idx]] = sequence[idx];
  }
  return SplitResult(
    splitName: split.splitName,
    weeklySchedule: [
      for (var k = 0; k < 7; k++) ScheduleDay(day: dayNames[k], type: dayType[k]),
    ],
    warnings: [...split.warnings],
  );
}
