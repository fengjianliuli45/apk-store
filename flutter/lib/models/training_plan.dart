class PlannedExercise {
  const PlannedExercise({required this.name, required this.sets, required this.reps});

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
