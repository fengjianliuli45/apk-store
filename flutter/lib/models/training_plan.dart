class PlannedExercise {
  const PlannedExercise({
    this.id,
    required this.name,
    required this.sets,
    required this.reps,
  });

  /// Engine exercise id when the row came from a generated plan.
  final String? id;
  final String name;
  final int sets;
  final String reps;
}

class DayWorkout {
  const DayWorkout({required this.title, required this.exercises});

  final String title;
  final List<PlannedExercise> exercises;

  bool get isRestDay => exercises.isEmpty;
}
