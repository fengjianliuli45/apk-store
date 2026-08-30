import 'exercise_library.dart';
import 'frequency_planner.dart';
import 'macro_allocator.dart';
import 'meal_distributor.dart';
import 'models.dart';
import 'profile_validator.dart';
import 'progression_planner.dart';
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

  /// Runs the full pipeline: validate → frequency → TDEE → macros → split →
  /// sessions → progression → meals → supplements → assembled plan. Throws
  /// [ValidationError] if `raw` is missing/out-of-range required fields.
  GeneratedPlan generate(Map<String, dynamic> raw) {
    final validated = validateProfile(raw);
    final (profile, freqPlan) = resolveFrequency(validated, _library);
    final tdee = calculateTdee(profile);
    final macros = allocateMacros(profile, tdee);
    final split = selectSplit(profile);
    final sessions = buildSessions(profile, split, _library);
    final progression = planProgression(profile);
    final mealPlan = distributeMeals(profile, macros);
    final supplements = adviseSupplements(profile, macros);
    final volume = weeklyVolumeFor(profile.level, profile.goal);
    final stageGoal = planStageGoal(profile, progression, sessions);
    final volumeReport = analyzeVolume(profile, split, sessions);

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
      weeklyVolumePerGroup: volume,
      stageGoal: stageGoal,
      weeklyVolumeDelivered:
          Map<String, num>.from(volumeReport['delivered'] as Map),
      volumeCoveragePct: volumeReport['coverage_pct'] as int,
      volumeNotes: List<String>.from(volumeReport['notes'] as List),
      capacityRecommendation:
          Map<String, dynamic>.from(volumeReport['recommendation'] as Map),
      frequencyPlan: freqPlan.toJson(),
    );
  }
}
