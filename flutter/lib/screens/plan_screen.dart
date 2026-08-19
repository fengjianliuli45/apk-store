import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../data/training_catalog.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// 计划 tab, embedded only inside the social module's bottom bar (screen
/// screen-social-feed, node 193:65) — never shown on Home. table_calendar
/// over the same fixed weekly plan used on the 训练 tab, marking training
/// days and listing the selected day's moves.
class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final selectedPlan = TrainingCatalog.forDate(_selectedDay);
    return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [Text('计划', style: AppTextStyles.screenTitle)],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
              child: TableCalendar(
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(color: AppColors.brandGreen.withValues(alpha: 0.5), shape: BoxShape.circle),
                  selectedDecoration: const BoxDecoration(color: AppColors.brandGreen, shape: BoxShape.circle),
                  selectedTextStyle: const TextStyle(fontFamily: AppFonts.inter, fontWeight: FontWeight.bold, color: AppColors.ink),
                  markerDecoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(fontFamily: AppFonts.inter, fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.ink),
                ),
                eventLoader: (day) => TrainingCatalog.forDate(day).isRestDay ? const [] : const [1],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_selectedDay.month}月${_selectedDay.day}日 · ${selectedPlan.title}',
                        style: AppTextStyles.cardTitle,
                      ),
                      const SizedBox(height: 12),
                      if (selectedPlan.isRestDay)
                        Text('这天是休息日', style: TextStyle(fontFamily: AppFonts.inter, color: AppColors.textMuted))
                      else
                        for (final ex in selectedPlan.exercises)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(ex.name, style: const TextStyle(fontFamily: AppFonts.inter, color: AppColors.ink)),
                                Text('${ex.sets} 组 × ${ex.reps}', style: AppTextStyles.cardMeta),
                              ],
                            ),
                          ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
    );
  }
}
