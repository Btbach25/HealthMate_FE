import 'package:fe/data/enums/metric_type.dart';
import 'package:fe/data/models/ui/metric_option.dart';
import 'package:fe/core/utils/metric_helper.dart';

/// Helper class for metric selection logic
/// Reduces if-else complexity in metric selection dialogs
class MetricSelectionHelper {
  static const Set<String> _backendSupportedMetricTypes = {
    'heart_rate',
    'steps_count',
    'calories_burned',
  };

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

  /// Backend auth-service chỉ chấp nhận: heart_rate, steps_count, calories_burned.
  /// Lọc bỏ các loại khác và chuẩn hóa calories_burnt -> calories_burned trước khi gửi API.
  static List<String> filterMetricTypesForBackend(List<String> metricTypes) {
    return metricTypes
        .map((m) => m == 'calories_burnt' ? 'calories_burned' : m)
        .where(_backendSupportedMetricTypes.contains)
        .toSet()
        .toList();
  }

  static bool isMetricSupportedByBackend(MetricType metricType) {
    return filterMetricTypesForBackend([metricType.value]).isNotEmpty;
  }

  /// Gets all available metrics
  static List<MetricOption> getAvailableMetrics() {
    return MetricHelper.availableMetrics;
  }
}

