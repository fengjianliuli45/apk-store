import '../models/training_plan.dart';
import 'models.dart';
import 'plan_copy.dart';

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
      for (final e in session.exercises)
        PlannedExercise(
          id: e.exerciseId,
          name: e.name,
          sets: e.sets,
          reps: e.reps,
        ),
    ],
  );
}

/// Weekday-keyed (1=Mon..7=Sun) lookup, matching TrainingCatalog.weeklyPlan
/// — GeneratedPlan.sessions is already ordered 周一..周日.
Map<int, DayWorkout> weeklyPlanFromGenerated(
  GeneratedPlan plan, {
  DateTime? now,
}) {
  final sessions = plan.sessions
      .map((s) => sessionForWeek(plan, s, now ?? DateTime.now()))
      .toList();
  return {
    for (var i = 0; i < sessions.length && i < 7; i++)
      i + 1: dayWorkoutFromSession(sessions[i]),
  };
}

SessionResult sessionForDate(GeneratedPlan plan, DateTime date) {
  if (plan.sessions.isEmpty) {
    return SessionResult(
      day: '',
      type: 'rest',
      durationMin: 0,
      exercises: const [],
      totalSets: 0,
    );
  }
  return sessionForWeek(
    plan,
    plan.sessions[(date.weekday - 1) % plan.sessions.length],
    date,
  );
}

/// Engine overrides are execution prescriptions, not a change to the saved base
/// plan. Keep the last week until reassessment instead of silently restarting.
WeekPlan? weekForDate(GeneratedPlan plan, DateTime date) {
  final cycle = plan.mesocycle;
  if (cycle == null || cycle.weeks.isEmpty) return null;
  final number =
      (cycle.currentWeek + planWeekNumber(plan.generatedAt, date) - 1).clamp(
        1,
        cycle.lengthWeeks,
      );
  return cycle.weeks.where((w) => w.week == number).firstOrNull;
}

SessionResult sessionForWeek(
  GeneratedPlan plan,
  SessionResult base,
  DateTime date,
) {
  final week = weekForDate(plan, date);
  if (week == null || base.isRest) return base;
  final overrides = week.setOverrides[base.day] ?? const <String, int>{};
  final exercises = [
    for (final e in base.exercises)
      ExerciseEntry(
        name: e.name,
        nameEn: e.nameEn,
        exerciseId: e.exerciseId,
        sets: overrides[e.exerciseId] ?? e.sets,
        reps: e.reps,
        load: e.load,
        loadKg: e.loadKg,
        restSec: e.restSec,
        rpe: e.rpe,
        tempo: e.tempo,
        notes:
            '本周目标 RIR ${week.rirTarget}（保留次数）${e.notes.isEmpty ? '' : '；${e.notes}'}',
        order: e.order,
        primaryMuscles: e.primaryMuscles,
        compound: e.compound,
        formCues: e.formCues,
        targetMuscle: e.targetMuscle,
        holdSeconds: e.holdSeconds,
        repDurationSeconds: e.repDurationSeconds,
      ),
  ];
  return SessionResult(
    day: base.day,
    type: base.type,
    // The engine only supplies a base-week duration estimate.
    durationMin: base.durationMin,
    exercises: exercises,
    totalSets: exercises.fold<int>(0, (sum, e) => sum + e.sets),
  );
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
        result.add(
          PlannedExercise(
            id: e.exerciseId,
            name: e.name,
            sets: e.sets,
            reps: e.reps,
          ),
        );
      }
    }
  }
  return result;
}
