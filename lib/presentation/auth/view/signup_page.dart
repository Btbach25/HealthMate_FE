import 'package:fe/core/constants/app_styles.dart';
import 'package:fe/presentation/auth/widgets/confirm_password_input.dart';
import 'package:fe/presentation/auth/widgets/password_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_size.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../data/repositories/auth_repository.dart';
import '../bloc/auth_form_bloc.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (context) => AuthFormBloc(
          authRepository: RepositoryProvider.of<AuthRepository>(context),
        ),
        child: const SignUpView(),
      ),
    );
  }
}

class SignUpView extends StatelessWidget {
  const SignUpView({super.key});

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
          if (state.needsVerification) {
            final emailToVerify = state.verificationEmail.isNotEmpty ? state.verificationEmail : state.email;
            context.go('/otp', extra: {'email': emailToVerify, 'flow': 'signup'});
          } else {
            context.go('/login');
          }
        }
      },
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSize.p24, 0, AppSize.p24, AppSize.p32),
                child: Container(
                  padding: const EdgeInsets.all(AppSize.p24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSize.r12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        spreadRadius: 5,
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: const SignUpForm(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignUpForm extends StatelessWidget {
  const SignUpForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Đăng ký tài khoản', style: AppStyles.h1, textAlign: TextAlign.center),
        const SizedBox(height: AppSize.p8),
        const Text(
          'Tạo tài khoản HealthMate để chăm sóc sức khỏe gia đình',
          style: AppStyles.bodyLg,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSize.p32),
        const Text('Họ tên', style: AppStyles.bodyBold),
        const SizedBox(height: AppSize.p8),
        _NameInput(),
        const SizedBox(height: AppSize.p16),
        const Text('Email', style: AppStyles.bodyBold),
        const SizedBox(height: AppSize.p8),
        _EmailInput(),
        const SizedBox(height: AppSize.p16),
        const Text('Mật khẩu', style: AppStyles.bodyBold),
        const SizedBox(height: AppSize.p8),
        PasswordInput(),
        const SizedBox(height: AppSize.p16),
        const Text('Xác nhận mật khẩu', style: AppStyles.bodyBold),
        const SizedBox(height: AppSize.p8),
        ConfirmPasswordInput(),
        const SizedBox(height: AppSize.p24),
        _SignUpButton(),
        const SizedBox(height: AppSize.p16),
        _LoginPrompt(),
        const SizedBox(height: AppSize.p16),
        const Text(
          'Bằng việc đăng ký, bạn đồng ý với các điều khoản sử dụng của chúng tôi. OTP chỉ được thử sai tối đa 5 lần, nếu vượt quá sẽ bị khóa 30 phút.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.textGrey),
        ),
      ],
    );
  }
}

class _NameInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthFormBloc, AuthFormState>(
      buildWhen: (previous, current) => previous.name != current.name,
      builder: (context, state) {
        return TextField(
          onChanged: (name) => context.read<AuthFormBloc>().add(NameChanged(name)),
          decoration: const InputDecoration(
            hintText: 'Nhập họ tên của bạn',
            prefixIcon: Icon(Icons.person_outline),
          ),
        );
      },
    );
  }
}

class _EmailInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthFormBloc, AuthFormState>(
      buildWhen: (previous, current) => previous.email != current.email,
      builder: (context, state) {
        return TextField(
          onChanged: (email) => context.read<AuthFormBloc>().add(EmailChanged(email)),
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'Nhập email của bạn',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        );
      },
    );
  }
}

class _SignUpButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthFormBloc, AuthFormState>(
      buildWhen: (previous, current) => previous.status != current.status || previous.isValidSignUp != current.isValidSignUp,
      builder: (context, state) {
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: AppSize.p16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSize.r12),
            ),
          ),
          onPressed: state.status == FormStatus.inProgress || !state.isValidSignUp
              ? null
              : () => context.read<AuthFormBloc>().add(SignUpSubmitted()),
          child: state.status == FormStatus.inProgress
              ? const SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                )
              : const Text('Đăng ký', style: AppStyles.button),
        );
      },
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Đã có tài khoản? '),
        TextButton(
          onPressed: () => context.go('/login'),
          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
          child: const Text('Đăng nhập ngay', style: AppStyles.link),
        ),
      ],
    );
  }
}

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSize.p32),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppSize.r12 * 2)),
      ),
      child: Column(
        children: [
          Image.asset('assets/icons/app_logo.png', height: 60),
          const SizedBox(height: AppSize.p16),
          const Text('HealthMate', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: AppSize.p8),
          const Text('Ứng dụng chăm sóc sức khỏe cho cả gia đình', style: TextStyle(fontSize: 14, color: Colors.white70)),
        ],
      ),
    );
  }
}