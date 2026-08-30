import 'models.dart';

class StageEvidence {
  const StageEvidence({
    required this.completedSessions,
    required this.activeWeeks,
    required this.comparableMeasurements,
    this.performanceImprovementPct,
    this.performanceConfirmations = 0,
    this.sameLoadRepGain,
    this.bodyTrendTargetMet = false,
    this.stablePositiveResponse = false,
    this.unresolvedSafetyIssue = false,
  });

  final int completedSessions;
  final int activeWeeks;
  final int comparableMeasurements;
  final double? performanceImprovementPct;
  final int performanceConfirmations;
  final int? sameLoadRepGain;
  final bool bodyTrendTargetMet;
  final bool stablePositiveResponse;
  final bool unresolvedSafetyIssue;
}

class StageAssessment {
  const StageAssessment({
    required this.achieved,
    required this.status,
    required this.adherenceMet,
    required this.dataQualityMet,
    required this.outcomeMet,
    required this.safetyMet,
    required this.confidence,
    required this.reasons,
    required this.nextAction,
  });

  final bool achieved;
  final String status;
  final bool adherenceMet;
  final bool dataQualityMet;
  final bool outcomeMet;
  final bool safetyMet;
  final String confidence;
  final List<String> reasons;
  final String nextAction;

  Map<String, dynamic> toJson() => {
        'achieved': achieved,
        'status': status,
        'adherence_met': adherenceMet,
        'data_quality_met': dataQualityMet,
        'outcome_met': outcomeMet,
        'safety_met': safetyMet,
        'confidence': confidence,
        'reasons': reasons,
        'next_action': nextAction,
      };
}

StageAssessment assessStage(StageGoal goal, StageEvidence evidence) {
  final reasons = <String>[];
  final adherenceMet =
      evidence.completedSessions >= goal.requiredSessions &&
      evidence.activeWeeks >= goal.minimumActiveWeeks;
  if (!adherenceMet) {
    reasons.add(
      '执行门槛未达成：需要 ${goal.requiredSessions} 次、覆盖 ${goal.minimumActiveWeeks} 周',
    );
  }

  final dataQualityMet =
      evidence.comparableMeasurements >= goal.minimumComparableMeasurements;
  if (!dataQualityMet) {
    reasons.add('可比较测量不足：至少需要 ${goal.minimumComparableMeasurements} 次');
  }

  final performanceMet =
      ((evidence.performanceImprovementPct ?? 0) >= 2.5 &&
          evidence.performanceConfirmations >= 2) ||
      (evidence.sameLoadRepGain ?? 0) >= 2;
  final outcomeMet =
      performanceMet ||
      evidence.bodyTrendTargetMet ||
      evidence.stablePositiveResponse;
  if (!outcomeMet) reasons.add('尚未观察到可复测的能力提升或稳定正向身体趋势');

  final safetyMet = !evidence.unresolvedSafetyIssue;
  if (!safetyMet) reasons.add('存在未处理的疼痛、伤病或安全问题');
  final achieved = adherenceMet && dataQualityMet && outcomeMet && safetyMet;

  return StageAssessment(
    achieved: achieved,
    status: achieved ? 'achieved' : 'extended',
    adherenceMet: adherenceMet,
    dataQualityMet: dataQualityMet,
    outcomeMet: outcomeMet,
    safetyMet: safetyMet,
    confidence: achieved ? 'high' : (dataQualityMet ? 'medium' : 'low'),
    reasons: achieved ? const ['第一阶段适应目标已达成'] : reasons,
    nextAction: achieved
        ? '生成宠物幼体并创建下一阶段目标'
        : (!safetyMet ? '先处理安全问题，再重新评估' : '延长阶段 2 周并调整容量或动作'),
  );
}
