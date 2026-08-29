import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/data/models/group/family_member.dart';
import 'package:flutter/material.dart';

/// Ánh xạ [HealthStatus] sang nhãn tiếng Việt, màu chữ và màu nền để hiển thị
/// trạng thái sức khoẻ của thành viên trong nhóm.
extension HealthStatusExtension on HealthStatus {
  /// Nhãn hiển thị cho người dùng.
  String get displayLabel {
    switch (this) {
      case HealthStatus.good:
        return 'Tốt';
      case HealthStatus.needsAttention:
        return 'Cần chú ý';
      case HealthStatus.healthy:
        return 'Khỏe mạnh';
    }
  }

  /// Returns the color for the health status
  Color get color {
    switch (this) {
      case HealthStatus.good:
        return AppColors.primary;
      case HealthStatus.needsAttention:
        return Colors.orange;
      case HealthStatus.healthy:
        return AppColors.primary;
    }
  }

  /// Returns the background color for the health status
  Color get backgroundColor {
    switch (this) {
      case HealthStatus.good:
        return AppColors.tagImportantBg;
      case HealthStatus.needsAttention:
        return AppColors.tagWarningBg;
      case HealthStatus.healthy:
        return AppColors.tagImportantBg;
    }
  }
}

