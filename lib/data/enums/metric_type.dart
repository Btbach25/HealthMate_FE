enum MetricType {
  heartRate,
  stepsCount,
  caloriesBurnt,
  bloodPressure,
  weight,
  sleep,
  temperature;

  String get value {
    switch (this) {
      case MetricType.heartRate:
        return 'heart_rate';
      case MetricType.stepsCount:
        return 'steps_count';
      case MetricType.caloriesBurnt:
        return 'calories_burnt';
      case MetricType.bloodPressure:
        return 'blood_pressure';
      case MetricType.weight:
        return 'weight';
      case MetricType.sleep:
        return 'sleep';
      case MetricType.temperature:
        return 'temperature';
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
      case 'blood_pressure':
        return bloodPressure;
      case 'weight':
        return weight;
      case 'sleep':
        return sleep;
      case 'temperature':
        return temperature;
      default:
        throw ArgumentError('Invalid metric type: $value');
    }
  }
}