/// Kết quả dự đoán mức căng thẳng từ ML service.
/// Ánh xạ response của `POST /metrics/stress/predict` (`label`, `label_name`,
/// `prob_stress`, `prob_baseline`, `calibrated`).
/// Quy ước backend: `label == 2` nghĩa là đang stress (xem [isStress]).
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
