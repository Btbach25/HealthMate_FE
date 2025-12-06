import 'package:fe/core/utils/converter.dart';

class Weight {
  final DateTime time;
  final String userId;
  final double? value;

  Weight({
    required this.time,
    required this.userId,
    this.value,
  });

  factory Weight.fromJson(Map<String, dynamic> json) {
    return Weight(
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

  Weight copyWith({
    DateTime? time,
    String? userId,
    double? value,
  }) {
    return Weight(
      time: time ?? this.time,
      userId: userId ?? this.userId,
      value: value ?? this.value,
    );
  }
}