/// One finished workout, persisted locally. Only complete sessions are
/// stored — aborting a set does not count.
class WorkoutLogEntry {
  WorkoutLogEntry({
    required this.id,
    required this.title,
    required this.timestampMs,
    required this.durationMs,
    required this.completedSets,
    required this.totalSets,
    required this.estimatedKcal,
  });

  final String id;
  final String title;
  final int timestampMs;
  final int durationMs;
  final int completedSets;
  final int totalSets;
  final int estimatedKcal;

  DateTime get at => DateTime.fromMillisecondsSinceEpoch(timestampMs);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'timestampMs': timestampMs,
        'durationMs': durationMs,
        'completedSets': completedSets,
        'totalSets': totalSets,
        'estimatedKcal': estimatedKcal,
      };

  factory WorkoutLogEntry.fromJson(Map<String, dynamic> json) => WorkoutLogEntry(
        id: json['id'] as String,
        title: json['title'] as String,
        timestampMs: json['timestampMs'] as int,
        durationMs: json['durationMs'] as int,
        completedSets: json['completedSets'] as int,
        totalSets: json['totalSets'] as int,
        estimatedKcal: json['estimatedKcal'] as int,
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
