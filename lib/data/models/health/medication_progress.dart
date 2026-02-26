class MedicationProgress {
  final int completed;
  final int total;

  MedicationProgress({
    required this.completed,
    required this.total,
  });

  factory MedicationProgress.fromJson(Map<String, dynamic> json) {
    return MedicationProgress(
      completed: json['completed'] as int,
      total: json['total'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'completed': completed,
      'total': total,
    };
  }

  MedicationProgress copyWith({
    int? completed,
    int? total,
  }) {
    return MedicationProgress(
      completed: completed ?? this.completed,
      total: total ?? this.total,
    );
  }
}