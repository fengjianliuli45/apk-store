import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/plan_backend_client.dart';
import '../models/workout_log.dart';
import '../planner/check_in.dart';
import '../planner/models.dart';
import '../planner/planner_gateway.dart';

class PlanVersionRecord {
  const PlanVersionRecord({
    required this.number,
    required this.createdAt,
    required this.plannerVersion,
    required this.changeReason,
    required this.planJson,
    required this.inputSnapshot,
    required this.synced,
  });

  final int number;
  final DateTime createdAt;
  final String plannerVersion;
  final String changeReason;
  final Map<String, dynamic> planJson;
  final Map<String, dynamic> inputSnapshot;
  final bool synced;

  PlanVersionRecord copyWith({bool? synced}) => PlanVersionRecord(
        number: number,
        createdAt: createdAt,
        plannerVersion: plannerVersion,
        changeReason: changeReason,
        planJson: planJson,
        inputSnapshot: inputSnapshot,
        synced: synced ?? this.synced,
      );

  Map<String, dynamic> toJson() => {
        'number': number,
        'created_at': createdAt.toIso8601String(),
        'planner_version': plannerVersion,
        'change_reason': changeReason,
        'plan_json': planJson,
        'input_snapshot': inputSnapshot,
        'synced': synced,
      };

  factory PlanVersionRecord.fromJson(Map<String, dynamic> json) =>
      PlanVersionRecord(
        number: (json['number'] as num).toInt(),
        createdAt: DateTime.parse(json['created_at'] as String),
        plannerVersion: json['planner_version'] as String,
        changeReason: json['change_reason'] as String,
        planJson: Map<String, dynamic>.from(json['plan_json'] as Map),
        inputSnapshot: Map<String, dynamic>.from(
          json['input_snapshot'] as Map? ?? const {},
        ),
        synced: (json['synced'] as bool?) ?? false,
      );
}

class PlanReviewResult {
  const PlanReviewResult({required this.review, required this.nextPlan});

  final Map<String, dynamic> review;
  final GeneratedPlan? nextPlan;

  String get verdict => review['verdict'] as String? ?? 'extend';
  bool get canAdopt => nextPlan != null && verdict != 'address_safety';
}

/// Owns the current plan and an append-only local version history. The Dart
/// engine is authoritative; backend persistence is best-effort and never
/// blocks local training.
class PlanController extends ChangeNotifier {
  PlanController({PlanRemoteStore? remoteStore})
      : _remoteStore = remoteStore ?? const PlanBackendClient();

  static const _kPlan = 'generated_plan_json';
  static const _kVersions = 'generated_plan_versions_v1';
  static const _kCheckPromptedAt = 'check_prompt_generated_at';
  static const _kCheckPromptedWeek = 'check_prompt_week';

  final PlanRemoteStore _remoteStore;
  final List<PlanVersionRecord> versions = [];
  GeneratedPlan? plan;
  String? checkPromptedAt;
  int checkPromptedWeek = 0;
  bool syncing = false;
  String? lastSyncError;

  bool get hasPlan => plan != null;
  int get currentVersion => versions.isEmpty ? 0 : versions.last.number;
  String get versionLabel => currentVersion == 0 ? '—' : 'v$currentVersion';
  String get plannerVersion => _plannerVersion(plan?.toJson() ?? const {});
  String get syncLabel {
    if (syncing) return '正在同步';
    if (versions.isEmpty) return '尚未保存';
    if (versions.last.synced) return '云端已同步';
    return _remoteStore.isConfigured ? '等待重试同步' : '本地已保存';
  }

  bool get needsCheckInPrompt {
    final current = plan;
    if (current == null) return false;
    return shouldPromptCheckIn(
      plan: current,
      promptedGeneratedAt: checkPromptedAt,
      promptedWeek: checkPromptedWeek,
    );
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawVersions = prefs.getString(_kVersions);
    if (rawVersions != null) {
      try {
        versions
          ..clear()
          ..addAll(
            (jsonDecode(rawVersions) as List).map(
              (item) => PlanVersionRecord.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            ),
          );
      } catch (_) {
        versions.clear();
      }
    }
    final raw = prefs.getString(_kPlan);
    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        plan = GeneratedPlan.fromJson(json);
        final normalizedJson = plan!.toJson();
        if (versions.isEmpty) {
          versions.add(
            PlanVersionRecord(
              number: 1,
              createdAt: plan!.generatedAt,
              plannerVersion: _plannerVersion(normalizedJson),
              changeReason: 'migrated-local-plan',
              planJson: normalizedJson,
              inputSnapshot: plan!.profile.toJson(),
              synced: false,
            ),
          );
          await _persistVersions(prefs);
        } else if (versions.last.changeReason == 'migrated-local-plan' &&
            versions.last.plannerVersion != _plannerVersion(normalizedJson)) {
          // Early migration builds preserved the legacy metadata (for example
          // engine 1.1) even though the in-memory plan had already been
          // normalized to the current schema. Repair that single migration
          // record so the "current" history row matches the visible plan.
          final legacy = versions.last;
          versions[versions.length - 1] = PlanVersionRecord(
            number: legacy.number,
            createdAt: legacy.createdAt,
            plannerVersion: _plannerVersion(normalizedJson),
            changeReason: legacy.changeReason,
            planJson: normalizedJson,
            inputSnapshot: legacy.inputSnapshot,
            synced: legacy.synced,
          );
          await _persistVersions(prefs);
        }
      } catch (_) {
        plan = null;
      }
    }
    checkPromptedAt = prefs.getString(_kCheckPromptedAt);
    checkPromptedWeek = prefs.getInt(_kCheckPromptedWeek) ?? 0;
    notifyListeners();
  }

  Future<void> markCheckPrompted({required DateTime generatedAt, required int week}) async {
    checkPromptedAt = generatedAt.toIso8601String();
    checkPromptedWeek = week;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCheckPromptedAt, checkPromptedAt!);
    await prefs.setInt(_kCheckPromptedWeek, week);
  }

  Future<void> save(
    GeneratedPlan value, {
    String changeReason = 'profile-generated',
    Map<String, dynamic>? inputSnapshot,
  }) async {
    final json = value.toJson();
    final record = PlanVersionRecord(
      number: currentVersion + 1,
      createdAt: DateTime.now().toUtc(),
      plannerVersion: _plannerVersion(json),
      changeReason: changeReason,
      planJson: json,
      inputSnapshot: inputSnapshot ?? value.profile.toJson(),
      synced: false,
    );
    plan = value;
    versions.add(record);
    checkPromptedAt = null;
    checkPromptedWeek = 0;
    lastSyncError = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPlan, jsonEncode(json));
    await _persistVersions(prefs);
    await prefs.remove(_kCheckPromptedAt);
    await prefs.remove(_kCheckPromptedWeek);
    await _syncRecord(record.number);
  }

  Future<PlanReviewResult> reviewCurrentCycle(
    List<WorkoutLogEntry> logs,
  ) async {
    final current = plan;
    if (current == null) throw StateError('No plan to review');
    final start = current.generatedAt;
    final cycleWeeks = current.stageGoal?.cycleWeeks ??
        current.mesocycle?.lengthWeeks ??
        current.progression.nextCheckWeek;
    final end = start.add(Duration(days: cycleWeeks * 7));
    final cycleLogs = logs
        .where((entry) => !entry.at.isBefore(start) && entry.at.isBefore(end))
        .map(_workoutForEngine)
        .toList();
    final gateway = await PlannerGateway.instance();
    final output = gateway.runCheckIn(
      current.toJson(),
      cycleLogs,
      completedCycles: (currentVersion - 1).clamp(0, 999),
    );
    final nextJson = output['next_plan'] as Map?;
    return PlanReviewResult(
      review: Map<String, dynamic>.from(output['review'] as Map),
      nextPlan: nextJson == null
          ? null
          : GeneratedPlan.fromJson(Map<String, dynamic>.from(nextJson)),
    );
  }

  Future<void> adoptReview(PlanReviewResult result) async {
    final next = result.nextPlan;
    if (next == null) throw StateError('This review has no adoptable plan');
    await save(
      next,
      changeReason: 'check-in: ${result.verdict}',
      inputSnapshot: next.profile.toJson(),
    );
  }

  Future<void> restoreVersion(int number) async {
    final record = versions.where((item) => item.number == number).firstOrNull;
    if (record == null) throw ArgumentError.value(number, 'number');
    await save(
      GeneratedPlan.fromJson(record.planJson),
      changeReason: 'restore: v$number',
      inputSnapshot: record.inputSnapshot,
    );
  }

  Future<void> retryPendingSync() async {
    for (final record in versions.where((item) => !item.synced).toList()) {
      await _syncRecord(record.number);
      if (lastSyncError != null) break;
    }
  }

  Future<void> _syncRecord(int number) async {
    if (!_remoteStore.isConfigured) return;
    final index = versions.indexWhere((item) => item.number == number);
    if (index < 0 || versions[index].synced) return;
    syncing = true;
    lastSyncError = null;
    notifyListeners();
    try {
      final record = versions[index];
      await _remoteStore.savePlan(
        plannerVersion: record.plannerVersion,
        inputSnapshot: record.inputSnapshot,
        planJson: record.planJson,
        changeReason: record.changeReason,
      );
      versions[index] = record.copyWith(synced: true);
      await _persistVersions(await SharedPreferences.getInstance());
    } catch (error) {
      lastSyncError = '$error';
    } finally {
      syncing = false;
      notifyListeners();
    }
  }

  Future<void> _persistVersions(SharedPreferences prefs) => prefs.setString(
        _kVersions,
        jsonEncode(versions.map((item) => item.toJson()).toList()),
      );

  static String _plannerVersion(Map<String, dynamic> json) =>
      ((json['meta'] as Map?)?['version'] as String?) ?? '1.8';

  static Map<String, dynamic> _workoutForEngine(WorkoutLogEntry entry) => {
        'date': entry.at.toUtc().toIso8601String().split('T').first,
        'plan_day': entry.at.weekday,
        'session_type': 'logged',
        'planned_sets': entry.totalSets,
        // Aggregate local logs do not yet contain load/RIR details. A
        // synthetic exercise carries only set completion so the engine can
        // count attendance without inventing performance evidence.
        'exercises': [
          {
            'exercise_id': 'aggregate_log',
            'planned_sets': entry.totalSets,
            'sets': [
              for (var index = 0; index < entry.completedSets; index++)
                const <String, dynamic>{},
            ],
          },
        ],
        'aborted': entry.completedSets * 2 < entry.totalSets,
        'pain_flag': false,
      };
}
