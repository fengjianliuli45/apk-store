import 'models.dart';

/// Port of fitness-planner's `explain_generator.py` — template-based (no
/// LLM call), turns the generated plan into readable Chinese copy.
const _evidenceDesc = {
  '41843416': 'ACSM 2026 立场——全部训练变量',
  '28834797': 'Schoenfeld 2017——低负荷 vs 高负荷等效',
  '27102172': 'Schoenfeld 2016——每肌群 2 次/周最优',
  '27433992': 'Schoenfeld 2017——组数剂量反应',
  '28698222': 'Morton 2018——蛋白质补充→增肌荟萃分析',
  '29414855': 'Stokes 2018——MPS 剂量反应',
  '37432300': 'Burke 2023——肌酸→增肌荟萃分析',
  '26817506': 'Longland 2016——缺口期高蛋白保肌',
};

String explainPlan({
  required UserProfile profile,
  required TDEEResult tdee,
  required MacroResult macros,
  required SplitResult split,
  required ProgressionResult progression,
}) {
  final lines = <String>[];

  lines.add(''.padRight(60, '='));
  lines.add('🏋️ 你的健身智能规划方案');
  lines.add(''.padRight(60, '='));
  lines.add('');

  lines.add('📋 身体数据');
  lines.add('  性别: ${profile.gender} | 年龄: ${profile.age} | BMI: ${profile.bmi}');
  if (profile.bodyFatPct != null) {
    lines.add('  体脂率: ${profile.bodyFatPct}% → 使用 Katch-McArdle 公式');
  } else {
    lines.add('  体脂率: 未提供 → 使用 Mifflin-St Jeor 公式');
  }
  lines.add('  训练水平: ${profile.level} | 目标: ${profile.goal}');
  lines.add('  每周训练: ${profile.daysPerWeek} 天 × ${profile.minutesPerSession} 分钟');
  lines.add('');

  lines.add('🔥 每日热量');
  lines.add('  BMR: ${tdee.bmr.toStringAsFixed(0)} kcal（${tdee.formulaUsed}）');
  lines.add('  TDEE: ${tdee.tdee.toStringAsFixed(0)} kcal（活动水平: ${tdee.activityLevel}, 乘数: ${tdee.activityMultiplier}）');
  final surplusText = switch (profile.goal) {
    'hypertrophy' => '增肌盈余 +${macros.surplusKcal} kcal',
    'fat_loss' => '减脂缺口 ${macros.surplusKcal} kcal',
    'strength' => '微盈余 +${macros.surplusKcal} kcal',
    'recomposition' => '维持热量',
    _ => '维持热量',
  };
  lines.add('  方向: $surplusText');
  lines.add('  目标每日热量: ${macros.dailyTargets['kcal']} kcal');
  lines.add('');

  lines.add('🥩 三大营养素');
  final dt = macros.dailyTargets;
  lines.add('  蛋白质: ${dt['protein_g']}g (${macros.perKg['protein']}g/kg)');
  final pk = macros.perKg['protein'];
  if (profile.goal == 'hypertrophy') {
    lines.add('    → 根据 Morton 2018（PMID 28698222）对 49 项研究、1863 名参与者的荟萃分析，蛋白质摄入 ${pk}g/kg 有助于最大化增肌效果。');
  } else if (profile.goal == 'fat_loss') {
    lines.add('    → 根据 Longland 2016（PMID 26817506），热量缺口期 ${pk}g/kg 蛋白质可有效保护瘦体重。');
  }
  lines.add('  脂肪: ${dt['fat_g']}g (${macros.perKg['fat']}g/kg)');
  lines.add('  碳水: ${dt['carbs_g']}g (${macros.perKg['carbs']}g/kg)');
  lines.add('');

  lines.add('💪 训练分肢');
  lines.add('  方案: ${split.splitName}');
  for (final day in split.weeklySchedule) {
    final icon = day.type == 'rest' ? '🏠' : '🏋️';
    lines.add('  ${day.day}: $icon ${day.type}');
  }
  for (final w in split.warnings) {
    lines.add('  ⚠️ $w');
  }
  lines.add('');

  lines.add('📈 渐进超负荷');
  lines.add('  策略: ${progression.strategy}');
  lines.add('  频率: ${progression.progressionFreq}');
  lines.add('  上肢加重: +${progression.incrementUpperKg}kg/次');
  lines.add('  下肢加重: +${progression.incrementLowerKg}kg/次');
  lines.add('  双进阶: ${progression.doubleProgression}');
  lines.add('  下次检查: 第 ${progression.nextCheckWeek} 周');
  lines.add('');

  lines.add('🔄 重评估触发条件');
  for (final trigger in progression.triggers) {
    final weekInfo = trigger.week != null ? '（第${trigger.week}周）' : '';
    lines.add('  • ${trigger.condition}$weekInfo → ${trigger.action}');
  }
  lines.add('');

  lines.add('📚 论文依据');
  lines.add('  本方案基于 ${_evidenceDesc.length} 篇同行评议论文，核心参考包括：');
  _evidenceDesc.forEach((pmid, desc) {
    lines.add('  • PMID $pmid: $desc');
  });
  lines.add('');

  lines.add(''.padRight(60, '='));

  return lines.join('\n');
}
