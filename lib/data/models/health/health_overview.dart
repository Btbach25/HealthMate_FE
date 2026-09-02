import 'package:equatable/equatable.dart';
import 'package:fe/data/models/health/blood_pressure.dart';
import 'package:fe/data/models/health/heart_rate.dart';
import 'package:fe/data/models/health/temperature.dart';
import 'package:fe/data/models/health/weight.dart';

/// Ảnh chụp nhanh các chỉ số sức khoẻ mới nhất hiển thị ở trang chủ.
/// Nguồn: `HealthService` (API) hoặc dữ liệu đọc từ thiết bị.
class HealthOverview extends Equatable {
  final HeartRate? heartRate;
  final Weight? weight;
  final BloodPressure? bloodPressure;
  final Temperature? temperature;
  final double? bloodOxygen;

  const HealthOverview({
    this.heartRate,
    this.weight,
    this.bloodPressure,
    this.temperature,
    this.bloodOxygen,
  });

  factory HealthOverview.empty() {
    return const HealthOverview();
  }

  factory HealthOverview.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return HealthOverview(
      heartRate: json['heart_rate'] != null
          ? HeartRate.fromJson(json['heart_rate'] as Map<String, dynamic>)
          : null,
      weight: json['weight'] != null
          ? Weight.fromJson(json['weight'] as Map<String, dynamic>)
          : null,
      bloodPressure: json['blood_pressure'] != null
          ? BloodPressure.fromJson(
              json['blood_pressure'] as Map<String, dynamic>,
            )
          : null,
      temperature: json['temperature'] != null
          ? Temperature.fromJson(json['temperature'] as Map<String, dynamic>)
          : null,
      bloodOxygen: parseDouble(json['spo2'] ?? json['blood_oxygen']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'heart_rate': heartRate?.toJson(),
      'weight': weight?.toJson(),
      'blood_pressure': bloodPressure?.toJson(),
      'temperature': temperature?.toJson(),
      'spo2': bloodOxygen,
    };
  }

  HealthOverview copyWith({
    HeartRate? heartRate,
    Weight? weight,
    BloodPressure? bloodPressure,
    Temperature? temperature,
    double? bloodOxygen,
  }) {
    return HealthOverview(
      heartRate: heartRate ?? this.heartRate,
      weight: weight ?? this.weight,
      bloodPressure: bloodPressure ?? this.bloodPressure,
      temperature: temperature ?? this.temperature,
      bloodOxygen: bloodOxygen ?? this.bloodOxygen,
    );
  }

  @override
  List<Object?> get props => [
    heartRate,
    weight,
    bloodPressure,
    temperature,
    bloodOxygen,
  ];
}
