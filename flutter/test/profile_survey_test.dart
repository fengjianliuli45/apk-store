import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest_pod_hud/screens/profile_survey_screen.dart';
import 'package:rest_pod_hud/planner/planner_gateway.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PlannerGateway gateway;
  setUpAll(() async => gateway = await PlannerGateway.instance());
  testWidgets('survey enforces engine minimum and removes explicit frequency', (
    tester,
  ) async {
    final minimum = gateway.minSessionMinutes(
      level: 'beginner',
      goal: 'hypertrophy',
      equipment: ['bodyweight', 'dumbbell'],
    );
    Map<String, dynamic>? submitted;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileSurveyScreen(
            engineGoal: 'hypertrophy',
            initialFields: const {
              'days_per_week': 7,
              'minutes_per_session': 15,
            },
            onSubmit: (fields) => submitted = fields,
          ),
        ),
      ),
    );
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('下一步'));
      await tester.pumpAndSettle();
    }
    expect(find.text('每次至少 $minimum 分钟'), findsOneWidget);
    expect(find.text('15 分钟'), findsNothing);
    expect(find.text('每周天数'), findsNothing);
    await tester.tap(find.text('生成计划'));
    expect(submitted, isNotNull);
    expect(submitted!.containsKey('days_per_week'), false);
    expect(submitted!['minutes_per_session'], greaterThanOrEqualTo(minimum));
    final plan = gateway.generate({...submitted!, 'goal': 'hypertrophy'});
    expect(plan.profile.daysPerWeek, 3);
    expect(tester.takeException(), isNull);
  });
}
