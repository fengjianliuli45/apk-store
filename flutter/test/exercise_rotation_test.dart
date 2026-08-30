import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rest_pod_hud/planner/planner_gateway.dart';

/// 任务 D：动作轮换（Dart 端口，对齐 fitness-planner）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const raw = {
    'gender': 'M', 'age': 28, 'height_cm': 178.0, 'weight_kg': 80.0,
    'level': 'intermediate', 'goal': 'hypertrophy', 'minutes_per_session': 75,
    'equipment': ['barbell', 'dumbbell', 'cable', 'machine'],
  };

  List<List<String>> _dayIds(Map<String, dynamic> plan) => [
        for (final s in (plan['training'] as Map)['schedule'] as List)
          if ((s as Map)['type'] != 'rest')
            [for (final e in s['exercises'] as List) (e as Map)['exercise_id'] as String],
      ];

  // 每个肌群本节课第一个动作 = 锚定
  Map<String, String> _anchors(Map<String, dynamic> plan) {
    final out = <String, String>{};
    for (final s in (plan['training'] as Map)['schedule'] as List) {
      if ((s as Map)['type'] == 'rest') continue;
      final seen = <String>{};
      for (final e in s['exercises'] as List) {
        final m = (e as Map)['target_muscle'] as String;
        final key = '${s['day']}|$m';
        if (seen.add(m)) out[key] = e['exercise_id'] as String;
      }
    }
    return out;
  }

  test('anchors stay fixed across exercise_cycle_offset, accessories rotate', () async {
    final gw = await PlannerGateway.instance();
    final p0 = gw.generate({...raw, 'exercise_cycle_offset': 0}).toJson();
    final p1 = gw.generate({...raw, 'exercise_cycle_offset': 1}).toJson();
    final p2 = gw.generate({...raw, 'exercise_cycle_offset': 2}).toJson();

    // 锚定动作三份计划完全一致
    expect(_anchors(p1), _anchors(p0));
    expect(_anchors(p2), _anchors(p0));

    // 但整体动作序列有变化（辅助动作轮换了）
    expect(_dayIds(p1), isNot(_dayIds(p0)));

    for (final entry in {0: p0, 1: p1, 2: p2}.entries) {
      (entry.value['meta'] as Map)['generated_at'] = 'X';
      File('${Directory.systemTemp.path}/dart_rot${entry.key}.json')
          .writeAsStringSync(
              const JsonEncoder.withIndent('  ').convert(entry.value));
    }
  });

  test('home user (bodyweight+band+pull_up_bar) plan — parity dump', () async {
    final gw = await PlannerGateway.instance();
    final plan = gw.generate({
      'gender': 'M', 'age': 25, 'height_cm': 175.0, 'weight_kg': 70.0,
      'level': 'beginner', 'goal': 'hypertrophy', 'minutes_per_session': 45,
      'equipment': const ['bodyweight', 'band', 'pull_up_bar'],
    }).toJson();
    (plan['meta'] as Map)['generated_at'] = 'X';
    File('${Directory.systemTemp.path}/dart_home_plan.json')
        .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(plan));
    // 每个大肌群都被安排到
    final trained = {
      for (final s in (plan['training'] as Map)['schedule'] as List)
        if ((s as Map)['type'] != 'rest')
          for (final e in s['exercises'] as List) (e as Map)['target_muscle']
    };
    for (final m in const ['chest', 'back', 'quads', 'hamstrings', 'shoulders']) {
      expect(trained.contains(m), isTrue, reason: '$m 未安排');
    }
  });

  test('advance check-in bumps exercise_cycle_offset; extend does not', () async {
    final gw = await PlannerGateway.instance();
    final plan = gw.generate(raw).toJson();
    expect((plan['profile'] as Map)['exercise_cycle_offset'], 0);

    // 造一个"阶段达成"的日志：出勤满 + 主项 e1RM 明显进步
    final sched = [
      for (final s in ((plan['training'] as Map)['schedule'] as List).cast<Map>())
        if (s['type'] != 'rest') s,
    ];
    final log = <Map<String, dynamic>>[];
    var d = DateTime(2026, 9, 1);
    for (var w = 0; w < 5; w++) {
      for (final s in sched) {
        final exs = [
          for (final e in s['exercises'] as List)
            {
              'exercise_id': (e as Map)['exercise_id'],
              'planned_sets': e['sets'],
              'sets': [
                for (var i = 0; i < (e['sets'] as int); i++)
                  {
                    'reps': 12,
                    'weight_kg': e['load_kg'] == null
                        ? null
                        : (e['load_kg'] as num) * (1 + 0.02 * w),
                    'rir': 1,
                  }
              ],
            },
        ];
        log.add({
          'date': '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
          'plan_day': 1, 'session_type': s['type'], 'planned_sets': 12,
          'exercises': exs, 'aborted': false,
        });
        d = d.add(const Duration(days: 2));
      }
    }
    final res = gw.runCheckIn(plan, log);
    final review = res['review'] as Map;
    if (review['verdict'] == 'advance') {
      expect((review['next_raw'] as Map)['exercise_cycle_offset'], 1);
    } else {
      // 没达成也不该轮换
      expect((review['next_raw'] as Map)['exercise_cycle_offset'], 0);
    }
  });

  test('bodyweight progression: reps maxed → next plan uses a harder variation', () async {
    final gw = await PlannerGateway.instance();
    const home = {
      'gender': 'M', 'age': 25, 'height_cm': 175.0, 'weight_kg': 70.0,
      'level': 'beginner', 'goal': 'hypertrophy', 'minutes_per_session': 60,
      'equipment': ['bodyweight', 'band', 'pull_up_bar'],
    };
    final plan = gw.generate(home).toJson();
    final sched = [
      for (final s in ((plan['training'] as Map)['schedule'] as List).cast<Map>())
        if (s['type'] != 'rest') s,
    ];
    final log = <Map<String, dynamic>>[];
    var d = DateTime(2026, 9, 1);
    for (var w = 0; w < 4; w++) {
      for (final s in sched) {
        log.add({
          'date': '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
          'plan_day': 1, 'session_type': s['type'], 'planned_sets': 12,
          'exercises': [
            for (final e in s['exercises'] as List)
              {
                'exercise_id': (e as Map)['exercise_id'],
                'planned_sets': e['sets'],
                'sets': [
                  for (var i = 0; i < (e['sets'] as int); i++)
                    {'reps': 12, 'rir': 1},
                ],
              },
          ],
          'aborted': false,
        });
        d = d.add(const Duration(days: 2));
      }
    }
    final res = gw.runCheckIn(plan, log);
    final review = Map<String, dynamic>.from(res['review'] as Map);
    expect((review['bodyweight_changes'] as Map).isNotEmpty, isTrue);
    // 下一份计划的自重锚定动作应比原来难（progression_rank 更高或换了动作）
    final oldFirst = (sched.first['exercises'] as List).first as Map;
    final np = res['next_plan'] as Map;
    (np['meta'] as Map)['generated_at'] = 'X';
    final newFirst = (((np['training'] as Map)['schedule'] as List)
            .cast<Map>()
            .firstWhere((s) => s['type'] != 'rest')['exercises'] as List)
        .first as Map;
    expect(newFirst['exercise_id'], isNot(oldFirst['exercise_id']));
    File('${Directory.systemTemp.path}/dart_bwprog_review.json')
        .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(review));
  });
}
