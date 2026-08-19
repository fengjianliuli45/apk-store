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
  String toString() => 'Profile validation failed:\n${errors.map((e) => '  - $e').join('\n')}';
}

class UserProfile {
  UserProfile({
    required this.gender,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.level,
    required this.goal,
    required this.daysPerWeek,
    required this.minutesPerSession,
    required this.equipment,
    this.bodyFatPct,
    this.mealsPerDay = 4,
    List<String>? supplements,
    this.targetWeightKg,
    List<String>? injuries,
    List<String>? dietaryRestrictions,
    this.cookingAccess = 'home',
    List<String>? warnings,
    List<String>? notes,
  })  : supplements = supplements ?? ['creatine'],
        injuries = injuries ?? [],
        dietaryRestrictions = dietaryRestrictions ?? [],
        warnings = warnings ?? [],
        notes = notes ?? [];

  final String gender;
  final int age;
  final double heightCm;
  final double weightKg;
  final String level;
  final String goal;
  final int daysPerWeek;
  final int minutesPerSession;
  final List<String> equipment;
  final double? bodyFatPct;
  final int mealsPerDay;
  final List<String> supplements;
  final double? targetWeightKg;
  final List<String> injuries;
  final List<String> dietaryRestrictions;
  final String cookingAccess;
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
  SplitResult({required this.splitName, required this.weeklySchedule, required this.warnings});

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
        primaryMuscles: List<String>.from(d['primary_muscles'] as List? ?? const []),
        secondaryMuscles: List<String>.from(d['secondary_muscles'] as List? ?? const []),
        movementPattern: (d['movement_pattern'] as String?) ?? '',
        compound: (d['compound'] as bool?) ?? false,
        equipmentRequired: List<String>.from(d['equipment_required'] as List? ?? const []),
        skillLevel: (d['skill_level'] as String?) ?? 'beginner',
        variations: List<String>.from(d['variations'] as List? ?? const []),
        injuryContraindications: List<String>.from(d['injury_contraindications'] as List? ?? const []),
        alternativesIfInjured: List<String>.from(d['alternatives_if_injured'] as List? ?? const []),
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
  });

  final String name;
  final String nameEn;
  final String exerciseId;
  final int sets;
  final String reps;
  final String load;
  final int restSec;
  final double rpe;
  final String tempo;
  final String notes;
  final int order;
  final List<String> primaryMuscles;
  final bool compound;
  final List<String> formCues;

  Map<String, dynamic> toJson() => {
        'name': name,
        'name_en': nameEn,
        'exercise_id': exerciseId,
        'sets': sets,
        'reps': reps,
        'load': load,
        'rest_sec': restSec,
        'rpe': rpe,
        'tempo': tempo,
        'notes': notes,
        'order': order,
        'primary_muscles': primaryMuscles,
        'compound': compound,
        'form_cues': formCues,
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

// ── progression_planner ────────────────────────────────────────────

class ReassessmentTrigger {
  ReassessmentTrigger({required this.condition, required this.action, this.week});
  final String condition;
  final String action;
  final int? week;

  Map<String, dynamic> toJson() => {'condition': condition, 'action': action, 'week': week};
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
  });

  final String strategy;
  final double incrementUpperKg;
  final double incrementLowerKg;
  final String progressionFreq;
  final String doubleProgression;
  final int nextCheckWeek;
  final List<ReassessmentTrigger> triggers;

  Map<String, dynamic> toJson() => {
        'strategy': strategy,
        'increment_upper_kg': incrementUpperKg,
        'increment_lower_kg': incrementLowerKg,
        'progression_freq': progressionFreq,
        'double_progression': doubleProgression,
        'next_check_week': nextCheckWeek,
        'reassessment_triggers': triggers.map((t) => t.toJson()).toList(),
      };
}

// ── meal_distributor ───────────────────────────────────────────────

class Meal {
  Meal({required this.name, required this.kcal, required this.proteinG, required this.fatG, required this.carbsG});

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

  Map<String, dynamic> toJson() => {'supplements': supplements.map((s) => s.toJson()).toList()};
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

  Map<String, dynamic> toJson() => {
        'meta': {'version': '1.0', 'generated_at': generatedAt.toIso8601String()},
        'profile': profile.toJson(),
        'nutrition': {
          'tdee': tdee.toJson(),
          'macros': macros.toJson(),
          'meals': mealPlan.toJson(),
          'supplements': supplements.toJson()['supplements'],
        },
        'training': {
          'split': split.splitName,
          'weekly_volume_per_group': weeklyVolumePerGroup,
          'schedule': sessions.map((s) => s.toJson()).toList(),
          'progression': progression.toJson(),
          'split_warnings': split.warnings,
        },
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
      generatedAt: DateTime.parse((json['meta'] as Map<String, dynamic>)['generated_at'] as String),
      profile: UserProfile(
        gender: profileJson['gender'] as String,
        age: profileJson['age'] as int,
        heightCm: (profileJson['height_cm'] as num).toDouble(),
        weightKg: (profileJson['weight_kg'] as num).toDouble(),
        level: profileJson['level'] as String,
        goal: profileJson['goal'] as String,
        daysPerWeek: profileJson['days_per_week'] as int,
        minutesPerSession: profileJson['minutes_per_session'] as int,
        equipment: List<String>.from(profileJson['equipment'] as List),
        bodyFatPct: (profileJson['body_fat_pct'] as num?)?.toDouble(),
        injuries: List<String>.from(profileJson['injuries'] as List? ?? const []),
        warnings: List<String>.from(profileJson['warnings'] as List? ?? const []),
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
            .map((s) => ScheduleDay(day: s['day'] as String, type: s['type'] as String))
            .toList(),
        warnings: List<String>.from(training['split_warnings'] as List? ?? const []),
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
              restSec: ex['rest_sec'] as int,
              rpe: (ex['rpe'] as num).toDouble(),
              tempo: ex['tempo'] as String,
              notes: ex['notes'] as String,
              order: ex['order'] as int,
              primaryMuscles: List<String>.from(ex['primary_muscles'] as List? ?? const []),
              compound: (ex['compound'] as bool?) ?? false,
              formCues: List<String>.from(ex['form_cues'] as List? ?? const []),
            );
          }).toList(),
        );
      }).toList(),
      progression: ProgressionResult(
        strategy: progressionJson['strategy'] as String,
        incrementUpperKg: (progressionJson['increment_upper_kg'] as num).toDouble(),
        incrementLowerKg: (progressionJson['increment_lower_kg'] as num).toDouble(),
        progressionFreq: progressionJson['progression_freq'] as String,
        doubleProgression: progressionJson['double_progression'] as String,
        nextCheckWeek: progressionJson['next_check_week'] as int,
        triggers: (progressionJson['reassessment_triggers'] as List)
            .map((t) => ReassessmentTrigger(condition: t['condition'] as String, action: t['action'] as String, week: t['week'] as int?))
            .toList(),
      ),
      mealPlan: MealPlan(
        meals: (mealsJson['meals'] as List)
            .map((m) => Meal(
                  name: m['name'] as String,
                  kcal: (m['kcal'] as num).toDouble(),
                  proteinG: (m['protein_g'] as num).toDouble(),
                  fatG: (m['fat_g'] as num).toDouble(),
                  carbsG: (m['carbs_g'] as num).toDouble(),
                ))
            .toList(),
        totalKcal: (mealsJson['total_kcal'] as num).toDouble(),
        totalProteinG: (mealsJson['total_protein_g'] as num).toDouble(),
        totalFatG: (mealsJson['total_fat_g'] as num).toDouble(),
        totalCarbsG: (mealsJson['total_carbs_g'] as num).toDouble(),
        foodExamples: Map<String, String>.from(mealsJson['food_examples'] as Map? ?? const {}),
      ),
      supplements: SupplementResult(
        (nutrition['supplements'] as List)
            .map((s) => Supplement(
                  name: s['name'] as String,
                  nameEn: s['name_en'] as String,
                  dose: s['dose'] as String,
                  condition: s['condition'] as String,
                  note: s['note'] as String,
                  pmid: s['pmid'] as String?,
                ))
            .toList(),
      ),
      weeklyVolumePerGroup: Map<String, num>.from(training['weekly_volume_per_group'] as Map),
    );
  }
}
