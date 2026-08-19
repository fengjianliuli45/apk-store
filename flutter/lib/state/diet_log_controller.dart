import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/diet_catalog.dart';
import '../models/meal.dart';

/// Local-only meal log (shared_preferences, no server). Mirrors the shape of
/// the old Compose DietLogViewModel but as a ChangeNotifier.
class DietLogController extends ChangeNotifier {
  static const _prefsKey = 'diet_log_meals_v1';

  final List<LoggedMeal> meals = [];
  final Map<MealSlot, int> _pickCursor = {};
  bool _loaded = false;

  bool get loaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    meals
      ..clear()
      ..addAll(raw.map((s) => LoggedMeal.fromJson(jsonDecode(s) as Map<String, dynamic>)));
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, meals.map((m) => jsonEncode(m.toJson())).toList());
  }

  MealSlot currentSlot() => MealSlotLabel.forHour(DateTime.now().hour);

  /// Local-catalog "estimate" for a just-taken photo — not vision AI, just a
  /// deterministic lookup by time-of-day, cycling so repeats vary a bit.
  MealTemplate estimateForPhoto() {
    final slot = currentSlot();
    final cursor = _pickCursor[slot] ?? 0;
    _pickCursor[slot] = cursor + 1;
    return DietCatalog.estimateFor(slot, cursor);
  }

  List<LoggedMeal> mealsOn(String dayKey) => meals.where((m) => m.dayKey == dayKey).toList();

  String get todayKey {
    final d = DateTime.now();
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  List<LoggedMeal> get todayMeals => mealsOn(todayKey);

  int get todayKcal => todayMeals.fold(0, (sum, m) => sum + m.kcal);

  Future<LoggedMeal> logTemplate(MealTemplate template, {MealSource source = MealSource.catalogEstimate}) {
    return _log(
      name: template.name,
      kcal: template.kcal,
      items: template.items,
      proteinG: template.proteinG,
      carbG: template.carbG,
      fatG: template.fatG,
      slot: template.slot,
      tip: template.tip,
      source: source,
    );
  }

  Future<LoggedMeal> logRecipe(RecipeItem recipe) {
    return _log(
      name: recipe.name,
      kcal: recipe.kcal,
      items: recipe.items,
      proteinG: recipe.proteinG,
      carbG: recipe.carbG,
      fatG: recipe.fatG,
      slot: currentSlot(),
      tip: recipe.blurb,
      source: MealSource.recipe,
    );
  }

  Future<LoggedMeal> logBarcodeProduct({
    required String name,
    required int kcal,
    required int proteinG,
    required int carbG,
    required int fatG,
  }) {
    return _log(
      name: name,
      kcal: kcal,
      items: const [],
      proteinG: proteinG,
      carbG: carbG,
      fatG: fatG,
      slot: currentSlot(),
      tip: '来自 Open Food Facts 条码查询',
      source: MealSource.barcode,
    );
  }

  Future<LoggedMeal> _log({
    required String name,
    required int kcal,
    required List<String> items,
    required int proteinG,
    required int carbG,
    required int fatG,
    required MealSlot slot,
    required String tip,
    required MealSource source,
  }) async {
    final meal = LoggedMeal(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      kcal: kcal,
      items: items,
      proteinG: proteinG,
      carbG: carbG,
      fatG: fatG,
      slot: slot,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      source: source,
      tip: tip,
    );
    meals.insert(0, meal);
    notifyListeners();
    await _persist();
    return meal;
  }
}
