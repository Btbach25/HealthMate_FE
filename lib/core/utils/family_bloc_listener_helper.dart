import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/utils/user_facing_error.dart';
import 'package:fe/presentation/family/bloc/family_bloc.dart';
import 'package:flutter/material.dart';

/// Sinh sẵn callback `listener` cho `BlocListener<FamilyBloc, FamilyState>`.
///
/// Các dialog/form của tab Gia đình đều lặp cùng một kịch bản: thành công thì
/// tắt loading → đóng dialog → báo thành công; lỗi thì tắt loading → hiện
/// thông báo lỗi ngay trong dialog. Helper này giữ kịch bản đó ở một chỗ.
///
/// Dùng kèm `InlineMessageMixin` (truyền `showInlineMessage` của mixin vào)
/// vì `SnackBar` bị dialog che khuất.
///
/// ```dart
/// BlocListener<FamilyBloc, FamilyState>(
///   listener: FamilyBlocListenerHelper.createDialogListener(
///     setLoading: () => setState(() => _isLoading = false),
///     showInlineMessage: showInlineMessage,
///     successStatus: FamilyStatus.groupCreated,
///     successMessage: 'Đã tạo nhóm',
///   ),
///   child: ...,
/// )
/// ```
class FamilyBlocListenerHelper {
  /// Listener cho dialog: xong việc thì tự đóng dialog.
  ///
  /// - [setLoading] được gọi ở CẢ hai nhánh thành công và lỗi — đây là chỗ
  ///   tắt cờ loading, không phải chỗ bật.
  /// - [successMessage] hiện bằng `SnackBar`, nên chỉ dùng khi [shouldPop] là
  ///   `true`; dialog đã đóng thì SnackBar mới nhìn thấy được.
  /// - Lỗi luôn đi qua `UserFacingError` để không lộ thuật ngữ kỹ thuật.
  /// - [shouldPop] = false khi form nằm thẳng trong trang (xem
  ///   [createFormListener]).
  static void Function(BuildContext, FamilyState) createDialogListener({
    required void Function() setLoading,
    required void Function(String, {Color? backgroundColor, Duration? duration})
    showInlineMessage,
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
          UserFacingError.message(state.errorMessage),
          backgroundColor: AppColors.error,
        );
        onError?.call();
      }
    };
  }

  /// Như [createDialogListener] nhưng KHÔNG đóng route khi thành công.
  ///
  /// Dùng cho form nằm thẳng trong trang (không phải dialog): pop ở đó sẽ đẩy
  /// người dùng ra khỏi cả màn hình.
  static void Function(BuildContext, FamilyState) createFormListener({
    required void Function() setLoading,
    required void Function(String, {Color? backgroundColor, Duration? duration})
    showInlineMessage,
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
