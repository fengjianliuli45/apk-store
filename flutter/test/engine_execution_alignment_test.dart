import 'package:flutter_test/flutter_test.dart';
import 'package:rest_pod_hud/planner/planner_gateway.dart';
import 'package:rest_pod_hud/planner/plan_adapter.dart';
import 'package:rest_pod_hud/planner/plan_sync.dart';
import 'package:rest_pod_hud/state/workout_session_controller.dart';
import 'package:rest_pod_hud/state/goal_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rest_pod_hud/models/meal.dart';
import 'package:rest_pod_hud/planner/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('four engine goals are exact; legacy unsupported preference requires selection', () async {
    expect(engineSupportedGoals.map((g) => g.engineGoal).toSet(), {
      'hypertrophy',
      'fat_loss',
      'strength',
      'recomposition',
    });
    SharedPreferences.setMockInitialValues({'fitness_goal': 'recovery'});
    final goals = GoalController();
    addTearDown(goals.dispose);
    await goals.load();
    expect(goals.hasChosen, isFalse);
    expect(() => FitnessGoal.recovery.engineGoal, throwsStateError);
  });
  test(
    'snack budget sums all engine snack meals; constrained recipes fail closed',
    () {
      final goals = DietGoals(
        kcal: 2000,
        proteinG: 100,
        carbG: 250,
        fatG: 60,
        recipeGoal: RecipeGoal.maintain,
        dietaryRestrictions: ['no_dairy'],
        meals: [
          Meal(name: '早加餐', kcal: 200, proteinG: 10, fatG: 5, carbsG: 20),
          Meal(name: '晚加餐', kcal: 300, proteinG: 20, fatG: 5, carbsG: 30),
        ],
      );
      expect(goals.kcalForSlot(MealSlot.snack), 500);
      expect(goals.mealForSlot(MealSlot.snack)!.proteinG, 30);
      expect(goals.recommendedRecipes(), isEmpty);
    },
  );
  test(
    'engine weekly overrides reach the execution adapter without mutating base',
    () async {
      final gateway = await PlannerGateway.instance();
      final plan = gateway.generate({
        'gender': 'M',
        'age': 28,
        'height_cm': 178,
        'weight_kg': 80,
        'level': 'intermediate',
        'goal': 'hypertrophy',
        'minutes_per_session': 75,
        'equipment': ['dumbbell'],
        'injuries': ['knee'],
        'dietary_restrictions': ['no_dairy'],
        'cooking_access': 'canteen',
        'volume_cycle_offset': 1,
        'kcal_adjust': 100,
        'exercise_cycle_offset': 2,
        'bodyweight_progress': {'squat': 1},
      });
      final original = plan.toJson().toString();
      for (final week in plan.mesocycle!.weeks) {
        final at = plan.generatedAt.add(Duration(days: (week.week - 1) * 7));
        var total = 0;
        for (final base in plan.sessions) {
          final actual = sessionForWeek(plan, base, at);
          total += actual.totalSets;
          for (final move in actual.exercises) {
            expect(move.sets, week.setOverrides[base.day]![move.exerciseId]);
            expect(move.notes, contains('RIR ${week.rirTarget}'));
            expect(
              move.restSec,
              base.exercises
                  .firstWhere((e) => e.exerciseId == move.exerciseId)
                  .restSec,
            );
          }
        }
        expect(total, week.weekTotalSets);
      }
      expect(plan.toJson().toString(), original);
      expect(
        weekForDate(
          plan,
          plan.generatedAt.add(const Duration(days: 500)),
        )!.isDeload,
        isTrue,
      );
      final restored = profileFieldsFrom(plan.profile);
      expect(restored['injuries'], plan.profile.injuries);
      expect(restored['dietary_restrictions'], ['no_dairy']);
      expect(restored['cooking_access'], 'canteen');
      expect(restored['volume_cycle_offset'], 1);
      expect(restored['kcal_adjust'], 100);
      expect(restored['exercise_cycle_offset'], 2);
      expect(restored['bodyweight_progress'], {'squat': 1});
    },
  );

  test(
    'tempo countdown is estimated, pauses and never fabricates completion',
    () {
      final controller = WorkoutSessionController();
      addTearDown(controller.dispose);
      controller.plans = [const SetPlan('squat', '深蹲', 12, tempo: '3-1-2-0')];
      controller.startSession();
      controller.startSet();
      expect(controller.estimatedWorkMs, 72000);
      expect(controller.timerText, '01:12.00');
      controller.setElapsedMs = 12000;
      expect(controller.timerText, '01:00.00');
      controller.setElapsedMs = 80000;
      expect(controller.timerText, '00:00.00');
      expect(controller.phase, WorkoutPhase.active);
      expect(controller.completedSets, 0);
      expect(controller.completedReps, 0);
      expect(const SetPlan('x', 'x', 6, tempo: '受控').estimatedWorkMs, isNull);
    },
  );
}
