import 'models.dart';

/// Port of fitness-planner's `supplement_advisor.py`.
SupplementResult adviseSupplements(UserProfile profile, MacroResult macros) {
  final results = <Supplement>[];

  final userSupps = profile.supplements.map((s) => s.toLowerCase()).toList();
  final explicitlyRejected = userSupps.any((s) => s.contains('no') || s.contains('不') || s.contains('拒绝'));

  if (!explicitlyRejected) {
    results.add(Supplement(
      name: '肌酸',
      nameEn: 'Creatine Monohydrate',
      dose: '5g/日',
      condition: '默认推荐（除非明确拒绝）',
      note: '持续服用，无需 loading，无需停用期。2-3 周可达饱和。',
      pmid: '37432300',
    ));
  }

  final dailyProtein = (macros.dailyTargets['protein_g'] as num).toDouble();
  final dietProteinEst = profile.weightKg * 1.0;
  if (dailyProtein > dietProteinEst) {
    final deficit = double.parse((dailyProtein - dietProteinEst).toStringAsFixed(1));
    results.add(Supplement(
      name: '乳清蛋白粉',
      nameEn: 'Whey Protein',
      dose: '补足差额约 ${deficit}g 蛋白',
      condition: '饮食蛋白不足时',
      note: '优先从食物摄取，不足部分用蛋白粉补足。',
      pmid: '28698222',
    ));
  }

  if (profile.cookingAccess == 'canteen' || profile.cookingAccess == 'none') {
    results.add(Supplement(
      name: '维生素 D3',
      nameEn: 'Vitamin D3',
      dose: '2000 IU/日',
      condition: '食堂就餐或室内生活方式',
      note: '一般健康建议，尤其日晒不足时。',
    ));
  }

  final restrictions = profile.dietaryRestrictions.map((r) => r.toLowerCase()).toList();
  final isVegetarian = restrictions.any((r) => r.contains('veg') || r.contains('素'));
  if (isVegetarian) {
    results.add(Supplement(
      name: '鱼油 / 藻油',
      nameEn: 'Fish Oil / Algae Oil',
      dose: '1-2g EPA+DHA/日',
      condition: '素食且无鱼摄入',
      note: '补充 Omega-3 脂肪酸，藻油为素食替代。',
    ));
  }

  return SupplementResult(results);
}
