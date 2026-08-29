import 'package:fe/data/enums/notification_type.dart';

/// Một thông báo liên quan tới nhóm gia đình hiển thị ở trang chủ.
/// JSON dùng snake_case (`time_ago`, `type`).
class FamilyNotification {
  final String id;
  final String message;
  final String? timeAgo;
  final NotificationType type;

  FamilyNotification({
    required this.id,
    required this.message,
    this.timeAgo,
    required this.type,
  });

  factory FamilyNotification.fromJson(Map<String, dynamic> json) {
    return FamilyNotification(
      id: json['id'] as String,
      message: json['message'] as String,
      timeAgo: json['time_ago'] as String?,
      type: NotificationType.fromValue(json['type'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'time_ago': timeAgo,
      'type': type.value,
    };
  }

  FamilyNotification copyWith({
    String? id,
    String? message,
    String? timeAgo,
    NotificationType? type,
  }) {
    return FamilyNotification(
      id: id ?? this.id,
      message: message ?? this.message,
      timeAgo: timeAgo ?? this.timeAgo,
      type: type ?? this.type,
    );
  }
}