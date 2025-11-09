import '../enums/metric_type.dart';

class SharingPermission {
  final String groupId;
  final String userId;
  final MetricType metricType;

  SharingPermission({
    required this.groupId,
    required this.userId,
    required this.metricType,
  });

  factory SharingPermission.fromJson(Map<String, dynamic> json) {
    return SharingPermission(
      groupId: json['group_id'] as String,
      userId: json['user_id'] as String,
      metricType: MetricType.fromValue(json['metric_type'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'group_id': groupId,
      'user_id': userId,
      'metric_type': metricType.value,
    };
  }

  SharingPermission copyWith({
    String? groupId,
    String? userId,
    MetricType? metricType,
  }) {
    return SharingPermission(
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      metricType: metricType ?? this.metricType,
    );
  }
}