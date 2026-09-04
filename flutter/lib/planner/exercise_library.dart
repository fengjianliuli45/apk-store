import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'injury_planner.dart';
import 'models.dart';

/// Port of fitness-planner's `exercise_library.py`. Loads
/// assets/data/exercises.json (same 108-move library as the Python engine).
const _typePatterns = {
  'push': ['horizontal_push', 'vertical_push'],
  'pull': ['horizontal_pull', 'vertical_pull'],
  'legs': ['squat', 'hip_hinge', 'knee_flexion', 'hip_extension', 'calf_raise'],
  'upper': ['horizontal_push', 'vertical_push', 'horizontal_pull', 'vertical_pull', 'elbow_flexion', 'elbow_extension'],
  'lower': ['squat', 'hip_hinge', 'knee_flexion', 'hip_extension', 'calf_raise'],
  'full_body': [
    'horizontal_push', 'vertical_push', 'horizontal_pull', 'vertical_pull',
    'squat', 'hip_hinge', 'knee_flexion', 'hip_extension', 'calf_raise', 'core',
  ],
  'core': ['core', 'trunk_flexion', 'trunk_rotation', 'anti_extension'],
};

class ExerciseLibrary {
  ExerciseLibrary._(this._exercises) : _index = {for (final e in _exercises) e.id: e};

  final List<Exercise> _exercises;
  final Map<String, Exercise> _index;

  static Future<ExerciseLibrary> load({String assetPath = 'assets/data/exercises.json'}) async {
    final raw = await rootBundle.loadString(assetPath);
    final data = jsonDecode(raw) as List;
    return ExerciseLibrary._(data.map((e) => Exercise.fromJson(e as Map<String, dynamic>)).toList());
  }

  List<Exercise> all() => List.unmodifiable(_exercises);

  int count() => _exercises.length;

  Exercise? getById(String id) => _index[id];

  Set<String> _expandedEquipment(List<String> equipment) {
    final expanded = {...equipment};
    if (expanded.contains('barbell')) {
      expanded.add('rack');
      expanded.add('bench');
    }
    if (expanded.contains('dumbbell')) {
      expanded.add('bench');
    }
    // 商业健身房 / 力量架自带单杠
    if (expanded.contains('rack') || expanded.contains('machine')) {
      expanded.add('pull_up_bar');
    }
    expanded.add('bodyweight');
    return expanded;
  }

  List<Exercise> query({
    required String exerciseType,
    required List<String> equipment,
    List<String> injuries = const [],
    String level = 'beginner',
  }) {
    final patterns = _typePatterns[exerciseType] ?? const [];
    if (patterns.isEmpty) return [];

    final inj = normalizeInjuries(injuries);
    final expandedEquip = _expandedEquipment(equipment);

    final results = <Exercise>[];
    for (final ex in _exercises) {
      if (!patterns.contains(ex.movementPattern)) continue;
      if (!ex.equipmentRequired.every(expandedEquip.contains)) continue;
      if (inj.isNotEmpty && isContraindicated(ex, inj)) continue;
      if (level == 'beginner' && ex.skillLevel == 'advanced') continue;
      results.add(ex);
    }
    return results;
  }

  List<Exercise> queryByMuscle(String muscle, List<String> equipment,
      {String level = 'beginner', List<String> injuries = const []}) {
    final inj = normalizeInjuries(injuries);
    final expandedEquip = _expandedEquipment(equipment);
    final results = <Exercise>[];
    for (final ex in _exercises) {
      if (!ex.primaryMuscles.contains(muscle) &&
          !ex.secondaryMuscles.contains(muscle)) {
        continue;
      }
      if (!ex.equipmentRequired.every(expandedEquip.contains)) continue;
      if (level == 'beginner' && ex.skillLevel == 'advanced') continue;
      if (inj.isNotEmpty && isContraindicated(ex, inj)) continue;
      results.add(ex);
    }
    return results;
  }

  List<Exercise> findAlternatives(String exerciseId, List<String> injuries) {
    final ex = getById(exerciseId);
    if (ex == null) return [];
    final inj = normalizeInjuries(injuries);
    return ex.alternativesIfInjured
        .map((id) => _index[id])
        .whereType<Exercise>()
        .where((a) => !isContraindicated(a, inj))
        .toList();
  }
}
