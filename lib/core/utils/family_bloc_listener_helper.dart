import 'package:fe/core/utils/error_message_parser.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/presentation/family/bloc/family_bloc.dart';
import 'package:flutter/material.dart';

/// Helper class for common FamilyBloc listener patterns
/// Reduces code duplication across family widgets
class FamilyBlocListenerHelper {
  /// Creates a listener callback for success/error handling in dialogs
  /// 
  /// [onSuccess] - Called when successStatus is reached
  /// [onError] - Called when error occurs (optional, defaults to showing inline message)
  /// [setLoading] - Callback to set loading state
  /// [showInlineMessage] - Callback to show inline message (from InlineMessageMixin)
  /// [successStatus] - The status that indicates success
  /// [successMessage] - Message to show in snackbar on success
  /// [shouldPop] - Whether to pop the dialog on success (default: true)
  static void Function(BuildContext, FamilyState) createDialogListener({
    required void Function() setLoading,
    required void Function(String, {Color? backgroundColor, Duration? duration}) showInlineMessage,
    required FamilyStatus successStatus,
    String? successMessage,
    bool shouldPop = true,
    VoidCallback? onSuccess,
    VoidCallback? onError,
  }) {
    return (context, state) {
      if (state.status == successStatus) {
        setLoading();
        if (shouldPop) {
          Navigator.pop(context);
        }
        if (successMessage != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMessage),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        onSuccess?.call();
      }
      if (state.status == FamilyStatus.error) {
        setLoading();
        showInlineMessage(
          ErrorMessageParser.parse(state.errorMessage),
          backgroundColor: AppColors.error,
        );
        onError?.call();
      }
    };
  }

  /// Creates a listener callback for form submissions
  /// Similar to createDialogListener but without pop
  static void Function(BuildContext, FamilyState) createFormListener({
    required void Function() setLoading,
    required void Function(String, {Color? backgroundColor, Duration? duration}) showInlineMessage,
    required FamilyStatus successStatus,
    String? successMessage,
    VoidCallback? onSuccess,
    VoidCallback? onError,
  }) {
    return createDialogListener(
      setLoading: setLoading,
      showInlineMessage: showInlineMessage,
      successStatus: successStatus,
      successMessage: successMessage,
      shouldPop: false,
      onSuccess: onSuccess,
      onError: onError,
    );
  }
}

