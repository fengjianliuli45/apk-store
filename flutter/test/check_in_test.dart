import 'package:flutter_test/flutter_test.dart';
import 'package:rest_pod_hud/planner/check_in.dart';
import 'package:rest_pod_hud/planner/models.dart';
import 'package:rest_pod_hud/planner/plan_copy.dart';

GeneratedPlan _plan({required DateTime generatedAt, int nextCheckWeek = 4}) {
  return GeneratedPlan(
    generatedAt: generatedAt,
    profile: UserProfile(
      gender: 'F',
      age: 26,
      heightCm: 165,
      weightKg: 55,
      level: 'beginner',
      goal: 'hypertrophy',
      daysPerWeek: 3,
      minutesPerSession: 45,
      equipment: const ['bodyweight'],
    ),
    tdee: TDEEResult(
      bmr: 1400,
      tdee: 1900,
      formulaUsed: 'mifflin_st_jeor',
      activityMultiplier: 1.375,
      activityLevel: 'light',
    ),
    macros: MacroResult(
      dailyTargets: const {'kcal': 2000, 'protein_g': 140, 'fat_g': 55, 'carbs_g': 220},
      perKg: const {'protein': 2.5, 'fat': 1.0, 'carbs': 4.0},
      surplusKcal: 200,
      goal: 'hypertrophy',
    ),
    split: SplitResult(splitName: '全身', weeklySchedule: const [], warnings: const []),
    sessions: const [],
    progression: ProgressionResult(
      strategy: 'linear_weekly',
      incrementUpperKg: 2.5,
      incrementLowerKg: 5,
      progressionFreq: '每周',
      doubleProgression: 'reps_then_load',
      nextCheckWeek: nextCheckWeek,
      triggers: const [],
    ),
    mealPlan: MealPlan(
      meals: const [],
      totalKcal: 2000,
      totalProteinG: 140,
      totalFatG: 55,
      totalCarbsG: 220,
    ),
    supplements: SupplementResult(const []),
    weeklyVolumePerGroup: const {},
  );
}

void main() {
  final start = DateTime(2026, 8, 1);

  test('week 1–3 are not check-in weeks', () {
    final plan = _plan(generatedAt: start);
    expect(planWeekNumber(start, DateTime(2026, 8, 3)), 1);
    expect(checkInDue(plan, now: DateTime(2026, 8, 21)), isFalse);
  });

  test('week 4 and 8 are due; week 5 is not', () {
    final plan = _plan(generatedAt: start);
    expect(planWeekNumber(start, DateTime(2026, 8, 22)), 4);
    expect(checkInDue(plan, now: DateTime(2026, 8, 22)), isTrue);
    expect(checkInDue(plan, now: DateTime(2026, 8, 29)), isFalse);
    expect(planWeekNumber(start, DateTime(2026, 9, 19)), 8);
    expect(checkInDue(plan, now: DateTime(2026, 9, 19)), isTrue);
  });

  test('dismissing week 4 does not re-prompt until the next cycle', () {
    final plan = _plan(generatedAt: start);
    final at = plan.generatedAt.toIso8601String();
    expect(
      shouldPromptCheckIn(
        plan: plan,
        promptedGeneratedAt: at,
        promptedWeek: 4,
        now: DateTime(2026, 8, 22),
      ),
      isFalse,
    );
    expect(
      shouldPromptCheckIn(
        plan: plan,
        promptedGeneratedAt: at,
        promptedWeek: 4,
        now: DateTime(2026, 9, 19),
      ),
      isTrue,
    );
  });

  test('a newly generated plan can prompt again on its own week 4', () {
    final old = _plan(generatedAt: start);
    final fresh = _plan(generatedAt: DateTime(2026, 9, 1));
    expect(
      shouldPromptCheckIn(
        plan: fresh,
        promptedGeneratedAt: old.generatedAt.toIso8601String(),
        promptedWeek: 4,
        now: DateTime(2026, 9, 22),
      ),
      isTrue,
    );
  });
}
