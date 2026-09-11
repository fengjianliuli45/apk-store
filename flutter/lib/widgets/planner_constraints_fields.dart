import 'package:flutter/material.dart';

/// Only engine-supported keys. Existing values survive unless explicitly edited.
class PlannerConstraintsFields extends StatefulWidget {
  const PlannerConstraintsFields({
    super.key,
    required this.initial,
    required this.onChanged,
  });
  final Map<String, dynamic> initial;
  final void Function(Map<String, dynamic>, String?) onChanged;
  @override
  State<PlannerConstraintsFields> createState() =>
      _PlannerConstraintsFieldsState();
}

class _PlannerConstraintsFieldsState extends State<PlannerConstraintsFields> {
  late final Map<String, dynamic> values = {...widget.initial};
  final Map<String, String> errors = {};
  void publish() => widget.onChanged({...values}, errors.values.firstOrNull);

  Widget choices(String key, Map<String, String> options) {
    final selected = List<String>.from(values[key] as List? ?? const []);
    return Wrap(
      spacing: 8,
      children: [
        for (final entry in {
          ...options,
          for (final value in selected)
            if (!options.containsKey(value)) value: value,
        }.entries)
          FilterChip(
            label: Text(entry.value),
            selected: selected.contains(entry.key),
            onSelected: (on) => setState(() {
              if (on) {
                selected.add(entry.key);
              } else {
                selected.remove(entry.key);
              }
              values[key] = selected;
              publish();
            }),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => ExpansionTile(
    title: const Text('伤病、饮食与力量基线'),
    subtitle: const Text('选填；会影响动作筛选和饮食建议'),
    childrenPadding: const EdgeInsets.all(12),
    children: [
      const Text('伤病部位（引擎筛选不等于医疗评估）'),
      choices('injuries', const {
        'knee': '膝',
        'shoulder': '肩',
        'lower_back': '下背',
        'wrist': '腕',
        'elbow': '肘',
        'hip': '髋',
        'ankle': '踝',
        'neck': '颈',
      }),
      const SizedBox(height: 12),
      const Text('饮食限制（仍需核对实际配料）'),
      choices('dietary_restrictions', const {
        'vegetarian': '蛋奶素',
        'vegan': '纯素',
        'halal': '清真',
        'no_pork': '不吃猪肉',
        'no_beef': '不吃牛肉',
        'no_dairy': '不吃乳制品',
        'no_gluten': '无麸质',
        'no_nut': '不吃坚果',
        'no_seafood': '不吃海鲜',
      }),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        initialValue: values['cooking_access'] as String? ?? 'home',
        decoration: const InputDecoration(labelText: '烹饪条件'),
        items: [
          for (final entry in const {
            'home': '可自己做饭',
            'canteen': '食堂',
            'none': '无法烹饪',
          }.entries)
            DropdownMenuItem(value: entry.key, child: Text(entry.value)),
        ],
        onChanged: (value) {
          values['cooking_access'] = value;
          publish();
        },
      ),
      const SizedBox(height: 16),
      const Text('已有力量基线：填写已知的估算 1RM（kg），不知道请留空；不需要为填表测试极限重量。'),
      for (final entry in const {
        'squat': '深蹲',
        'bench': '卧推',
        'hinge': '硬拉/罗马尼亚硬拉',
        'row': '划船',
      }.entries)
        TextFormField(
          key: ValueKey('baseline_${entry.key}'),
          initialValue:
              (widget.initial['strength_baseline']
                      as Map?)?[entry.key]?['one_rm_kg']
                  ?.toString() ??
              '',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: '${entry.value}估算 1RM（kg）',
            helperText:
                (widget.initial['strength_baseline']
                        as Map?)?[entry.key]?['weight_kg'] ==
                    null
                ? null
                : '已保存重量/次数基线；不修改则保留',
            errorText: errors[entry.key],
          ),
          onChanged: (text) => setState(() {
            final baseline = Map<String, dynamic>.from(
              values['strength_baseline'] as Map? ?? {},
            );
            final number = double.tryParse(text.trim());
            errors.remove(entry.key);
            if (text.trim().isEmpty) {
              baseline.remove(entry.key);
            } else if (number == null || !number.isFinite || number <= 0) {
              errors[entry.key] = '请输入大于 0 的有效重量，或留空';
            } else {
              baseline[entry.key] = {'one_rm_kg': number};
            }
            values['strength_baseline'] = baseline;
            publish();
          }),
        ),
    ],
  );
}
