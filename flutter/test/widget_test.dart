import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rest_pod_hud/main.dart';

Future<void> _skipLogin(WidgetTester tester) async {
  // Default test surface (800x600, landscape-ish) is shorter than any real
  // phone and clips this phone-shaped UI — use a normal portrait size.
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(const RestPodApp());
  // The auth gate shows a CircularProgressIndicator while loading, whose
  // implicit animation never settles — pump a few frames instead of
  // pumpAndSettle() to get past it.
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.tap(find.text('跳过，先看看'));
  await tester.pump();

  // Goal survey (first login only): pick a goal, then continue.
  await tester.tap(find.text('增肌'));
  await tester.pump();
  await tester.tap(find.text('继续'));
  await tester.pump();

  // Profile survey (4 steps, defaults are fine — just walk through).
  await tester.tap(find.text('下一步'));
  await tester.pump();
  await tester.tap(find.text('下一步'));
  await tester.pump();
  await tester.tap(find.text('下一步'));
  await tester.pump();
  await tester.tap(find.text('生成计划'));
  await tester.pump();

  // Generating plan: the exercise-library asset load is real IO — it
  // doesn't respect FakeAsync's virtual clock, so let real time pass
  // first. Then the screen's own minimum-perceived-duration delay
  // (Future.delayed, fake-zone since it's created after that) needs
  // virtual time advanced instead.
  await tester.runAsync(
    () => Future.delayed(const Duration(milliseconds: 500)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1000));
  await tester.pump();

  // Welcome animation: skip straight through, no need to wait on the
  // (missing in tests) MiniMax clip or its placeholder pulse animation.
  await tester.tap(find.text('进入 App'));
  await tester.pump();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('home tab shows STOPWATCH wordmark and start button', (
    tester,
  ) async {
    await _skipLogin(tester);

    expect(find.text('STOPWATCH'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            (widget.data == '开始训练' || widget.data == '今日休息'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('social tab shows seeded posts', (tester) async {
    await _skipLogin(tester);
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();

    expect(find.text('ME'), findsOneWidget);
    expect(find.text('体能维度雷达图'), findsOneWidget);
    expect(find.text('最近训练记录'), findsOneWidget);

    await tester.tap(find.text('社交'));
    await tester.pumpAndSettle();

    expect(find.text('社交圈'), findsOneWidget);
    expect(find.text('完成胸推日'), findsOneWidget);
    expect(find.text('夜跑收工'), findsOneWidget);
    expect(find.byTooltip('消息'), findsOneWidget);

    await tester.tap(find.byTooltip('消息'));
    await tester.pumpAndSettle();

    expect(find.text('消息'), findsOneWidget);
    expect(find.text('林晨'), findsOneWidget);
  });
}
