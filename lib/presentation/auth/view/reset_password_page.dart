import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/constants/app_styles.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/utils/toast_utils.dart';
import 'package:fe/data/repositories/auth_repository.dart';
import 'package:fe/presentation/auth/bloc/auth_form_bloc.dart';
import 'package:fe/presentation/auth/widgets/auth_form_layout.dart';
import 'package:fe/presentation/auth/widgets/confirm_password_input.dart';
import 'package:fe/presentation/auth/widgets/password_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Màn đặt mật khẩu mới (route `/reset-password`) — bước cuối của luồng quên
/// mật khẩu.
///
/// Điều kiện tiên quyết: người dùng vừa xác thực OTP thành công, vì
/// `AuthRepository.resetPassword` dựa vào token tạm được lưu ở bước đó. Vào
/// thẳng route này mà chưa qua OTP sẽ nhận lỗi từ BE.
class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (context) => AuthFormBloc(
          authRepository: RepositoryProvider.of<AuthRepository>(context),
        ),
        child: const ResetPasswordView(),
      ),
    );
  }
}

class ResetPasswordView extends StatelessWidget {
  const ResetPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthFormBloc, AuthFormState>(
      listener: (context, state) {
        if (!context.mounted) return;
        if (state.status == FormStatus.failure) {
          ToastUtils.showCustomToast(
            context,
            state.errorMessage,
            ToastType.error,
          );
        }
        if (state.status == FormStatus.success) {
          ToastUtils.showCustomToast(
            context,
            state.successMessage,
            ToastType.success,
          );
          // Dùng go() chứ không pop(): đổi mật khẩu xong phải đăng nhập lại,
          // và stack phía sau (OTP, quên mật khẩu) không còn ý nghĩa.
          context.go('/login');
        }
      },
      child: const AuthFormLayout(child: ResetPasswordForm()),
    );
  }
}

class ResetPasswordForm extends StatelessWidget {
  const ResetPasswordForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Tạo mật khẩu mới',
          style: AppStyles.h1,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSize.p8),
        const Text(
          'Mật khẩu mới của bạn phải khác với mật khẩu đã sử dụng trước đây.',
          style: AppStyles.bodyLg,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSize.p32),
        const Text('Mật khẩu', style: AppStyles.bodyBold),
        const SizedBox(height: AppSize.p8),
        PasswordInput(),
        const SizedBox(height: AppSize.p16),
        const Text('Xác nhận mật khẩu', style: AppStyles.bodyBold),
        const SizedBox(height: AppSize.p8),
        ConfirmPasswordInput(),
        const SizedBox(height: AppSize.p24),
        _SubmitButton(),
      ],
    );
  }
}

class _SubmitButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthFormBloc, AuthFormState>(
      buildWhen: (previous, current) => previous.status != current.status,
      builder: (context, state) {
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: AppSize.p16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSize.r12),
            ),
          ),
          // Không chặn theo validate client: AuthFormBloc tự kiểm tra khớp mật
          // khẩu và độ dài rồi hiện toast lỗi, để người dùng biết vì sao sai.
          onPressed: state.status == FormStatus.inProgress
              ? null
              : () =>
                    context.read<AuthFormBloc>().add(ResetPasswordSubmitted()),
          child: state.status == FormStatus.inProgress
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : const Text('Lưu mật khẩu', style: AppStyles.button),
        );
      },
    );
  }
}
