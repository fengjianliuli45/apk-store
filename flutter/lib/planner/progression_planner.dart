import 'models.dart';

/// Port of fitness-planner's `progression_planner.py`.
const _progressionRules = {
  'beginner': {'freq': '每周', 'upper_kg': 2.5, 'lower_kg': 5.0, 'cycle_weeks': 4},
  'intermediate': {'freq': '每2周', 'upper_kg': 2.5, 'lower_kg': 5.0, 'cycle_weeks': 4},
  'advanced': {'freq': '每月', 'upper_kg': 1.25, 'lower_kg': 2.5, 'cycle_weeks': 4},
};

const _strategyMap = {
  'beginner': 'linear_weekly',
  'intermediate': 'biweekly_double_progression',
  'advanced': 'monthly_periodization',
};

ProgressionResult planProgression(UserProfile profile) {
  final rules = _progressionRules[profile.level] ?? _progressionRules['beginner']!;

  final triggers = [
    ReassessmentTrigger(condition: '体重变化 >2kg', action: '重新计算 TDEE + 营养素'),
    ReassessmentTrigger(condition: '训练满 4 周', action: '全动作组数+1 或试加重', week: 4),
    ReassessmentTrigger(condition: '训练满 12 周', action: '建议切换分肢方案，检查是否改目标', week: 12),
    ReassessmentTrigger(condition: '连续 2 周无法完成计划', action: '下调 10% 容量'),
    ReassessmentTrigger(condition: '中断 >2 周', action: '回退 10-20% 容量'),
    ReassessmentTrigger(condition: '目标变更', action: '全量重算'),
  ];

  return ProgressionResult(
    strategy: _strategyMap[profile.level] ?? 'linear_weekly',
    incrementUpperKg: rules['upper_kg'] as double,
    incrementLowerKg: rules['lower_kg'] as double,
    progressionFreq: rules['freq'] as String,
    doubleProgression: '双进阶：当无法再加重量时：先+1次→达到上限次数后降次加重循环',
    nextCheckWeek: rules['cycle_weeks'] as int,
    triggers: triggers,
  );
}
