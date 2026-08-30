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

  test('parity: fat_loss + vegan plan (diet break) + check-in for Python diff', () async {
    final gateway = await PlannerGateway.instance();
    final raw = {
      'gender': 'F', 'age': 30, 'height_cm': 166.0, 'weight_kg': 62.0,
      'level': 'intermediate', 'goal': 'fat_loss',
      'days_per_week': 4, 'minutes_per_session': 55,
      'equipment': const ['dumbbell', 'barbell'], 'meals_per_day': 4,
      'dietary_restrictions': const ['vegan'], 'cooking_access': 'canteen',
    };
    final plan = gateway.generate(raw);
    final pj = plan.toJson();
    (pj['meta'] as Map)['generated_at'] = '2026-08-30T00:00:00+00:00';
    File('${Directory.systemTemp.path}/dart_fatloss_plan.json')
        .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(pj));

    // ~4 周慢速掉秤 → 期望加缺口 -150
    const dates = ['2026-06-01', '2026-06-08', '2026-06-15', '2026-06-22', '2026-06-29', '2026-07-06'];
    final body = [
      for (var i = 0; i < dates.length; i++)
        {'date': dates[i], 'weight_kg': 62.0 - i * 0.11},
    ];
    final log = [
      for (final d in const [
        '2026-06-01', '2026-06-03', '2026-06-05', '2026-06-08', '2026-06-10',
        '2026-06-12', '2026-06-15', '2026-06-17', '2026-06-19', '2026-06-22',
        '2026-06-24', '2026-06-26'
      ])
        {
          'date': d, 'plan_day': 1, 'session_type': 'full', 'planned_sets': 12,
          'exercises': const [], 'aborted': false,
        },
    ];
    final res = gateway.runCheckIn(pj, log.cast<Map<String, dynamic>>(),
        bodyLog: body.cast<Map<String, dynamic>>());
    final review = Map<String, dynamic>.from(res['review'] as Map);
    // next_plan 的 generated_at 会变，剔掉再 dump
    if (res['next_plan'] != null) {
      final np = Map<String, dynamic>.from(res['next_plan'] as Map);
      (np['meta'] as Map)['generated_at'] = 'X';
      review['_next_plan'] = np;
    }
    File('${Directory.systemTemp.path}/dart_fatloss_review.json')
        .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(review));
    expect(review['kcal_change'], -150);

    // 减脂中周期减载周 = diet break（热量提到维持量）
    final deload =
        ((pj['training'] as Map)['mesocycle'] as Map)['weeks'] as List;
    expect((deload.last as Map)['diet_break'], true);
    expect((deload.last as Map)['diet_kcal_delta'], greaterThan(0));
    // 下一份计划确实降了热量
    final nextKcal = (((review['_next_plan'] as Map)['nutrition'] as Map)['macros']
        as Map)['daily_targets'] as Map;
    final baseKcal =
        ((pj['nutrition'] as Map)['macros'] as Map)['daily_targets'] as Map;
    expect((nextKcal['kcal'] as num) < (baseKcal['kcal'] as num), true);
  });
}
