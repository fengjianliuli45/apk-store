import 'food_db.dart' as food_db;
import 'models.dart';

/// Port of fitness-planner's `meal_distributor.py`.
const mealNames4 = ['早餐', '午餐', '练后加餐', '晚餐'];
const mealNames5 = ['早餐', '午餐', '练后加餐', '晚餐', '晚加餐'];
const mealNames3 = ['早餐', '午餐', '晚餐'];
const mealNames6 = ['早餐', '早加餐', '午餐', '练后加餐', '晚餐', '晚加餐'];

/// 膳食纤维 14g / 1000 kcal（Academy of Nutrition and Dietetics）
const fiberPer1000Kcal = 14;

/// 饮水 33 ml/kg 基线，训练日额外 +500 ml
const waterMlPerKg = 33;
const waterMlTrainingBonus = 500;

int _round(double x) => (x + 0.5).floor();

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
    final isPostWorkout = name == '练后加餐';
    if (isPostWorkout) {
      protein *= 1.2;
      carbs *= 1.2;
    }
    final kcal = protein * 4 + fat * 9 + carbs * 4;
    meals.add(Meal(
      name: name,
      kcal: kcal,
      proteinG: protein,
      fatG: fat,
      carbsG: carbs,
      isPostWorkout: isPostWorkout,
    ));
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

  // 具体吃法
  final restrictions = food_db.normalizeRestrictions(profile.dietaryRestrictions);
  final cooking = profile.cookingAccess;
  for (var idx = 0; idx < meals.length; idx++) {
    final m = meals[idx];
    final target = {'protein_g': m.proteinG, 'carbs_g': m.carbsG, 'fat_g': m.fatG};
    m.options = food_db.suggestMeal(target, restrictions, cooking, m.isPostWorkout,
        rotate: idx);
    m.handPortions = food_db.handPortionText(target);
  }

  final totalP = meals.fold<double>(0, (s, m) => s + m.proteinG);
  final totalF = meals.fold<double>(0, (s, m) => s + m.fatG);
  final totalC = meals.fold<double>(0, (s, m) => s + m.carbsG);
  final totalK = meals.fold<double>(0, (s, m) => s + m.kcal);

  final fiberG = _round(totalK / 1000 * fiberPer1000Kcal);
  final waterRest = _round(profile.weightKg * waterMlPerKg);
  final waterTraining = waterRest + waterMlTrainingBonus;

  final dietNotes = <String>[...macros.notes];
  // 每餐 0.4 g/kg 为最优刺激（Schoenfeld & Aragon 2018），0.3 g/kg 为触发阈值下限
  final proteinFloor =
      double.parse((0.3 * profile.weightKg).toStringAsFixed(1));
  final proteinTarget =
      double.parse((0.4 * profile.weightKg).toStringAsFixed(1));
  final lowMeals = meals
      .where((m) => m.proteinG + 1e-6 < proteinFloor)
      .map((m) => m.name)
      .toList();
  if (lowMeals.isNotEmpty) {
    dietNotes.add('每餐蛋白最优 ~${proteinTarget}g（0.4 g/kg），下限 ${proteinFloor}g（0.3 g/kg）；'
        '偏低的餐：${lowMeals.join('、')}——把蛋白挪一些过去或加一份');
  }
  dietNotes.add('蛋白尽量均分到各餐，相邻 3–4 小时一次（MPS 窗口 ~2–3h）');
  dietNotes.add('膳食纤维 ≥${fiberG}g/天：每餐一拳蔬菜 + 主食尽量选糙米/燕麦/薯类');
  dietNotes.add('饮水：非训练日约 ${waterRest}ml，训练日约 ${waterTraining}ml');
  if (restrictions.contains('vegan')) {
    dietNotes.add('纯素需额外关注：维生素 B12（必补）、铁、Omega-3（藻油）——见补剂建议');
  }

  return MealPlan(
    meals: meals,
    totalKcal: totalK,
    totalProteinG: totalP,
    totalFatG: totalF,
    totalCarbsG: totalC,
    fiberG: fiberG,
    waterMlRest: waterRest,
    waterMlTraining: waterTraining,
    dietNotes: dietNotes,
  );
}
