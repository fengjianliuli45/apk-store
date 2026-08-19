import '../models/training_plan.dart';

/// A single fixed sample week, keyed by ISO weekday (1=Mon..7=Sun). No
/// backend — the calendar tab just repeats this pattern week over week.
class TrainingCatalog {
  TrainingCatalog._();

  static const weeklyPlan = <int, DayWorkout>{
    1: DayWorkout(
      title: '胸推日',
      exercises: [
        PlannedExercise(name: '杠铃卧推', sets: 4, reps: '8-10'),
        PlannedExercise(name: '上斜哑铃卧推', sets: 3, reps: '10-12'),
        PlannedExercise(name: '双杠臂屈伸', sets: 3, reps: '12'),
      ],
    ),
    2: DayWorkout(
      title: '有氧日',
      exercises: [
        PlannedExercise(name: '慢跑', sets: 1, reps: '30 分钟'),
        PlannedExercise(name: '跳绳', sets: 3, reps: '3 分钟'),
      ],
    ),
    3: DayWorkout(
      title: '腿日',
      exercises: [
        PlannedExercise(name: '深蹲', sets: 4, reps: '12'),
        PlannedExercise(name: '保加利亚分腿蹲', sets: 3, reps: '10/侧'),
        PlannedExercise(name: '腿举', sets: 3, reps: '12'),
      ],
    ),
    4: DayWorkout(title: '休息日', exercises: []),
    5: DayWorkout(
      title: '背部日',
      exercises: [
        PlannedExercise(name: '引体向上', sets: 4, reps: '力竭'),
        PlannedExercise(name: '杠铃划船', sets: 3, reps: '10'),
        PlannedExercise(name: '高位下拉', sets: 3, reps: '12'),
      ],
    ),
    6: DayWorkout(
      title: '肩部 & 核心',
      exercises: [
        PlannedExercise(name: '哑铃推举', sets: 4, reps: '10'),
        PlannedExercise(name: '侧平举', sets: 3, reps: '15'),
        PlannedExercise(name: '平板支撑', sets: 3, reps: '60 秒'),
      ],
    ),
    7: DayWorkout(title: '休息日', exercises: []),
  };

  static DayWorkout forDate(DateTime date) => weeklyPlan[date.weekday]!;

  /// Flat move library shown on the 训练 tab, independent of the calendar.
  static const exerciseLibrary = [
    PlannedExercise(name: '深蹲', sets: 4, reps: '12'),
    PlannedExercise(name: '杠铃卧推', sets: 4, reps: '8-10'),
    PlannedExercise(name: '引体向上', sets: 4, reps: '力竭'),
    PlannedExercise(name: '硬拉', sets: 3, reps: '6-8'),
    PlannedExercise(name: '哑铃推举', sets: 4, reps: '10'),
    PlannedExercise(name: '平板支撑', sets: 3, reps: '60 秒'),
  ];
}
