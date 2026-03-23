// lib/presentation/auth/view/reset_password_page.dart
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
          ToastUtils.showCustomToast(context, state.errorMessage, ToastType.error);
        }
        if (state.status == FormStatus.success) {
          ToastUtils.showCustomToast(context, state.successMessage, ToastType.success);
          // Sau khi đổi mật khẩu thành công, quay về trang đăng nhập
          context.go('/login');
        }
      },
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            // horizontal: AppSize.p24, 
            // vertical: AppSize.p32
          ),
          child: Column(
            children: [
              // const AppHeader(),
              // const SizedBox(height: AppSize.p32),
              Container(
                padding: const EdgeInsets.all(AppSize.p24),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSize.r12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          spreadRadius: 5,
                          blurRadius: 20)
                    ]),
                child: const ResetPasswordForm(),
              ),
            ],
          ),
        ),
      ),
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
        const Text('Tạo mật khẩu mới', style: AppStyles.h1, textAlign: TextAlign.center),
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
          onPressed: state.status == FormStatus.inProgress
              ? null
              : () => context.read<AuthFormBloc>().add(ResetPasswordSubmitted()),
          child: state.status == FormStatus.inProgress
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                )
              : const Text('Lưu mật khẩu', style: AppStyles.button),
        );
      },
    );
  }
}

// LƯU Ý: Để tái sử dụng _PasswordInput và _ConfirmPasswordInput,
// bạn có thể cần tách chúng ra khỏi file signup_page.dart và đặt vào
// một thư mục widgets chung trong presentation/auth/widgets/
// Sau đó import chúng vào cả 2 file. Hiện tại, để đơn giản,
// ta có thể import trực tiếp từ signup_page.