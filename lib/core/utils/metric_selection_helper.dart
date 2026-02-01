import 'package:fe/data/enums/metric_type.dart';
import 'package:fe/data/models/ui/metric_option.dart';
import 'package:fe/core/utils/metric_helper.dart';

/// Helper class for metric selection logic
/// Reduces if-else complexity in metric selection dialogs
class MetricSelectionHelper {
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

  /// Gets all available metrics
  static List<MetricOption> getAvailableMetrics() {
    return MetricHelper.availableMetrics;
  }
}

