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
