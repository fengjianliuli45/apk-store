import 'models.dart';

/// Port of fitness-planner's `macro_allocator.py`.
const goalSurplus = {
  'hypertrophy': 350,
  'fat_loss': -400,
  'strength': 200,
  'recomposition': 0,
};

const proteinPerKg = {
  'hypertrophy': 2.0,
  'fat_loss': 2.2,
  'strength': 1.8,
  'recomposition': 1.8,
};

const fatPerKg = {
  'hypertrophy': 1.0,
  'fat_loss': 0.8,
  'strength': 1.0,
  'recomposition': 1.0,
};

const proteinKcalPerG = 4;
const fatKcalPerG = 9;
const carbKcalPerG = 4;

MacroResult allocateMacros(UserProfile profile, TDEEResult tdee) {
  final goal = profile.goal;
  final w = profile.weightKg;

  final surplus = goalSurplus[goal] ?? 0;
  var dailyKcal = tdee.tdee + surplus;

  final proteinG = double.parse((proteinPerKg[goal]! * w).toStringAsFixed(1));
  final fatG = double.parse((fatPerKg[goal]! * w).toStringAsFixed(1));

  final proteinKcal = proteinG * proteinKcalPerG;
  final fatKcal = fatG * fatKcalPerG;
  var carbsKcal = dailyKcal - proteinKcal - fatKcal;
  var carbsG = double.parse((carbsKcal / carbKcalPerG).toStringAsFixed(1));

  if (carbsG < 0) {
    carbsG = 0.0;
    dailyKcal = proteinKcal + fatKcal;
  }

  return MacroResult(
    dailyTargets: {
      'kcal': dailyKcal.round(),
      'protein_g': proteinG,
      'fat_g': fatG,
      'carbs_g': carbsG,
    },
    perKg: {
      'protein': double.parse((proteinG / w).toStringAsFixed(1)),
      'fat': double.parse((fatG / w).toStringAsFixed(1)),
      'carbs': double.parse((carbsG / w).toStringAsFixed(1)),
    },
    surplusKcal: surplus,
    goal: goal,
  );
}
