import 'package:fe/data/enums/metric_type.dart';

/// Cầu nối giữa tên chỉ số phía FE và tên chỉ số phía backend.
///
/// Tồn tại vì hai bên KHÔNG khớp nhau hoàn toàn:
/// 1. Khác chính tả — enum FE dùng `calories_burnt`, bảng `metric_types` của
///    storage-service dùng `calories_burned`.
/// 2. Khác phạm vi — FE vẽ được 8 chỉ số, backend mới nhận 5.
///
/// Gửi thẳng tên FE lên server sẽ bị từ chối với lỗi "invalid metric", nên
/// mọi danh sách chỉ số đi ra API đều phải qua
/// [filterMetricTypesForBackend] trước.
///
/// ```dart
/// // Vẽ: chỉ bật những ô backend nhận được
/// final options = MetricHelper.availableMetrics
///     .where((m) => MetricSelectionHelper.isMetricSupportedByBackend(m.type))
///     .toList();
///
/// // Gửi: đổi tên + lọc
/// final payload = MetricSelectionHelper.filterMetricTypesForBackend(
///   MetricSelectionHelper.toApiFormat(selected),
/// );
/// ```
class MetricSelectionHelper {
  /// Khớp cột `metric_types.name` trong storage-service (theo migration).
  ///
  /// Đây là phỏng đoán phía FE, dùng khi chưa gọi được
  /// `GET /groups/metric-types`. Backend bổ sung chỉ số mới thì phải cập nhật
  /// tay danh sách này.
  static const Set<String> _backendSupportedMetricTypes = {
    'heart_rate',
    'steps_count',
    'calories_burned',
    'blood_pressure',
    'spo2',
  };

  /// Đổi tên chỉ số FE sang tên backend (`calories_burnt` → `calories_burned`).
  ///
  /// Tên không nằm trong diện đổi thì trả nguyên vẹn.
  static String toBackendMetricName(String metricType) {
    if (metricType == 'calories_burnt') return 'calories_burned';
    return metricType;
  }

  /// Phải chọn ít nhất một chỉ số thì mới cho lưu.
  static bool validateSelection(Set<MetricType> selectedMetrics) {
    return selectedMetrics.isNotEmpty;
  }

  /// Thông báo lỗi đi kèm [validateSelection].
  static String getValidationErrorMessage() {
    return 'Vui lòng chọn ít nhất một chỉ số để chia sẻ';
  }

  /// So sánh lựa chọn hiện tại với lựa chọn ban đầu, bỏ qua thứ tự.
  ///
  /// Dùng để bật/tắt nút Lưu hoặc hỏi xác nhận khi người dùng rời form.
  static bool hasMetricsChanged(
    Set<MetricType> selected,
    List<MetricType> original,
  ) {
    if (selected.length != original.length) return true;
    return !selected.every((type) => original.contains(type));
  }

  /// Đổi tập enum đã chọn thành danh sách chuỗi thô của FE.
  ///
  /// Đây MỚI là dạng thô — vẫn còn tên FE. Phải cho qua
  /// [filterMetricTypesForBackend] trước khi đưa vào body request.
  static List<String> toApiFormat(Set<MetricType> selectedMetrics) {
    return selectedMetrics.map((m) => m.value).toList();
  }

  /// Chuẩn hoá tên rồi bỏ những chỉ số backend không nhận. Kết quả đã khử
  /// trùng lặp — cần thiết vì hai tên FE khác nhau có thể quy về cùng một
  /// tên backend.
  static List<String> filterMetricTypesForBackend(List<String> metricTypes) {
    return metricTypes
        .map(toBackendMetricName)
        .where(_backendSupportedMetricTypes.contains)
        .toSet()
        .toList();
  }

  /// Bản chỉ-đọc của danh sách phỏng đoán, cho nơi cần dùng khi chưa gọi được
  /// `GET /groups/metric-types`.
  static Set<String> get backendMetricNameSet =>
      Set.unmodifiable(_backendSupportedMetricTypes);

  /// Giao danh sách đã lọc với danh sách `metric_types` THẬT lấy từ server.
  ///
  /// Dùng khi đã gọi được `GET /groups/metric-types`: chính xác hơn
  /// [_backendSupportedMetricTypes] vốn chỉ là phỏng đoán cứng trong code.
  /// Kết quả được sắp xếp để payload ổn định giữa các lần gọi.
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

  /// Backend có nhận chỉ số này không — dùng để làm mờ ô chọn thay vì để
  /// người dùng chọn rồi mới báo lỗi lúc lưu.
  static bool isMetricSupportedByBackend(MetricType metricType) {
    return filterMetricTypesForBackend([metricType.value]).isNotEmpty;
  }
}
