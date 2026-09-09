class WorkoutSetLog {
  const WorkoutSetLog({
    required this.setNumber,
    required this.reps,
    required this.durationMs,
    this.weightKg,
    this.rir,
    this.rpe,
    this.painFlag = false,
    this.painArea,
  });

  final int setNumber;
  final int reps;
  final int durationMs;
  final double? weightKg;
  final int? rir;
  final double? rpe;
  final bool painFlag;
  final String? painArea;

  Map<String, dynamic> toJson() => {
    'setNumber': setNumber,
    'reps': reps,
    'durationMs': durationMs,
    'weightKg': weightKg,
    'rir': rir,
    'rpe': rpe,
    'painFlag': painFlag,
    'painArea': painArea,
  };

  Map<String, dynamic> toEngineJson() => {
    'reps': reps,
    if (weightKg != null) 'weight_kg': weightKg,
    if (rir != null) 'rir': rir,
    if (rpe != null) 'rpe': rpe,
  };

  factory WorkoutSetLog.fromJson(Map<String, dynamic> json) => WorkoutSetLog(
    setNumber: (json['setNumber'] as num?)?.toInt() ?? 0,
    reps: (json['reps'] as num?)?.toInt() ?? 0,
    durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
    weightKg: (json['weightKg'] as num?)?.toDouble(),
    rir: (json['rir'] as num?)?.toInt(),
    rpe: (json['rpe'] as num?)?.toDouble(),
    painFlag: json['painFlag'] as bool? ?? false,
    painArea: json['painArea'] as String?,
  );
}

class WorkoutExerciseLog {
  const WorkoutExerciseLog({
    required this.exerciseId,
    required this.plannedSets,
    required this.sets,
  });

  final String exerciseId;
  final int plannedSets;
  final List<WorkoutSetLog> sets;

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'plannedSets': plannedSets,
    'sets': sets.map((set) => set.toJson()).toList(growable: false),
  };

  Map<String, dynamic> toEngineJson() => {
    'exercise_id': exerciseId,
    'planned_sets': plannedSets,
    'sets': sets.map((set) => set.toEngineJson()).toList(growable: false),
  };

  factory WorkoutExerciseLog.fromJson(Map<String, dynamic> json) =>
      WorkoutExerciseLog(
        exerciseId: json['exerciseId'] as String? ?? '',
        plannedSets: (json['plannedSets'] as num?)?.toInt() ?? 0,
        sets: (json['sets'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (set) => WorkoutSetLog.fromJson(Map<String, dynamic>.from(set)),
            )
            .toList(growable: false),
      );
}

/// One locally persisted workout. Structured set evidence is optional so
/// older aggregate records remain readable without fabricating load or RIR.
class WorkoutLogEntry {
  WorkoutLogEntry({
    required this.id,
    required this.title,
    required this.timestampMs,
    required this.durationMs,
    required this.completedSets,
    required this.totalSets,
    required this.estimatedKcal,
    this.planDay = '',
    this.sessionType = 'logged',
    this.aborted = false,
    this.painFlag = false,
    this.recoveryScore,
    this.exercises = const [],
  });

  final String id;
  final String title;
  final int timestampMs;
  final int durationMs;
  final int completedSets;
  final int totalSets;
  final int estimatedKcal;
  final String planDay;
  final String sessionType;
  final bool aborted;
  final bool painFlag;
  final double? recoveryScore;
  final List<WorkoutExerciseLog> exercises;

  DateTime get at => DateTime.fromMillisecondsSinceEpoch(timestampMs);

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'timestampMs': timestampMs,
    'durationMs': durationMs,
    'completedSets': completedSets,
    'totalSets': totalSets,
    'estimatedKcal': estimatedKcal,
    'planDay': planDay,
    'sessionType': sessionType,
    'aborted': aborted,
    'painFlag': painFlag,
    'recoveryScore': recoveryScore,
    'exercises': exercises.map((item) => item.toJson()).toList(growable: false),
  };

  Map<String, dynamic> toEngineJson() => {
    'date': at.toUtc().toIso8601String().split('T').first,
    'plan_day': planDay.isEmpty ? at.weekday : planDay,
    'session_type': sessionType,
    'planned_sets': totalSets,
    'exercises': exercises.isNotEmpty
        ? exercises.map((item) => item.toEngineJson()).toList(growable: false)
        : [
            {
              'exercise_id': 'aggregate_log',
              'planned_sets': totalSets,
              'sets': [
                for (var index = 0; index < completedSets; index++)
                  const <String, dynamic>{},
              ],
            },
          ],
    'aborted': aborted || completedSets * 2 < totalSets,
    'pain_flag':
        painFlag ||
        exercises.any((exercise) => exercise.sets.any((set) => set.painFlag)),
    if (recoveryScore != null) 'recovery_score': recoveryScore,
  };

  factory WorkoutLogEntry.fromJson(Map<String, dynamic> json) =>
      WorkoutLogEntry(
        id: json['id'] as String,
        title: json['title'] as String,
        timestampMs: json['timestampMs'] as int,
        durationMs: json['durationMs'] as int,
        completedSets: json['completedSets'] as int,
        totalSets: json['totalSets'] as int,
        estimatedKcal: json['estimatedKcal'] as int,
        planDay: json['planDay'] as String? ?? '',
        sessionType: json['sessionType'] as String? ?? 'logged',
        aborted: json['aborted'] as bool? ?? false,
        painFlag: json['painFlag'] as bool? ?? false,
        recoveryScore: (json['recoveryScore'] as num?)?.toDouble(),
        exercises: (json['exercises'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (item) =>
                  WorkoutExerciseLog.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList(growable: false),
      );
}

class FitnessRadarScores {
  const FitnessRadarScores({
    required this.strength,
    required this.consistency,
    required this.volume,
    required this.diet,
    required this.completion,
  });

  /// 0..1 axes drawn on the profile radar.
  final double strength;
  final double consistency;
  final double volume;
  final double diet;
  final double completion;

  List<double> get values => [strength, consistency, volume, diet, completion];

  static const labels = ['力量', '坚持', '容量', '饮食', '完成'];
}
