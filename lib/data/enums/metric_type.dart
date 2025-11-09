enum MetricType {
  heartRate,
  stepsCount,
  caloriesBurnt;

  String get value {
    switch (this) {
      case MetricType.heartRate:
        return 'heart_rate';
      case MetricType.stepsCount:
        return 'steps_count';
      case MetricType.caloriesBurnt:
        return 'calories_burnt';
    }
  }

  static MetricType fromValue(String? value) {
    switch (value) {
      case 'heart_rate':
        return heartRate;
      case 'steps_count':
        return stepsCount;
      case 'calories_burnt':
        return caloriesBurnt;
      default:
        throw ArgumentError('Invalid metric type: $value');
    }
  }
}