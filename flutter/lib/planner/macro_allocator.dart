import 'food_db.dart';
import 'models.dart';

/// Port of fitness-planner's `macro_allocator.py`.

/// 植物蛋白消化率 / 亮氨酸偏低 → 上调 g/kg（PMC11281145, MDPI 16(8)1122）
const dietProteinBump = {'vegan': 0.3, 'vegetarian': 0.2};
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
  final notes = <String>[];

  final surplus = goalSurplus[goal] ?? 0;
  final kcalAdjust = profile.kcalAdjust;
  var dailyKcal = tdee.tdee + surplus + kcalAdjust;
  if (kcalAdjust != 0) {
    notes.add('按上一周期体重趋势，热量已${kcalAdjust > 0 ? '上调' : '下调'} ${kcalAdjust.abs()} kcal');
  }

  var proteinPerKgVal = proteinPerKg[goal]!;
  final restrictions = normalizeRestrictions(profile.dietaryRestrictions);
  if (restrictions.contains('vegan')) {
    proteinPerKgVal += dietProteinBump['vegan']!;
    notes.add('纯素：蛋白已上调 +0.3 g/kg，优先豆制品/大豆蛋白粉（亮氨酸足）');
  } else if (restrictions.contains('vegetarian')) {
    proteinPerKgVal += dietProteinBump['vegetarian']!;
    notes.add('蛋奶素：蛋白已上调 +0.2 g/kg，多用乳清/蛋/豆制品');
  }

  final proteinG = double.parse((proteinPerKgVal * w).toStringAsFixed(1));
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
    notes: notes,
  );
}
