import 'package:fe/core/utils/converter.dart';

class StepsCount {
  final DateTime time;
  final String userId;
  final int value;

  StepsCount({
    required this.time,
    required this.userId,
    required this.value,
  });

  factory StepsCount.fromJson(Map<String, dynamic> json) {
    return StepsCount(
      time: cvToDateRequired(json['time'] as String),
      userId: json['user_id'] as String,
      value: json['value'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time.toIso8601String(),
      'user_id': userId,
      'value': value,
    };
  }

  StepsCount copyWith({
    DateTime? time,
    String? userId,
    int? value,
  }) {
    return StepsCount(
      time: time ?? this.time,
      userId: userId ?? this.userId,
      value: value ?? this.value,
    );
  }
}