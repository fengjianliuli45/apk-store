import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest_pod_hud/widgets/planner_constraints_fields.dart';

void main() {
  testWidgets(
    'constraints preserve untouched baseline and validate edited values',
    (tester) async {
      Map<String, dynamic>? result;
      String? error;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PlannerConstraintsFields(
                initial: const {
                  'strength_baseline': {
                    'bench': {'weight_kg': 50, 'reps': 8},
                  },
                  'kcal_adjust': 100,
                },
                onChanged: (values, issue) {
                  result = values;
                  error = issue;
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('伤病、饮食与力量基线'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, '膝'));
      await tester.pump();
      expect(result!['injuries'], ['knee']);
      expect(result!['strength_baseline']['bench'], {
        'weight_kg': 50,
        'reps': 8,
      });
      expect(result!['kcal_adjust'], 100);
      final field = find.byKey(const ValueKey('baseline_squat'));
      await tester.ensureVisible(field);
      await tester.enterText(field, '-1');
      await tester.pump();
      expect(error, isNotNull);
      await tester.enterText(field, '80');
      await tester.pump();
      expect(error, isNull);
      expect(result!['strength_baseline']['squat'], {'one_rm_kg': 80.0});
      await tester.enterText(field, '');
      await tester.pump();
      expect(result!['strength_baseline'].containsKey('squat'), isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}
