import 'package:flutter_test/flutter_test.dart';
import 'package:rest_pod_hud/planner/exercise_library.dart';
import 'package:rest_pod_hud/planner/models.dart';
import 'package:rest_pod_hud/planner/session_builder.dart';
import 'package:rest_pod_hud/planner/split_selector.dart';

/// 任务 ①：容量↔课时一致性（Dart 端口，对齐 fitness-planner Python 引擎）。

UserProfile _profile({
  String level = 'intermediate',
  String goal = 'hypertrophy',
  int days = 4,
  int minutes = 60,
  List<String> equipment = const ['barbell', 'dumbbell', 'cable', 'machine'],
}) =>
    UserProfile(
      gender: 'M',
      age: 28,
      heightCm: 175,
      weightKg: 72,
      level: level,
      goal: goal,
      daysPerWeek: days,
      minutesPerSession: minutes,
      equipment: equipment,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ExerciseLibrary lib;
  setUpAll(() async {
    lib = await ExerciseLibrary.load();
  });

  test('generates 7 days, rest days empty', () {
    final p = _profile();
    final sessions = buildSessions(p, selectSplit(p), lib);
    expect(sessions.length, 7);
    for (final s in sessions.where((s) => s.type == 'rest')) {
      expect(s.exercises, isEmpty);
    }
  });

  test('duration never exceeds the user budget and covers real set time', () {
    final p = _profile(minutes: 60);
    final sessions = buildSessions(p, selectSplit(p), lib);
    for (final s in sessions.where((s) => s.type != 'rest')) {
      expect(s.durationMin, lessThanOrEqualTo(p.minutesPerSession));
      expect(s.totalSets, greaterThan(0));
    }
  });

  test('training days are balanced (no ~2x lopsided hybrid day)', () {
    final p = _profile(level: 'intermediate', days: 5, minutes: 75);
    final sessions = buildSessions(p, selectSplit(p), lib);
    final totals = [
      for (final s in sessions.where((s) => s.type != 'rest')) s.totalSets,
    ];
    expect(totals.reduce((a, b) => a < b ? a : b), greaterThan(0));
    final maxT = totals.reduce((a, b) => a > b ? a : b);
    final minT = totals.reduce((a, b) => a < b ? a : b);
    expect(maxT / minT, lessThanOrEqualTo(1.8));
  });

  test('every exercise carries a target_muscle', () {
    final p = _profile();
    final sessions = buildSessions(p, selectSplit(p), lib);
    for (final s in sessions) {
      for (final e in s.exercises) {
        expect(e.targetMuscle, isNotEmpty);
      }
    }
  });

  test('analyzeVolume: no phantom overcount, coverage <= 100', () {
    final p = _profile(level: 'advanced', days: 6, minutes: 90);
    final split = selectSplit(p);
    final report = analyzeVolume(p, split, buildSessions(p, split, lib));
    final target = report['target'] as Map<String, int>;
    final delivered = report['delivered'] as Map<String, int>;
    target.forEach((m, t) {
      expect(delivered[m]!, lessThanOrEqualTo(t + 2));
    });
    expect(report['coverage_pct'] as int, lessThanOrEqualTo(100));
  });

  test('analyzeVolume: coverage scales up with more session time', () {
    final short = _profile(days: 4, minutes: 45);
    final long = _profile(days: 4, minutes: 90);
    int cov(UserProfile p) {
      final sp = selectSplit(p);
      return analyzeVolume(p, sp, buildSessions(p, sp, lib))['coverage_pct'] as int;
    }

    expect(cov(short), lessThanOrEqualTo(cov(long)));
  });

  test('tight schedule surfaces a soft capacity recommendation', () {
    final p = _profile(level: 'intermediate', days: 3, minutes: 60);
    final sp = selectSplit(p);
    final report = analyzeVolume(p, sp, buildSessions(p, sp, lib));
    expect(report['coverage_pct'] as int, lessThan(90));
    expect((report['recommendation'] as Map).isNotEmpty, isTrue);
    expect((report['notes'] as List), isNotEmpty);
  });

  test('3-day intermediate now maps to full_body (higher frequency)', () {
    final p = _profile(level: 'intermediate', days: 3);
    expect(selectSplit(p).splitName, 'full_body');
  });
}
