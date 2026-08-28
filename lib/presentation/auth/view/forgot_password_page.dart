import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/constants/app_styles.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/utils/toast_utils.dart';
import 'package:fe/data/repositories/auth_repository.dart';
import 'package:fe/presentation/auth/bloc/auth_form_bloc.dart';
import 'package:fe/presentation/auth/widgets/auth_form_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Màn "Quên mật khẩu" (route `/forgot-password`): nhập email để nhận mã OTP.
///
/// Bước 1 của luồng khôi phục mật khẩu: /forgot-password -> /otp ->
/// /reset-password.
class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (context) => AuthFormBloc(
          authRepository: RepositoryProvider.of<AuthRepository>(context),
        ),
        child: const ForgotPasswordView(),
      ),
    );
  }
}

class ForgotPasswordView extends StatelessWidget {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthFormBloc, AuthFormState>(
      listener: (context, state) {
        if (!context.mounted) return;
        if (state.status == FormStatus.failure) {
          ToastUtils.showCustomToast(context, state.errorMessage, ToastType.error);
        }
        if (state.status == FormStatus.success) {
          ToastUtils.showCustomToast(context, state.successMessage, ToastType.success);
          // Route /otp đọc `extra` dạng Map { email, flow }. Bắt buộc truyền
          // flow 'forgot', nếu không router mặc định về OtpFlow.login và người
          // dùng bị đưa về trang chủ thay vì /reset-password sau khi xác thực.
          context.go('/otp', extra: {'email': state.email, 'flow': 'forgot'});
        }
      },
      child: const AuthFormLayout(child: ForgotPasswordForm()),
    );
  }
}

class ForgotPasswordForm extends StatelessWidget {
  const ForgotPasswordForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Quên mật khẩu', style: AppStyles.h1, textAlign: TextAlign.center),
        const SizedBox(height: AppSize.p8),
        const Text(
          'Nhập email để nhận mã khôi phục mật khẩu',
          style: AppStyles.bodyLg,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSize.p32),
        const Text('Email', style: AppStyles.bodyBold),
        const SizedBox(height: AppSize.p8),
        _EmailInput(),
        const SizedBox(height: AppSize.p24),
        _SubmitButton(),
        const SizedBox(height: AppSize.p16),
        _BackToLoginLink(),
      ],
    );
  }
}

class _EmailInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: (email) => context.read<AuthFormBloc>().add(EmailChanged(email)),
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        hintText: 'Nhập email của bạn',
        prefixIcon: Icon(Icons.email_outlined),
      ),
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
          onPressed: state.status == FormStatus.inProgress
              ? null
              : () => context.read<AuthFormBloc>().add(ForgotPasswordSubmitted()),
          child: state.status == FormStatus.inProgress
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                )
              : const Text('Gửi mã khôi phục', style: AppStyles.button),
        );
      },
    );
  }
}

class _BackToLoginLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => context.go('/login'),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.arrow_back, size: 16),
          SizedBox(width: AppSize.p4),
          Text('Quay lại đăng nhập'),
        ],
      ),
    );
  }
}
