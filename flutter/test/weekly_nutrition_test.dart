import 'package:flutter_test/flutter_test.dart';
import 'package:rest_pod_hud/planner/planner_gateway.dart';
import 'package:rest_pod_hud/planner/plan_sync.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('deload diet applies energy delta, preserves protein/fat, redistributes all meals', () async {
    final gateway = await PlannerGateway.instance();
    final plan = gateway.generate({
      'gender': 'M',
      'age': 28,
      'height_cm': 178,
      'weight_kg': 80,
      'level': 'intermediate',
      'goal': 'fat_loss',
      'minutes_per_session': 75,
      'equipment': ['dumbbell'],
      'days_per_week': 3,
      'dietary_restrictions': ['vegan'],
      'kcal_adjust': 100,
      'meals_per_day': 6,
    });
    final before = plan.toJson().toString();
    final normal = DietGoals.fromPlan(plan, now: plan.generatedAt);
    final adjusted = DietGoals.fromPlan(
      plan,
      now: plan.generatedAt.add(const Duration(days: 28)),
    );
    expect(adjusted.kcal, normal.kcal + 400);
    // Same fixture asserted in the authoritative Python projection test.
    expect(adjusted.kcal, 2855);
    expect(adjusted.proteinG, 200);
    expect(adjusted.fatG, 64);
    expect(adjusted.carbG, 370);
    expect(adjusted.proteinG, normal.proteinG);
    expect(adjusted.fatG, normal.fatG);
    expect(adjusted.carbG, normal.carbG + 100);
    expect(
      adjusted.meals.fold<double>(0, (sum, m) => sum + m.kcal),
      closeTo(adjusted.kcal, 1),
    );
    expect(adjusted.cycleNote, contains('+400'));
    expect(adjusted.dietaryRestrictions, contains('vegan'));
    expect(plan.toJson().toString(), before);
  });
}
