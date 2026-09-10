import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest_pod_hud/screens/home_screen.dart';
import 'package:rest_pod_hud/state/diet_log_controller.dart';
import 'package:rest_pod_hud/state/workout_log_controller.dart';
import 'package:rest_pod_hud/state/workout_session_controller.dart';

void main() {
  testWidgets('rest day explains schedule and preview does not start workout', (
    tester,
  ) async {
    const channel = MethodChannel('com.restpod.hud/unity');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (_) async => false,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = WorkoutSessionController()
      ..plans = []
      ..isRestDay = true;
    addTearDown(session.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          session: session,
          dietLog: DietLogController(),
          workoutLog: WorkoutLogController(),
          plannedDaysPerWeek: 3,
          onOpenProfile: () {},
          onOpenSocial: () {},
          onEditPlan: () {},
          nextTrainingLabel: '下次训练：9月11日 周五 · 全身',
          previewExercises: const [SetPlan('bodyweight_squat', '徒手深蹲', 0)],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('今日休息'));
    await tester.pumpAndSettle();
    expect(find.text('今日按计划恢复'), findsOneWidget);
    await tester.tap(find.text('知道了'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('查看动作演示 · 不计入训练'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('徒手深蹲'));
    await tester.pumpAndSettle();
    expect(find.text('动作演示 · 不计入训练'), findsOneWidget);
    expect(find.textContaining('暂不支持 Unity'), findsOneWidget);
    expect(session.isRestDay, true);
    expect(session.phase, WorkoutPhase.idle);
    expect(session.hasResumableSession, false);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
