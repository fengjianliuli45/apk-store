import 'dart:math' as math;

/// Port of fitness-planner's `food_db.py`.
///
/// 食物交换份法（ADA / 美国营养学会）+ 手掌法（Precision Nutrition）：
/// 把每餐宏量目标翻成具体吃法。不是识别模型，是查表。

const palmProteinG = 22.0; // 1 手掌 ≈ 22g 蛋白
const cuppedCarbG = 22.0; // 1 捧   ≈ 22g 碳水
const thumbFatG = 11.0; // 1 拇指 ≈ 11g 脂肪

const _restrictionAliases = <String, String>{
  'vegetarian': 'vegetarian', 'veg': 'vegetarian', '素': 'vegetarian',
  '蛋奶素': 'vegetarian', 'lacto_ovo': 'vegetarian',
  'vegan': 'vegan', '纯素': 'vegan', '全素': 'vegan',
  'halal': 'halal', '清真': 'halal',
  'no_pork': 'no_pork', '不吃猪肉': 'no_pork', 'no-pork': 'no_pork',
  'no_beef': 'no_beef', '不吃牛肉': 'no_beef', 'no-beef': 'no_beef',
  'lactose': 'no_dairy', 'lactose_intolerant': 'no_dairy', 'no_dairy': 'no_dairy',
  'dairy_free': 'no_dairy', '乳糖不耐': 'no_dairy', '不吃乳制品': 'no_dairy',
  'gluten': 'no_gluten', 'gluten_free': 'no_gluten', 'no_gluten': 'no_gluten',
  '麸质过敏': 'no_gluten', '无麸质': 'no_gluten', '乳糜泻': 'no_gluten',
  'nut_allergy': 'no_nut', 'no_nut': 'no_nut', '坚果过敏': 'no_nut',
  'seafood_allergy': 'no_seafood', 'no_seafood': 'no_seafood', '海鲜过敏': 'no_seafood',
  'shellfish_allergy': 'no_seafood',
};

Set<String> normalizeRestrictions(List<String>? raw) {
  final out = <String>{};
  for (final r in raw ?? const <String>[]) {
    final key = r.trim().toLowerCase();
    final mapped = _restrictionAliases[key];
    if (mapped != null) out.add(mapped);
  }
  if (out.contains('vegan')) {
    out.addAll(['vegetarian', 'no_dairy']);
  }
  return out;
}

class _Food {
  const _Food(this.id, this.name, this.p, this.f, this.c, this.kind,
      {this.allergens = const {}, this.leu = false, this.canteen = true});
  final String id;
  final String name;
  final double p;
  final double f;
  final double c;
  final String kind; // meat | seafood | egg | dairy | plant
  final Set<String> allergens; // gluten | nut | soy
  final bool leu;
  final bool canteen;
}

const _proteins = <_Food>[
  _Food('chicken_breast', '鸡胸肉', 31, 3.6, 0, 'meat', leu: true),
  _Food('chicken_thigh', '鸡腿肉（去皮）', 24, 9, 0, 'meat', leu: true),
  _Food('lean_beef', '瘦牛肉', 26, 8, 0, 'meat', leu: true),
  _Food('lean_pork', '猪里脊', 22, 7, 0, 'meat', leu: true),
  _Food('white_fish', '龙利鱼 / 巴沙鱼', 20, 2, 0, 'seafood', leu: true),
  _Food('salmon', '三文鱼', 20, 13, 0, 'seafood', leu: true),
  _Food('shrimp', '虾仁', 20, 1, 1, 'seafood', leu: true),
  _Food('egg', '全蛋', 13, 11, 1, 'egg', leu: true),
  _Food('egg_white', '蛋清', 11, 0.2, 0.7, 'egg', leu: true),
  _Food('greek_yogurt', '无糖希腊酸奶', 9, 4, 4, 'dairy', leu: true),
  _Food('cottage_cheese', '白干酪 / 茅屋芝士', 11, 4, 3, 'dairy', leu: true),
  _Food('milk', '牛奶', 3.3, 3.6, 5, 'dairy', leu: true),
  _Food('whey', '乳清蛋白粉', 80, 6, 8, 'dairy', leu: true, canteen: false),
  _Food('tofu_firm', '北豆腐', 12, 6, 3, 'plant', allergens: {'soy'}, leu: true),
  _Food('tofu_dried', '豆腐干', 16, 8, 4, 'plant', allergens: {'soy'}, leu: true),
  _Food('soy_milk', '无糖豆浆', 3.5, 1.8, 1.2, 'plant', allergens: {'soy'}, leu: true),
  _Food('edamame', '毛豆', 11, 5, 9, 'plant', allergens: {'soy'}, leu: true),
  _Food('tempeh', '天贝', 19, 11, 9, 'plant', allergens: {'soy'}, leu: true),
  _Food('soy_protein_powder', '大豆分离蛋白粉', 82, 3, 5, 'plant',
      allergens: {'soy'}, leu: true, canteen: false),
  _Food('seitan', '面筋', 25, 2, 14, 'plant', allergens: {'gluten'}),
  _Food('lentils', '扁豆（熟）', 9, 0.4, 20, 'plant'),
  _Food('chickpeas', '鹰嘴豆（熟）', 9, 2.6, 27, 'plant'),
];

const _staples = <_Food>[
  _Food('rice', '米饭', 2.6, 0.3, 28, 'plant'),
  _Food('brown_rice', '糙米饭', 2.7, 0.9, 25, 'plant'),
  _Food('oats', '燕麦', 13, 7, 60, 'plant'),
  _Food('sweet_potato', '红薯', 1.6, 0.1, 20, 'plant'),
  _Food('potato', '土豆', 2, 0.1, 17, 'plant'),
  _Food('corn', '玉米', 3.4, 1.5, 19, 'plant'),
  _Food('rice_noodles', '米粉 / 河粉', 3, 0.3, 24, 'plant'),
  _Food('quinoa', '藜麦（熟）', 4.4, 1.9, 21, 'plant'),
  _Food('banana', '香蕉', 1.1, 0.3, 23, 'plant'),
  _Food('whole_wheat_bread', '全麦面包', 12, 4, 43, 'plant', allergens: {'gluten'}),
  _Food('noodles', '面条（熟）', 5, 1, 25, 'plant', allergens: {'gluten'}),
];

const _veg = <_Food>[
  _Food('broccoli', '西兰花', 2.8, 0.4, 7, 'plant'),
  _Food('leafy_greens', '青菜 / 菠菜', 2.5, 0.3, 4, 'plant'),
  _Food('bell_pepper', '彩椒', 1, 0.3, 6, 'plant'),
  _Food('cucumber_tomato', '黄瓜 / 番茄', 0.9, 0.2, 3.5, 'plant'),
  _Food('mushroom', '菌菇', 3, 0.3, 3, 'plant'),
  _Food('carrot', '胡萝卜', 0.9, 0.2, 10, 'plant'),
];

const _fats = <_Food>[
  _Food('olive_oil', '橄榄油 / 菜籽油', 0, 100, 0, 'plant'),
  _Food('avocado', '牛油果', 2, 15, 9, 'plant'),
  _Food('seeds', '奇亚籽 / 亚麻籽', 17, 31, 42, 'plant'),
  _Food('nuts_almond', '杏仁 / 混合坚果', 21, 50, 22, 'plant', allergens: {'nut'}),
  _Food('peanut_butter', '花生酱', 25, 50, 20, 'plant', allergens: {'nut'}),
];

int _round(double x) => (x + 0.5).floor();

bool _allowed(_Food food, Set<String> r) {
  final kind = food.kind;
  final al = food.allergens;
  if (r.contains('vegetarian') &&
      !(kind == 'egg' || kind == 'dairy' || kind == 'plant')) {
    return false;
  }
  if (r.contains('vegan') && kind != 'plant') return false;
  if (r.contains('halal') && food.id == 'lean_pork') return false;
  if (r.contains('no_dairy') && kind == 'dairy') return false;
  if (r.contains('no_seafood') && kind == 'seafood') return false;
  if (r.contains('no_gluten') && al.contains('gluten')) return false;
  if (r.contains('no_nut') && al.contains('nut')) return false;
  if (r.contains('no_pork') && food.id == 'lean_pork') return false;
  if (r.contains('no_beef') && food.id == 'lean_beef') return false;
  return true;
}

List<_Food> _pool(List<_Food> cat, Set<String> r, bool canteen,
    {bool preferLeucine = false}) {
  var pool = cat.where((f) => _allowed(f, r)).toList();
  if (canteen) {
    final ok = pool.where((f) => f.canteen).toList();
    if (ok.isNotEmpty) pool = ok;
  }
  if (preferLeucine) {
    pool = [...pool.where((f) => f.leu), ...pool.where((f) => !f.leu)];
  }
  return pool;
}

int _gramsFor(_Food food, String macro, double targetG) {
  final per = macro == 'p' ? food.p : (macro == 'c' ? food.c : food.f);
  if (per <= 0 || targetG <= 0) return 0;
  return math.max(5, _round(targetG / per * 100 / 5) * 5);
}

Map<String, int> handPortions(Map<String, double> meal) {
  return {
    'protein_palms': math.max(1, _round(meal['protein_g']! / palmProteinG)),
    'carb_cupped': math.max(0, _round(meal['carbs_g']! / cuppedCarbG)),
    'fat_thumbs': math.max(0, _round(meal['fat_g']! / thumbFatG)),
    'veg_fists': (meal['carbs_g'] ?? 0) < 40 ? 1 : 2,
  };
}

String handPortionText(Map<String, double> meal) {
  final hp = handPortions(meal);
  final parts = <String>['${hp['protein_palms']} 手掌蛋白'];
  if (hp['carb_cupped']! > 0) parts.add('${hp['carb_cupped']} 捧碳水');
  parts.add('${hp['veg_fists']} 拳蔬菜');
  if (hp['fat_thumbs']! > 0) parts.add('${hp['fat_thumbs']} 拇指脂肪');
  return parts.join(' + ');
}

List<Map<String, dynamic>> suggestMeal(Map<String, double> meal,
    Set<String> restrictions, String cookingAccess, bool isPostWorkout,
    {int nOptions = 2, int rotate = 0}) {
  final canteen = cookingAccess == 'canteen' || cookingAccess == 'none';
  final proteins = _pool(_proteins, restrictions, canteen, preferLeucine: true);
  final staples = _pool(_staples, restrictions, canteen);
  final veg = _pool(_veg, restrictions, canteen);
  final fats = _pool(_fats, restrictions, canteen);

  final n = math.min(nOptions, math.max(1, proteins.length));
  final options = <Map<String, dynamic>>[];
  for (var i = 0; i < n; i++) {
    final k = i + rotate;
    final items = <String>[];
    var baseFat = 0.0;
    if (proteins.isNotEmpty) {
      final p = proteins[k % proteins.length];
      final g = _gramsFor(p, 'p', meal['protein_g']!);
      baseFat += p.f * g / 100;
      items.add('${p.name} ${g}g');
    }
    if (staples.isNotEmpty) {
      final s = staples[k % staples.length];
      final g = _gramsFor(s, 'c', meal['carbs_g']!);
      baseFat += s.f * g / 100;
      if (g > 0) items.add('${s.name} ${g}g');
    }
    if (veg.isNotEmpty) {
      items.add('${veg[k % veg.length].name} 150g');
    }
    final fatGap = meal['fat_g']! - baseFat;
    if (fatGap >= 4 && fats.isNotEmpty) {
      final fsrc = fats[k % fats.length];
      final g = _gramsFor(fsrc, 'f', fatGap);
      if (g >= 5) items.add('${fsrc.name} ${g}g');
    }
    var note = isPostWorkout ? '练后：先补蛋白 + 快碳' : '';
    if (canteen) {
      final prefix = note.isNotEmpty ? '$note；' : '';
      note = '$prefix食堂/外食按份估算：蛋白管够、主食减半、少油';
    }
    options.add({'items': items, 'note': note});
  }
  return options;
}

List<String> leucineRichNames(Set<String> restrictions, {int limit = 5}) {
  return _proteins
      .where((f) => f.leu && _allowed(f, restrictions))
      .map((f) => f.name)
      .take(limit)
      .toList();
}
