import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest_pod_hud/screens/placeholder_screens.dart';
import 'package:rest_pod_hud/state/workout_session_controller.dart';

void main() {
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
