import 'exercise_library.dart';
import 'models.dart';

/// Port of fitness-planner's `session_builder.py`.
///
/// Volume = weekly target ÷ **actual** schedule frequency, capped per session,
/// and clipped by session time budget.
const weeklyVolume = {
  'beginner': {
    'chest': 10, 'back': 12, 'quads': 10, 'hamstrings': 6, 'shoulders': 8,
    'biceps': 6, 'triceps': 6, 'calves': 4, 'core': 4,
  },
  'intermediate': {
    'chest': 14, 'back': 16, 'quads': 14, 'hamstrings': 8, 'shoulders': 12,
    'biceps': 8, 'triceps': 8, 'calves': 6, 'core': 6,
  },
  'advanced': {
    'chest': 18, 'back': 20, 'quads': 18, 'hamstrings': 10, 'shoulders': 16,
    'biceps': 10, 'triceps': 10, 'calves': 8, 'core': 8,
  },
};

const maxSetsPerMuscleSession = {
  'beginner': 6,
  'intermediate': 10,
  'advanced': 12,
};

const _trainingVars = {
  'hypertrophy': {'load_pct': '65-80% 1RM', 'reps': '8-12', 'sets_range': [3, 4], 'rest_sec': 90, 'rpe': 7.5, 'tempo': '3-1-2-0', 'rir': '1-3'},
  'strength': {'load_pct': '≥80% 1RM', 'reps': '3-6', 'sets_range': [4, 5], 'rest_sec': 150, 'rpe': 8.0, 'tempo': '受控', 'rir': '1-2'},
  'fat_loss': {'load_pct': '60-75% 1RM', 'reps': '10-15', 'sets_range': [3, 4], 'rest_sec': 45, 'rpe': 7.0, 'tempo': '3-1-2-0', 'rir': '2-3'},
  'recomposition': {'load_pct': '65-80% 1RM', 'reps': '8-12', 'sets_range': [3, 4], 'rest_sec': 90, 'rpe': 7.5, 'tempo': '3-1-2-0', 'rir': '1-3'},
};

const _sessionMuscles = {
  'push': ['chest', 'shoulders', 'triceps'],
  'pull': ['back', 'biceps', 'rear_delt'],
  'legs': ['quads', 'hamstrings', 'glutes', 'calves'],
  'upper': ['chest', 'back', 'shoulders', 'biceps', 'triceps'],
  'lower': ['quads', 'hamstrings', 'glutes', 'calves'],
  'full_body': ['chest', 'back', 'quads', 'hamstrings', 'shoulders'],
  'core': ['core', 'abs'],
};

/// Kept for docs/compat; volume math now uses [_actualMuscleFrequency].
const splitFrequency = {
  'full_body': {'chest': 2, 'back': 2, 'quads': 2, 'hamstrings': 2, 'shoulders': 2, 'biceps': 2, 'triceps': 2, 'calves': 1, 'core': 2},
  'upper_lower': {'chest': 2, 'back': 2, 'quads': 2, 'hamstrings': 2, 'shoulders': 2, 'biceps': 2, 'triceps': 2, 'calves': 2, 'core': 1},
  'push_pull_legs': {'chest': 1.5, 'back': 1.5, 'quads': 1.5, 'hamstrings': 1, 'shoulders': 1.5, 'biceps': 1.5, 'triceps': 1.5, 'calves': 1, 'core': 1},
  'ppl_upper_lower': {'chest': 2, 'back': 2, 'quads': 2, 'hamstrings': 1.5, 'shoulders': 2.5, 'biceps': 2, 'triceps': 2, 'calves': 1, 'core': 1},
  'ppl_ppl': {'chest': 2, 'back': 2, 'quads': 2, 'hamstrings': 2, 'shoulders': 2.5, 'biceps': 2, 'triceps': 2, 'calves': 2, 'core': 1},
};

Map<String, int> _actualMuscleFrequency(List<ScheduleDay> schedule) {
  final freq = <String, int>{};
  for (final dayInfo in schedule) {
    if (dayInfo.type == 'rest') continue;
    for (final muscle in _sessionMuscles[dayInfo.type] ?? const <String>[]) {
      freq[muscle] = (freq[muscle] ?? 0) + 1;
    }
  }
  return freq;
}

Map<String, int> _setsPerSessionMap(
  Map<String, int> volume,
  Map<String, int> frequency,
  String level,
) {
  final cap = maxSetsPerMuscleSession[level] ?? 8;
  final out = <String, int>{};
  volume.forEach((muscle, totalSets) {
    final freq = frequency[muscle] ?? 0;
    final f = freq < 1 ? 1 : freq;
    final per = (totalSets / f).round();
    final clamped = per < 2 ? 2 : per;
    out[muscle] = clamped > cap ? cap : clamped;
  });
  return out;
}

int _estimateSetSeconds(int restSec) => 45 + restSec;

List<SessionResult> buildSessions(UserProfile profile, SplitResult split, ExerciseLibrary library) {
  final level = profile.level;
  final goal = profile.goal;
  final vars_ = _trainingVars[goal] ?? _trainingVars['hypertrophy']!;
  final volume = Map<String, int>.from(weeklyVolume[level] ?? weeklyVolume['beginner']!);
  final frequency = _actualMuscleFrequency(split.weeklySchedule);
  final muscleSetsPerSession = _setsPerSessionMap(volume, frequency, level);

  final budgetSec = (profile.minutesPerSession * 60 * 0.85).round().clamp(15 * 60, 24 * 60 * 60);
  final setCost = _estimateSetSeconds(vars_['rest_sec'] as int);
  final setsRange = (vars_['sets_range'] as List).cast<int>();

  final sessions = <SessionResult>[];
  for (final dayInfo in split.weeklySchedule) {
    final dayName = dayInfo.day;
    final sessionType = dayInfo.type;

    if (sessionType == 'rest') {
      sessions.add(SessionResult(day: dayName, type: 'rest', durationMin: 0, exercises: const [], totalSets: 0));
      continue;
    }

    final targetMuscles = _sessionMuscles[sessionType] ?? const [];

    var exercises = library.query(
      exerciseType: sessionType,
      equipment: profile.equipment,
      injuries: profile.injuries,
      level: level,
    );
    // Stable sort (matches Python's list.sort() guarantee — Dart's
    // List.sort is not stable, so ties are broken by original index to
    // keep results deterministic and identical to the Python engine).
    final indexed = exercises.indexed.toList()
      ..sort((a, b) {
        final aKey = (a.$2.compound ? 0 : 1, a.$2.skillLevel != 'beginner' ? 1 : 0);
        final bKey = (b.$2.compound ? 0 : 1, b.$2.skillLevel != 'beginner' ? 1 : 0);
        final c1 = aKey.$1.compareTo(bKey.$1);
        if (c1 != 0) return c1;
        final c2 = aKey.$2.compareTo(bKey.$2);
        if (c2 != 0) return c2;
        return a.$1.compareTo(b.$1);
      });
    exercises = indexed.map((e) => e.$2).toList();

    final sessionExercises = <ExerciseEntry>[];
    var order = 1;
    final usedIds = <String>{};
    var usedSec = 0;

    for (final muscle in targetMuscles) {
      var setsNeeded = muscleSetsPerSession[muscle];
      if (setsNeeded == null) {
        if (muscle == 'glutes' || muscle == 'rear_delt') {
          setsNeeded = 3;
        } else {
          continue;
        }
      }
      if (setsNeeded <= 0) continue;

      var remainingBudgetSets = ((budgetSec - usedSec) / setCost).floor();
      if (remainingBudgetSets < 2) break;
      if (setsNeeded > remainingBudgetSets) setsNeeded = remainingBudgetSets;

      var muscleExercises = exercises.where((e) => e.primaryMuscles.contains(muscle) && !usedIds.contains(e.id)).toList();
      if (muscleExercises.isEmpty) {
        muscleExercises = exercises.where((e) => e.secondaryMuscles.contains(muscle) && !usedIds.contains(e.id)).toList();
      }
      if (muscleExercises.isEmpty) continue;

      var remainingSets = setsNeeded;
      final candidates = muscleExercises.take(3).toList();
      final nEx = candidates.length;
      for (var i = 0; i < nEx; i++) {
        if (remainingSets <= 0) break;
        remainingBudgetSets = ((budgetSec - usedSec) / setCost).floor();
        if (remainingBudgetSets < 2) break;

        final ex = candidates[i];
        int sets;
        if (i == nEx - 1) {
          sets = remainingSets < remainingBudgetSets ? remainingSets : remainingBudgetSets;
        } else {
          sets = remainingSets;
          if (sets > setsRange[1]) sets = setsRange[1];
          if (sets > remainingBudgetSets) sets = remainingBudgetSets;
        }

        if (sets < setsRange[0]) {
          if (remainingSets >= 2 && i == nEx - 1) {
            sets = remainingSets < remainingBudgetSets ? remainingSets : remainingBudgetSets;
          } else if (remainingSets >= setsRange[0]) {
            sets = setsRange[0];
          } else {
            break;
          }
        }
        if (sets < 2) break;

        sessionExercises.add(ExerciseEntry(
          name: ex.name,
          nameEn: ex.nameEn,
          exerciseId: ex.id,
          sets: sets,
          reps: vars_['reps'] as String,
          load: vars_['load_pct'] as String,
          restSec: vars_['rest_sec'] as int,
          rpe: vars_['rpe'] as double,
          tempo: vars_['tempo'] as String,
          notes: 'RIR ${vars_['rir']}',
          order: order,
          primaryMuscles: ex.primaryMuscles,
          compound: ex.compound,
          formCues: ex.formCues,
        ));
        usedIds.add(ex.id);
        order++;
        remainingSets -= sets;
        usedSec += sets * setCost;
      }
    }

    final totalSets = sessionExercises.fold<int>(0, (sum, e) => sum + e.sets);
    var estMin = profile.minutesPerSession;
    if (totalSets > 0) {
      final warmupPad = (profile.minutesPerSession * 0.15).round();
      final pad = warmupPad < 5 ? 5 : warmupPad;
      estMin = ((usedSec / 60).round() + pad);
      if (estMin > profile.minutesPerSession) estMin = profile.minutesPerSession;
      if (estMin < 0) estMin = 0;
    }
    sessions.add(SessionResult(
      day: dayName,
      type: sessionType,
      durationMin: totalSets == 0 ? profile.minutesPerSession : (estMin == 0 ? profile.minutesPerSession : estMin),
      exercises: sessionExercises,
      totalSets: totalSets,
    ));
  }

  return sessions;
}
