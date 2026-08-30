import '../data/diet_catalog.dart';
import '../models/meal.dart';
import 'models.dart';

/// Daily diet targets taken from a generated plan, with catalog fallbacks
/// so older accounts that predate plan generation still have numbers.
class DietGoals {
  const DietGoals({
    required this.kcal,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
    required this.recipeGoal,
    required this.meals,
  });

  final int kcal;
  final int proteinG;
  final int carbG;
  final int fatG;
  final RecipeGoal recipeGoal;
  final List<Meal> meals;

  static const fallback = DietGoals(
    kcal: DietCatalog.goalKcal,
    proteinG: DietCatalog.proteinGoal,
    carbG: DietCatalog.carbGoal,
    fatG: DietCatalog.fatGoal,
    recipeGoal: RecipeGoal.recommend,
    meals: [],
  );

  factory DietGoals.fromPlan(GeneratedPlan plan) {
    final dt = plan.macros.dailyTargets;
    return DietGoals(
      kcal: (dt['kcal'] as num?)?.round() ?? DietCatalog.goalKcal,
      proteinG: (dt['protein_g'] as num?)?.round() ?? DietCatalog.proteinGoal,
      carbG: (dt['carbs_g'] as num?)?.round() ?? DietCatalog.carbGoal,
      fatG: (dt['fat_g'] as num?)?.round() ?? DietCatalog.fatGoal,
      recipeGoal: switch (plan.macros.goal) {
        'fat_loss' => RecipeGoal.cut,
        'hypertrophy' => RecipeGoal.bulk,
        'strength' => RecipeGoal.bulk,
        _ => RecipeGoal.maintain,
      },
      meals: plan.mealPlan.meals,
    );
  }

  Meal? mealForSlot(MealSlot slot) {
    final names = switch (slot) {
      MealSlot.breakfast => const ['早餐'],
      MealSlot.lunch => const ['午餐'],
      MealSlot.dinner => const ['晚餐'],
      MealSlot.snack => const ['练后加餐', '早加餐', '晚加餐', '加餐'],
    };
    for (final name in names) {
      for (final meal in meals) {
        if (meal.name == name) return meal;
      }
    }
    return null;
  }

  int kcalForSlot(MealSlot slot) => mealForSlot(slot)?.kcal.round() ?? (kcal / 4).round();

  /// Concrete "how to eat this" line for a slot: first engine food-library
  /// option, falling back to the hand-portion equivalent.
  String? foodExampleFor(MealSlot slot) {
    final meal = mealForSlot(slot);
    if (meal == null) return null;
    if (meal.options.isNotEmpty) {
      final items =
          (meal.options.first['items'] as List?)?.cast<String>() ?? const [];
      if (items.isNotEmpty) return items.join(' + ');
    }
    return meal.handPortions.isNotEmpty ? meal.handPortions : null;
  }

  List<RecipeItem> recommendedRecipes() {
    final match = DietCatalog.recipes
        .where((r) => r.goal == recipeGoal || r.goal == RecipeGoal.recommend)
        .toList();
    return match.isEmpty ? DietCatalog.recipes : match;
  }
}

/// Raw PlannerGateway fields reconstructed from a saved plan, so the
/// input flow can be reopened and edited after the first generation.
Map<String, dynamic> profileFieldsFrom(UserProfile profile) {
  return {
    'gender': profile.gender,
    'age': profile.age,
    'height_cm': profile.heightCm,
    'weight_kg': profile.weightKg,
    'level': profile.level,
    'days_per_week': profile.daysPerWeek,
    'minutes_per_session': profile.minutesPerSession,
    'equipment': List<String>.from(profile.equipment),
    'meals_per_day': profile.mealsPerDay,
    if (profile.bodyFatPct != null) 'body_fat_pct': profile.bodyFatPct,
    if (profile.targetWeightKg != null) 'target_weight_kg': profile.targetWeightKg,
  };
}
