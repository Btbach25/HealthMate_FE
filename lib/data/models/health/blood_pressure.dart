import 'package:fe/core/utils/converter.dart';

class BloodPressure {
  final DateTime time;
  final String userId;
  final int? systolic;
  final int? diastolic; 

  BloodPressure({
    required this.time,
    required this.userId,
    this.systolic,
    this.diastolic,
  });

  factory BloodPressure.fromJson(Map<String, dynamic> json) {
    return BloodPressure(
      time: cvToDate(json['time'] as String),
      userId: json['user_id'] as String,
      systolic: json['systolic'] as int?,
      diastolic: json['diastolic'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time.toIso8601String(),
      'user_id': userId,
      'systolic': systolic,
      'diastolic': diastolic,
    };
  }

  BloodPressure copyWith({
    DateTime? time,
    String? userId,
    int? systolic,
    int? diastolic,
  }) {
    return BloodPressure(
      time: time ?? this.time,
      userId: userId ?? this.userId,
      systolic: systolic ?? this.systolic,
      diastolic: diastolic ?? this.diastolic,
    );
  }
}