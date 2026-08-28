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

/// Màn đăng ký (route `/signup`).
///
/// Sau khi đăng ký thành công, đích đến phụ thuộc cờ
/// [AuthFormState.needsVerification] do BE quyết định: có thì sang `/otp`,
/// không thì về `/login`.
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
            // Ưu tiên verificationEmail (email BE thực sự gửi OTP tới, có thể
            // đã được chuẩn hoá), chỉ fallback về email người dùng gõ.
            final emailToVerify = state.verificationEmail.isNotEmpty ? state.verificationEmail : state.email;
            context.go('/otp', extra: {'email': emailToVerify, 'flow': 'signup'});
          } else {
            context.go('/login');
          }
        }
      },
      child: const AuthFormLayout(child: SignUpForm()),
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
