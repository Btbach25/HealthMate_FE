import 'package:fe/core/theme/app_icons.dart';
import 'package:fe/data/enums/metric_type.dart';
import 'package:fe/data/models/ui/metric_option.dart';
import 'package:flutter/material.dart';

/// Danh mục chỉ số sức khoẻ hiển thị được, kèm nhãn tiếng Việt và icon.
///
/// Đây là NGUỒN SỰ THẬT DUY NHẤT cho phần hiển thị chỉ số. Cần dựng danh sách
/// chọn chỉ số ở bất kỳ đâu (dialog chia sẻ, form quyền nhóm) thì đọc
/// [availableMetrics] chứ đừng khai báo lại nhãn/icon tại chỗ.
///
/// ```dart
/// _selectableMetrics = MetricHelper.availableMetrics
///     .where((m) => MetricSelectionHelper.isMetricSupportedByBackend(m.type))
///     .toList();
/// ```
///
/// Lưu ý: danh sách này là những gì FE **vẽ được**, không phải những gì
/// backend **nhận được** — hai tập đó khác nhau. Trước khi gửi lên server
/// phải lọc qua `MetricSelectionHelper.filterMetricTypesForBackend`.
class MetricHelper {
  /// Toàn bộ chỉ số FE hiển thị được, theo thứ tự dùng để vẽ danh sách.
  ///
  /// Thêm chỉ số mới thì phải sửa cả ba nơi: `MetricType`, danh sách này, và
  /// `MetricSelectionHelper._backendSupportedMetricTypes` (nếu backend đã hỗ
  /// trợ). Thiếu bước cuối, chỉ số hiện lên nhưng lưu sẽ thất bại.
  static const List<MetricOption> availableMetrics = [
    MetricOption(
      type: MetricType.heartRate,
      label: 'Nhịp tim',
      icon: AppIcons.heart,
    ),
    MetricOption(
      type: MetricType.bloodPressure,
      label: 'Huyết áp',
      icon: AppIcons.bloodPressure,
    ),
    MetricOption(
      type: MetricType.spo2,
      label: 'SpO2',
      icon: AppIcons.spo2,
    ),
    MetricOption(
      type: MetricType.weight,
      label: 'Cân nặng',
      icon: AppIcons.weight,
    ),
    MetricOption(
      type: MetricType.temperature,
      label: 'Nhiệt độ',
      icon: AppIcons.temperature,
    ),
    MetricOption(
      type: MetricType.sleep,
      label: 'Giấc ngủ',
      icon: AppIcons.sleep,
    ),
    MetricOption(
      type: MetricType.stepsCount,
      label: 'Số bước chân',
      icon: AppIcons.steps,
    ),
    MetricOption(
      type: MetricType.caloriesBurnt,
      label: 'Lượng calo',
      icon: Icons.local_fire_department_outlined,
    ),
  ];

  /// Tra cứu nhãn + icon của một [MetricType].
  ///
  /// NÉM `ArgumentError` nếu [type] chưa có trong [availableMetrics] — cố ý
  /// để lỗi lộ ra ngay khi thêm enum mới mà quên khai báo, thay vì âm thầm
  /// vẽ ra ô trống.
  static MetricOption getMetricOption(MetricType type) {
    return availableMetrics.firstWhere(
      (m) => m.type == type,
      orElse: () => throw ArgumentError('Metric type not found: $type'),
    );
  }
}
