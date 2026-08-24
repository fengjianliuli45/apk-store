import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/workout_log.dart';
import '../planner/models.dart';
import '../planner/plan_adapter.dart';
import 'workout_log_controller.dart';

/// Session phases. Idle/Ready/Active/Rest mirror the Compose
/// `WorkoutSessionViewModel` state machine from archive/android-compose —
/// Flutter only drives the timer + Home UI; the pod's own Ready/Active/Rest
/// screens live in the Unity scene (see UnityCoachPlaceholderScreen). Once a
/// real Unity build is wired in, `UnityWidgetController.postMessage` should
/// call these same methods (startSet/completeSet/addRestSeconds/skipRest/
/// abortWorkout) so Flutter stays the single source of truth for timing.
enum WorkoutPhase { idle, ready, active, rest }

class SetPlan {
  const SetPlan(this.name, this.targetReps, {this.restMs = WorkoutSessionController.restDefaultMs});
  final String name;
  final int targetReps;
  final int restMs;
}

class WorkoutSessionController extends ChangeNotifier {
  static const restDefaultMs = 30000;
  static const _tickInterval = Duration(milliseconds: 50);
  static const _lastFiveMs = 5000;
  static const _repIntervalMs = 2000;

  static const _fallbackPlans = [
    SetPlan('深蹲', 12),
    SetPlan('深蹲', 12),
    SetPlan('俯卧撑', 12),
    SetPlan('俯卧撑', 12),
  ];

  List<SetPlan> plans = List<SetPlan>.of(_fallbackPlans);
  bool isRestDay = false;
  String sessionTitle = '';
  WorkoutLogController? log;
  double bodyWeightKg = 70;

  /// True after the last set of a session is completed (not after abort).
  bool justFinished = false;

  int _workoutElapsedMs = 0;
  int _setsFinished = 0;

  int get totalSets => plans.length;

  WorkoutPhase phase = WorkoutPhase.idle;
  int currentSet = 1;
  int completedReps = 0;
  int setElapsedMs = 0;
  bool isPaused = false;
  int restRemainingMs = restDefaultMs;
  int restDurationMs = restDefaultMs;
  bool isLastFiveSeconds = false;

  Timer? _ticker;
  final Stopwatch _stopwatch = Stopwatch();
  int _lastElapsedMs = 0;

  String get exerciseName => plans.isEmpty ? sessionTitle : plans[currentSet - 1].name;

  String get nextExerciseName =>
      currentSet < plans.length ? plans[currentSet].name : exerciseName;

  int get targetReps => plans.isEmpty ? 0 : plans[currentSet - 1].targetReps;

  int get _currentRestMs => plans.isEmpty
      ? restDefaultMs
      : plans[currentSet - 1].restMs.clamp(5000, 180000);

  void attachLog(WorkoutLogController workoutLog) {
    log = workoutLog;
  }

  /// Binds the live session queue to today's generated workout. Rest days
  /// leave [isRestDay] true and refuse to start a dummy set list.
  void applyToday(GeneratedPlan? plan) {
    bodyWeightKg = plan?.profile.weightKg ?? 70;
    if (plan == null || plan.sessions.isEmpty) {
      plans = List<SetPlan>.of(_fallbackPlans);
      isRestDay = false;
      sessionTitle = '';
      _reset(notify: false);
      notifyListeners();
      return;
    }
    final session = sessionForDate(plan, DateTime.now());
    sessionTitle = sessionTypeLabels[session.type] ?? session.type;
    if (session.isRest || session.exercises.isEmpty) {
      plans = const [];
      isRestDay = true;
      _reset(notify: false);
      notifyListeners();
      return;
    }
    plans = _setPlansFromSession(session);
    isRestDay = false;
    _reset(notify: false);
    notifyListeners();
  }

  static List<SetPlan> _setPlansFromSession(SessionResult session) {
    final sets = <SetPlan>[];
    for (final exercise in session.exercises) {
      final reps = _parseTargetReps(exercise.reps);
      final restMs = (exercise.restSec <= 0 ? 30 : exercise.restSec) * 1000;
      for (var i = 0; i < exercise.sets; i++) {
        sets.add(SetPlan(exercise.name, reps, restMs: restMs));
      }
    }
    return sets;
  }

  static int _parseTargetReps(String reps) {
    final nums = RegExp(r'\d+').allMatches(reps).map((m) => int.parse(m.group(0)!)).toList();
    if (nums.isEmpty) return 10;
    return nums.last.clamp(5, 20);
  }

  bool get isRunning => phase == WorkoutPhase.active || phase == WorkoutPhase.rest;

  bool get canStart => !isRestDay && plans.isNotEmpty;

  /// Idle HUD subtitle: today's first move, or a rest-day cue.
  String get previewCue {
    if (isRestDay) return '按计划恢复';
    if (plans.isEmpty) return '轻触进入训练舱';
    final first = plans.first.name;
    return '$first · $totalSets组';
  }

  /// mm:ss.cc — set-elapsed while active, rest countdown while resting.
  String get timerText {
    final ms = phase == WorkoutPhase.rest ? restRemainingMs : setElapsedMs;
    final centis = ms ~/ 10;
    final minutes = centis ~/ 6000;
    final seconds = (centis % 6000) ~/ 100;
    final cs = centis % 100;
    return '${_pad(minutes)}:${_pad(seconds)}.${_pad(cs)}';
  }

  double get ringProgress {
    if (phase == WorkoutPhase.rest) {
      final total = restDurationMs.clamp(1, 1 << 31);
      return (restRemainingMs / total).clamp(0.0, 1.0);
    }
    if (phase == WorkoutPhase.active) {
      return (completedReps / targetReps).clamp(0.0, 1.0);
    }
    return 0.0;
  }

  String get phaseLabel => switch (phase) {
        WorkoutPhase.idle => 'READY',
        WorkoutPhase.ready => 'READY',
        WorkoutPhase.active => 'ACTIVE',
        WorkoutPhase.rest => 'REST',
      };

  void startSession() {
    if (plans.isEmpty) return;
    justFinished = false;
    _workoutElapsedMs = 0;
    _setsFinished = 0;
    _applySet(1, WorkoutPhase.ready);
  }

  void startSet() {
    phase = WorkoutPhase.active;
    setElapsedMs = 0;
    completedReps = 0;
    isPaused = false;
    _startTicker();
    notifyListeners();
  }

  void togglePause() {
    if (phase != WorkoutPhase.active) return;
    isPaused = !isPaused;
    notifyListeners();
  }

  void completeSet() {
    if (phase != WorkoutPhase.active) return;
    _setsFinished += 1;
    if (currentSet >= totalSets) {
      _finishWorkout();
    } else {
      _beginRest();
    }
  }

  void addRestSeconds([int seconds = 30]) {
    if (phase != WorkoutPhase.rest) return;
    final extra = seconds * 1000;
    restRemainingMs += extra;
    restDurationMs += extra;
    isLastFiveSeconds = restRemainingMs <= _lastFiveMs;
    notifyListeners();
  }

  void skipRest() {
    if (phase != WorkoutPhase.rest) return;
    restRemainingMs = _lastFiveMs;
    isLastFiveSeconds = true;
    notifyListeners();
  }

  void startNextSetNow() {
    if (phase != WorkoutPhase.rest) return;
    _advance(autoStart: true);
  }

  /// Long-press-to-end from the Compose original. Abandoned sessions are
  /// not written to the workout log.
  void abortWorkout() {
    justFinished = false;
    _reset();
  }

  void _finishWorkout() {
    final durationMs = _workoutElapsedMs.clamp(1000, 6 * 3600 * 1000);
    final hours = durationMs / 3600000;
    final kcal = (bodyWeightKg * 5.0 * hours).round().clamp(1, 2000);
    final title = sessionTitle.isEmpty ? exerciseName : sessionTitle;
    final workoutLog = log;
    if (workoutLog != null) {
      unawaited(
        workoutLog.record(
          WorkoutLogEntry(
            id: '${DateTime.now().millisecondsSinceEpoch}',
            title: title,
            timestampMs: DateTime.now().millisecondsSinceEpoch,
            durationMs: durationMs,
            completedSets: _setsFinished,
            totalSets: totalSets,
            estimatedKcal: kcal,
          ),
        ),
      );
    }
    justFinished = true;
    _reset();
  }

  void _beginRest() {
    phase = WorkoutPhase.rest;
    restRemainingMs = _currentRestMs;
    restDurationMs = _currentRestMs;
    isLastFiveSeconds = false;
    isPaused = false;
    _startTicker();
    notifyListeners();
  }

  void _advance({required bool autoStart}) {
    final next = currentSet + 1;
    if (next > totalSets) {
      _reset();
      return;
    }
    _applySet(next, autoStart ? WorkoutPhase.active : WorkoutPhase.ready);
    if (autoStart) {
      _startTicker();
    } else {
      _ticker?.cancel();
    }
  }

  void _applySet(int setNumber, WorkoutPhase newPhase) {
    currentSet = setNumber;
    phase = newPhase;
    completedReps = 0;
    setElapsedMs = 0;
    isPaused = false;
    restRemainingMs = _currentRestMs;
    restDurationMs = _currentRestMs;
    isLastFiveSeconds = false;
    notifyListeners();
  }

  void _reset({bool notify = true}) {
    _ticker?.cancel();
    _ticker = null;
    _stopwatch
      ..stop()
      ..reset();
    phase = WorkoutPhase.idle;
    currentSet = 1;
    completedReps = 0;
    setElapsedMs = 0;
    isPaused = false;
    restRemainingMs = restDefaultMs;
    restDurationMs = restDefaultMs;
    isLastFiveSeconds = false;
    _workoutElapsedMs = 0;
    _setsFinished = 0;
    if (notify) notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _stopwatch
      ..reset()
      ..start();
    _lastElapsedMs = 0;
    _ticker = Timer.periodic(_tickInterval, (_) => _onTick());
  }

  void _onTick() {
    final now = _stopwatch.elapsedMilliseconds;
    final dt = now - _lastElapsedMs;
    _lastElapsedMs = now;

    if (phase == WorkoutPhase.active) {
      if (isPaused) return;
      setElapsedMs += dt;
      _workoutElapsedMs += dt;
      final autoReps = (setElapsedMs ~/ _repIntervalMs).clamp(0, targetReps);
      if (autoReps > completedReps) completedReps = autoReps;
      notifyListeners();
    } else if (phase == WorkoutPhase.rest) {
      _workoutElapsedMs += dt;
      final remaining = (restRemainingMs - dt).clamp(0, 1 << 31);
      restRemainingMs = remaining;
      isLastFiveSeconds = remaining <= _lastFiveMs;
      if (remaining <= 0) {
        _advance(autoStart: true);
        return;
      }
      notifyListeners();
    }
  }

  static String _pad(int value) => value.toString().padLeft(2, '0');

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
