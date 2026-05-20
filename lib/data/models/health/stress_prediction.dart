class StressPrediction {
  final int label;
  final String labelName;
  final double probStress;
  final double probBaseline;
  final bool calibrated;

  const StressPrediction({
    required this.label,
    required this.labelName,
    required this.probStress,
    required this.probBaseline,
    required this.calibrated,
  });

  bool get isStress => label == 2;

  factory StressPrediction.fromJson(Map<String, dynamic> json) {
    return StressPrediction(
      label: (json['label'] as num).toInt(),
      labelName: json['label_name'] as String,
      probStress: (json['prob_stress'] as num).toDouble(),
      probBaseline: (json['prob_baseline'] as num).toDouble(),
      calibrated: json['calibrated'] as bool? ?? false,
    );
  }
}
