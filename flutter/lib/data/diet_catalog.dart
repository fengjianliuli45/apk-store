import '../models/meal.dart';

/// Local meal + recipe catalog, ported from archive/android-compose
/// DietLogViewModel. This is a fixed lookup table, not a vision model — the
/// UI must always label matches from here as an estimate, never "AI 识别".
class DietCatalog {
  DietCatalog._();

  static const goalKcal = 2000;
  static const proteinGoal = 150;
  static const carbGoal = 220;
  static const fatGoal = 65;

  static const meals = <MealTemplate>[
    MealTemplate(
      name: '燕麦酸奶碗',
      kcal: 420,
      items: ['燕麦 80g', '希腊酸奶 150g', '蓝莓 40g'],
      proteinG: 24,
      carbG: 58,
      fatG: 10,
      slot: MealSlot.breakfast,
      tip: '早餐蛋白质不错，上午不易饿。',
    ),
    MealTemplate(
      name: '全麦蛋吐司',
      kcal: 380,
      items: ['全麦吐司 2 片', '水煮蛋 2 个', '牛油果 40g'],
      proteinG: 22,
      carbG: 36,
      fatG: 16,
      slot: MealSlot.breakfast,
      tip: '脂肪来自牛油果，属于优质来源。',
    ),
    MealTemplate(
      name: '香蕉花生酱吐司',
      kcal: 450,
      items: ['全麦吐司 2 片', '香蕉 1 根', '花生酱 15g'],
      proteinG: 14,
      carbG: 68,
      fatG: 14,
      slot: MealSlot.breakfast,
      tip: '训练日前的快碳早餐。',
    ),
    MealTemplate(
      name: '鸡胸糙米碗',
      kcal: 520,
      items: ['鸡胸肉 150g', '糙米饭 180g', '西兰花 80g'],
      proteinG: 48,
      carbG: 62,
      fatG: 8,
      slot: MealSlot.lunch,
      tip: '经典减脂午餐，蛋白质密度高。',
    ),
    MealTemplate(
      name: '牛肉番茄意面',
      kcal: 610,
      items: ['瘦牛肉 120g', '全麦意面 100g', '番茄酱汁 80g'],
      proteinG: 38,
      carbG: 72,
      fatG: 16,
      slot: MealSlot.lunch,
      tip: '午后碳水偏高，适合有训练的日子。',
    ),
    MealTemplate(
      name: '三文鱼藜麦碗',
      kcal: 530,
      items: ['三文鱼 120g', '藜麦 100g', '菠菜 60g'],
      proteinG: 36,
      carbG: 42,
      fatG: 22,
      slot: MealSlot.lunch,
      tip: '优质脂肪来自三文鱼，对恢复友好。',
    ),
    MealTemplate(
      name: '清蒸鲈鱼配时蔬',
      kcal: 390,
      items: ['鲈鱼 180g', '西兰花 100g', '胡萝卜 60g'],
      proteinG: 42,
      carbG: 18,
      fatG: 12,
      slot: MealSlot.dinner,
      tip: '低碳晚餐，晚上负担小。',
    ),
    MealTemplate(
      name: '豆腐蔬菜汤面',
      kcal: 410,
      items: ['北豆腐 120g', '荞麦面 80g', '青菜 100g'],
      proteinG: 22,
      carbG: 54,
      fatG: 10,
      slot: MealSlot.dinner,
      tip: '植物蛋白为主，好消化。',
    ),
    MealTemplate(
      name: '虾仁沙拉',
      kcal: 320,
      items: ['虾仁 120g', '混合生菜 80g', '橄榄油醋汁 10g'],
      proteinG: 28,
      carbG: 12,
      fatG: 14,
      slot: MealSlot.dinner,
      tip: '轻食晚餐，脂肪来自油醋汁。',
    ),
    MealTemplate(
      name: '希腊酸奶杯',
      kcal: 180,
      items: ['希腊酸奶 150g', '蜂蜜 8g', '核桃 10g'],
      proteinG: 16,
      carbG: 18,
      fatG: 6,
      slot: MealSlot.snack,
      tip: '加餐蛋白质友好。',
    ),
    MealTemplate(
      name: '苹果杏仁',
      kcal: 160,
      items: ['苹果 1 个', '杏仁 12g'],
      proteinG: 4,
      carbG: 22,
      fatG: 8,
      slot: MealSlot.snack,
      tip: '纤维加一点优质脂肪。',
    ),
    MealTemplate(
      name: '坚果能量棒',
      kcal: 220,
      items: ['燕麦棒 1 根', '混合坚果 15g'],
      proteinG: 8,
      carbG: 24,
      fatG: 12,
      slot: MealSlot.snack,
      tip: '训练间隙的快能量。',
    ),
  ];

  static const recipes = <RecipeItem>[
    RecipeItem(
      name: '低脂鸡胸肉沙拉',
      kcal: 350,
      goal: RecipeGoal.cut,
      items: ['鸡胸 120g', '生菜', '小番茄'],
      proteinG: 38,
      carbG: 14,
      fatG: 10,
      blurb: '高蛋白低脂，减脂日首选。',
    ),
    RecipeItem(
      name: '牛油果鸡胸',
      kcal: 290,
      goal: RecipeGoal.cut,
      items: ['鸡胸 100g', '牛油果 40g', '黄瓜'],
      proteinG: 32,
      carbG: 10,
      fatG: 12,
      blurb: '优质脂肪控量，饱腹感强。',
    ),
    RecipeItem(
      name: '虾仁时蔬',
      kcal: 310,
      goal: RecipeGoal.cut,
      items: ['虾仁 120g', '西兰花', '彩椒'],
      proteinG: 30,
      carbG: 16,
      fatG: 8,
      blurb: '低碳水海鲜餐。',
    ),
    RecipeItem(
      name: '三文鱼藜麦',
      kcal: 530,
      goal: RecipeGoal.recommend,
      items: ['三文鱼 120g', '藜麦 100g', '菠菜'],
      proteinG: 36,
      carbG: 42,
      fatG: 22,
      blurb: '均衡推荐，恢复友好。',
    ),
    RecipeItem(
      name: '希腊酸奶碗',
      kcal: 280,
      goal: RecipeGoal.recommend,
      items: ['希腊酸奶', '燕麦', '浆果'],
      proteinG: 20,
      carbG: 32,
      fatG: 8,
      blurb: '正餐或加餐都可以。',
    ),
    RecipeItem(
      name: '日式定食',
      kcal: 480,
      goal: RecipeGoal.maintain,
      items: ['烤鱼', '米饭', '味增汤'],
      proteinG: 32,
      carbG: 55,
      fatG: 14,
      blurb: '维持体重的清淡套餐。',
    ),
    RecipeItem(
      name: '豆腐蔬菜汤',
      kcal: 320,
      goal: RecipeGoal.maintain,
      items: ['北豆腐', '青菜', '菌菇'],
      proteinG: 18,
      carbG: 28,
      fatG: 10,
      blurb: '植物蛋白，好消化。',
    ),
    RecipeItem(
      name: '牛肉红薯碗',
      kcal: 620,
      goal: RecipeGoal.bulk,
      items: ['瘦牛肉 150g', '红薯 200g', '西兰花'],
      proteinG: 42,
      carbG: 70,
      fatG: 14,
      blurb: '增肌日的碳蛋白组合。',
    ),
    RecipeItem(
      name: '鸡胸西兰花饭',
      kcal: 560,
      goal: RecipeGoal.bulk,
      items: ['鸡胸 180g', '米饭 200g', '西兰花'],
      proteinG: 52,
      carbG: 64,
      fatG: 8,
      blurb: '蛋白质拉满。',
    ),
    RecipeItem(
      name: '乳清燕麦',
      kcal: 480,
      goal: RecipeGoal.bulk,
      items: ['燕麦 80g', '乳清 1 勺', '香蕉'],
      proteinG: 32,
      carbG: 62,
      fatG: 8,
      blurb: '训练后窗口的快碳+蛋白。',
    ),
  ];

  /// Cycles through the catalog for [slot] so repeated captures don't always
  /// land on the same template — same trick as the old Compose picker.
  /// When [preferKcal] is set (from the generated meal plan), pick the closest
  /// match first, then rotate among near matches.
  static MealTemplate estimateFor(MealSlot slot, int cursor, {int? preferKcal}) {
    final pool = meals.where((m) => m.slot == slot).toList();
    final list = pool.isEmpty ? List<MealTemplate>.from(meals) : pool;
    if (preferKcal == null) return list[cursor % list.length];
    final sorted = [...list]..sort(
        (a, b) => (a.kcal - preferKcal).abs().compareTo((b.kcal - preferKcal).abs()),
      );
    return sorted[cursor % sorted.length];
  }

  static MacroLevel levelOf(int total, int goal) {
    final ratio = total / (goal <= 0 ? 1 : goal);
    if (ratio < 0.55) return MacroLevel.low;
    if (ratio > 1.08) return MacroLevel.high;
    return MacroLevel.ok;
  }
}

enum MacroLevel { low, ok, high }

extension MacroLevelLabel on MacroLevel {
  String get label => switch (this) {
        MacroLevel.low => '偏低',
        MacroLevel.ok => '达标',
        MacroLevel.high => '偏高',
      };
}
