import '../data/diet_catalog.dart';
import '../models/meal.dart';
import 'models.dart';
import 'plan_adapter.dart';
import 'weekly_nutrition.dart';

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
    this.foodExamples = const {},
    this.dietaryRestrictions = const [],
    this.cycleNote = '',
  });

  final int kcal;
  final int proteinG;
  final int carbG;
  final int fatG;
  final RecipeGoal recipeGoal;
  final List<Meal> meals;
  final Map<String, String> foodExamples;
  final List<String> dietaryRestrictions;
  final String cycleNote;

  static const fallback = DietGoals(
    kcal: DietCatalog.goalKcal,
    proteinG: DietCatalog.proteinGoal,
    carbG: DietCatalog.carbGoal,
    fatG: DietCatalog.fatGoal,
    recipeGoal: RecipeGoal.recommend,
    meals: [],
  );

  factory DietGoals.fromPlan(GeneratedPlan plan, {DateTime? now}) {
    final week = weekForDate(plan, now ?? DateTime.now());
    final (macros, meals) = nutritionForWeek(plan, week);
    final dt = macros.dailyTargets;
    return DietGoals(
      kcal: dt['kcal']?.round() ?? DietCatalog.goalKcal,
      proteinG: dt['protein_g']?.round() ?? DietCatalog.proteinGoal,
      carbG: dt['carbs_g']?.round() ?? DietCatalog.carbGoal,
      fatG: dt['fat_g']?.round() ?? DietCatalog.fatGoal,
      recipeGoal: switch (plan.macros.goal) {
        'fat_loss' => RecipeGoal.cut,
        'hypertrophy' => RecipeGoal.bulk,
        'strength' => RecipeGoal.bulk,
        _ => RecipeGoal.maintain,
      },
      meals: meals.meals,
      foodExamples: meals.foodExamples,
      cycleNote: (week?.dietKcalDelta ?? 0) == 0 ? '' : macros.notes.last,
      dietaryRestrictions: plan.profile.dietaryRestrictions,
    );
  }

  Meal? mealForSlot(MealSlot slot) {
    final names = switch (slot) {
      MealSlot.breakfast => const ['早餐'],
      MealSlot.lunch => const ['午餐'],
      MealSlot.dinner => const ['晚餐'],
      MealSlot.snack => const ['练后加餐', '早加餐', '晚加餐', '加餐'],
    };
    final matches = meals.where((m) => names.contains(m.name)).toList();
    if (matches.length > 1) {
      return Meal(
        name: matches.map((m) => m.name).join(' / '),
        kcal: matches.fold<double>(0, (sum, m) => sum + m.kcal),
        proteinG: matches.fold<double>(0, (sum, m) => sum + m.proteinG),
        fatG: matches.fold<double>(0, (sum, m) => sum + m.fatG),
        carbsG: matches.fold<double>(0, (sum, m) => sum + m.carbsG),
        handPortions: matches
            .map((m) => '${m.name}：${m.handPortions}')
            .join('；'),
      );
    }
    for (final name in names) {
      for (final meal in meals) {
        if (meal.name == name) return meal;
      }
    }
    return null;
  }

  int kcalForSlot(MealSlot slot) =>
      mealForSlot(slot)?.kcal.round() ?? (kcal / 4).round();

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
    if (meal.handPortions.isNotEmpty) return meal.handPortions;
    if (foodExamples.isEmpty) return null;
    final target = meal.proteinG;
    MapEntry<String, String>? closest;
    var distance = double.infinity;
    for (final entry in foodExamples.entries) {
      final grams = double.tryParse(
        RegExp(r'\d+(?:\.\d+)?').firstMatch(entry.key)?.group(0) ?? '',
      );
      if (grams == null) continue;
      final nextDistance = (grams - target).abs();
      if (nextDistance < distance) {
        distance = nextDistance;
        closest = entry;
      }
    }
    return closest?.value;
  }

  List<RecipeItem> recommendedRecipes() {
    // Static recipes have no reliable exclusion/allergen metadata. Do not
    // present them as personalized recommendations when constraints exist.
    if (dietaryRestrictions.isNotEmpty) return const [];
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
    'injuries': List<String>.of(profile.injuries),
    'dietary_restrictions': List<String>.of(profile.dietaryRestrictions),
    'cooking_access': profile.cookingAccess,
    'supplements': List<String>.of(profile.supplements),
    'strength_baseline': {
      for (final entry in profile.strengthBaseline.entries)
        entry.key: entry.value is Map
            ? Map<String, dynamic>.from(entry.value as Map)
            : entry.value,
    },
    'volume_cycle_offset': profile.volumeCycleOffset,
    'kcal_adjust': profile.kcalAdjust,
    'exercise_cycle_offset': profile.exerciseCycleOffset,
    'bodyweight_progress': Map<String, int>.of(profile.bodyweightProgress),
    if (profile.bodyFatPct != null) 'body_fat_pct': profile.bodyFatPct,
    if (profile.targetWeightKg != null)
      'target_weight_kg': profile.targetWeightKg,
  };
}
