import 'models.dart';
import 'plan_copy.dart';

/// Check-in is due on week 4, 8, 12… when [ProgressionResult.nextCheckWeek]
/// is 4. Week 1–3 of a freshly generated plan never prompt.
bool checkInDue(GeneratedPlan plan, {DateTime? now}) {
  final cycle = plan.progression.nextCheckWeek;
  if (cycle <= 0) return false;
  final week = planWeekNumber(plan.generatedAt, now);
  return week >= cycle && week % cycle == 0;
}

/// [promptedWeek] is the last week we already showed the dialog for this
/// [promptedGeneratedAt]. A new plan (different generatedAt) always qualifies
/// again once it hits a check week.
bool shouldPromptCheckIn({
  required GeneratedPlan plan,
  required String? promptedGeneratedAt,
  required int promptedWeek,
  DateTime? now,
}) {
  if (!checkInDue(plan, now: now)) return false;
  final week = planWeekNumber(plan.generatedAt, now);
  if (promptedGeneratedAt == plan.generatedAt.toIso8601String() && promptedWeek >= week) {
    return false;
  }
  return true;
}
