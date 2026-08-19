import 'package:flutter/material.dart';

import '../../models/meal.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Bottom sheet shown after taking a photo: a catalog-matched estimate the
/// user can confirm, re-roll, or bail out of into the manual picker.
class DietEstimateSheet extends StatefulWidget {
  const DietEstimateSheet({
    super.key,
    required this.initial,
    required this.onReroll,
    required this.onConfirm,
    required this.onManualPick,
  });

  final MealTemplate initial;
  final MealTemplate Function() onReroll;
  final void Function(MealTemplate template) onConfirm;
  final VoidCallback onManualPick;

  @override
  State<DietEstimateSheet> createState() => _DietEstimateSheetState();
}

class _DietEstimateSheetState extends State<DietEstimateSheet> {
  late MealTemplate _template = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: AppColors.textMuted, borderRadius: BorderRadius.circular(2)),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.brandGreen, borderRadius: BorderRadius.circular(10)),
                child: const Text('目录估算', style: AppTextStyles.tagLabel),
              ),
              const SizedBox(width: 8),
              Text(_template.slot.label, style: AppTextStyles.cardTime),
            ],
          ),
          const SizedBox(height: 12),
          Text(_template.name, style: AppTextStyles.cardTitle),
          const SizedBox(height: 4),
          Text('${_template.kcal} kcal · ${_template.items.join(' · ')}', style: AppTextStyles.cardMeta),
          const SizedBox(height: 8),
          Text(_template.tip, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(
            '蛋白质 ${_template.proteinG}g · 碳水 ${_template.carbG}g · 脂肪 ${_template.fatG}g',
            style: TextStyle(fontFamily: AppFonts.jetBrainsMono, fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _template = widget.onReroll()),
                  child: const Text('换一个'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.brandGreen, foregroundColor: AppColors.ink),
                  onPressed: () => widget.onConfirm(_template),
                  child: const Text('确认打卡'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: widget.onManualPick,
            child: const Text('不对？手动选择食物', style: TextStyle(color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }
}
