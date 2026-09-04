import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/workout_database.dart';
import '../models/workout_log.dart';
import '../planner/models.dart';
import '../planner/plan_adapter.dart';
import 'workout_log_controller.dart';

/// Session phases. Idle/Ready/Active/Rest mirror the Compose
/// `WorkoutSessionViewModel` state machine from archive/android-compose —
/// Flutter only drives the timer + Home UI; the pod's own Ready/Active/Rest
/// screens live in the Unity scene. The UnitySessionCoordinator mirrors this
/// state through the versioned native bridge so Flutter remains the single
/// source of truth for timing and completion.
enum WorkoutPhase { idle, ready, active, rest }

class SetPlan {
  const SetPlan(
    this.exerciseId,
    this.name,
    this.targetReps, {
    this.restMs = WorkoutSessionController.restDefaultMs,
  });
  final String exerciseId;
  final String name;
  final int targetReps;
  final int restMs;
}

class WorkoutSessionController extends ChangeNotifier {
  WorkoutSessionController({
    this.resumeCountdownStep = const Duration(seconds: 1),
  });

  static const restDefaultMs = 30000;
  static const _tickInterval = Duration(milliseconds: 50);
  static const _lastFiveMs = 5000;

  static const _fallbackPlans = [
    SetPlan('bodyweight_squat', '深蹲', 12),
    SetPlan('bodyweight_squat', '深蹲', 12),
    SetPlan('push_up', '俯卧撑', 12),
    SetPlan('push_up', '俯卧撑', 12),
  ];

  List<SetPlan> plans = List<SetPlan>.of(_fallbackPlans);
  bool isRestDay = false;
  String sessionTitle = '';
  WorkoutLogController? log;
  WorkoutDatabase? _store;
  WorkoutDatabase Function()? _storeFactory;
  double bodyWeightKg = 70;

  /// True after the last set of a session is completed (not after abort).
  bool justFinished = false;

  int _workoutElapsedMs = 0;
  int _setsFinished = 0;
  String? _sessionId;
  Timer? _resumeCountdownTimer;
  int resumeCountdownSeconds = 0;

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
  final Duration resumeCountdownStep;
  final Stopwatch _stopwatch = Stopwatch();
  int _lastElapsedMs = 0;

  String get exerciseName =>
      plans.isEmpty ? sessionTitle : plans[currentSet - 1].name;

  String get exerciseId =>
      plans.isEmpty ? '' : plans[currentSet - 1].exerciseId;

  String get nextExerciseName =>
      currentSet < plans.length ? plans[currentSet].name : exerciseName;

  String get nextExerciseId =>
      currentSet < plans.length ? plans[currentSet].exerciseId : exerciseId;

  int get targetReps => plans.isEmpty ? 0 : plans[currentSet - 1].targetReps;

  int get completedSets => _setsFinished;
  bool get hasResumableSession => _sessionId != null && isRunning;

  int get _currentRestMs => plans.isEmpty
      ? restDefaultMs
      : plans[currentSet - 1].restMs.clamp(5000, 180000);

  void attachLog(WorkoutLogController workoutLog) {
    log = workoutLog;
  }

  void attachStore(WorkoutDatabase workoutStore) {
    _store = workoutStore;
  }

  void attachStoreFactory(WorkoutDatabase Function() factory) {
    _storeFactory = factory;
  }

  WorkoutDatabase? get _database => _store ??= _storeFactory?.call();

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

  /// Restores an interrupted local session in a safety-paused state. The
  /// user must explicitly resume before the coach moves again.
  Future<bool> restoreResumableSession() async {
    final draft = await _database?.loadResumableSession();
    if (draft == null) return false;
    final persistedPlans = _decodePlans(draft.planJson);
    if (persistedPlans.isNotEmpty) {
      plans = persistedPlans;
    } else if (plans.isEmpty && draft.exerciseId.isNotEmpty) {
      plans = List<SetPlan>.generate(
        draft.totalSets,
        (_) => SetPlan(
          draft.exerciseId,
          draft.exerciseLabel.isEmpty ? draft.exerciseId : draft.exerciseLabel,
          draft.targetReps,
          restMs: restDefaultMs,
        ),
      );
    }
    if (plans.isEmpty) return false;
    if (draft.totalSets != totalSets || draft.currentSet > totalSets) {
      return false;
    }
    sessionTitle = draft.title;
    isRestDay = false;
    _sessionId = draft.id;
    currentSet = draft.currentSet.clamp(1, totalSets);
    completedReps = draft.currentRep.clamp(0, targetReps);
    _workoutElapsedMs = draft.effectiveDurationMs;
    _setsFinished = draft.completedSets.clamp(0, totalSets);
    restRemainingMs = draft.restRemainingMs.clamp(0, 180000);
    restDurationMs = _currentRestMs;
    phase = draft.phase == 'rest' ? WorkoutPhase.rest : WorkoutPhase.active;
    isPaused = true;
    resumeCountdownSeconds = 0;
    setElapsedMs = phase == WorkoutPhase.active ? draft.setElapsedMs : 0;
    _startTicker();
    _persist('session_recovered');
    notifyListeners();
    return true;
  }

  static List<SetPlan> _setPlansFromSession(SessionResult session) {
    final sets = <SetPlan>[];
    for (final exercise in session.exercises) {
      final reps = _parseTargetReps(exercise.reps);
      final restMs = (exercise.restSec <= 0 ? 30 : exercise.restSec) * 1000;
      for (var i = 0; i < exercise.sets; i++) {
        sets.add(
          SetPlan(exercise.exerciseId, exercise.name, reps, restMs: restMs),
        );
      }
    }
    return sets;
  }

  static String _encodePlans(List<SetPlan> values) => jsonEncode(
    values
        .map(
          (plan) => {
            'exerciseId': plan.exerciseId,
            'name': plan.name,
            'targetReps': plan.targetReps,
            'restMs': plan.restMs,
          },
        )
        .toList(growable: false),
  );

  static List<SetPlan> _decodePlans(String encoded) {
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map(
            (entry) => SetPlan(
              entry['exerciseId']?.toString() ?? '',
              entry['name']?.toString() ?? '',
              (entry['targetReps'] as num?)?.toInt() ?? 0,
              restMs: (entry['restMs'] as num?)?.toInt() ?? restDefaultMs,
            ),
          )
          .where(
            (plan) =>
                plan.exerciseId.isNotEmpty &&
                plan.name.isNotEmpty &&
                plan.targetReps > 0,
          )
          .toList(growable: false);
    } on FormatException {
      return const [];
    }
  }

  static int _parseTargetReps(String reps) {
    final nums = RegExp(r'\d+')
        .allMatches(reps)
        .map((m) => int.parse(m.group(0)!))
        .toList();
    if (nums.isEmpty) return 10;
    return nums.last.clamp(5, 20);
  }

  bool get isRunning =>
      phase == WorkoutPhase.active || phase == WorkoutPhase.rest;

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
    _sessionId = 'workout-${DateTime.now().microsecondsSinceEpoch}';
    _workoutElapsedMs = 0;
    _setsFinished = 0;
    _applySet(1, WorkoutPhase.ready);
    _persist('session_started');
  }

  void startSet() {
    phase = WorkoutPhase.active;
    setElapsedMs = 0;
    completedReps = 0;
    isPaused = false;
    _startTicker();
    _persist('set_started');
    notifyListeners();
  }

  void togglePause() {
    if (phase != WorkoutPhase.active && phase != WorkoutPhase.rest) return;
    _syncClock();
    if (isPaused) {
      if (resumeCountdownSeconds > 0) return;
      _startResumeCountdown();
      return;
    }
    isPaused = true;
    _resumeCountdownTimer?.cancel();
    resumeCountdownSeconds = 0;
    _persist('session_paused');
    notifyListeners();
  }

  void pauseForInterruption([String reason = 'host_interruption']) {
    if (!isRunning || isPaused) return;
    _syncClock();
    isPaused = true;
    _resumeCountdownTimer?.cancel();
    resumeCountdownSeconds = 0;
    _persist('session_paused', payload: {'reason': reason});
    notifyListeners();
  }

  void registerRep() {
    if (phase != WorkoutPhase.active || isPaused) return;
    _syncClock();
    completedReps = (completedReps + 1).clamp(0, targetReps);
    if (completedReps >= targetReps) {
      completeSet();
      return;
    }
    _persist('rep_recorded');
    notifyListeners();
  }

  void completeSet() {
    if (phase != WorkoutPhase.active) return;
    _syncClock();
    _persistCurrentSet('completed');
    _setsFinished += 1;
    if (currentSet >= totalSets) {
      _finishWorkout();
    } else {
      _beginRest();
    }
  }

  void addRestSeconds([int seconds = 30]) {
    if (phase != WorkoutPhase.rest || isPaused) return;
    _syncClock();
    final extra = seconds * 1000;
    restRemainingMs += extra;
    restDurationMs += extra;
    isLastFiveSeconds = restRemainingMs <= _lastFiveMs;
    _persist('rest_extended', payload: {'seconds': seconds});
    notifyListeners();
  }

  void skipRest() {
    if (phase != WorkoutPhase.rest || isPaused) return;
    _syncClock();
    restRemainingMs = _lastFiveMs;
    isLastFiveSeconds = true;
    _persist('rest_skipped');
    notifyListeners();
  }

  void startNextSetNow() {
    if (phase != WorkoutPhase.rest || isPaused) return;
    _syncClock();
    _advance(autoStart: true);
  }

  /// Long-press-to-end from the Compose original. Abandoned sessions are
  /// not written to the workout log.
  void abortWorkout() {
    stopWorkout(stopReason: 'legacy_abort');
  }

  /// Stops the current workout without discarding completed work. The current
  /// log model cannot yet distinguish completed and stopped sessions; the
  /// SQLite migration will preserve that status explicitly. Until then this
  /// keeps the completed sets and effective duration instead of aborting.
  void stopWorkout({String? stopReason}) {
    justFinished = false;
    _syncClock();
    if (phase == WorkoutPhase.active &&
        (completedReps > 0 || setElapsedMs > 0)) {
      _persistCurrentSet('incomplete');
    }
    _persist('session_stopped', status: 'stopped', stopReason: stopReason);
    if (_setsFinished > 0 || _workoutElapsedMs > 0) {
      _recordWorkout();
    }
    _reset(clearSession: true);
  }

  void _finishWorkout() {
    _syncClock();
    _persist('session_completed', status: 'completed');
    _recordWorkout();
    justFinished = true;
    _reset(clearSession: true);
  }

  void _recordWorkout() {
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
  }

  void _beginRest() {
    phase = WorkoutPhase.rest;
    restRemainingMs = _currentRestMs;
    restDurationMs = _currentRestMs;
    isLastFiveSeconds = false;
    isPaused = false;
    _startTicker();
    _persist('rest_started');
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
      _persist('set_started');
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

  void _reset({bool notify = true, bool clearSession = false}) {
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
    _resumeCountdownTimer?.cancel();
    _resumeCountdownTimer = null;
    resumeCountdownSeconds = 0;
    if (clearSession) _sessionId = null;
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

  void _syncClock({bool notify = false}) {
    final now = _stopwatch.elapsedMilliseconds;
    final dt = now - _lastElapsedMs;
    _lastElapsedMs = now;
    if (dt <= 0) return;

    if (phase == WorkoutPhase.active) {
      if (isPaused) return;
      setElapsedMs += dt;
      _workoutElapsedMs += dt;
      if (notify) notifyListeners();
    } else if (phase == WorkoutPhase.rest) {
      if (isPaused) return;
      _workoutElapsedMs += dt;
      final remaining = (restRemainingMs - dt).clamp(0, 1 << 31);
      restRemainingMs = remaining;
      isLastFiveSeconds = remaining <= _lastFiveMs;
      if (remaining <= 0) {
        _advance(autoStart: true);
        return;
      }
      if (notify) notifyListeners();
    }
  }

  void _onTick() => _syncClock(notify: true);

  void _startResumeCountdown() {
    resumeCountdownSeconds = 3;
    _persist('resume_requested');
    notifyListeners();
    _resumeCountdownTimer?.cancel();
    _resumeCountdownTimer = Timer.periodic(resumeCountdownStep, (timer) {
      resumeCountdownSeconds -= 1;
      if (resumeCountdownSeconds <= 0) {
        timer.cancel();
        _resumeCountdownTimer = null;
        resumeCountdownSeconds = 0;
        isPaused = false;
        _persist('session_resumed');
      }
      notifyListeners();
    });
  }

  void _persist(
    String eventType, {
    String? status,
    String? stopReason,
    Map<String, Object?> payload = const {},
  }) {
    final id = _sessionId;
    final database = _database;
    if (id == null || database == null || plans.isEmpty) return;
    final phaseName = switch (phase) {
      WorkoutPhase.rest => 'rest',
      WorkoutPhase.active => 'active',
      WorkoutPhase.ready => 'ready',
      WorkoutPhase.idle => 'idle',
    };
    unawaited(() async {
      await database.saveSession(
        id: id,
        title: sessionTitle.isEmpty ? exerciseName : sessionTitle,
        status: status ?? (isPaused ? 'paused' : 'active'),
        effectiveDurationMs: _workoutElapsedMs,
        setElapsedMs: setElapsedMs,
        restRemainingMs: restRemainingMs,
        completedSets: _setsFinished,
        totalSets: totalSets,
        currentSet: currentSet,
        currentRep: completedReps,
        targetReps: targetReps,
        phase: phaseName,
        isPaused: isPaused,
        planJson: _encodePlans(plans),
        eventType: eventType,
        stopReason: stopReason,
        payload: payload,
      );
      await database.saveExercise(
        sessionId: id,
        exerciseId: exerciseId,
        label: exerciseName,
        sequence: currentSet,
        status: status ?? (isPaused ? 'paused' : 'active'),
        completedSets: _setsFinished,
        totalSets: totalSets,
      );
    }());
  }

  void _persistCurrentSet(String status) {
    final id = _sessionId;
    final database = _database;
    if (id == null || database == null || plans.isEmpty) return;
    unawaited(
      database.saveSet(
        sessionId: id,
        exerciseId: exerciseId,
        setNumber: currentSet,
        targetReps: targetReps,
        actualReps: completedReps,
        effectiveDurationMs: setElapsedMs,
        status: status,
      ),
    );
  }

  static String _pad(int value) => value.toString().padLeft(2, '0');

  @override
  void dispose() {
    _ticker?.cancel();
    _resumeCountdownTimer?.cancel();
    super.dispose();
  }
}
