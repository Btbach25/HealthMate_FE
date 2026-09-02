enum NotificationType {
  info,
  important,
  urgent;

  String get value {
    switch (this) {
      case NotificationType.info:
        return 'info';
      case NotificationType.important:
        return 'important';
      case NotificationType.urgent:
        return 'urgent';
    }
  }

  static NotificationType fromValue(String? value) {
    switch (value) {
      case 'info':
        return info;
      case 'important':
        return important;
      case 'urgent':
        return urgent;
      default:
        return info; // Mặc định là 'info' nếu không rõ
    }
  }
}
