import 'package:fe/core/utils/converter.dart';

class CaloriesBurnt {
  final DateTime time;
  final String userId;
  final double value;

  CaloriesBurnt({
    required this.time,
    required this.userId,
    required this.value,
  });

  factory CaloriesBurnt.fromJson(Map<String, dynamic> json) {
    return CaloriesBurnt(
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

  CaloriesBurnt copyWith({
    DateTime? time,
    String? userId,
    double? value,
  }) {
    return CaloriesBurnt(
      time: time ?? this.time,
      userId: userId ?? this.userId,
      value: value ?? this.value,
    );
  }
}