enum MetricStatus {
  normal,
  warning,
  danger;

  String get value {
    switch (this) {
      case MetricStatus.normal:
        return 'normal';
      case MetricStatus.warning:
        return 'warning';
      case MetricStatus.danger:
        return 'danger';
    }
  }

  static MetricStatus fromValue(String? value) {
    switch (value) {
      case 'normal':
        return normal;
      case 'warning':
        return warning;
      case 'danger':
        return danger;
      default:
        return normal;
    }
  }
}
