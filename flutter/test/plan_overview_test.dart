import 'package:flutter_test/flutter_test.dart';
import 'package:rest_pod_hud/models/workout_log.dart';
import 'package:rest_pod_hud/planner/models.dart';
import 'package:rest_pod_hud/planner/plan_overview.dart';
import 'package:rest_pod_hud/planner/stage_goal_planner.dart';

GeneratedPlan _plan({
  required DateTime generatedAt,
  List<String>? injuries,
  String goal = 'hypertrophy',
}) {
  final profile = UserProfile(
    gender: 'M',
    age: 28,
    heightCm: 178,
    weightKg: 76,
    level: 'beginner',
    goal: goal,
    daysPerWeek: 3,
    minutesPerSession: 45,
    equipment: const ['barbell', 'bodyweight'],
    injuries: injuries ?? const [],
  );
  final sessions = [
    SessionResult(
      day: '周一',
      type: 'upper',
      durationMin: 42,
      totalSets: 18,
      exercises: [
        ExerciseEntry(
          name: '杠铃卧推',
          nameEn: 'bench',
          exerciseId: 'bench_press',
          sets: 4,
          reps: '5',
          load: '70kg',
          restSec: 150,
          rpe: 8,
          tempo: '受控',
          notes: '',
          order: 1,
          compound: true,
        ),
        ExerciseEntry(
          name: '绳索面拉',
          nameEn: 'face_pull',
          exerciseId: 'face_pull',
          sets: 3,
          reps: '12',
          load: 'bodyweight',
          restSec: 60,
          rpe: 7,
          tempo: '受控',
          notes: '',
          order: 2,
        ),
      ],
    ),
    SessionResult(day: '周二', type: 'rest', durationMin: 0, exercises: const [], totalSets: 0),
    SessionResult(
      day: '周三',
      type: 'lower',
      durationMin: 40,
      totalSets: 16,
      exercises: [
        ExerciseEntry(
          name: '杠铃深蹲',
          nameEn: 'squat',
          exerciseId: 'barbell_squat',
          sets: 4,
          reps: '6',
          load: '80kg',
          restSec: 150,
          rpe: 8,
          tempo: '受控',
          notes: '',
          order: 1,
          compound: true,
        ),
      ],
    ),
    SessionResult(day: '周四', type: 'rest', durationMin: 0, exercises: const [], totalSets: 0),
    SessionResult(
      day: '周五',
      type: 'full_body',
      durationMin: 38,
      totalSets: 14,
      exercises: [
        ExerciseEntry(
          name: '徒手深蹲',
          nameEn: 'squat',
          exerciseId: 'bodyweight_squat',
          sets: 3,
          reps: '12',
          load: 'bodyweight',
          restSec: 90,
          rpe: 7,
          tempo: '受控',
          notes: '',
          order: 1,
        ),
      ],
    ),
    SessionResult(day: '周六', type: 'rest', durationMin: 0, exercises: const [], totalSets: 0),
    SessionResult(day: '周日', type: 'rest', durationMin: 0, exercises: const [], totalSets: 0),
  ];
  final progression = ProgressionResult(
    strategy: 'linear_weekly',
    incrementUpperKg: 2.5,
    incrementLowerKg: 5,
    progressionFreq: '每周',
    doubleProgression: 'reps_then_load',
    nextCheckWeek: 4,
    triggers: const [],
  );
  return GeneratedPlan(
    generatedAt: generatedAt,
    profile: profile,
    tdee: TDEEResult(
      bmr: 1700,
      tdee: 2300,
      formulaUsed: 'mifflin_st_jeor',
      activityMultiplier: 1.375,
      activityLevel: 'light',
    ),
    macros: MacroResult(
      dailyTargets: const {'kcal': 2650, 'protein_g': 150, 'fat_g': 70, 'carbs_g': 320},
      perKg: const {'protein': 2.0, 'fat': 1.0, 'carbs': 4.0},
      surplusKcal: 350,
      goal: goal,
    ),
    split: SplitResult(splitName: '全身', weeklySchedule: const [], warnings: const []),
    sessions: sessions,
    progression: progression,
    mealPlan: MealPlan(
      meals: const [],
      totalKcal: 2650,
      totalProteinG: 150,
      totalFatG: 70,
      totalCarbsG: 320,
      foodExamples: const {},
    ),
    supplements: SupplementResult(const []),
    weeklyVolumePerGroup: const {},
    stageGoal: planStageGoal(profile, progression, sessions),
  );
}

void main() {
  final start = DateTime(2026, 8, 4); // Tuesday

  test('overview exposes cycle status, weekly rhythm and engine reasons', () {
    final plan = _plan(generatedAt: start);
    final overview = PlanOverview.from(plan: plan, now: DateTime(2026, 8, 13)); // Thursday week 2
    expect(overview.currentWeek, 2);
    expect(overview.cycleWeeks, 4);
    expect(overview.stageTitle, '适应阶段');
    expect(overview.cycleTargetLabel, contains('杠铃卧推'));
    expect(overview.weekDays, hasLength(7));
    expect(overview.weekDays[3].isToday, isTrue);
    expect(overview.weekDays[3].isRest, isTrue);
    expect(overview.today.isRest, isTrue);
    expect(overview.reasons.first.text, contains('每周 3 次'));
    expect(overview.review.conclusionTitle, '继续观察');
    expect(overview.review.changes.map((change) => change.value), contains('+2.5 kg'));
  });

  test('missing body data stays 继续观察 instead of failure copy', () {
    final plan = _plan(generatedAt: start);
    final overview = PlanOverview.from(plan: plan, now: DateTime(2026, 8, 13));
    expect(overview.review.intensityLabel, '继续观察');
    expect(overview.review.weightTrendLabel, '继续观察');
    expect(overview.review.conclusionBody, contains('继续观察'));
    expect(overview.review.conclusionBody, isNot(contains('失败')));
  });

  test('injuries become caution copy and completion uses local logs', () {
    final plan = _plan(generatedAt: start, injuries: const ['shoulder']);
    final logs = [
      WorkoutLogEntry(
        id: '1',
        title: '上肢',
        timestampMs: DateTime(2026, 8, 10).millisecondsSinceEpoch,
        durationMs: 40 * 60000,
        completedSets: 18,
        totalSets: 18,
        estimatedKcal: 220,
      ),
    ];
    final overview = PlanOverview.from(
      plan: plan,
      logs: logs,
      now: DateTime(2026, 8, 13),
    );
    expect(overview.reasons.any((reason) => reason.caution), isTrue);
    expect(overview.review.painCaution, isTrue);
    expect(overview.review.completionKnown, isTrue);
    expect(overview.review.completionPct, greaterThan(0));
    expect(overview.review.cautionBody, contains('伤病'));
  });

  test('week 4 marks review due so the next-stage CTA can open', () {
    final plan = _plan(generatedAt: start);
    final overview = PlanOverview.from(plan: plan, now: DateTime(2026, 8, 25));
    expect(overview.review.reviewDue, isTrue);
    expect(overview.review.adoptEnabled, isTrue);
  });
}
