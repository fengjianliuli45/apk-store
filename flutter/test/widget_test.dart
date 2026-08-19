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
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('home tab shows STOPWATCH wordmark and start button', (tester) async {
    await _skipLogin(tester);

    expect(find.text('STOPWATCH'), findsOneWidget);
    expect(find.text('开始训练'), findsOneWidget);
  });

  testWidgets('social tab shows seeded posts', (tester) async {
    await _skipLogin(tester);
    await tester.tap(find.byIcon(Icons.groups));
    await tester.pump();

    expect(find.text('社交圈'), findsOneWidget);
    expect(find.text('完成胸推日'), findsOneWidget);
    expect(find.text('夜跑收工'), findsOneWidget);
  });
}
