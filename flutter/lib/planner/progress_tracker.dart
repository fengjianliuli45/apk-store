import 'stage_assessor.dart';
import 'response_profiler.dart';

/// Port of fitness-planner's `progress_tracker.py`.
/// 训练日志 → stage_assessor / response_profiler 的输入。
///
/// LoggedSet     = {reps, weight_kg?, rpe?, rir?}
/// LoggedExercise= {exercise_id, planned_sets, sets: [LoggedSet]}
/// LoggedSession = {date, plan_day, session_type, planned_sets, exercises, aborted, pain_flag}
/// BodyEntry     = {date, weight_kg, waist_cm?}

const _rirTrustworthy = 3;

double? epleyE1rm(double weightKg, int reps, int? rir) {
  final r = rir ?? 0;
  if (r > _rirTrustworthy) return null;
  final eff = (reps + r) > 12 ? 12 : (reps + r);
  return double.parse((weightKg * (1 + eff / 30)).toStringAsFixed(1));
}

int _ordinal(String d) => DateTime.parse(d).difference(DateTime(1, 1, 1)).inDays;

(int, int) _isoWeek(String d) {
  final dt = DateTime.parse(d);
  // ISO week: Thursday of this week determines the year+week.
  final thursday = dt.add(Duration(days: 3 - ((dt.weekday + 6) % 7)));
  final firstThursday = DateTime(thursday.year, 1, 4);
  final week = 1 +
      (thursday.difference(firstThursday).inDays -
              ((firstThursday.weekday + 6) % 7) +
              ((thursday.weekday + 6) % 7)) ~/
          7;
  return (thursday.year, week);
}

int _completedSets(Map s) => [
      for (final ex in (s['exercises'] as List? ?? const []))
        (ex['sets'] as List? ?? const []).length,
    ].fold(0, (a, b) => a + b);

bool _isCompleted(Map s) {
  if (s['aborted'] == true) return false;
  final planned = (s['planned_sets'] as num?)?.toInt() ?? 0;
  if (planned <= 0) return _completedSets(s) > 0;
  return _completedSets(s) / planned >= 0.5;
}

List<String> _baselineIds(Map plan) => [
      for (final b in ((plan['stage_goal'] as Map?)?['baseline_lifts'] as List? ?? const []))
        b['exercise_id'] as String,
    ];

Map<String, (int, int)> _planRepsRange(Map plan) {
  final out = <String, (int, int)>{};
  for (final s in ((plan['training'] as Map)['schedule'] as List)) {
    for (final e in (s['exercises'] as List)) {
      final rr = (e['reps'] as String? ?? '').replaceAll('＋', '+');
      if (rr.contains('-')) {
        final parts = rr.split('-');
        final a = int.tryParse(parts[0]), b = int.tryParse(parts[1]);
        if (a != null && b != null) out[e['exercise_id'] as String] = (a, b);
      }
    }
  }
  return out;
}

Map<String, List<Map<String, dynamic>>> _liftSeries(
    Map plan, List<Map<String, dynamic>> sessions) {
  final repsRange = _planRepsRange(plan);
  final wanted = _baselineIds(plan).toSet();
  final series = <String, List<Map<String, dynamic>>>{for (final i in wanted) i: []};
  final ordered = [...sessions]
    ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
  for (final sess in ordered) {
    if (!_isCompleted(sess)) continue;
    for (final ex in (sess['exercises'] as List? ?? const [])) {
      final eid = ex['exercise_id'] as String?;
      if (eid == null || !wanted.contains(eid)) continue;
      final sets = (ex['sets'] as List? ?? const []);
      final e1rms = <double>[];
      final loads = <double>[];
      final doneReps = <int>[];
      for (final s in sets) {
        final w = (s['weight_kg'] as num?)?.toDouble();
        final reps = (s['reps'] as num?)?.toInt();
        final rir = (s['rir'] as num?)?.toInt();
        if (reps != null) doneReps.add(reps);
        if (w != null) loads.add(w);
        if (w != null && reps != null) {
          final v = epleyE1rm(w, reps, rir);
          if (v != null) e1rms.add(v);
        }
      }
      final topLoad = loads.isEmpty ? null : loads.reduce((a, b) => a > b ? a : b);
      final rr = repsRange[eid] ?? (6, 12);
      final repsAtTop = [
        for (final s in sets)
          if ((s['weight_kg'] as num?)?.toDouble() == topLoad && s['reps'] != null)
            (s['reps'] as num).toInt(),
      ];
      final rirVals = [
        for (final s in sets)
          if (s['rir'] != null) (s['rir'] as num).toInt(),
      ];
      series[eid]!.add({
        'date': sess['date'],
        'best_e1rm': e1rms.isEmpty ? null : e1rms.reduce((a, b) => a > b ? a : b),
        'top_load': topLoad,
        'best_reps_at_top': repsAtTop.isEmpty
            ? null
            : repsAtTop.reduce((a, b) => a > b ? a : b),
        'all_top_range': doneReps.isNotEmpty && doneReps.every((r) => r >= rr.$2),
        'any_below_bottom': doneReps.isNotEmpty && doneReps.any((r) => r < rr.$1),
        'avg_rir': rirVals.isEmpty
            ? null
            : double.parse(
                (rirVals.fold(0, (a, b) => a + b) / rirVals.length).toStringAsFixed(1)),
      });
    }
  }
  return series;
}

double _median(List<double> xs) {
  final s = [...xs]..sort();
  final n = s.length;
  return n.isOdd ? s[n ~/ 2] : (s[n ~/ 2 - 1] + s[n ~/ 2]) / 2;
}

(double?, int) _performancePct(Map<String, List<Map<String, dynamic>>> series) {
  final pcts = <double>[];
  var confirmations = 0;
  for (final entries in series.values) {
    final pts = [
      for (final e in entries)
        if (e['best_e1rm'] != null) e['best_e1rm'] as double,
    ];
    if (pts.length < 2) continue;
    final change = (pts.last - pts.first) / pts.first * 100;
    pcts.add(change);
    if (change >= 2.5) confirmations++;
  }
  if (pcts.isEmpty) return (null, 0);
  return (double.parse(_median(pcts).toStringAsFixed(1)), confirmations);
}

int _sameLoadRepGain(Map<String, List<Map<String, dynamic>>> series) {
  var best = 0;
  for (final entries in series.values) {
    Map<String, dynamic>? first;
    for (final e in entries) {
      if (e['top_load'] != null && e['best_reps_at_top'] != null) {
        first = e;
        break;
      }
    }
    if (first == null) continue;
    for (final e in entries.reversed) {
      if (e['top_load'] == first['top_load'] && e['best_reps_at_top'] != null) {
        final g = (e['best_reps_at_top'] as int) - (first['best_reps_at_top'] as int);
        if (g > best) best = g;
        break;
      }
    }
  }
  return best;
}

double _fitSlope(List<(double, double)> pairs) {
  final n = pairs.length;
  if (n < 2) return 0;
  final sx = pairs.fold(0.0, (a, p) => a + p.$1);
  final sy = pairs.fold(0.0, (a, p) => a + p.$2);
  final sxx = pairs.fold(0.0, (a, p) => a + p.$1 * p.$1);
  final sxy = pairs.fold(0.0, (a, p) => a + p.$1 * p.$2);
  final denom = n * sxx - sx * sx;
  return denom == 0 ? 0 : (n * sxy - sx * sy) / denom;
}

(bool, double?, double?) _bodyTrend(List<Map<String, dynamic>> body, String goal) {
  if (body.length < 3) return (false, null, null);
  final b = [...body]..sort((x, y) => (x['date'] as String).compareTo(y['date'] as String));
  final d0 = _ordinal(b.first['date'] as String);
  if (_ordinal(b.last['date'] as String) - d0 < 10) return (false, null, null);
  final w = [
    for (final e in b)
      if (e['weight_kg'] != null)
        ((_ordinal(e['date'] as String) - d0).toDouble(), (e['weight_kg'] as num).toDouble()),
  ];
  double? weightPct;
  if (w.length >= 2 && w.first.$2 != 0) {
    weightPct = double.parse(((w.last.$2 - w.first.$2) / w.first.$2 * 100).toStringAsFixed(2));
  }
  final ws = [
    for (final e in b)
      if (e['waist_cm'] != null)
        ((_ordinal(e['date'] as String) - d0).toDouble(), (e['waist_cm'] as num).toDouble()),
  ];
  double? waistPct;
  if (ws.length >= 2 && ws.first.$2 != 0) {
    waistPct = double.parse(((ws.last.$2 - ws.first.$2) / ws.first.$2 * 100).toStringAsFixed(2));
  }
  bool met;
  if (goal == 'fat_loss') {
    final wtOk = w.length >= 3 && _fitSlope(w) < 0 && (weightPct ?? 0) <= -0.5;
    final waistOk = ws.isNotEmpty && ws.first.$2 - ws.last.$2 >= 1.0;
    met = wtOk || waistOk;
  } else {
    final wtOk = w.length >= 3 && _fitSlope(w) >= 0 && (weightPct ?? 0) >= 0.25;
    final waistOk = waistPct == null || waistPct <= 1.0;
    met = wtOk && waistOk;
  }
  return (met, weightPct, waistPct);
}

/// 体重周变化率（%/周），用回归斜率算，抗单点波动。
/// 需 ≥3 次称重、跨度 ≥14 天，否则 null（数据不够不调整）。
double? weeklyWeightPct(List<Map<String, dynamic>> body) {
  final b = [
    for (final e in body)
      if (e['weight_kg'] != null && e['date'] != null) e,
  ]..sort((x, y) => (x['date'] as String).compareTo(y['date'] as String));
  if (b.length < 3) return null;
  final d0 = _ordinal(b.first['date'] as String);
  final span = _ordinal(b.last['date'] as String) - d0;
  if (span < 14) return null;
  final pairs = [
    for (final e in b)
      ((_ordinal(e['date'] as String) - d0).toDouble(),
          (e['weight_kg'] as num).toDouble()),
  ];
  final slopePerDay = _fitSlope(pairs);
  final meanW = pairs.fold(0.0, (a, p) => a + p.$2) / pairs.length;
  if (meanW <= 0) return null;
  return double.parse((slopePerDay * 7 / meanW * 100).toStringAsFixed(3));
}

bool _painUnresolved(List<Map<String, dynamic>> sessions) {
  if (sessions.isEmpty) return false;
  final ordered = [...sessions]
    ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
  return ordered
      .sublist(ordered.length - (ordered.length < 3 ? ordered.length : 3))
      .any((s) => s['pain_flag'] == true);
}

StageEvidence aggregateEvidence(
  Map plan,
  List<Map<String, dynamic>> workoutLog,
  List<Map<String, dynamic>> bodyLog,
) {
  final goal = (plan['profile'] as Map?)?['goal'] as String? ?? 'hypertrophy';
  final completed = workoutLog.where(_isCompleted).toList();
  final activeWeeks = {
    for (final s in completed)
      if (s['date'] != null) _isoWeek(s['date'] as String),
  }.length;
  final series = _liftSeries(plan, workoutLog);
  final comparable = series.values
      .map((v) => v.where((e) => e['best_e1rm'] != null).length)
      .fold(0, (a, b) => a > b ? a : b);
  final (perfPct, confirmations) = _performancePct(series);
  final repGain = _sameLoadRepGain(series);
  final (bodyMet, _, _) = _bodyTrend(bodyLog, goal);
  return StageEvidence(
    completedSessions: completed.length,
    activeWeeks: activeWeeks,
    comparableMeasurements: comparable,
    performanceImprovementPct: perfPct,
    performanceConfirmations: confirmations,
    sameLoadRepGain: repGain == 0 ? null : repGain,
    bodyTrendTargetMet: bodyMet,
    unresolvedSafetyIssue: _painUnresolved(workoutLog),
  );
}

ResponseObservation aggregateObservation(
  Map plan,
  List<Map<String, dynamic>> workoutLog,
  List<Map<String, dynamic>> bodyLog,
  int completedCycles,
) {
  final goal = (plan['profile'] as Map?)?['goal'] as String? ?? 'hypertrophy';
  final planned =
      ((plan['stage_goal'] as Map?)?['planned_sessions'] as num?)?.toInt() ?? 1;
  final completed = workoutLog.where(_isCompleted).length;
  final adherence = double.parse((completed / planned * 100).toStringAsFixed(1));
  final series = _liftSeries(plan, workoutLog);
  final (perfPct, _) = _performancePct(series);
  final (_, weightPct, waistPct) = _bodyTrend(bodyLog, goal);
  final rirGaps = [
    for (final v in series.values)
      for (final e in v)
        if (e['avg_rir'] != null) 2 - (e['avg_rir'] as double),
  ];
  final recovery = rirGaps.isEmpty
      ? null
      : double.parse(
          (rirGaps.fold(0.0, (a, b) => a + b) / rirGaps.length).toStringAsFixed(2));
  return ResponseObservation(
    completedCycles: completedCycles,
    adherencePct: adherence,
    performanceImprovementPct: perfPct,
    weightTrendPct: weightPct,
    waistTrendPct: waistPct,
    recoveryScore: recovery,
  );
}

int _trailingTrue(List<Map<String, dynamic>> entries, String key) {
  var n = 0;
  for (final e in entries.reversed) {
    if (e[key] == true) {
      n++;
    } else {
      break;
    }
  }
  return n;
}

Map<String, Map<String, dynamic>> perExerciseProgress(
  Map plan,
  List<Map<String, dynamic>> workoutLog,
) {
  final series = _liftSeries(plan, workoutLog);
  final out = <String, Map<String, dynamic>>{};
  series.forEach((eid, entries) {
    if (entries.isEmpty) return;
    final last3 = entries.sublist(entries.length - (entries.length < 3 ? entries.length : 3));
    final decl = entries.length >= 3 &&
        entries[entries.length - 1]['best_e1rm'] != null &&
        entries[entries.length - 2]['best_e1rm'] != null &&
        entries[entries.length - 3]['best_e1rm'] != null &&
        (entries[entries.length - 1]['best_e1rm'] as double) <
            (entries[entries.length - 2]['best_e1rm'] as double) &&
        (entries[entries.length - 2]['best_e1rm'] as double) <
            (entries[entries.length - 3]['best_e1rm'] as double);
    out[eid] = {
      'instances': entries.length,
      'e1rm_change_pct': (entries.length >= 2 &&
              entries.first['best_e1rm'] != null &&
              entries.last['best_e1rm'] != null)
          ? double.parse((((entries.last['best_e1rm'] as double) -
                      (entries.first['best_e1rm'] as double)) /
                  (entries.first['best_e1rm'] as double) *
                  100)
              .toStringAsFixed(1))
          : null,
      'last_all_top_range': last3.isNotEmpty && (last3.last['all_top_range'] == true),
      'consecutive_below_bottom': _trailingTrue(entries, 'any_below_bottom'),
      'avg_rir': last3.isNotEmpty ? last3.last['avg_rir'] : null,
      'e1rm_declining': decl,
    };
  });
  return out;
}
