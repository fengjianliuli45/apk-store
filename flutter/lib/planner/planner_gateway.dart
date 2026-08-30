import 'exercise_library.dart';
import 'frequency_planner.dart';
import 'injury_planner.dart';
import 'macro_allocator.dart';
import 'meal_distributor.dart';
import 'check_in_engine.dart';
import 'models.dart';
import 'profile_validator.dart';
import 'load_planner.dart';
import 'mesocycle_planner.dart';
import 'progression_planner.dart';
import 'recovery_planner.dart';
import 'schedule_planner.dart';
import 'session_builder.dart';
import 'split_selector.dart';
import 'supplement_advisor.dart';
import 'tdee_calculator.dart';
import 'stage_goal_planner.dart';

/// Single entry point into the ported fitness-planner engine — this is the
/// `PlannerGateway` referenced by docs/Stopwatch-app-design-blueprint-v2.md
/// §14.2 ("UI 只经 PlannerGateway 取计划，不直接依赖 Python 结构"). UI code
/// should only ever call [PlannerGateway.generate]; it should never import
/// the individual planner/*.dart modules directly.
class PlannerGateway {
  PlannerGateway._(this._library);

  final ExerciseLibrary _library;

  static PlannerGateway? _instance;

  /// Loads the (cached) exercise library asset and returns a ready gateway.
  static Future<PlannerGateway> instance() async {
    return _instance ??= PlannerGateway._(await ExerciseLibrary.load());
  }

  /// onboarding: 用户选完 目标/水平/器械 后，用这个拿「每次最少练多少分钟」，
  /// 把时长选项的下限设成它——不要给更短的选项再事后上调。
  int minSessionMinutes({
    required String level,
    required String goal,
    required List<String> equipment,
  }) =>
      minSessionMinutesFor(level, goal, equipment, _library);

  /// Runs the full pipeline: validate → frequency → TDEE → macros → split →
  /// sessions → progression → meals → supplements → assembled plan. Throws
  /// [ValidationError] if `raw` is missing/out-of-range required fields.
  /// 中周期边界：评估上一个周期的训练日志 → 产出下一份计划。
  /// 返回 {'review': {...}, 'next_plan': {...}|null}（address_safety 时 next_plan 为 null）。
  Map<String, dynamic> runCheckIn(
    Map<String, dynamic> planJson,
    List<Map<String, dynamic>> workoutLog, {
    List<Map<String, dynamic>> bodyLog = const [],
    int completedCycles = 0,
  }) {
    final review = reviewCycle(planJson, workoutLog,
        bodyLog: bodyLog, completedCycles: completedCycles, library: _library);
    Map<String, dynamic>? nextPlan;
    if (review.verdict != 'address_safety' && review.nextRaw.isNotEmpty) {
      nextPlan = generate(review.nextRaw).toJson();
    }
    return {'review': review.toJson(), 'next_plan': nextPlan};
  }

  GeneratedPlan generate(Map<String, dynamic> raw) {
    final validated = validateProfile(raw);
    final (profile, freqPlan) = resolveFrequency(validated, _library);
    final tdee = calculateTdee(profile);
    final macros = allocateMacros(profile, tdee);
    final split = reschedule(profile, selectSplit(profile));
    final sessions = buildSessions(profile, split, _library);
    final progression = planProgression(profile);
    final mealPlan = distributeMeals(profile, macros);
    final supplements = adviseSupplements(profile, macros);
    final stageGoal = planStageGoal(profile, progression, sessions);
    final volumeReport = analyzeVolume(profile, split, sessions);
    final recoveryDays = planRecovery(profile, split, volumeReport);
    final mesocycle = planMesocycle(profile, sessions, progression,
        surplusKcal: macros.surplusKcal);
    final injuryAcc = injuryBlock(profile, volumeReport, sessions, _library);

    return GeneratedPlan(
      generatedAt: DateTime.now().toUtc(),
      profile: profile,
      tdee: tdee,
      macros: macros,
      split: split,
      sessions: sessions,
      progression: progression,
      mealPlan: mealPlan,
      supplements: supplements,
      weeklyVolumePerGroup:
          Map<String, num>.from(volumeReport['target'] as Map),
      stageGoal: stageGoal,
      weeklyVolumeOptimal:
          Map<String, num>.from(volumeReport['optimal'] as Map),
      weeklyVolumeDelivered:
          Map<String, num>.from(volumeReport['delivered'] as Map),
      volumeCoveragePct: volumeReport['coverage_pct'] as int,
      vsOptimalPct: volumeReport['vs_optimal_pct'] as int,
      volumeNotes: List<String>.from(volumeReport['notes'] as List),
      capacityRecommendation:
          Map<String, dynamic>.from(volumeReport['recommendation'] as Map),
      frequencyPlan: freqPlan.toJson(),
      recoveryDays: recoveryDays,
      mesocycle: mesocycle,
      oneRmEstimates: {
        for (final e in buildOneRmMap(profile.strengthBaseline).entries)
          e.key: {'kg': e.value, 'name': baselineCn[e.key] ?? e.key},
      },
      injuryAccommodations: injuryAcc,
    );
  }
}
