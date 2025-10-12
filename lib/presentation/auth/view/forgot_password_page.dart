import 'package:fe/core/constants/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_size.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../data/repositories/auth_repository.dart';
import '../bloc/auth_form_bloc.dart';
import 'signup_page.dart';

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
        if (state.status == FormStatus.failure) {
          ToastUtils.showCustomToast(context, state.errorMessage, ToastType.error);
        }
        if (state.status == FormStatus.success) {
          // Hiển thị toast thành công và điều hướng đến trang OTP
          ToastUtils.showCustomToast(context, state.successMessage, ToastType.success);
          context.go('/otp');
        }
      },
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            // horizontal: AppSize.p24, 
            // vertical: AppSize.p32
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppHeader(),
              const SizedBox(height: AppSize.p32),
              // Form Card
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSize.p24, 0, AppSize.p24, AppSize.p32),
                child: Container(
                  padding: const EdgeInsets.all(AppSize.p24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSize.r12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 5,
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: const ForgotPasswordForm(),
                ),
              ),
            ],
          ),
        ),
      ),
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
        // Icon chìa khóa
        Icon(Icons.vpn_key_outlined, size: 48, color: AppColors.primary.withOpacity(0.5)),
        const SizedBox(height: AppSize.p16),
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