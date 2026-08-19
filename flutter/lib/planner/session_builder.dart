import 'exercise_library.dart';
import 'models.dart';

/// Port of fitness-planner's `session_builder.py`.
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

const splitFrequency = {
  'full_body': {'chest': 2, 'back': 2, 'quads': 2, 'hamstrings': 2, 'shoulders': 2, 'biceps': 2, 'triceps': 2, 'calves': 1, 'core': 2},
  'upper_lower': {'chest': 2, 'back': 2, 'quads': 2, 'hamstrings': 2, 'shoulders': 2, 'biceps': 2, 'triceps': 2, 'calves': 2, 'core': 1},
  'push_pull_legs': {'chest': 1.5, 'back': 1.5, 'quads': 1.5, 'hamstrings': 1, 'shoulders': 1.5, 'biceps': 1.5, 'triceps': 1.5, 'calves': 1, 'core': 1},
  'ppl_upper_lower': {'chest': 2, 'back': 2, 'quads': 2, 'hamstrings': 1.5, 'shoulders': 2.5, 'biceps': 2, 'triceps': 2, 'calves': 1, 'core': 1},
  'ppl_ppl': {'chest': 2, 'back': 2, 'quads': 2, 'hamstrings': 2, 'shoulders': 2.5, 'biceps': 2, 'triceps': 2, 'calves': 2, 'core': 1},
};

List<SessionResult> buildSessions(UserProfile profile, SplitResult split, ExerciseLibrary library) {
  final level = profile.level;
  final goal = profile.goal;
  final vars_ = _trainingVars[goal] ?? _trainingVars['hypertrophy']!;
  final volume = weeklyVolume[level] ?? weeklyVolume['beginner']!;
  final frequency = splitFrequency[split.splitName] ?? splitFrequency['full_body']!;

  final muscleSetsPerSession = <String, int>{};
  volume.forEach((muscle, totalSets) {
    final freq = (frequency[muscle] ?? 1).toDouble();
    final perSession = (totalSets / freq).round();
    muscleSetsPerSession[muscle] = perSession < 2 ? 2 : perSession;
  });

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

    final setsRange = (vars_['sets_range'] as List).cast<int>();

    for (final muscle in targetMuscles) {
      final setsNeeded = muscleSetsPerSession[muscle] ?? 3;

      var muscleExercises = exercises.where((e) => e.primaryMuscles.contains(muscle) && !usedIds.contains(e.id)).toList();
      if (muscleExercises.isEmpty) {
        muscleExercises = exercises.where((e) => e.secondaryMuscles.contains(muscle) && !usedIds.contains(e.id)).toList();
      }
      if (muscleExercises.isEmpty) continue;

      var remainingSets = setsNeeded;
      for (final ex in muscleExercises.take(2)) {
        if (remainingSets <= 0) break;
        var sets = remainingSets < setsRange[1] ? remainingSets : setsRange[1];
        if (sets < setsRange[0]) sets = setsRange[0];

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
      }
    }

    final totalSets = sessionExercises.fold<int>(0, (sum, e) => sum + e.sets);
    sessions.add(SessionResult(
      day: dayName,
      type: sessionType,
      durationMin: profile.minutesPerSession,
      exercises: sessionExercises,
      totalSets: totalSets,
    ));
  }

  return sessions;
}
