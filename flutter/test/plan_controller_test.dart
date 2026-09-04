import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rest_pod_hud/data/plan_backend_client.dart';
import 'package:rest_pod_hud/models/workout_log.dart';
import 'package:rest_pod_hud/planner/planner_gateway.dart';
import 'package:rest_pod_hud/state/plan_controller.dart';

class _FakeRemoteStore implements PlanRemoteStore {
  _FakeRemoteStore({this.isConfigured = true});

  @override
  final bool isConfigured;
  final List<Map<String, dynamic>> saved = [];

  @override
  Future<void> savePlan({
    required String plannerVersion,
    required Map<String, dynamic> inputSnapshot,
    required Map<String, dynamic> planJson,
    required String changeReason,
  }) async {
    saved.add({
      'plannerVersion': plannerVersion,
      'inputSnapshot': inputSnapshot,
      'planJson': planJson,
      'changeReason': changeReason,
    });
  }
}

const _raw = <String, dynamic>{
  'gender': 'M',
  'age': 28,
  'height_cm': 178.0,
  'weight_kg': 76.0,
  'level': 'beginner',
  'goal': 'hypertrophy',
  'minutes_per_session': 60,
  'equipment': ['bodyweight', 'dumbbell'],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('save appends immutable versions and syncs the OpenAPI payload', () async {
    final remote = _FakeRemoteStore();
    final plan = (await PlannerGateway.instance()).generate(_raw);
    final controller = PlanController(remoteStore: remote);

    await controller.save(plan, inputSnapshot: _raw);
    await controller.save(plan, changeReason: 'check-in: extend');

    expect(controller.currentVersion, 2);
    expect(controller.versions.map((item) => item.number), [1, 2]);
    expect(controller.versions.every((item) => item.synced), isTrue);
    expect(remote.saved, hasLength(2));
    expect(remote.saved.first['plannerVersion'], '1.8');

    final restored = PlanController(remoteStore: _FakeRemoteStore());
    await restored.load();
    expect(restored.currentVersion, 2);
    expect(restored.plan, isNotNull);
  });

  test('restoring an old plan creates a new rollback-safe version', () async {
    final plan = (await PlannerGateway.instance()).generate(_raw);
    final controller = PlanController(remoteStore: _FakeRemoteStore());
    await controller.save(plan);
    await controller.save(plan, changeReason: 'profile-generated');

    await controller.restoreVersion(1);

    expect(controller.currentVersion, 3);
    expect(controller.versions.last.changeReason, 'restore: v1');
  });

  test('legacy local plan migration normalizes engine metadata', () async {
    final plan = (await PlannerGateway.instance()).generate(_raw);
    final legacyJson = plan.toJson();
    (legacyJson['meta'] as Map<String, dynamic>)['version'] = '1.1';
    SharedPreferences.setMockInitialValues({
      'generated_plan_json': jsonEncode(legacyJson),
    });

    final controller = PlanController(
      remoteStore: _FakeRemoteStore(isConfigured: false),
    );
    await controller.load();

    expect(controller.versions, hasLength(1));
    expect(controller.versions.single.changeReason, 'migrated-local-plan');
    expect(controller.versions.single.plannerVersion, '1.8');
    expect(
      ((controller.versions.single.planJson['meta'] as Map)['version']),
      '1.8',
    );
  });

  test('cycle review uses the deterministic engine and never invents evidence', () async {
    final plan = (await PlannerGateway.instance()).generate(_raw);
    final controller = PlanController(remoteStore: _FakeRemoteStore(isConfigured: false));
    await controller.save(plan);

    final review = await controller.reviewCurrentCycle([
      WorkoutLogEntry(
        id: 'aggregate-1',
        title: '训练',
        timestampMs: DateTime.now().millisecondsSinceEpoch,
        durationMs: 30 * 60 * 1000,
        completedSets: 8,
        totalSets: 10,
        estimatedKcal: 120,
      ),
    ]);

    expect(review.verdict, 'extend');
    expect(review.nextPlan, isNotNull);
    expect((review.review['assessment'] as Map)['data_quality_met'], isFalse);
    expect(review.review['summary'], contains('1/'));
  });
}
