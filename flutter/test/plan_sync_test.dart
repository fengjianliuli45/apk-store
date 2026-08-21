import 'package:flutter_test/flutter_test.dart';
import 'package:rest_pod_hud/models/meal.dart';
import 'package:rest_pod_hud/planner/models.dart';
import 'package:rest_pod_hud/planner/plan_sync.dart';
import 'package:rest_pod_hud/state/workout_session_controller.dart';

GeneratedPlan _stubPlan({
  required String goal,
  required List<SessionResult> sessions,
  List<Meal> meals = const [],
  Map<String, String> foodExamples = const {},
  Map<String, num>? dailyTargets,
}) {
  return GeneratedPlan(
    generatedAt: DateTime.utc(2026, 8, 21),
    profile: UserProfile(
      gender: 'M',
      age: 28,
      heightCm: 170,
      weightKg: 65,
      level: 'beginner',
      goal: goal,
      daysPerWeek: 3,
      minutesPerSession: 30,
      equipment: const ['bodyweight', 'dumbbell'],
    ),
    tdee: TDEEResult(
      bmr: 1600,
      tdee: 2100,
      formulaUsed: 'mifflin_st_jeor',
      activityMultiplier: 1.375,
      activityLevel: 'light',
    ),
    macros: MacroResult(
      dailyTargets: dailyTargets ??
          const {'kcal': 2200, 'protein_g': 160, 'fat_g': 60, 'carbs_g': 250},
      perKg: const {'protein': 2.5, 'fat': 0.9, 'carbs': 3.8},
      surplusKcal: 250,
      goal: goal,
    ),
    split: SplitResult(splitName: '全身', weeklySchedule: const [], warnings: const []),
    sessions: sessions,
    progression: ProgressionResult(
      strategy: 'linear',
      incrementUpperKg: 2.5,
      incrementLowerKg: 5,
      progressionFreq: 'weekly',
      doubleProgression: 'reps_then_load',
      nextCheckWeek: 4,
      triggers: const [],
    ),
    mealPlan: MealPlan(
      meals: meals,
      totalKcal: 2200,
      totalProteinG: 160,
      totalFatG: 60,
      totalCarbsG: 250,
      foodExamples: foodExamples,
    ),
    supplements: SupplementResult(const []),
    weeklyVolumePerGroup: const {},
  );
}

SessionResult _session({
  required String type,
  List<ExerciseEntry> exercises = const [],
}) {
  return SessionResult(
    day: '周一',
    type: type,
    durationMin: type == 'rest' ? 0 : 40,
    exercises: exercises,
    totalSets: exercises.fold(0, (sum, e) => sum + e.sets),
  );
}

ExerciseEntry _move(String name, {int sets = 3, String reps = '8-10', int restSec = 90}) {
  return ExerciseEntry(
    name: name,
    nameEn: name,
    exerciseId: name,
    sets: sets,
    reps: reps,
    load: 'RPE 7',
    restSec: restSec,
    rpe: 7,
    tempo: '2010',
    notes: '',
    order: 1,
  );
}

void main() {
  test('kcalForSlot prefers named engine meals over an even split', () {
    final goals = DietGoals(
      kcal: 1800,
      proteinG: 140,
      carbG: 180,
      fatG: 50,
      recipeGoal: RecipeGoal.cut,
      meals: [
        Meal(name: '早餐', kcal: 400, proteinG: 30, fatG: 10, carbsG: 40),
        Meal(name: '午餐', kcal: 550, proteinG: 40, fatG: 15, carbsG: 55),
      ],
    );

    expect(goals.kcalForSlot(MealSlot.breakfast), 400);
    expect(goals.kcalForSlot(MealSlot.lunch), 550);
    expect(goals.kcalForSlot(MealSlot.dinner), 450);
  });

  test('recipe pool follows the engine goal', () {
    const cut = DietGoals(
      kcal: 1600,
      proteinG: 130,
      carbG: 140,
      fatG: 45,
      recipeGoal: RecipeGoal.cut,
      meals: [],
    );
    expect(cut.recommendedRecipes(), isNotEmpty);
    expect(
      cut.recommendedRecipes().every(
        (r) => r.goal == RecipeGoal.cut || r.goal == RecipeGoal.recommend,
      ),
      isTrue,
    );
  });

  test('fromPlan maps macros, meals and hypertrophy onto bulk recipes', () {
    final goals = DietGoals.fromPlan(
      _stubPlan(
        goal: 'hypertrophy',
        sessions: [_session(type: 'rest')],
        meals: [Meal(name: '早餐', kcal: 480, proteinG: 36, fatG: 12, carbsG: 50)],
        dailyTargets: const {
          'kcal': 2340,
          'protein_g': 155,
          'fat_g': 62,
          'carbs_g': 268,
        },
      ),
    );

    expect(goals.kcal, 2340);
    expect(goals.proteinG, 155);
    expect(goals.recipeGoal, RecipeGoal.bulk);
    expect(goals.kcalForSlot(MealSlot.breakfast), 480);
  });

  test('foodExampleFor picks the closest protein example', () {
    final goals = DietGoals(
      kcal: 1800,
      proteinG: 140,
      carbG: 180,
      fatG: 50,
      recipeGoal: RecipeGoal.cut,
      meals: [Meal(name: '早餐', kcal: 400, proteinG: 33, fatG: 10, carbsG: 40)],
      foodExamples: const {
        '20g_protein': '鸡蛋 3个',
        '35g_protein': '鸡胸肉 150g',
        '40g_protein': '鸡胸肉 170g',
      },
    );

    expect(goals.foodExampleFor(MealSlot.breakfast), '鸡胸肉 150g');
    expect(goals.foodExampleFor(MealSlot.dinner), isNull);
  });

  test('applyToday expands today\'s session into the live set queue', () {
    final todayIndex = DateTime.now().weekday - 1;
    final sessions = [
      for (var i = 0; i < 7; i++)
        i == todayIndex
            ? _session(
                type: 'push',
                exercises: [_move('哑铃卧推', sets: 3, reps: '8-10', restSec: 90)],
              )
            : _session(type: 'rest'),
    ];
    final controller = WorkoutSessionController()
      ..applyToday(_stubPlan(goal: 'hypertrophy', sessions: sessions));

    expect(controller.isRestDay, isFalse);
    expect(controller.canStart, isTrue);
    expect(controller.totalSets, 3);
    expect(controller.exerciseName, '哑铃卧推');
    expect(controller.targetReps, 10);
    expect(controller.plans.first.restMs, 90000);
    controller.dispose();
  });

  test('applyToday refuses to start a dummy workout on rest days', () {
    final sessions = [for (var i = 0; i < 7; i++) _session(type: 'rest')];
    final controller = WorkoutSessionController()
      ..applyToday(_stubPlan(goal: 'fat_loss', sessions: sessions));

    expect(controller.isRestDay, isTrue);
    expect(controller.canStart, isFalse);
    expect(controller.plans, isEmpty);
    expect(controller.previewCue, '按计划恢复');
    controller.dispose();
  });
}
