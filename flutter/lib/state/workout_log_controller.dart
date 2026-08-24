import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/workout_log.dart';

/// Local history of finished workouts. Profile stats, the radar, and the
/// home idle ring all read from here — no backend.
class WorkoutLogController extends ChangeNotifier {
  static const _prefsKey = 'workout_log_v1';

  final List<WorkoutLogEntry> entries = [];
  bool _loaded = false;

  bool get loaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    entries
      ..clear()
      ..addAll(raw.map((s) => WorkoutLogEntry.fromJson(jsonDecode(s) as Map<String, dynamic>)));
    entries.sort((a, b) => b.timestampMs.compareTo(a.timestampMs));
    _loaded = true;
    notifyListeners();
  }

  Future<void> record(WorkoutLogEntry entry) async {
    entries.insert(0, entry);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, entries.map((e) => jsonEncode(e.toJson())).toList());
  }

  int get sessionCount => entries.length;

  int get totalDurationMs => entries.fold(0, (sum, e) => sum + e.durationMs);

  int get totalKcal => entries.fold(0, (sum, e) => sum + e.estimatedKcal);

  List<WorkoutLogEntry> get recent => entries.take(5).toList();

  /// Consecutive calendar days with a finished workout, counting back from
  /// today (or yesterday if today is still empty).
  int streakDays({DateTime? now}) {
    if (entries.isEmpty) return 0;
    final today = _dateOnly(now ?? DateTime.now());
    final days = entries.map((e) => _dateOnly(e.at)).toSet();
    var cursor = days.contains(today) ? today : today.subtract(const Duration(days: 1));
    if (!days.contains(cursor)) return 0;
    var streak = 0;
    while (days.contains(cursor)) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int completedThisWeek({DateTime? now}) {
    final start = _weekStart(now ?? DateTime.now());
    return entries.where((e) => !e.at.isBefore(start)).length;
  }

  /// Planned training days this week vs finished sessions. Used by the home
  /// idle ring so the arc is weekly completion, not a decorative 86%.
  double weekProgress({required int plannedDays, DateTime? now}) {
    final planned = plannedDays.clamp(1, 7);
    return (completedThisWeek(now: now) / planned).clamp(0.0, 1.0);
  }

  int averageMinutes() {
    if (entries.isEmpty) return 0;
    return (totalDurationMs / entries.length / 60000).round();
  }

  FitnessRadarScores radar({
    required int plannedDaysPerWeek,
    required int plannedMinutes,
    required int dietGoalKcal,
    required List<int> lastSevenDayKcals,
    DateTime? now,
  }) {
    final days = plannedDaysPerWeek.clamp(1, 7);
    final strength = (sessionCount / (days * 4)).clamp(0.0, 1.0);
    final consistency = (streakDays(now: now) / 7).clamp(0.0, 1.0);
    final minutes = averageMinutes();
    final volume = plannedMinutes <= 0
        ? 0.0
        : (minutes / plannedMinutes).clamp(0.0, 1.0);
    final diet = _dietScore(dietGoalKcal, lastSevenDayKcals);
    final completion = weekProgress(plannedDays: days, now: now);
    return FitnessRadarScores(
      strength: strength,
      consistency: consistency,
      volume: volume,
      diet: diet,
      completion: completion,
    );
  }

  static double _dietScore(int goalKcal, List<int> days) {
    if (goalKcal <= 0) return 0;
    final logged = days.where((kcal) => kcal > 0).toList();
    if (logged.isEmpty) return 0;
    final avg = logged.reduce((a, b) => a + b) / logged.length;
    return (1 - ((avg / goalKcal) - 1).abs()).clamp(0.0, 1.0);
  }

  static DateTime _dateOnly(DateTime t) => DateTime(t.year, t.month, t.day);

  static DateTime _weekStart(DateTime t) {
    final day = _dateOnly(t);
    return day.subtract(Duration(days: day.weekday - 1));
  }
}

String formatWorkoutDuration(int ms) {
  final minutes = ms ~/ 60000;
  if (minutes < 60) return '$minutes分';
  final hours = minutes / 60;
  if (hours < 10) return '${hours.toStringAsFixed(1)}时';
  return '${hours.round()}时';
}

String formatWorkoutKcal(int kcal) {
  if (kcal >= 10000) return '${(kcal / 1000).toStringAsFixed(1)}k';
  return '$kcal';
}

String relativeWorkoutDay(DateTime at, DateTime now) {
  final a = DateTime(at.year, at.month, at.day);
  final b = DateTime(now.year, now.month, now.day);
  final delta = b.difference(a).inDays;
  if (delta == 0) return '今天';
  if (delta == 1) return '昨天';
  if (delta > 0 && delta < 7) {
    const names = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return names[at.weekday - 1];
  }
  return '${at.month}月${at.day}日';
}
