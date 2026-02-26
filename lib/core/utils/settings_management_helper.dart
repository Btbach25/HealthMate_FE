import 'package:fe/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Helper class for settings management
/// Provides reusable methods for loading and updating settings
/// Reduces code duplication across settings tabs
class SettingsManagementHelper {
  /// Loads settings with error handling
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

  /// Updates settings with optimistic update and error handling
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

    // Optimistic update
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
        // Revert on error
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

  /// Builds loading indicator widget
  static Widget buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

