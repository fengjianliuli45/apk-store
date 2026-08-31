/// Port of fitness-planner's `cohort_compare.py`.
/// 同类对标软提示（B 方案）：把 benchmark 结果翻成一句话。引擎不发网络请求。

const _bands = <String, String>{
  'ahead': '领先（超过同类 75%）',
  'above': '正常偏上',
  'normal': '正常范围',
  'behind': '偏慢，可以再逼一点 / 检查恢复与饮食',
};

/// 从计划 JSON 组 benchmark 查询参数。
Map<String, dynamic> cohortQueryParams(
    Map<String, dynamic> plan, double weeksElapsed) {
  final p = (plan['profile'] as Map?) ?? const {};
  return {
    'sex': p['gender'] ?? 'M',
    'age': (p['age'] as num?)?.toInt() ?? 25,
    'bmi': (p['bmi'] as num?)?.toDouble() ?? 22.0,
    'level': p['level'] ?? 'beginner',
    'goal': p['goal'] ?? 'hypertrophy',
    'weeks_elapsed': weeksElapsed,
    'equipment': List<String>.from(p['equipment'] as List? ?? const []),
  };
}

/// user_value 相对 {p25,p50,p75} 落在哪一档。
/// 返回 {band, label, vs_median_pct}；band ∈ ahead|above|normal|behind。
Map<String, dynamic> cohortCompare(double userValue, Map<String, dynamic> stats) {
  final p25 = (stats['p25'] as num).toDouble();
  final p50 = (stats['p50'] as num).toDouble();
  final p75 = (stats['p75'] as num).toDouble();
  final v = userValue;
  final String band;
  if (v >= p75) {
    band = 'ahead';
  } else if (v >= p50) {
    band = 'above';
  } else if (v >= p25) {
    band = 'normal';
  } else {
    band = 'behind';
  }
  double? vsMedian;
  if (p50 != 0) {
    vsMedian = double.parse(((v - p50) / p50.abs() * 100).toStringAsFixed(1));
  }
  return {'band': band, 'label': _bands[band], 'vs_median_pct': vsMedian};
}

String _signed(double x) => '${x >= 0 ? '+' : ''}${x.toStringAsFixed(0)}';

String cohortHint(String metricCn, double userValue, Map<String, dynamic> stats) {
  final c = cohortCompare(userValue, stats);
  final p50 = (stats['p50'] as num).toDouble();
  final p25 = (stats['p25'] as num).toDouble();
  final p75 = (stats['p75'] as num).toDouble();
  return '$metricCn ${_signed(userValue)}%：同类中位数 ${_signed(p50)}%'
      '（p25~p75 ${_signed(p25)}%~${_signed(p75)}%），${c['label']}。';
}
