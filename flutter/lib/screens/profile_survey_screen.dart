import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/gradient_background.dart';

/// Second half of onboarding, after GoalSurveyScreen picks 训练目标: fills
/// in the rest of the fields fitness-planner's PlannerGateway.generate()
/// requires (see docs/Stopwatch-app-design-blueprint-v2.md §6.2 入门问答,
/// questions 2-5). One step per screen via an internal index, matching the
/// v2 "每屏一个问题" constraint.
class ProfileSurveyScreen extends StatefulWidget {
  const ProfileSurveyScreen({
    super.key,
    required this.onSubmit,
    this.initialFields,
    this.allowExit = false,
    this.onBackToGoal,
  });

  /// Raw fields PlannerGateway.generate() needs besides `goal` (added by
  /// the caller, which already knows the chosen FitnessGoal).
  final void Function(Map<String, dynamic> profileFields) onSubmit;
  final Map<String, dynamic>? initialFields;
  final bool allowExit;
  final VoidCallback? onBackToGoal;

  @override
  State<ProfileSurveyScreen> createState() => _ProfileSurveyScreenState();
}

enum _Scene { home, street, gym }

extension on _Scene {
  String get label => switch (this) {
    _Scene.home => '居家',
    _Scene.street => '街头',
    _Scene.gym => '健身房',
  };

  List<String> get equipment => switch (this) {
    _Scene.home => ['bodyweight', 'dumbbell'],
    _Scene.street => ['bodyweight'],
    _Scene.gym => ['bodyweight', 'dumbbell', 'barbell', 'cable', 'machine'],
  };
}

const _levels = [
  ('beginner', '新手'),
  ('intermediate', '有基础'),
  ('advanced', '经常练'),
];

const _minuteOptions = [15, 30, 45, 60];

class _ProfileSurveyScreenState extends State<ProfileSurveyScreen> {
  int _step = 0;

  late String _gender;
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _bodyFatController;
  late final TextEditingController _targetWeightController;

  late _Scene _scene;
  late String _level;

  late int _daysPerWeek;
  late int _minutesPerSession;
  late int _mealsPerDay;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialFields ?? const <String, dynamic>{};
    _gender = (initial['gender'] as String?) ?? 'M';
    _ageController = TextEditingController(text: '${initial['age'] ?? 28}');
    _heightController = TextEditingController(
      text: _numText(initial['height_cm'], 170),
    );
    _weightController = TextEditingController(
      text: _numText(initial['weight_kg'], 65),
    );
    _bodyFatController = TextEditingController(
      text: initial['body_fat_pct'] == null
          ? ''
          : _numText(initial['body_fat_pct'], 0),
    );
    _targetWeightController = TextEditingController(
      text: initial['target_weight_kg'] == null
          ? ''
          : _numText(initial['target_weight_kg'], 0),
    );
    _scene = _sceneFromEquipment(initial['equipment']);
    _level = (initial['level'] as String?) ?? 'beginner';
    _daysPerWeek = (initial['days_per_week'] as num?)?.toInt() ?? 3;
    _minutesPerSession =
        (initial['minutes_per_session'] as num?)?.toInt() ?? 30;
    _mealsPerDay = (initial['meals_per_day'] as num?)?.toInt() ?? 4;
  }

  static String _numText(Object? value, num fallback) {
    if (value is num) {
      return value == value.roundToDouble() ? '${value.round()}' : '$value';
    }
    return '$fallback';
  }

  static _Scene _sceneFromEquipment(Object? raw) {
    final equipment = raw is List ? raw.map((e) => '$e').toSet() : <String>{};
    if (equipment.contains('barbell') ||
        equipment.contains('machine') ||
        equipment.contains('cable')) {
      return _Scene.gym;
    }
    if (equipment.contains('dumbbell')) return _Scene.home;
    if (equipment.contains('bodyweight') && equipment.length <= 1) {
      return _Scene.street;
    }
    return _Scene.home;
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _bodyFatController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  void _next() {
    if (_step == 3) {
      final bodyFat = double.tryParse(_bodyFatController.text);
      final targetWeight = double.tryParse(_targetWeightController.text);
      final answers = <String, dynamic>{
        'gender': _gender,
        'age': int.tryParse(_ageController.text) ?? 28,
        'height_cm': double.tryParse(_heightController.text) ?? 170.0,
        'weight_kg': double.tryParse(_weightController.text) ?? 65.0,
        'level': _level,
        'days_per_week': _daysPerWeek,
        'minutes_per_session': _minutesPerSession,
        'equipment': _scene.equipment,
        'meals_per_day': _mealsPerDay,
      };
      if (bodyFat != null) answers['body_fat_pct'] = bodyFat;
      if (targetWeight != null) {
        answers['target_weight_kg'] = targetWeight;
      }
      widget.onSubmit(answers);
      return;
    }
    setState(() => _step++);
  }

  void _back() {
    if (_step == 0) {
      widget.onBackToGoal?.call();
      return;
    }
    setState(() => _step--);
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (_step > 0 || widget.onBackToGoal != null)
                  IconButton(
                    onPressed: _back,
                    icon: const Icon(Icons.arrow_back, color: AppColors.ink),
                  ),
                Expanded(
                  child: Row(
                    children: [
                      for (var i = 0; i < 4; i++) ...[
                        Expanded(
                          child: Container(
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: i <= _step
                                  ? AppColors.brandGreen
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(child: SingleChildScrollView(child: _buildStep())),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandGreen,
                  foregroundColor: AppColors.ink,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: _next,
                child: Text(
                  _step == 3 ? '生成计划' : '下一步',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    return switch (_step) {
      0 => _sceneStep(),
      1 => _bodyStep(),
      2 => _levelStep(),
      _ => _scheduleStep(),
    };
  }

  Widget _sceneStep() {
    return _StepShell(
      title: '你通常在哪里练？',
      subtitle: '决定能用到的器械',
      child: Column(
        children: [
          for (final scene in _Scene.values) ...[
            _ChoiceCard(
              label: scene.label,
              selected: _scene == scene,
              onTap: () => setState(() => _scene = scene),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _bodyStep() {
    return _StepShell(
      title: '基础身体数据',
      subtitle: '用来计算热量和营养素目标',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _ChoiceCard(
                  label: '男',
                  selected: _gender == 'M',
                  onTap: () => setState(() => _gender = 'M'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ChoiceCard(
                  label: '女',
                  selected: _gender == 'F',
                  onTap: () => setState(() => _gender = 'F'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _NumberField(label: '年龄', suffix: '岁', controller: _ageController),
          const SizedBox(height: 12),
          _NumberField(
            label: '身高',
            suffix: 'cm',
            controller: _heightController,
          ),
          const SizedBox(height: 12),
          _NumberField(
            label: '体重',
            suffix: 'kg',
            controller: _weightController,
          ),
          const SizedBox(height: 12),
          _NumberField(
            label: '目标体重',
            suffix: 'kg',
            controller: _targetWeightController,
            hint: '选填',
          ),
          const SizedBox(height: 12),
          _NumberField(
            label: '体脂',
            suffix: '%',
            controller: _bodyFatController,
            hint: '选填',
          ),
        ],
      ),
    );
  }

  Widget _levelStep() {
    return _StepShell(
      title: '训练经验',
      subtitle: '影响每周训练容量和动作难度',
      child: Column(
        children: [
          for (final (value, label) in _levels) ...[
            _ChoiceCard(
              label: label,
              selected: _level == value,
              onTap: () => setState(() => _level = value),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _scheduleStep() {
    return _StepShell(
      title: '每周练几天，每次多久？',
      subtitle: '用来匹配分肢方案和活动量',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('每周天数', style: AppTextStyles.cardMeta),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: _daysPerWeek > 1
                    ? () => setState(() => _daysPerWeek--)
                    : null,
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: AppColors.ink,
                ),
              ),
              Text('$_daysPerWeek 天', style: AppTextStyles.cardTitle),
              IconButton(
                onPressed: _daysPerWeek < 7
                    ? () => setState(() => _daysPerWeek++)
                    : null,
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('单次时长', style: AppTextStyles.cardMeta),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: [
              for (final m in _minuteOptions)
                ChoiceChip(
                  label: Text('$m 分钟'),
                  selected: _minutesPerSession == m,
                  selectedColor: AppColors.brandGreen,
                  onSelected: (_) => setState(() => _minutesPerSession = m),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text('每天几餐', style: AppTextStyles.cardMeta),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: [
              for (final n in const [3, 4, 5, 6])
                ChoiceChip(
                  label: Text('$n 餐'),
                  selected: _mealsPerDay == n,
                  selectedColor: AppColors.brandGreen,
                  onSelected: (_) => setState(() => _mealsPerDay = n),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepShell extends StatelessWidget {
  const _StepShell({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.cardTitle),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 13,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 20),
        child,
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandGreen : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.ink : Colors.transparent,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(label, style: AppTextStyles.cardName),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.suffix,
    required this.controller,
    this.hint,
  });

  final String label;
  final String suffix;
  final TextEditingController controller;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(label, style: AppTextStyles.cardMeta),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: AppFonts.jetBrainsMono,
                fontSize: 16,
                color: AppColors.ink,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: AppTextStyles.cardMeta,
              ),
            ),
          ),
          Text(suffix, style: AppTextStyles.cardMeta),
        ],
      ),
    );
  }
}
