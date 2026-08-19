import 'models.dart';

/// Port of fitness-planner's `meal_distributor.py`.
const mealNames4 = ['早餐', '午餐', '练后加餐', '晚餐'];
const mealNames5 = ['早餐', '午餐', '练后加餐', '晚餐', '晚加餐'];
const mealNames3 = ['早餐', '午餐', '晚餐'];
const mealNames6 = ['早餐', '早加餐', '午餐', '练后加餐', '晚餐', '晚加餐'];

const foodExamples = {
  '35g_protein': '鸡胸肉 150g ≈ 鸡蛋 5个 ≈ 蛋白粉 1.5勺 ≈ 豆腐 400g',
  '40g_protein': '鸡胸肉 170g ≈ 鸡蛋 6个 ≈ 蛋白粉 1.7勺 ≈ 豆腐 450g',
  '30g_protein': '鸡胸肉 130g ≈ 鸡蛋 4个 ≈ 蛋白粉 1.3勺 ≈ 豆腐 350g',
  '20g_protein': '鸡胸肉 85g ≈ 鸡蛋 3个 ≈ 蛋白粉 0.9勺 ≈ 豆腐 230g',
};

MealPlan distributeMeals(UserProfile profile, MacroResult macros) {
  final n = profile.mealsPerDay;

  final dailyProtein = (macros.dailyTargets['protein_g'] as num).toDouble();
  final dailyFat = (macros.dailyTargets['fat_g'] as num).toDouble();
  final dailyCarbs = (macros.dailyTargets['carbs_g'] as num).toDouble();

  final perMealProtein = dailyProtein / n;
  final perMealFat = dailyFat / n;
  final perMealCarbs = dailyCarbs / n;

  List<String> names;
  if (n <= 3) {
    names = mealNames3.sublist(0, n);
  } else if (n == 4) {
    names = mealNames4;
  } else if (n == 5) {
    names = mealNames5;
  } else {
    names = mealNames6.sublist(0, n > mealNames6.length ? mealNames6.length : n);
  }

  final meals = <Meal>[];
  for (final name in names) {
    var protein = perMealProtein;
    var fat = perMealFat;
    var carbs = perMealCarbs;
    var kcal = protein * 4 + fat * 9 + carbs * 4;

    if (name == '练后加餐') {
      protein *= 1.2;
      carbs *= 1.2;
      kcal = protein * 4 + fat * 9 + carbs * 4;
    }

    meals.add(Meal(name: name, kcal: kcal, proteinG: protein, fatG: fat, carbsG: carbs));
  }

  final totalPBefore = meals.fold<double>(0, (s, m) => s + m.proteinG);
  final totalCBefore = meals.fold<double>(0, (s, m) => s + m.carbsG);
  if (totalPBefore > 0) {
    final pScale = dailyProtein / totalPBefore;
    for (final m in meals) {
      m.proteinG *= pScale;
    }
  }
  if (totalCBefore > 0) {
    final cScale = dailyCarbs / totalCBefore;
    for (final m in meals) {
      m.carbsG *= cScale;
    }
  }
  for (final m in meals) {
    m.kcal = m.proteinG * 4 + m.fatG * 9 + m.carbsG * 4;
  }

  final totalP = meals.fold<double>(0, (s, m) => s + m.proteinG);
  final totalF = meals.fold<double>(0, (s, m) => s + m.fatG);
  final totalC = meals.fold<double>(0, (s, m) => s + m.carbsG);
  final totalK = meals.fold<double>(0, (s, m) => s + m.kcal);

  return MealPlan(
    meals: meals,
    totalKcal: totalK,
    totalProteinG: totalP,
    totalFatG: totalF,
    totalCarbsG: totalC,
    foodExamples: foodExamples,
  );
}
