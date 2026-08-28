import 'package:fe/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Hai khuôn xử lý lặp đi lặp lại ở các tab Cài đặt: tải cài đặt và lưu cài
/// đặt, kèm sẵn `try/catch`, kiểm tra `context.mounted` và SnackBar báo kết quả.
///
/// Có helper này để không tab nào quên bước `if (context.mounted)` sau `await`
/// — bỏ sót là app ném lỗi khi người dùng rời màn hình giữa lúc đang gọi API.
class SettingsManagementHelper {
  /// Tải cài đặt, tự báo lỗi bằng SnackBar nếu hỏng.
  ///
  /// [onSuccess] chỉ chạy khi widget còn gắn trên cây; [onError] là chỗ tắt
  /// cờ loading của màn hình.
  ///
  /// ```dart
  /// SettingsManagementHelper.loadSettingsWithErrorHandling<UserSettings>(
  ///   context: context,
  ///   loadFunction: () => repo.fetchSettings(),
  ///   onSuccess: (s) => setState(() => _settings = s),
  ///   onError: () => setState(() => _isLoading = false),
  /// );
  /// ```
  static Future<void> loadSettingsWithErrorHandling<T>({
    required BuildContext context,
    required Future<T> Function() loadFunction,
    required void Function(T) onSuccess,
    required void Function() onError,
    String? errorMessage,
  }) async {
    try {
      final settings = await loadFunction();
      if (context.mounted) {
        onSuccess(settings);
      }
    } catch (e) {
      if (context.mounted) {
        onError();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage ?? 'Lỗi khi tải cài đặt: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Lưu cài đặt theo kiểu **optimistic**: đổi giao diện trước, gọi API sau,
  /// hỏng thì trả về giá trị cũ.
  ///
  /// Nhờ vậy công tắc trong Cài đặt phản hồi tức thì thay vì đứng chờ mạng.
  /// Cái giá phải trả: giao diện có thể nháy về trạng thái cũ khi API lỗi —
  /// chỉ dùng cho thao tác nhanh, dễ hoàn tác (bật/tắt, đổi lựa chọn), đừng
  /// dùng cho thao tác phá huỷ.
  ///
  /// [update] phải trả về **bản sao đã sửa** (`copyWith`), không được sửa
  /// tại chỗ đối tượng cũ — sửa tại chỗ thì [onRevert] không còn gì để khôi
  /// phục.
  ///
  /// ```dart
  /// SettingsManagementHelper.updateSettingWithErrorHandling<UserSettings>(
  ///   context: context,
  ///   currentSettings: _settings,
  ///   update: (s) => s.copyWith(reminderEnabled: value),
  ///   saveFunction: repo.saveSettings,
  ///   onUpdate: (s) => setState(() => _settings = s),
  ///   onRevert: (s) => setState(() => _settings = s),
  /// );
  /// ```
  static Future<void> updateSettingWithErrorHandling<T extends Object>({
    required BuildContext context,
    required T currentSettings,
    required T Function(T) update,
    required Future<void> Function(T) saveFunction,
    required void Function(T) onUpdate,
    required void Function(T) onRevert,
    String? successMessage,
    String? errorMessage,
  }) async {
    final previousSettings = currentSettings;
    final updatedSettings = update(currentSettings);

    onUpdate(updatedSettings);

    try {
      await saveFunction(updatedSettings);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage ?? 'Đã cập nhật cài đặt'),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        onRevert(previousSettings);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage ?? 'Lỗi khi lưu cài đặt: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Vòng quay chờ căn giữa cho các tab Cài đặt.
  ///
  /// Cần kèm thông điệp hoặc chiếm cả màn thì dùng `LoadingWidget` thay vì
  /// hàm này.
  static Widget buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}
