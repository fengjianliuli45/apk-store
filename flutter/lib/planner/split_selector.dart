import 'models.dart';

/// Port of fitness-planner's `split_selector.py`.
const dayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

const splitTemplates = {
  'full_body': ['full_body', 'rest', 'full_body', 'rest', 'full_body', 'rest', 'rest'],
  'push_pull_legs': ['push', 'pull', 'legs', 'rest', 'push', 'pull', 'rest'],
  'upper_lower': ['upper', 'lower', 'rest', 'upper', 'lower', 'rest', 'rest'],
  'ppl_upper_lower': ['push', 'pull', 'legs', 'upper', 'lower', 'rest', 'rest'],
  'ppl_ppl': ['push', 'pull', 'legs', 'push', 'pull', 'legs', 'rest'],
};

SplitResult selectSplit(UserProfile profile) {
  final d = profile.daysPerWeek ?? 3;
  final level = profile.level;
  final warnings = <String>[];

  String splitName;
  if (d == 2) {
    splitName = 'full_body';
  } else if (d == 3) {
    // 全身 3 次/周：给定训练量下频率更高，比 3 天 PPL（每肌群 1 次/周）
    // 显著更能兑现周容量。各水平统一全身。
    splitName = 'full_body';
    if (level != 'beginner') {
      warnings.add('3 天训练用全身分肢（每肌群 2–3 次/周）比 PPL 更高效；想练 PPL 建议加到 6 天');
    }
  } else if (d == 4) {
    splitName = 'upper_lower';
  } else if (d == 5) {
    splitName = 'ppl_upper_lower';
  } else if (d == 6) {
    splitName = 'ppl_ppl';
  } else if (d == 7) {
    splitName = 'ppl_ppl';
    warnings.add('每周训练 7 天不推荐，建议至少安排 1 天休息');
  } else if (d == 1) {
    splitName = 'full_body';
    warnings.add('每周仅 1 天训练，效果有限，建议至少 2 天');
  } else {
    splitName = 'full_body';
  }

  final template = splitTemplates[splitName]!;

  var trainingSeen = 0;
  final adjusted = <String>[];
  for (final dayType in template) {
    if (dayType != 'rest') {
      if (trainingSeen < d) {
        adjusted.add(dayType);
        trainingSeen++;
      } else {
        adjusted.add('rest');
      }
    } else {
      adjusted.add('rest');
    }
  }

  final schedule = <ScheduleDay>[
    for (var i = 0; i < adjusted.length; i++) ScheduleDay(day: dayNames[i], type: adjusted[i]),
  ];

  return SplitResult(splitName: splitName, weeklySchedule: schedule, warnings: warnings);
}
