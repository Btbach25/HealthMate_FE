import 'package:equatable/equatable.dart';
import 'package:fe/data/models/health/blood_pressure.dart';
import 'package:fe/data/models/health/heart_rate.dart';
import 'package:fe/data/models/health/temperature.dart';
import 'package:fe/data/models/health/weight.dart';

class HealthOverview extends Equatable {
  final HeartRate? heartRate;
  final Weight? weight;
  final BloodPressure? bloodPressure;
  final Temperature? temperature;

  const HealthOverview({
    this.heartRate,
    this.weight,
    this.bloodPressure,
    this.temperature,
  });

  factory HealthOverview.empty() {
    return const HealthOverview();
  }

  factory HealthOverview.fromJson(Map<String, dynamic> json) {
    return HealthOverview(
      heartRate: json['heart_rate'] != null
          ? HeartRate.fromJson(json['heart_rate'] as Map<String, dynamic>)
          : null,
      weight: json['weight'] != null
          ? Weight.fromJson(json['weight'] as Map<String, dynamic>)
          : null,
      bloodPressure: json['blood_pressure'] != null
          ? BloodPressure.fromJson(json['blood_pressure'] as Map<String, dynamic>)
          : null,
      temperature: json['temperature'] != null
          ? Temperature.fromJson(json['temperature'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'heart_rate': heartRate?.toJson(),
      'weight': weight?.toJson(),
      'blood_pressure': bloodPressure?.toJson(),
      'temperature': temperature?.toJson(),
    };
  }

  HealthOverview copyWith({
    HeartRate? heartRate,
    Weight? weight,
    BloodPressure? bloodPressure,
    Temperature? temperature,
  }) {
    return HealthOverview(
      heartRate: heartRate ?? this.heartRate,
      weight: weight ?? this.weight,
      bloodPressure: bloodPressure ?? this.bloodPressure,
      temperature: temperature ?? this.temperature,
    );
  }

  @override
  List<Object?> get props => [heartRate, weight, bloodPressure, temperature];
}