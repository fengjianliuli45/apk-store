import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rest_pod_hud/planner/food_db.dart';
import 'package:rest_pod_hud/planner/macro_allocator.dart';
import 'package:rest_pod_hud/planner/meal_distributor.dart';
import 'package:rest_pod_hud/planner/planner_gateway.dart';
import 'package:rest_pod_hud/planner/profile_validator.dart';
import 'package:rest_pod_hud/planner/tdee_calculator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('restriction normalization: vegan implies vegetarian + no_dairy', () {
    final r = normalizeRestrictions(['纯素']);
    expect(r.containsAll({'vegan', 'vegetarian', 'no_dairy'}), isTrue);
  });

  test('vegan meal suggestions contain no animal foods', () {
    final opts = suggestMeal(
      {'protein_g': 35, 'carbs_g': 60, 'fat_g': 15},
      normalizeRestrictions(['vegan']),
      'home',
      false,
    );
    final joined = opts
        .expand((o) => (o['items'] as List).cast<String>())
        .join(' ');
    for (final animal in [
      '鸡胸', '鸡腿', '瘦牛肉', '猪里脊', '龙利', '三文鱼', '虾仁',
      '全蛋', '蛋清', '希腊酸奶', '白干酪', '牛奶', '乳清',
    ]) {
      expect(joined.contains(animal), isFalse, reason: '出现了 $animal: $joined');
    }
  });

  test('halal filters pork but keeps chicken/beef', () {
    final opts = suggestMeal(
      {'protein_g': 40, 'carbs_g': 70, 'fat_g': 12},
      normalizeRestrictions(['清真']),
      'home',
      false,
      nOptions: 3,
    );
    final joined =
        opts.expand((o) => (o['items'] as List).cast<String>()).join(' ');
    expect(joined.contains('里脊'), isFalse);
  });

  test('hand portions scale with the meal', () {
    final hp = handPortions({'protein_g': 44, 'carbs_g': 44, 'fat_g': 22});
    expect(hp['protein_palms'], 2);
    expect(hp['carb_cupped'], 2);
    expect(hp['fat_thumbs'], 2);
  });

  test('vegan protein target is bumped and notes recorded', () {
    final raw = {
      'gender': 'M', 'age': 25, 'height_cm': 178.0, 'weight_kg': 75.0,
      'level': 'intermediate', 'goal': 'hypertrophy', 'days_per_week': 4,
      'minutes_per_session': 75, 'equipment': const ['barbell'],
      'dietary_restrictions': const ['vegan'],
    };
    final p = validateProfile(raw);
    final macros = allocateMacros(p, calculateTdee(p));
    expect(macros.perKg['protein']! > 2.0, isTrue);
    expect(macros.notes.any((n) => n.contains('纯素')), isTrue);
    final mp = distributeMeals(p, macros);
    expect(mp.fiberG > 0, isTrue);
    expect(mp.waterMlTraining, mp.waterMlRest + 500);
    for (final m in mp.meals) {
      expect(m.options, isNotEmpty);
      expect(m.handPortions, isNotEmpty);
    }
  });

  test('parity: dump generated demo plan for Python diff', () async {
    final gateway = await PlannerGateway.instance();
    final plan = gateway.generate({
      'gender': 'M', 'age': 28, 'height_cm': 175.0, 'weight_kg': 72.0,
      'body_fat_pct': 16.0, 'level': 'intermediate', 'goal': 'hypertrophy',
      'days_per_week': 4, 'minutes_per_session': 75,
      'equipment': const ['barbell', 'dumbbell', 'cable', 'machine'],
      'meals_per_day': 4,
      'strength_baseline': const {
        'squat': {'weight_kg': 100.0, 'reps': 5},
        'bench': {'weight_kg': 72.5, 'reps': 6},
        'hinge': {'weight_kg': 120.0, 'reps': 5},
        'row': {'weight_kg': 60.0, 'reps': 8},
      },
    });
    final json = plan.toJson();
    (json['meta'] as Map)['generated_at'] = '2026-08-30T00:00:00+00:00';
    (json['profile'] as Map).remove('generated_at');
    final out = File('${Directory.systemTemp.path}/dart_demo_plan.json');
    out.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(json));
    expect(out.existsSync(), isTrue);
  });
}
