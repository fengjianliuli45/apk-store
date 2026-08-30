import 'models.dart';

/// Port of fitness-planner's `tdee_calculator.py`.
/// Mifflin-St Jeor (no body fat) or Katch-McArdle (with body fat).
(double, String) _selectActivityLevel(UserProfile p) {
  final d = p.daysPerWeek ?? 3;
  final m = p.minutesPerSession;
  if (d == 0) return (1.20, 'sedentary');
  if (d <= 2 || m <= 30) return (1.375, 'light');
  if (d >= 3 && d <= 4) return (1.55, 'moderate');
  if (d >= 5 && d <= 6 && m >= 60) return (1.725, 'active');
  if (d == 7) return (1.90, 'very_active');
  return (1.55, 'moderate');
}

TDEEResult calculateTdee(UserProfile profile) {
  double bmr;
  String formula;
  if (profile.bodyFatPct != null) {
    final lean = profile.leanMassKg;
    bmr = 370 + 21.6 * lean;
    formula = 'katch_mcardle';
  } else {
    final w = profile.weightKg;
    final h = profile.heightCm;
    final a = profile.age;
    if (profile.gender == 'M') {
      bmr = 10 * w + 6.25 * h - 5 * a + 5;
    } else {
      bmr = 10 * w + 6.25 * h - 5 * a - 161;
    }
    formula = 'mifflin_st_jeor';
  }

  final (multiplier, level) = _selectActivityLevel(profile);
  final tdee = bmr * multiplier;

  return TDEEResult(bmr: bmr, tdee: tdee, formulaUsed: formula, activityMultiplier: multiplier, activityLevel: level);
}
