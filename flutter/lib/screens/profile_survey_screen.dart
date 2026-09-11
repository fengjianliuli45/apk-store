import 'package:flutter/material.dart';

import '../planner/planner_gateway.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/gradient_background.dart';
import '../widgets/planner_constraints_fields.dart';

/// Second half of onboarding, after GoalSurveyScreen picks 训练目标: fills
/// in the rest of the fields fitness-planner's PlannerGateway.generate()
/// requires (see docs/Stopwatch-app-design-blueprint-v2.md §6.2 入门问答,
/// questions 2-5). One step per screen via an internal index, matching the
/// v2 "每屏一个问题" constraint.
class ProfileSurveyScreen extends StatefulWidget {
  const ProfileSurveyScreen({
    super.key,
    required this.onSubmit,
    required this.engineGoal,
    this.initialFields,
    this.allowExit = false,
    this.onBackToGoal,
  });

  /// Raw fields PlannerGateway.generate() needs besides `goal` (added by
  /// the caller, which already knows the chosen FitnessGoal).
  final void Function(Map<String, dynamic> profileFields) onSubmit;
  final String engineGoal;
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

const _minuteOptions = [30, 45, 60, 75, 90, 105, 120];

class _ProfileSurveyScreenState extends State<ProfileSurveyScreen> {
  int _step = 0;

  late String _gender;
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _bodyFatController;
  late final TextEditingController _targetWeightController;

  late _Scene _scene;
  late List<String> _equipment;
  Map<String, dynamic> _constraints = {};
  String? _constraintsError;
  late String _level;

  int? _minimumMinutes;
  bool _calculating = false;
  String? _minimumError;
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
    _equipment = List<String>.from(
      initial['equipment'] as List? ?? _scene.equipment,
    );
    _level = (initial['level'] as String?) ?? 'beginner';
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

  Future<void> _next() async {
    if (_calculating) return;
    if (_step == 1) {
      final age = int.tryParse(_ageController.text.trim());
      final height = double.tryParse(_heightController.text.trim());
      final weight = double.tryParse(_weightController.text.trim());
      final fatText = _bodyFatController.text.trim();
      final targetText = _targetWeightController.text.trim();
      final fat = double.tryParse(fatText);
      final target = double.tryParse(targetText);
      bool outside(double? value, double min, double max) =>
          value == null || !value.isFinite || value < min || value > max;
      final error = age == null || age < 16 || age > 80
          ? '年龄须为 16–80 岁的整数'
          : outside(height, 120, 250)
          ? '身高须为 120–250 cm'
          : outside(weight, 35, 250)
          ? '体重须为 35–250 kg'
          : fatText.isNotEmpty && outside(fat, 3, 60)
          ? '体脂须为 3–60%，也可留空'
          : targetText.isNotEmpty &&
                (target == null || !target.isFinite || target <= 0)
          ? '请填写有效目标体重，也可留空'
          : null;
      if (error != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
        return;
      }
    }
    if (_step == 2) {
      setState(() {
        _calculating = true;
        _minimumError = null;
      });
      try {
        final gateway = await PlannerGateway.instance();
        final minimum = gateway.minSessionMinutes(
          level: _level,
          goal: widget.engineGoal,
          equipment: _equipment,
        );
        if (!mounted) return;
        setState(() {
          _minimumMinutes = minimum;
          _minutesPerSession = _minutesPerSession.clamp(minimum, 120);
          _step = 3;
        });
      } catch (_) {
        if (mounted) setState(() => _minimumError = '无法计算最低时长，请重试。');
      } finally {
        if (mounted) setState(() => _calculating = false);
      }
      return;
    }
    if (_step == 3) {
      if (_constraintsError != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_constraintsError!)));
        return;
      }
      if (_minimumMinutes == null || _minutesPerSession < _minimumMinutes!) {
        return;
      }
      final bodyFat = double.tryParse(_bodyFatController.text);
      final targetWeight = double.tryParse(_targetWeightController.text);
      final answers = <String, dynamic>{
        ...?widget.initialFields,
        ..._constraints,
        'gender': _gender,
        'age': int.tryParse(_ageController.text) ?? 28,
        'height_cm': double.tryParse(_heightController.text) ?? 170.0,
        'weight_kg': double.tryParse(_weightController.text) ?? 65.0,
        'level': _level,
        'minutes_per_session': _minutesPerSession,
        'equipment': _equipment,
        'meals_per_day': _mealsPerDay,
      };
      // Frequency is recalculated; clearing an optional field must remove it.
      answers.remove('days_per_week');
      answers.remove('body_fat_pct');
      answers.remove('target_weight_kg');
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
    if (_calculating) return;
    if (_step == 3 && _constraintsError != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_constraintsError!)));
      return;
    }
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
            if (_minimumError != null) Text(_minimumError!),
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
                onPressed: _calculating ? null : _next,
                child: Text(
                  _calculating
                      ? '计算最低时长…'
                      : _step == 3
                      ? '生成计划'
                      : '下一步',
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
              onTap: () => setState(() {
                _scene = scene;
                _equipment = List.of(scene.equipment);
              }),
            ),
            const SizedBox(height: 12),
          ],
          const Text('请勾选实际可用器械，场景仅提供预选：'),
          Wrap(
            spacing: 8,
            children: [
              for (final entry in const {
                'bodyweight': '徒手',
                'dumbbell': '哑铃',
                'barbell': '杠铃',
                'cable': '绳索',
                'machine': '器械',
                'band': '弹力带',
                'pull_up_bar': '单杠',
                'kettlebell': '壶铃',
                'bench': '训练凳',
                'rack': '深蹲架',
              }.entries)
                FilterChip(
                  label: Text(entry.value),
                  selected: _equipment.contains(entry.key),
                  onSelected: (on) => setState(() {
                    if (on) {
                      _equipment.add(entry.key);
                    } else {
                      _equipment.remove(entry.key);
                    }
                    if (_equipment.isEmpty) _equipment.add('bodyweight');
                  }),
                ),
            ],
          ),
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
      title: '每次可以训练多久？',
      subtitle: '引擎根据每周训练容量自动安排天数与恢复日',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('每次至少 $_minimumMinutes 分钟', style: AppTextStyles.cardTitle),
          const Text('根据你的目标、训练经验和器械计算。这是训练日的单次时长，不要求休息日训练。'),
          const SizedBox(height: 20),
          Text('单次时长', style: AppTextStyles.cardMeta),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: [
              for (final m in ({
                _minimumMinutes!,
                _minutesPerSession,
                ..._minuteOptions,
              }.where((m) => m >= _minimumMinutes!).toList()..sort()))
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
          PlannerConstraintsFields(
            initial: {...?widget.initialFields, ..._constraints},
            onChanged: (values, error) {
              _constraints = values;
              _constraintsError = error;
            },
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
