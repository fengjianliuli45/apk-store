import '../models/training_plan.dart';
import 'models.dart';

/// Bridges engine output onto the existing training_plan.dart view models
/// so TrainingScreen/PlanScreen (built for the static TrainingCatalog)
/// don't need a parallel rendering path for generated plans.
const sessionTypeLabels = {
  'push': '推',
  'pull': '拉',
  'legs': '腿',
  'upper': '上肢',
  'lower': '下肢',
  'full_body': '全身',
  'rest': '休息日',
};

DayWorkout dayWorkoutFromSession(SessionResult session) {
  final label = sessionTypeLabels[session.type] ?? session.type;
  return DayWorkout(
    title: label,
    exercises: [
      for (final e in session.exercises) PlannedExercise(name: e.name, sets: e.sets, reps: e.reps),
    ],
  );
}

/// Weekday-keyed (1=Mon..7=Sun) lookup, matching TrainingCatalog.weeklyPlan
/// — GeneratedPlan.sessions is already ordered 周一..周日.
Map<int, DayWorkout> weeklyPlanFromGenerated(GeneratedPlan plan) {
  final sessions = plan.sessions;
  return {
    for (var i = 0; i < sessions.length && i < 7; i++) i + 1: dayWorkoutFromSession(sessions[i]),
  };
}

SessionResult sessionForDate(GeneratedPlan plan, DateTime date) {
  return plan.sessions[(date.weekday - 1) % plan.sessions.length];
}

/// The generated plan repeats week over week (same as TrainingCatalog),
/// so any date maps onto the 7-day schedule by weekday.
DayWorkout dayWorkoutForDate(GeneratedPlan plan, DateTime date) {
  return dayWorkoutFromSession(sessionForDate(plan, date));
}

/// Flat, de-duplicated move list across the week, for the 训练 tab's 动作库.
List<PlannedExercise> exerciseLibraryFromGenerated(GeneratedPlan plan) {
  final seen = <String>{};
  final result = <PlannedExercise>[];
  for (final session in plan.sessions) {
    for (final e in session.exercises) {
      if (seen.add(e.exerciseId)) {
        result.add(PlannedExercise(name: e.name, sets: e.sets, reps: e.reps));
      }
    }
  }
  return result;
}
