import 'package:flutter/material.dart';

import '../../data/diet_catalog.dart';
import '../../models/meal.dart';
import '../../planner/plan_sync.dart';
import '../../state/diet_log_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Figma screen-history (199:229), backed by the existing persisted meal log.
class DietHistoryScreen extends StatefulWidget {
  const DietHistoryScreen({super.key, required this.dietLog});
  final DietLogController dietLog;

  @override
  State<DietHistoryScreen> createState() => _DietHistoryScreenState();
}

class _DietHistoryScreenState extends State<DietHistoryScreen> {
  DateTime _selected = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.dietLog,
      builder: (context, _) {
        final key = _dayKey(_selected);
        final meals = widget.dietLog.mealsOn(key);
        final kcal = meals.fold(0, (sum, meal) => sum + meal.kcal);
        final protein = meals.fold(0, (sum, meal) => sum + meal.proteinG);
        final carbs = meals.fold(0, (sum, meal) => sum + meal.carbG);
        final fat = meals.fold(0, (sum, meal) => sum + meal.fatG);
        return Material(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE2ECE9), Color(0xFFFAFAF8), Colors.white],
                stops: [0, 0.6, 1],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                        ),
                        const Text(
                          '饮食记录',
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(
                          width: 48,
                          child: Icon(Icons.calendar_today_outlined, size: 20),
                        ),
                      ],
                    ),
                  ),
                  _WeekStrip(
                    selected: _selected,
                    onSelect: (day) => setState(() => _selected = day),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      children: [
                        _SummaryCard(
                          kcal: kcal,
                          protein: protein,
                          carbs: carbs,
                          fat: fat,
                          goals: widget.dietLog.goals,
                        ),
                        if (widget.dietLog.goals.meals.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _EatPlanCard(goals: widget.dietLog.goals),
                        ],
                        const SizedBox(height: 16),
                        if (meals.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 34),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Column(
                              children: [
                                Icon(
                                  Icons.restaurant_outlined,
                                  color: AppColors.textMuted,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  '这一天还没有饮食记录',
                                  style: TextStyle(color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          )
                        else
                          for (final meal in meals) ...[
                            _MealRow(meal: meal),
                            const SizedBox(height: 10),
                          ],
                        _AddMealButton(onTap: () => Navigator.pop(context)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.selected, required this.onSelect});
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;
  @override
  Widget build(BuildContext context) {
    final monday = selected.subtract(Duration(days: selected.weekday - 1));
    const names = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < 7; i++)
            GestureDetector(
              onTap: () => onSelect(monday.add(Duration(days: i))),
              child: Container(
                width: 42,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _sameDay(selected, monday.add(Duration(days: i)))
                      ? AppColors.brandGreen
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D0D1112),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      names[i],
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${monday.add(Duration(days: i)).day}',
                      style: const TextStyle(
                        fontFamily: AppFonts.chakraPetch,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.goals,
  });
  final int kcal;
  final int protein;
  final int carbs;
  final int fat;
  final DietGoals goals;
  @override
  Widget build(BuildContext context) {
    final progress = (kcal / goals.kcal.clamp(1, 1 << 31)).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0D1112),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('今日总摄入', style: TextStyle(fontSize: 14)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$kcal',
                    style: const TextStyle(
                      fontFamily: AppFonts.chakraPetch,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    ' / ${goals.kcal} kcal',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFF2F5F4),
              color: AppColors.brandGreen,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _SummaryTag(
                '蛋白质 · ${DietCatalog.levelOf(protein, goals.proteinG).label}',
              ),
              const SizedBox(width: 8),
              _SummaryTag(
                '碳水 · ${DietCatalog.levelOf(carbs, goals.carbG).label}',
                highlighted: true,
              ),
              const SizedBox(width: 8),
              _SummaryTag(
                '脂肪 · ${DietCatalog.levelOf(fat, goals.fatG).label}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EatPlanCard extends StatelessWidget {
  const _EatPlanCard({required this.goals});
  final DietGoals goals;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0D1112),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('今日吃计划', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          for (final meal in goals.meals) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      meal.name,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '${meal.kcal.round()} kcal · 蛋白 ${meal.proteinG.round()}g',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryTag extends StatelessWidget {
  const _SummaryTag(this.label, {this.highlighted = false});
  final String label;
  final bool highlighted;
  @override
  Widget build(BuildContext context) => Flexible(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.brandGreen.withValues(alpha: 0.10)
            : const Color(0xFFF2F5F4),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

class _MealRow extends StatelessWidget {
  const _MealRow({required this.meal});
  final LoggedMeal meal;
  @override
  Widget build(BuildContext context) {
    final image = switch (meal.slot) {
      MealSlot.breakfast => 'assets/diet/breakfast.png',
      MealSlot.lunch => 'assets/diet/lunch.png',
      MealSlot.dinner => 'assets/diet/lunch.png',
      MealSlot.snack => 'assets/diet/breakfast.png',
    };
    final time = DateTime.fromMillisecondsSinceEpoch(meal.timestampMs);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0D1112),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              image,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _SlotThumb(slot: meal.slot),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.slot.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${meal.name} · ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${meal.kcal} kcal',
            style: const TextStyle(
              fontFamily: AppFonts.chakraPetch,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddMealButton extends StatelessWidget {
  const _AddMealButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.textMuted,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        '+ 添加餐食',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
        ),
      ),
    ),
  );
}

class _SlotThumb extends StatelessWidget {
  const _SlotThumb({required this.slot});

  final MealSlot slot;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      color: AppColors.brandGreen.withValues(alpha: 0.35),
      alignment: Alignment.center,
      child: Text(
        slot.label.substring(0, 1),
        style: const TextStyle(
          fontFamily: AppFonts.inter,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
    );
  }
}
