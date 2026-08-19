import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Matches the 训练目标 options in docs/Stopwatch-app-design-blueprint-v2.md
// §6.2 入门问答, question 1.
enum FitnessGoal { weightLoss, muscleGain, toning, endurance, recovery }

extension FitnessGoalLabel on FitnessGoal {
  String get label => switch (this) {
        FitnessGoal.weightLoss => '减脂',
        FitnessGoal.muscleGain => '增肌',
        FitnessGoal.toning => '塑形',
        FitnessGoal.endurance => '体能',
        FitnessGoal.recovery => '恢复',
      };

  String get description => switch (this) {
        FitnessGoal.weightLoss => '降低体脂，提升燃脂效率',
        FitnessGoal.muscleGain => '增加肌肉量，力量训练为主',
        FitnessGoal.toning => '线条紧致，兼顾力量和有氧',
        FitnessGoal.endurance => '提升耐力和心肺能力',
        FitnessGoal.recovery => '低强度恢复，保护身体状态',
      };

  /// fitness-planner's engine only models 4 strength-training goals
  /// (hypertrophy/fat_loss/strength/recomposition) — 体能 and 恢复 don't
  /// map cleanly onto any of them, so both fall back to recomposition
  /// (maintenance macros, moderate training vars) as the closest safe
  /// default rather than distorting a goal the engine wasn't built for.
  String get engineGoal => switch (this) {
        FitnessGoal.weightLoss => 'fat_loss',
        FitnessGoal.muscleGain => 'hypertrophy',
        FitnessGoal.toning => 'recomposition',
        FitnessGoal.endurance => 'recomposition',
        FitnessGoal.recovery => 'recomposition',
      };
}

/// Tracks the goal picked in the post-login survey. Local-only (no
/// backend), same pattern as SettingsController.
class GoalController extends ChangeNotifier {
  static const _kGoal = 'fitness_goal';

  FitnessGoal? goal;

  bool get hasChosen => goal != null;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kGoal);
    goal = stored == null ? null : FitnessGoal.values.byName(stored);
    notifyListeners();
  }

  Future<void> choose(FitnessGoal value) async {
    goal = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kGoal, value.name);
  }
}
