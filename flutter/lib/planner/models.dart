/// Dart port of the `fitness-planner` Python engine's dataclasses
/// (github.com/fengjianliuli45/fitness-planner). Ported instead of called
/// over the network so plan generation works fully offline (see
/// docs/Stopwatch-app-design-blueprint-v2.md §14.3 "offline-first").
library;

// ── profile_validator ──────────────────────────────────────────────

const validGenders = ['M', 'F'];
const validLevels = ['beginner', 'intermediate', 'advanced'];
const validGoals = ['hypertrophy', 'fat_loss', 'strength', 'recomposition'];
const validCooking = ['home', 'canteen', 'none'];

class ValidationError implements Exception {
  ValidationError(this.errors);
  final List<String> errors;

  @override
  String toString() =>
      'Profile validation failed:\n${errors.map((e) => '  - $e').join('\n')}';
}

class UserProfile {
  UserProfile({
    required this.gender,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.level,
    required this.goal,
    required this.minutesPerSession,
    required this.equipment,
    this.daysPerWeek,
    this.bodyFatPct,
    this.mealsPerDay = 4,
    List<String>? supplements,
    this.targetWeightKg,
    List<String>? injuries,
    List<String>? dietaryRestrictions,
    this.cookingAccess = 'home',
    Map<String, dynamic>? strengthBaseline,
    List<String>? warnings,
    List<String>? notes,
  }) : supplements = supplements ?? ['creatine'],
       injuries = injuries ?? [],
       dietaryRestrictions = dietaryRestrictions ?? [],
       strengthBaseline = strengthBaseline ?? {},
       warnings = warnings ?? [],
       notes = notes ?? [];

  final String gender;
  final int age;
  final double heightCm;
  final double weightKg;
  final String level;
  final String goal;
  final int? daysPerWeek;   // null → 由 frequencyPlanner 推导
  final int minutesPerSession;
  final List<String> equipment;
  final double? bodyFatPct;
  final int mealsPerDay;
  final List<String> supplements;
  final double? targetWeightKg;
  final List<String> injuries;
  final List<String> dietaryRestrictions;
  final String cookingAccess;
  final Map<String, dynamic> strengthBaseline; // {basis: {weight_kg,reps} | {one_rm_kg}}
  final List<String> warnings;
  final List<String> notes;

  double get bmi {
    final h = heightCm / 100;
    return double.parse((weightKg / (h * h)).toStringAsFixed(1));
  }

  double get leanMassKg {
    if (bodyFatPct != null) return weightKg * (1 - bodyFatPct! / 100);
    return weightKg;
  }

  Map<String, dynamic> toJson() => {
    'gender': gender,
    'age': age,
    'height_cm': heightCm,
    'weight_kg': weightKg,
    'bmi': bmi,
    'body_fat_pct': bodyFatPct,
    'level': level,
    'goal': goal,
    'days_per_week': daysPerWeek,
    'minutes_per_session': minutesPerSession,
    'equipment': equipment,
    'meals_per_day': mealsPerDay,
    'target_weight_kg': targetWeightKg,
    'strength_baseline': strengthBaseline,
    'injuries': injuries,
    'warnings': warnings,
    'notes': notes,
  };
}

// ── tdee_calculator ────────────────────────────────────────────────

class TDEEResult {
  TDEEResult({
    required this.bmr,
    required this.tdee,
    required this.formulaUsed,
    required this.activityMultiplier,
    required this.activityLevel,
  });

  final double bmr;
  final double tdee;
  final String formulaUsed;
  final double activityMultiplier;
  final String activityLevel;

  Map<String, dynamic> toJson() => {
    'bmr': double.parse(bmr.toStringAsFixed(1)),
    'tdee': double.parse(tdee.toStringAsFixed(1)),
    'formula_used': formulaUsed,
    'activity_multiplier': activityMultiplier,
    'activity_level': activityLevel,
  };
}

// ── macro_allocator ────────────────────────────────────────────────

class MacroResult {
  MacroResult({
    required this.dailyTargets,
    required this.perKg,
    required this.surplusKcal,
    required this.goal,
  });

  final Map<String, num> dailyTargets; // kcal, protein_g, fat_g, carbs_g
  final Map<String, num> perKg; // protein, fat, carbs
  final int surplusKcal;
  final String goal;

  Map<String, dynamic> toJson() => {
    'daily_targets': dailyTargets,
    'per_kg': perKg,
    'surplus_kcal': surplusKcal,
    'goal': goal,
  };
}

// ── split_selector ─────────────────────────────────────────────────

class ScheduleDay {
  ScheduleDay({required this.day, required this.type});
  final String day;
  final String type;

  Map<String, dynamic> toJson() => {'day': day, 'type': type};
}

class SplitResult {
  SplitResult({
    required this.splitName,
    required this.weeklySchedule,
    required this.warnings,
  });

  final String splitName;
  final List<ScheduleDay> weeklySchedule;
  final List<String> warnings;

  Map<String, dynamic> toJson() => {
    'split_name': splitName,
    'weekly_schedule': weeklySchedule.map((d) => d.toJson()).toList(),
    'warnings': warnings,
  };
}

// ── exercise_library ───────────────────────────────────────────────

class Exercise {
  Exercise({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.movementPattern,
    required this.compound,
    required this.equipmentRequired,
    required this.skillLevel,
    required this.variations,
    required this.injuryContraindications,
    required this.alternativesIfInjured,
    required this.formCues,
    this.videoUrl,
  });

  final String id;
  final String name;
  final String nameEn;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final String movementPattern;
  final bool compound;
  final List<String> equipmentRequired;
  final String skillLevel;
  final List<String> variations;
  final List<String> injuryContraindications;
  final List<String> alternativesIfInjured;
  final List<String> formCues;
  final String? videoUrl;

  factory Exercise.fromJson(Map<String, dynamic> d) => Exercise(
    id: d['id'] as String,
    name: d['name'] as String,
    nameEn: (d['name_en'] as String?) ?? '',
    primaryMuscles: List<String>.from(
      d['primary_muscles'] as List? ?? const [],
    ),
    secondaryMuscles: List<String>.from(
      d['secondary_muscles'] as List? ?? const [],
    ),
    movementPattern: (d['movement_pattern'] as String?) ?? '',
    compound: (d['compound'] as bool?) ?? false,
    equipmentRequired: List<String>.from(
      d['equipment_required'] as List? ?? const [],
    ),
    skillLevel: (d['skill_level'] as String?) ?? 'beginner',
    variations: List<String>.from(d['variations'] as List? ?? const []),
    injuryContraindications: List<String>.from(
      d['injury_contraindications'] as List? ?? const [],
    ),
    alternativesIfInjured: List<String>.from(
      d['alternatives_if_injured'] as List? ?? const [],
    ),
    videoUrl: d['video_url'] as String?,
    formCues: List<String>.from(d['form_cues'] as List? ?? const []),
  );
}

// ── session_builder ────────────────────────────────────────────────

class ExerciseEntry {
  ExerciseEntry({
    required this.name,
    required this.nameEn,
    required this.exerciseId,
    required this.sets,
    required this.reps,
    required this.load,
    required this.restSec,
    required this.rpe,
    required this.tempo,
    required this.notes,
    required this.order,
    this.primaryMuscles = const [],
    this.compound = false,
    this.formCues = const [],
    this.targetMuscle = '',
    this.loadKg,
  });

  final String name;
  final String nameEn;
  final String exerciseId;
  final int sets;
  final String reps;
  final String load;
  final double? loadKg; // 有起始 1RM 时算出的建议重量；否则 null（首周找）
  final int restSec;
  final double rpe;
  final String tempo;
  final String notes;
  final int order;
  final List<String> primaryMuscles;
  final String targetMuscle;
  final bool compound;
  final List<String> formCues;

  Map<String, dynamic> toJson() => {
    'name': name,
    'name_en': nameEn,
    'exercise_id': exerciseId,
    'sets': sets,
    'reps': reps,
    'load': load,
    'load_kg': loadKg,
    'rest_sec': restSec,
    'rpe': rpe,
    'tempo': tempo,
    'notes': notes,
    'order': order,
    'primary_muscles': primaryMuscles,
    'compound': compound,
    'form_cues': formCues,
    'target_muscle': targetMuscle,
  };
}

class SessionResult {
  SessionResult({
    required this.day,
    required this.type,
    required this.durationMin,
    required this.exercises,
    required this.totalSets,
  });

  final String day;
  final String type;
  final int durationMin;
  final List<ExerciseEntry> exercises;
  final int totalSets;

  bool get isRest => type == 'rest';

  Map<String, dynamic> toJson() => {
    'day': day,
    'type': type,
    'duration_min': durationMin,
    'exercises': exercises.map((e) => e.toJson()).toList(),
    'total_sets': totalSets,
  };
}

// ── recovery_planner ───────────────────────────────────────────────

class RecoveryDay {
  RecoveryDay({
    required this.day,
    required this.kind,
    required this.durationMin,
    required this.title,
    required this.focus,
    this.items = const [],
  });

  final String day;
  final String kind; // rest | mobility | cardio | pump
  final int durationMin;
  final String title;
  final String focus;
  final List<String> items;

  Map<String, dynamic> toJson() => {
    'day': day,
    'kind': kind,
    'duration_min': durationMin,
    'title': title,
    'focus': focus,
    'items': items,
  };

  factory RecoveryDay.fromJson(Map<String, dynamic> m) => RecoveryDay(
    day: m['day'] as String,
    kind: m['kind'] as String,
    durationMin: (m['duration_min'] as num).toInt(),
    title: m['title'] as String,
    focus: m['focus'] as String,
    items: List<String>.from(m['items'] as List? ?? const []),
  );
}

// ── mesocycle_planner ─────────────────────────────────────────────

class WeekPlan {
  WeekPlan({
    required this.week,
    required this.phase,
    required this.rirTarget,
    required this.isDeload,
    required this.volumeMult,
    required this.setOverrides,
    required this.weekTotalSets,
  });

  final int week;
  final String phase;
  final int rirTarget;
  final bool isDeload;
  final double volumeMult;
  final Map<String, Map<String, int>> setOverrides;
  final int weekTotalSets;

  Map<String, dynamic> toJson() => {
    'week': week,
    'phase': phase,
    'rir_target': rirTarget,
    'is_deload': isDeload,
    'volume_mult': double.parse(volumeMult.toStringAsFixed(2)),
    'set_overrides': setOverrides,
    'week_total_sets': weekTotalSets,
  };

  factory WeekPlan.fromJson(Map<String, dynamic> m) => WeekPlan(
    week: m['week'] as int,
    phase: m['phase'] as String,
    rirTarget: m['rir_target'] as int,
    isDeload: m['is_deload'] as bool,
    volumeMult: (m['volume_mult'] as num).toDouble(),
    setOverrides: {
      for (final e in (m['set_overrides'] as Map).entries)
        e.key as String: {
          for (final x in (e.value as Map).entries)
            x.key as String: (x.value as num).toInt(),
        },
    },
    weekTotalSets: m['week_total_sets'] as int,
  );
}

class Mesocycle {
  Mesocycle({
    required this.lengthWeeks,
    required this.currentWeek,
    required this.weeks,
  });

  final int lengthWeeks;
  final int currentWeek;
  final List<WeekPlan> weeks;

  Map<String, dynamic> toJson() => {
    'length_weeks': lengthWeeks,
    'current_week': currentWeek,
    'weeks': weeks.map((w) => w.toJson()).toList(),
  };

  factory Mesocycle.fromJson(Map<String, dynamic> m) => Mesocycle(
    lengthWeeks: m['length_weeks'] as int,
    currentWeek: m['current_week'] as int,
    weeks: [
      for (final w in (m['weeks'] as List))
        WeekPlan.fromJson(w as Map<String, dynamic>),
    ],
  );
}

// ── progression_planner ────────────────────────────────────────────

class ReassessmentTrigger {
  ReassessmentTrigger({
    required this.condition,
    required this.action,
    this.week,
  });
  final String condition;
  final String action;
  final int? week;

  Map<String, dynamic> toJson() => {
    'condition': condition,
    'action': action,
    'week': week,
  };
}

class ProgressionResult {
  ProgressionResult({
    required this.strategy,
    required this.incrementUpperKg,
    required this.incrementLowerKg,
    required this.progressionFreq,
    required this.doubleProgression,
    required this.nextCheckWeek,
    required this.triggers,
    this.deloadEveryWeeks = 4,
    this.deloadVolumePct = 60,
    this.deloadNote = '',
  });

  final String strategy;
  final double incrementUpperKg;
  final double incrementLowerKg;
  final String progressionFreq;
  final String doubleProgression;
  final int nextCheckWeek;
  final int deloadEveryWeeks;
  final int deloadVolumePct;
  final String deloadNote;
  final List<ReassessmentTrigger> triggers;

  Map<String, dynamic> toJson() => {
    'strategy': strategy,
    'increment_upper_kg': incrementUpperKg,
    'increment_lower_kg': incrementLowerKg,
    'progression_freq': progressionFreq,
    'double_progression': doubleProgression,
    'next_check_week': nextCheckWeek,
    'deload_every_weeks': deloadEveryWeeks,
    'deload_volume_pct': deloadVolumePct,
    'deload_note': deloadNote,
    'reassessment_triggers': triggers.map((t) => t.toJson()).toList(),
  };
}

// ── first-stage adaptation goal ───────────────────────────────────

class OutcomeTarget {
  const OutcomeTarget({
    required this.metric,
    required this.threshold,
    required this.unit,
    required this.description,
    this.required = false,
  });

  final String metric;
  final double threshold;
  final String unit;
  final String description;
  final bool required;

  Map<String, dynamic> toJson() => {
    'metric': metric,
    'threshold': threshold,
    'unit': unit,
    'description': description,
    'required': required,
  };

  factory OutcomeTarget.fromJson(Map<String, dynamic> json) => OutcomeTarget(
    metric: json['metric'] as String,
    threshold: (json['threshold'] as num).toDouble(),
    unit: json['unit'] as String,
    description: json['description'] as String,
    required: (json['required'] as bool?) ?? false,
  );
}

class StageGoal {
  const StageGoal({
    required this.stageType,
    required this.goalType,
    required this.cycleWeeks,
    required this.plannedSessions,
    required this.requiredSessions,
    required this.adherenceTargetPct,
    required this.minimumActiveWeeks,
    required this.minimumComparableMeasurements,
    required this.outcomeTargets,
    required this.completionRule,
    this.unlockReward = 'pet_hatchling',
    this.baselineLifts = const [],
  });

  final String stageType;
  final String goalType;
  final int cycleWeeks;
  final int plannedSessions;
  final int requiredSessions;
  final int adherenceTargetPct;
  final int minimumActiveWeeks;
  final int minimumComparableMeasurements;
  final List<OutcomeTarget> outcomeTargets;
  final String completionRule;
  final String unlockReward;
  final List<Map<String, dynamic>> baselineLifts;

  Map<String, dynamic> toJson() => {
    'stage_type': stageType,
    'goal_type': goalType,
    'cycle_weeks': cycleWeeks,
    'planned_sessions': plannedSessions,
    'required_sessions': requiredSessions,
    'adherence_target_pct': adherenceTargetPct,
    'minimum_active_weeks': minimumActiveWeeks,
    'minimum_comparable_measurements': minimumComparableMeasurements,
    'outcome_targets': outcomeTargets.map((target) => target.toJson()).toList(),
    'completion_rule': completionRule,
    'unlock_reward': unlockReward,
    'baseline_lifts': baselineLifts,
  };

  factory StageGoal.fromJson(Map<String, dynamic> json) => StageGoal(
    stageType: json['stage_type'] as String,
    goalType: json['goal_type'] as String,
    cycleWeeks: json['cycle_weeks'] as int,
    plannedSessions: json['planned_sessions'] as int,
    requiredSessions: json['required_sessions'] as int,
    adherenceTargetPct: json['adherence_target_pct'] as int,
    minimumActiveWeeks: json['minimum_active_weeks'] as int,
    minimumComparableMeasurements:
        json['minimum_comparable_measurements'] as int,
    outcomeTargets: (json['outcome_targets'] as List? ?? const [])
        .map((target) => OutcomeTarget.fromJson(target as Map<String, dynamic>))
        .toList(),
    baselineLifts: [
      for (final b in (json['baseline_lifts'] as List? ?? const []))
        Map<String, dynamic>.from(b as Map),
    ],
    completionRule: (json['completion_rule'] as String?) ?? '',
    unlockReward: (json['unlock_reward'] as String?) ?? 'pet_hatchling',
  );
}

// ── meal_distributor ───────────────────────────────────────────────

class Meal {
  Meal({
    required this.name,
    required this.kcal,
    required this.proteinG,
    required this.fatG,
    required this.carbsG,
  });

  final String name;
  double kcal;
  double proteinG;
  double fatG;
  double carbsG;

  Map<String, dynamic> toJson() => {
    'name': name,
    'kcal': kcal.round(),
    'protein_g': double.parse(proteinG.toStringAsFixed(1)),
    'fat_g': double.parse(fatG.toStringAsFixed(1)),
    'carbs_g': double.parse(carbsG.toStringAsFixed(1)),
  };
}

class MealPlan {
  MealPlan({
    required this.meals,
    required this.totalKcal,
    required this.totalProteinG,
    required this.totalFatG,
    required this.totalCarbsG,
    required this.foodExamples,
  });

  final List<Meal> meals;
  final double totalKcal;
  final double totalProteinG;
  final double totalFatG;
  final double totalCarbsG;
  final Map<String, String> foodExamples;

  Map<String, dynamic> toJson() => {
    'meals': meals.map((m) => m.toJson()).toList(),
    'total_kcal': totalKcal.round(),
    'total_protein_g': double.parse(totalProteinG.toStringAsFixed(1)),
    'total_fat_g': double.parse(totalFatG.toStringAsFixed(1)),
    'total_carbs_g': double.parse(totalCarbsG.toStringAsFixed(1)),
    'food_examples': foodExamples,
  };
}

// ── supplement_advisor ─────────────────────────────────────────────

class Supplement {
  Supplement({
    required this.name,
    required this.nameEn,
    required this.dose,
    required this.condition,
    required this.note,
    this.pmid,
  });

  final String name;
  final String nameEn;
  final String dose;
  final String condition;
  final String note;
  final String? pmid;

  Map<String, dynamic> toJson() => {
    'name': name,
    'name_en': nameEn,
    'dose': dose,
    'condition': condition,
    'note': note,
    'pmid': pmid,
  };
}

class SupplementResult {
  SupplementResult(this.supplements);
  final List<Supplement> supplements;

  Map<String, dynamic> toJson() => {
    'supplements': supplements.map((s) => s.toJson()).toList(),
  };
}

// ── plan_output (aggregate) ────────────────────────────────────────

class GeneratedPlan {
  GeneratedPlan({
    required this.generatedAt,
    required this.profile,
    required this.tdee,
    required this.macros,
    required this.split,
    required this.sessions,
    required this.progression,
    required this.mealPlan,
    required this.supplements,
    required this.weeklyVolumePerGroup,
    this.stageGoal,
    this.weeklyVolumeDelivered = const {},
    this.volumeCoveragePct = 100,
    this.vsOptimalPct = 100,
    this.weeklyVolumeOptimal = const {},
    this.volumeNotes = const [],
    this.capacityRecommendation = const {},
    this.frequencyPlan = const {},
    this.recoveryDays = const [],
    this.oneRmEstimates = const {},
    this.mesocycle,
  });

  final DateTime generatedAt;
  final UserProfile profile;
  final TDEEResult tdee;
  final MacroResult macros;
  final SplitResult split;
  final List<SessionResult> sessions;
  final ProgressionResult progression;
  final MealPlan mealPlan;
  final SupplementResult supplements;
  final Map<String, num> weeklyVolumePerGroup;
  final StageGoal? stageGoal;

  /// 训练量对账。`weeklyVolumePerGroup` = 自适应目标（本计划承诺的量）；
  /// `weeklyVolumeOptimal` = 最优训练量 MAV；`volumeCoveragePct` 对自适应目标
  /// 通常 100；`vsOptimalPct` = 相当于最优的百分比。
  final Map<String, num> weeklyVolumeDelivered;
  final Map<String, num> weeklyVolumeOptimal;
  final int volumeCoveragePct;
  final int vsOptimalPct;
  final List<String> volumeNotes;
  final Map<String, dynamic> capacityRecommendation;

  /// 引擎定频率的结果（任务 ①.5）：天数、（可能上调的）时长、最低时长、说明。
  final Map<String, dynamic> frequencyPlan;

  /// 休息日的轻日安排（交付 2）：mobility / cardio / pump / rest。
  final List<RecoveryDay> recoveryDays;

  /// 中周期（任务 A/④）：积累期 + 减载周。
  final Mesocycle? mesocycle;

  /// 起始 1RM 估计（任务 ②）：{basis: {kg, name}}。
  final Map<String, dynamic> oneRmEstimates;

  Map<String, dynamic> toJson() => {
    'meta': {'version': '1.7', 'generated_at': generatedAt.toIso8601String()},
    'profile': {
      ...profile.toJson(),
      'one_rm_estimates': oneRmEstimates,
    },
    'nutrition': {
      'tdee': tdee.toJson(),
      'macros': macros.toJson(),
      'meals': mealPlan.toJson(),
      'supplements': supplements.toJson()['supplements'],
    },
    'training': {
      'split': split.splitName,
      'weekly_volume_target': weeklyVolumePerGroup,
      'weekly_volume_optimal': weeklyVolumeOptimal,
      'weekly_volume_per_group': weeklyVolumePerGroup,
      'weekly_volume_delivered': weeklyVolumeDelivered,
      'volume_coverage_pct': volumeCoveragePct,
      'vs_optimal_pct': vsOptimalPct,
      'volume_notes': volumeNotes,
      'capacity_recommendation': capacityRecommendation,
      'frequency_plan': frequencyPlan.isEmpty ? null : frequencyPlan,
      'recovery_days': recoveryDays.map((r) => r.toJson()).toList(),
      'mesocycle': mesocycle?.toJson(),
      'schedule': sessions.map((s) => s.toJson()).toList(),
      'progression': progression.toJson(),
      'split_warnings': split.warnings,
    },
    if (stageGoal != null) 'stage_goal': stageGoal!.toJson(),
  };

  factory GeneratedPlan.fromJson(Map<String, dynamic> json) {
    final profileJson = json['profile'] as Map<String, dynamic>;
    final nutrition = json['nutrition'] as Map<String, dynamic>;
    final training = json['training'] as Map<String, dynamic>;
    final tdeeJson = nutrition['tdee'] as Map<String, dynamic>;
    final macrosJson = nutrition['macros'] as Map<String, dynamic>;
    final mealsJson = nutrition['meals'] as Map<String, dynamic>;
    final progressionJson = training['progression'] as Map<String, dynamic>;

    return GeneratedPlan(
      generatedAt: DateTime.parse(
        (json['meta'] as Map<String, dynamic>)['generated_at'] as String,
      ),
      profile: UserProfile(
        gender: profileJson['gender'] as String,
        age: profileJson['age'] as int,
        heightCm: (profileJson['height_cm'] as num).toDouble(),
        weightKg: (profileJson['weight_kg'] as num).toDouble(),
        level: profileJson['level'] as String,
        goal: profileJson['goal'] as String,
        daysPerWeek: (profileJson['days_per_week'] as num?)?.toInt(),
        minutesPerSession: profileJson['minutes_per_session'] as int,
        equipment: List<String>.from(profileJson['equipment'] as List),
        bodyFatPct: (profileJson['body_fat_pct'] as num?)?.toDouble(),
        mealsPerDay: (profileJson['meals_per_day'] as num?)?.toInt() ?? 4,
        targetWeightKg: (profileJson['target_weight_kg'] as num?)?.toDouble(),
        strengthBaseline: Map<String, dynamic>.from(
          profileJson['strength_baseline'] as Map? ?? const {},
        ),
        injuries: List<String>.from(
          profileJson['injuries'] as List? ?? const [],
        ),
        warnings: List<String>.from(
          profileJson['warnings'] as List? ?? const [],
        ),
        notes: List<String>.from(profileJson['notes'] as List? ?? const []),
      ),
      tdee: TDEEResult(
        bmr: (tdeeJson['bmr'] as num).toDouble(),
        tdee: (tdeeJson['tdee'] as num).toDouble(),
        formulaUsed: tdeeJson['formula_used'] as String,
        activityMultiplier: (tdeeJson['activity_multiplier'] as num).toDouble(),
        activityLevel: tdeeJson['activity_level'] as String,
      ),
      macros: MacroResult(
        dailyTargets: Map<String, num>.from(macrosJson['daily_targets'] as Map),
        perKg: Map<String, num>.from(macrosJson['per_kg'] as Map),
        surplusKcal: macrosJson['surplus_kcal'] as int,
        goal: macrosJson['goal'] as String,
      ),
      split: SplitResult(
        splitName: training['split'] as String,
        weeklySchedule: (training['schedule'] as List)
            .map(
              (s) => ScheduleDay(
                day: s['day'] as String,
                type: s['type'] as String,
              ),
            )
            .toList(),
        warnings: List<String>.from(
          training['split_warnings'] as List? ?? const [],
        ),
      ),
      sessions: (training['schedule'] as List).map((s) {
        final m = s as Map<String, dynamic>;
        return SessionResult(
          day: m['day'] as String,
          type: m['type'] as String,
          durationMin: m['duration_min'] as int,
          totalSets: m['total_sets'] as int,
          exercises: (m['exercises'] as List).map((e) {
            final ex = e as Map<String, dynamic>;
            return ExerciseEntry(
              name: ex['name'] as String,
              nameEn: ex['name_en'] as String,
              exerciseId: ex['exercise_id'] as String,
              sets: ex['sets'] as int,
              reps: ex['reps'] as String,
              load: ex['load'] as String,
              loadKg: (ex['load_kg'] as num?)?.toDouble(),
              restSec: ex['rest_sec'] as int,
              rpe: (ex['rpe'] as num).toDouble(),
              tempo: ex['tempo'] as String,
              notes: ex['notes'] as String,
              order: ex['order'] as int,
              primaryMuscles: List<String>.from(
                ex['primary_muscles'] as List? ?? const [],
              ),
              compound: (ex['compound'] as bool?) ?? false,
              formCues: List<String>.from(ex['form_cues'] as List? ?? const []),
              targetMuscle: (ex['target_muscle'] as String?) ?? '',
            );
          }).toList(),
        );
      }).toList(),
      progression: ProgressionResult(
        strategy: progressionJson['strategy'] as String,
        incrementUpperKg: (progressionJson['increment_upper_kg'] as num)
            .toDouble(),
        incrementLowerKg: (progressionJson['increment_lower_kg'] as num)
            .toDouble(),
        progressionFreq: progressionJson['progression_freq'] as String,
        doubleProgression: progressionJson['double_progression'] as String,
        nextCheckWeek: progressionJson['next_check_week'] as int,
        deloadEveryWeeks: (progressionJson['deload_every_weeks'] as int?) ?? 4,
        deloadVolumePct: (progressionJson['deload_volume_pct'] as int?) ?? 60,
        deloadNote: (progressionJson['deload_note'] as String?) ?? '',
        triggers: (progressionJson['reassessment_triggers'] as List)
            .map(
              (t) => ReassessmentTrigger(
                condition: t['condition'] as String,
                action: t['action'] as String,
                week: t['week'] as int?,
              ),
            )
            .toList(),
      ),
      mealPlan: MealPlan(
        meals: (mealsJson['meals'] as List)
            .map(
              (m) => Meal(
                name: m['name'] as String,
                kcal: (m['kcal'] as num).toDouble(),
                proteinG: (m['protein_g'] as num).toDouble(),
                fatG: (m['fat_g'] as num).toDouble(),
                carbsG: (m['carbs_g'] as num).toDouble(),
              ),
            )
            .toList(),
        totalKcal: (mealsJson['total_kcal'] as num).toDouble(),
        totalProteinG: (mealsJson['total_protein_g'] as num).toDouble(),
        totalFatG: (mealsJson['total_fat_g'] as num).toDouble(),
        totalCarbsG: (mealsJson['total_carbs_g'] as num).toDouble(),
        foodExamples: Map<String, String>.from(
          mealsJson['food_examples'] as Map? ?? const {},
        ),
      ),
      supplements: SupplementResult(
        (nutrition['supplements'] as List)
            .map(
              (s) => Supplement(
                name: s['name'] as String,
                nameEn: s['name_en'] as String,
                dose: s['dose'] as String,
                condition: s['condition'] as String,
                note: s['note'] as String,
                pmid: s['pmid'] as String?,
              ),
            )
            .toList(),
      ),
      weeklyVolumePerGroup: Map<String, num>.from(
        training['weekly_volume_per_group'] as Map,
      ),
      weeklyVolumeOptimal: Map<String, num>.from(
        training['weekly_volume_optimal'] as Map? ?? const {},
      ),
      weeklyVolumeDelivered: Map<String, num>.from(
        training['weekly_volume_delivered'] as Map? ?? const {},
      ),
      volumeCoveragePct: (training['volume_coverage_pct'] as num?)?.toInt() ?? 100,
      vsOptimalPct: (training['vs_optimal_pct'] as num?)?.toInt() ?? 100,
      volumeNotes: List<String>.from(
        training['volume_notes'] as List? ?? const [],
      ),
      capacityRecommendation: Map<String, dynamic>.from(
        training['capacity_recommendation'] as Map? ?? const {},
      ),
      frequencyPlan: Map<String, dynamic>.from(
        training['frequency_plan'] as Map? ?? const {},
      ),
      mesocycle: (training['mesocycle'] as Map<String, dynamic>?) == null
          ? null
          : Mesocycle.fromJson(training['mesocycle'] as Map<String, dynamic>),
      recoveryDays: [
        for (final r in (training['recovery_days'] as List? ?? const []))
          RecoveryDay.fromJson(r as Map<String, dynamic>),
      ],
      stageGoal: json['stage_goal'] == null
          ? null
          : StageGoal.fromJson(json['stage_goal'] as Map<String, dynamic>),
    );
  }
}
