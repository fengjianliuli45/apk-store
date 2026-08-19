import 'package:flutter/material.dart';

import '../../data/diet_catalog.dart';
import '../../models/meal.dart';
import '../../state/diet_log_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/back_bar.dart';
import '../../widgets/gradient_background.dart';

/// Manual pick from the local meal catalog — the fallback when there's no
/// barcode match, and a first-class entry point on its own.
class DietMealPickerScreen extends StatelessWidget {
  const DietMealPickerScreen({super.key, required this.dietLog});

  final DietLogController dietLog;

  @override
  Widget build(BuildContext context) {
    final bySlot = <MealSlot, List<MealTemplate>>{
      for (final slot in MealSlot.values) slot: DietCatalog.meals.where((m) => m.slot == slot).toList(),
    };
    return GradientBackground(
      child: Column(
        children: [
          const BackBar(title: '手动选择食物'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                for (final slot in MealSlot.values) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 6),
                    child: Text(
                      slot.label,
                      style: const TextStyle(fontFamily: AppFonts.inter, fontWeight: FontWeight.w600, color: AppColors.ink),
                    ),
                  ),
                  for (final template in bySlot[slot]!)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: () async {
                          await dietLog.logTemplate(template, source: MealSource.catalogEstimate);
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('已打卡：${template.name}')),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(template.name, style: AppTextStyles.cardName),
                                    const SizedBox(height: 2),
                                    Text(template.items.join(' · '), style: AppTextStyles.cardMeta),
                                  ],
                                ),
                              ),
                              Text('${template.kcal} kcal', style: AppTextStyles.cardStat),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
