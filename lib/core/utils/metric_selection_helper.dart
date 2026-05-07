import 'package:fe/data/enums/metric_type.dart';
import 'package:fe/data/models/ui/metric_option.dart';
import 'package:fe/core/utils/metric_helper.dart';

/// Helper class for metric selection logic
/// Reduces if-else complexity in metric selection dialogs
class MetricSelectionHelper {
  /// Khớp `metric_types.name` trong storage-service (migration).
  static const Set<String> _backendSupportedMetricTypes = {
    'heart_rate',
    'steps_count',
    'calories_burned',
    'blood_pressure',
    'spo2',
  };

  /// Chuẩn hóa tên gửi auth/storage (ví dụ enum FE dùng `calories_burnt`).
  static String toBackendMetricName(String metricType) {
    if (metricType == 'calories_burnt') return 'calories_burned';
    return metricType;
  }

  /// Validates that at least one metric is selected
  static bool validateSelection(Set<MetricType> selectedMetrics) {
    return selectedMetrics.isNotEmpty;
  }

  /// Gets validation error message
  static String getValidationErrorMessage() {
    return 'Vui lòng chọn ít nhất một chỉ số để chia sẻ';
  }

  /// Checks if metrics have changed
  static bool hasMetricsChanged(
    Set<MetricType> selected,
    List<MetricType> original,
  ) {
    if (selected.length != original.length) return true;
    return !selected.every((type) => original.contains(type));
  }

  /// Converts selected metrics to API format
  static List<String> toApiFormat(Set<MetricType> selectedMetrics) {
    return selectedMetrics.map((m) => m.value).toList();
  }

  /// Lọc theo `metric_types` trên BE; chuẩn hóa `calories_burnt` -> `calories_burned`.
  static List<String> filterMetricTypesForBackend(List<String> metricTypes) {
    return metricTypes
        .map(toBackendMetricName)
        .where(_backendSupportedMetricTypes.contains)
        .toSet()
        .toList();
  }

  /// Tên chỉ số FE dự đoán BE có (khi chưa gọi được GET /groups/metric-types).
  static Set<String> get backendMetricNameSet =>
      Set.unmodifiable(_backendSupportedMetricTypes);

  /// Chỉ giữ tên có trong bảng `metric_types` thật trên máy chủ (đã chuẩn hóa).
  static List<String> intersectWithServerMetricNames(
    List<String> backendFilteredTypes,
    Set<String> serverMetricNames,
  ) {
    return backendFilteredTypes
        .where(serverMetricNames.contains)
        .toSet()
        .toList()
      ..sort();
  }

  static bool isMetricSupportedByBackend(MetricType metricType) {
    return filterMetricTypesForBackend([metricType.value]).isNotEmpty;
  }

  /// Gets all available metrics
  static List<MetricOption> getAvailableMetrics() {
    return MetricHelper.availableMetrics;
  }
}

