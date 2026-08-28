import 'package:fe/core/utils/converter.dart';

/// Chỉ số thân nhiệt — một mục trong [HealthOverview].
class Temperature {
  final DateTime time;
  final String userId;
  final double? value;

  Temperature({
    required this.time,
    required this.userId,
    this.value,
  });

  factory Temperature.fromJson(Map<String, dynamic> json) {
    return Temperature(
      time: cvToDate(json['time'] as String),
      userId: json['user_id'] as String,
      value: (json['value'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time.toIso8601String(),
      'user_id': userId,
      'value': value,
    };
  }

  Temperature copyWith({
    DateTime? time,
    String? userId,
    double? value,
  }) {
    return Temperature(
      time: time ?? this.time,
      userId: userId ?? this.userId,
      value: value ?? this.value,
    );
  }
}