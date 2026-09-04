import 'models.dart';

/// Short Chinese labels for engine fields that were previously JSON-only.

String progressionStrategyLabel(String strategy) => switch (strategy) {
      'linear_weekly' => '每周线性加重',
      'biweekly_double_progression' => '双周双进阶',
      'monthly_periodization' => '每月周期化',
      _ => strategy,
    };

int planWeekNumber(DateTime generatedAt, [DateTime? now]) {
  final days = (now ?? DateTime.now()).difference(generatedAt).inDays;
  return ((days < 0 ? 0 : days) ~/ 7) + 1;
}

String supplementLine(SupplementResult result) {
  if (result.supplements.isEmpty) return '暂无补剂建议';
  return result.supplements.map((s) => '${s.name} ${s.dose}').join(' · ');
}

String mealPlanLine(MealPlan plan) {
  if (plan.meals.isEmpty) return '还没有餐次分配';
  return plan.meals.map((m) => '${m.name} ${m.kcal.round()}kcal').join(' · ');
}

String trainingGoalLabel(String goal) => switch (goal) {
      'hypertrophy' => '增肌',
      'fat_loss' => '减脂',
      'strength' => '力量',
      'recomposition' => '重组',
      _ => goal,
    };

String stageTypeLabel(String stageType) => switch (stageType) {
      'adaptation' => '适应阶段',
      'accumulation' => '累积阶段',
      'intensification' => '强化阶段',
      'deload' => '减载阶段',
      _ => stageType,
    };

String stageGoalSummary(String goal) => switch (goal) {
      'hypertrophy' => '提高肌肉量，同时稳定训练容量',
      'fat_loss' => '制造可控热量缺口，同时保护力量',
      'strength' => '提高主要动作负荷，同时保持技术稳定',
      'recomposition' => '改善体成分，同时维持训练容量',
      _ => '按当前目标推进本周期训练',
    };

String weekdayShortLabel(int weekday) {
  const names = ['一', '二', '三', '四', '五', '六', '日'];
  return names[(weekday - 1).clamp(0, 6)];
}
