enum MealSlot { breakfast, lunch, dinner, snack }

extension MealSlotLabel on MealSlot {
  String get label => switch (this) {
        MealSlot.breakfast => '早餐',
        MealSlot.lunch => '午餐',
        MealSlot.dinner => '晚餐',
        MealSlot.snack => '加餐',
      };

  static MealSlot forHour(int hour) {
    if (hour >= 5 && hour <= 10) return MealSlot.breakfast;
    if (hour >= 11 && hour <= 15) return MealSlot.lunch;
    if (hour >= 16 && hour <= 20) return MealSlot.dinner;
    return MealSlot.snack;
  }
}

/// A local catalog entry — the "manual pick" fallback when there's no
/// barcode match. Ported from archive/android-compose DietLogViewModel.
class MealTemplate {
  const MealTemplate({
    required this.name,
    required this.kcal,
    required this.items,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
    required this.slot,
    required this.tip,
  });

  final String name;
  final int kcal;
  final List<String> items;
  final int proteinG;
  final int carbG;
  final int fatG;
  final MealSlot slot;
  final String tip;
}

enum RecipeGoal { recommend, cut, bulk, maintain }

extension RecipeGoalLabel on RecipeGoal {
  String get label => switch (this) {
        RecipeGoal.recommend => '推荐',
        RecipeGoal.cut => '减脂',
        RecipeGoal.bulk => '增肌',
        RecipeGoal.maintain => '维持',
      };
}

class RecipeItem {
  const RecipeItem({
    required this.name,
    required this.kcal,
    required this.goal,
    required this.items,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
    required this.blurb,
  });

  final String name;
  final int kcal;
  final RecipeGoal goal;
  final List<String> items;
  final int proteinG;
  final int carbG;
  final int fatG;
  final String blurb;
}

enum MealSource { catalogEstimate, barcode, recipe }

extension MealSourceLabel on MealSource {
  String get label => switch (this) {
        MealSource.catalogEstimate => '目录估算',
        MealSource.barcode => '条码识别',
        MealSource.recipe => '食谱',
      };
}

class LoggedMeal {
  LoggedMeal({
    required this.id,
    required this.name,
    required this.kcal,
    required this.items,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
    required this.slot,
    required this.timestampMs,
    required this.source,
    this.tip = '',
  });

  final String id;
  final String name;
  final int kcal;
  final List<String> items;
  final int proteinG;
  final int carbG;
  final int fatG;
  final MealSlot slot;
  final int timestampMs;
  final MealSource source;
  final String tip;

  String get dayKey {
    final d = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kcal': kcal,
        'items': items,
        'proteinG': proteinG,
        'carbG': carbG,
        'fatG': fatG,
        'slot': slot.name,
        'timestampMs': timestampMs,
        'source': source.name,
        'tip': tip,
      };

  factory LoggedMeal.fromJson(Map<String, dynamic> json) => LoggedMeal(
        id: json['id'] as String,
        name: json['name'] as String,
        kcal: json['kcal'] as int,
        items: (json['items'] as List).cast<String>(),
        proteinG: json['proteinG'] as int,
        carbG: json['carbG'] as int,
        fatG: json['fatG'] as int,
        slot: MealSlot.values.byName(json['slot'] as String),
        timestampMs: json['timestampMs'] as int,
        source: MealSource.values.byName(json['source'] as String),
        tip: json['tip'] as String? ?? '',
      );
}
