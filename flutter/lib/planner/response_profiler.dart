class ResponseObservation {
  const ResponseObservation({
    required this.completedCycles,
    required this.adherencePct,
    this.performanceImprovementPct,
    this.weightTrendPct,
    this.waistTrendPct,
    this.recoveryScore,
  });

  final int completedCycles;
  final double adherencePct;
  final double? performanceImprovementPct;
  final double? weightTrendPct;
  final double? waistTrendPct;
  final double? recoveryScore;
}

class ResponseProfile {
  const ResponseProfile({
    required this.maturity,
    required this.trainingStyle,
    required this.metabolismResponse,
    required this.muscleGainResponse,
    required this.fatLossResponse,
    required this.confidence,
  });

  final String maturity;
  final String trainingStyle;
  final String metabolismResponse;
  final String muscleGainResponse;
  final String fatLossResponse;
  final String confidence;

  Map<String, dynamic> toJson() => {
        'maturity': maturity,
        'training_style': trainingStyle,
        'metabolism_response': metabolismResponse,
        'muscle_gain_response': muscleGainResponse,
        'fat_loss_response': fatLossResponse,
        'confidence': confidence,
      };
}

ResponseProfile profileResponse(ResponseObservation observation) {
  final trainingStyle = observation.adherencePct >= 85
      ? 'steady'
      : (observation.adherencePct >= 60 ? 'variable' : 'still_learning');
  if (observation.completedCycles < 2) {
    return ResponseProfile(
      maturity: 'preliminary',
      trainingStyle: trainingStyle,
      metabolismResponse: 'unknown',
      muscleGainResponse: 'unknown',
      fatLossResponse: 'unknown',
      confidence: 'low',
    );
  }

  final performance = observation.performanceImprovementPct;
  final muscle = performance == null
      ? 'unknown'
      : (performance >= 5 ? 'responsive' : 'steady');
  final hasBodyData =
      observation.weightTrendPct != null || observation.waistTrendPct != null;
  final improved =
      (observation.weightTrendPct ?? 0) < 0 ||
      (observation.waistTrendPct ?? 0) < 0;
  final fat = hasBodyData ? (improved ? 'responsive' : 'steady') : 'unknown';
  final metabolism = hasBodyData ? 'observed' : 'unknown';
  final knownAxes = [
    muscle,
    fat,
    metabolism,
  ].where((value) => value != 'unknown').length;
  return ResponseProfile(
    maturity: observation.completedCycles < 3 ? 'developing' : 'established',
    trainingStyle: trainingStyle,
    metabolismResponse: metabolism,
    muscleGainResponse: muscle,
    fatLossResponse: fat,
    confidence: knownAxes >= 2 ? 'medium' : 'low',
  );
}
