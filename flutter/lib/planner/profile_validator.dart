import 'models.dart';

/// Port of fitness-planner's `profile_validator.py`.
UserProfile validateProfile(Map<String, dynamic> raw) {
  const requiredFields = [
    'gender', 'age', 'height_cm', 'weight_kg',
    'level', 'goal', 'days_per_week', 'minutes_per_session', 'equipment',
  ];

  final errors = <String>[];
  final warnings = <String>[];
  final notes = <String>[];

  for (final f in requiredFields) {
    if (!raw.containsKey(f) || raw[f] == null) {
      errors.add('缺少必填字段: $f');
    }
  }
  if (errors.isNotEmpty) throw ValidationError(errors);

  final gender = (raw['gender'] as String).toUpperCase();
  if (!validGenders.contains(gender)) errors.add('gender 必须是 $validGenders，得到: $gender');

  final ageRaw = raw['age'];
  if (ageRaw is! num) {
    errors.add('age 必须是数字，得到: ${ageRaw.runtimeType}');
  } else if (ageRaw < 16 || ageRaw > 80) {
    errors.add('age 范围应为 16-80，得到: $ageRaw');
  }

  final heightCm = (raw['height_cm'] as num).toDouble();
  if (heightCm < 120 || heightCm > 250) errors.add('height_cm 范围应为 120-250，得到: $heightCm');

  final weightKg = (raw['weight_kg'] as num).toDouble();
  if (weightKg < 35 || weightKg > 250) errors.add('weight_kg 范围应为 35-250，得到: $weightKg');

  final level = (raw['level'] as String).toLowerCase();
  if (!validLevels.contains(level)) errors.add('level 必须是 $validLevels，得到: $level');

  final goal = (raw['goal'] as String).toLowerCase();
  if (!validGoals.contains(goal)) errors.add('goal 必须是 $validGoals，得到: $goal');

  final daysPerWeek = (raw['days_per_week'] as num).toInt();
  if (daysPerWeek < 0 || daysPerWeek > 7) errors.add('days_per_week 范围应为 0-7，得到: $daysPerWeek');

  final minutesPerSession = (raw['minutes_per_session'] as num).toInt();
  if (minutesPerSession < 0 || minutesPerSession > 180) {
    errors.add('minutes_per_session 范围应为 0-180，得到: $minutesPerSession');
  }

  var equipment = List<String>.from(raw['equipment'] as List? ?? const []);
  if (equipment.isEmpty) {
    equipment = ['bodyweight'];
    notes.add('equipment 为空，默认使用 bodyweight');
  }

  if (errors.isNotEmpty) throw ValidationError(errors);

  double? bodyFatPct = (raw['body_fat_pct'] as num?)?.toDouble();
  if (bodyFatPct != null) {
    if (bodyFatPct < 3 || bodyFatPct > 60) errors.add('body_fat_pct 范围应为 3-60，得到: $bodyFatPct');
  } else {
    notes.add('body_fat_pct 未提供，将使用 Mifflin-St Jeor 公式');
  }

  var mealsPerDay = (raw['meals_per_day'] as num?)?.toInt() ?? 4;
  if (mealsPerDay < 1 || mealsPerDay > 8) {
    warnings.add('meals_per_day=$mealsPerDay 不在常见范围 1-8，已保留');
    mealsPerDay = mealsPerDay.clamp(1, 8);
  }

  final supplements = List<String>.from((raw['supplements'] as List?) ?? const ['creatine']);

  final targetWeightKg = (raw['target_weight_kg'] as num?)?.toDouble();
  final injuries = List<String>.from((raw['injuries'] as List?) ?? const []);
  final dietaryRestrictions = List<String>.from((raw['dietary_restrictions'] as List?) ?? const []);

  var cookingAccess = (raw['cooking_access'] as String?) ?? 'home';
  if (!validCooking.contains(cookingAccess)) {
    warnings.add('cooking_access=$cookingAccess 不在 $validCooking，默认 home');
    cookingAccess = 'home';
  }

  if (errors.isNotEmpty) throw ValidationError(errors);

  final bmi = weightKg / ((heightCm / 100) * (heightCm / 100));
  if (bmi < 15) {
    warnings.add('BMI=${bmi.toStringAsFixed(1)} 偏低（<15），建议咨询医生');
  } else if (bmi > 40) {
    warnings.add('BMI=${bmi.toStringAsFixed(1)} 偏高（>40），建议咨询医生');
  }

  if (daysPerWeek == 1) warnings.add('days_per_week=1 训练频率过低，建议至少 2 天');

  if (goal == 'strength' && level == 'beginner') {
    warnings.add('力量目标+新手 → 建议先以增肌打基础（hypertrophy）3-6 个月');
  }

  return UserProfile(
    gender: gender,
    age: ageRaw.toInt(),
    heightCm: heightCm,
    weightKg: weightKg,
    level: level,
    goal: goal,
    daysPerWeek: daysPerWeek,
    minutesPerSession: minutesPerSession,
    equipment: equipment,
    bodyFatPct: bodyFatPct,
    mealsPerDay: mealsPerDay,
    supplements: supplements,
    targetWeightKg: targetWeightKg,
    injuries: injuries,
    dietaryRestrictions: dietaryRestrictions,
    cookingAccess: cookingAccess,
    warnings: warnings,
    notes: notes,
  );
}
