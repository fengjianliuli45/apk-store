import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest_pod_hud/screens/placeholder_screens.dart';
import 'package:rest_pod_hud/state/workout_session_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.restpod.hud/unity'),
          (call) async => call.method == 'isAvailable' ? false : null,
        );
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.restpod.hud/unity'),
          null,
        );
  });
  testWidgets(
    'background pauses fallback and foreground requires explicit resume',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final session = WorkoutSessionController()
        ..plans = const [SetPlan('bodyweight_squat', '徒手深蹲', 12)]
        ..startSession()
        ..startSet();
      await tester.pumpWidget(
        MaterialApp(home: UnityCoachPlaceholderScreen(session: session)),
      );
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(session.isPaused, isTrue);
      final elapsed = session.setElapsedMs;
      await tester.pump(const Duration(seconds: 10));
      expect(session.setElapsedMs, elapsed);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.text('继续训练'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      session.dispose();
    },
  );

  testWidgets('ten sets and duplicate taps finish once and return home', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = WorkoutSessionController()
      ..plans = List.generate(
        10,
        (_) => const SetPlan('bodyweight_squat', '徒手深蹲', 12),
      )
      ..startSession()
      ..startSet();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => UnityCoachPlaceholderScreen(session: session),
                ),
              ),
              child: const Text('首页'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('首页'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    for (var i = 1; i <= 10; i++) {
      expect(session.currentSet, i);
      final complete = tester
          .widget<GestureDetector>(
            find
                .ancestor(
                  of: find.text('完成这组'),
                  matching: find.byType(GestureDetector),
                )
                .first,
          )
          .onTap!;
      complete();
      complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('记录本组'), findsOneWidget);
      final save = tester
          .widget<GestureDetector>(
            find
                .ancestor(
                  of: find.text('保存并完成本组'),
                  matching: find.byType(GestureDetector),
                )
                .first,
          )
          .onTap!;
      save();
      save();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      if (i < 10) {
        expect(session.phase, WorkoutPhase.rest);
        await tester.tap(find.text('进入下一组'));
        await tester.pump();
      }
    }
    expect(session.justFinished, isTrue);
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('训练舱'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    session.dispose();
  });

  testWidgets(
    'interrupted fallback session can resume before recording a set',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final session = WorkoutSessionController()
        ..plans = const [SetPlan('bodyweight_squat', '徒手深蹲', 12)]
        ..startSession()
        ..startSet()
        ..pauseForInterruption();
      await tester.pumpWidget(
        MaterialApp(home: UnityCoachPlaceholderScreen(session: session)),
      );
      await tester.pump();
      expect(find.text('已暂停'), findsOneWidget);
      expect(find.text('完成这组'), findsNothing);
      await tester.tap(find.text('继续训练'));
      await tester.pump();
      expect(find.text('3 秒后继续'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      expect(session.isPaused, isFalse);
      expect(find.text('完成这组'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(session.setElapsedMs, greaterThan(0));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      session.dispose();
    },
  );

  testWidgets(
    'evidence sheet owns controllers until its exit animation finishes',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final session = WorkoutSessionController()
        ..plans = const [SetPlan('bodyweight_squat', '徒手深蹲', 12)]
        ..startSession()
        ..startSet();

      await tester.pumpWidget(
        MaterialApp(home: UnityCoachPlaceholderScreen(session: session)),
      );
      await tester.pump();

      await tester.tap(find.text('完成这组'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('记录本组'), findsOneWidget);

      await tester.tap(find.byType(TextField).first);
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('记录本组'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      session.dispose();
    },
  );
}
