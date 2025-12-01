import 'package:fe/core/utils/converter.dart';

class HeartRate {
  final DateTime time;
  final String userId;
  final double value;

  HeartRate({
    required this.time,
    required this.userId,
    required this.value,
  });

  factory HeartRate.fromJson(Map<String, dynamic> json) {
    return HeartRate(
      time: cvToDate(json['time'] as String),
      userId: json['user_id'] as String,
      value: (json['value'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time.toIso8601String(),
      'user_id': userId,
      'value': value,
    };
  }

  HeartRate copyWith({
    DateTime? time,
    String? userId,
    double? value,
  }) {
    return HeartRate(
      time: time ?? this.time,
      userId: userId ?? this.userId,
      value: value ?? this.value,
    );
  }
}