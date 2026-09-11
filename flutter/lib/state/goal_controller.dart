import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Matches the 训练目标 options in docs/Stopwatch-app-design-blueprint-v2.md
// §6.2 入门问答, question 1.
enum FitnessGoal {
  weightLoss,
  muscleGain,
  toning,
  endurance,
  recovery,
  strength,
}

const engineSupportedGoals = [
  FitnessGoal.weightLoss,
  FitnessGoal.muscleGain,
  FitnessGoal.toning,
  FitnessGoal.strength,
];

extension FitnessGoalLabel on FitnessGoal {
  String get label => switch (this) {
    FitnessGoal.weightLoss => '减脂',
    FitnessGoal.muscleGain => '增肌',
    FitnessGoal.toning => '塑形',
    FitnessGoal.endurance => '体能',
    FitnessGoal.recovery => '恢复',
    FitnessGoal.strength => '力量',
  };

  String get description => switch (this) {
    FitnessGoal.weightLoss => '降低体脂，提升燃脂效率',
    FitnessGoal.muscleGain => '增加肌肉量，力量训练为主',
    FitnessGoal.toning => '线条紧致，兼顾力量和有氧',
    FitnessGoal.endurance => '提升耐力和心肺能力',
    FitnessGoal.recovery => '低强度恢复，保护身体状态',
    FitnessGoal.strength => '以提升力量为目标，采用引擎力量处方',
  };

  /// Legacy endurance/recovery values remain readable but cannot generate a
  /// different goal silently. Loading them reopens goal selection.
  String get engineGoal => switch (this) {
    FitnessGoal.weightLoss => 'fat_loss',
    FitnessGoal.muscleGain => 'hypertrophy',
    FitnessGoal.toning => 'recomposition',
    FitnessGoal.strength => 'strength',
    FitnessGoal.endurance ||
    FitnessGoal.recovery => throw StateError('该目标尚无对应引擎，请重新选择训练目标'),
  };
}

/// Tracks the goal picked in the post-login survey. Local-only (no
/// backend), same pattern as SettingsController.
class GoalController extends ChangeNotifier {
  static const _kGoal = 'fitness_goal';
  static const _kWelcomeGoal = 'welcome_animation_goal_v1';

  FitnessGoal? goal;
  String? _welcomeGoal;

  bool get hasChosen => goal != null;
  bool get welcomeSeen => goal != null && _welcomeGoal == goal!.name;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kGoal);
    goal = engineSupportedGoals.where((g) => g.name == stored).firstOrNull;
    _welcomeGoal = prefs.getString(_kWelcomeGoal);
    notifyListeners();
  }

  Future<void> choose(FitnessGoal value) async {
    if (!engineSupportedGoals.contains(value)) {
      throw ArgumentError('Unsupported engine goal');
    }
    if (goal != value) _welcomeGoal = null;
    goal = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kGoal, value.name);
    if (_welcomeGoal == null) await prefs.remove(_kWelcomeGoal);
  }

  Future<void> markWelcomeSeen() async {
    final selected = goal;
    if (selected == null) return;
    _welcomeGoal = selected.name;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kWelcomeGoal, selected.name);
  }
}
