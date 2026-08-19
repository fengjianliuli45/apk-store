import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rest_pod_hud/main.dart';

void main() {
  testWidgets('home tab shows STOPWATCH wordmark and start button', (tester) async {
    await tester.pumpWidget(const RestPodApp());

    expect(find.text('STOPWATCH'), findsOneWidget);
    expect(find.text('开始训练'), findsOneWidget);
  });

  testWidgets('social tab shows seeded posts', (tester) async {
    await tester.pumpWidget(const RestPodApp());
    await tester.tap(find.byIcon(Icons.groups));
    await tester.pumpAndSettle();

    expect(find.text('社交圈'), findsOneWidget);
    expect(find.text('完成胸推日'), findsOneWidget);
    expect(find.text('夜跑收工'), findsOneWidget);
  });
}
