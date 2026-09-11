import 'models.dart';
import 'meal_distributor.dart';

/// Port of engine/weekly_nutrition.py; derived execution values only.
(MacroResult, MealPlan) nutritionForWeek(GeneratedPlan plan, WeekPlan? week) {
  final delta = week?.dietKcalDelta ?? 0;
  if (delta == 0) return (plan.macros, plan.mealPlan);
  final targets = Map<String, num>.of(plan.macros.dailyTargets);
  final fixed = targets['protein_g']! * 4 + targets['fat_g']! * 9;
  final requested = targets['kcal']! + delta;
  targets['kcal'] = requested < fixed ? fixed : requested;
  targets['carbs_g'] = double.parse(
    ((targets['kcal']! - fixed) / 4).toStringAsFixed(1),
  );
  final macros = MacroResult(
    dailyTargets: targets,
    perKg: {
      ...plan.macros.perKg,
      'carbs': double.parse(
        (targets['carbs_g']! / plan.profile.weightKg).toStringAsFixed(1),
      ),
    },
    surplusKcal: plan.macros.surplusKcal,
    goal: plan.macros.goal,
    notes: [
      ...plan.macros.notes,
      '中周期第 ${week!.week} 周：相对基准热量调整 ${delta > 0 ? '+' : ''}$delta kcal',
    ],
  );
  return (macros, distributeMeals(plan.profile, macros));
}
