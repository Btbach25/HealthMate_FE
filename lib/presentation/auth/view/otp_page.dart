import 'package:fe/core/constants/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

import '../../../core/constants/app_size.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../data/repositories/auth_repository.dart';
import '../bloc/auth_form_bloc.dart';

class OtpPage extends StatelessWidget {
  const OtpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (context) => AuthFormBloc(
          authRepository: RepositoryProvider.of<AuthRepository>(context),
        ),
        child: const OtpView(),
      ),
    );
  }
}

class OtpView extends StatelessWidget {
  const OtpView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthFormBloc, AuthFormState>(
      listener: (context, state) {
        if (state.status == FormStatus.failure) {
          ToastUtils.showCustomToast(context, state.errorMessage, ToastType.error);
        }
        if (state.status == FormStatus.success) {
          ToastUtils.showCustomToast(context, 'Xác thực thành công. Vui lòng đăng nhập.', ToastType.success);
          context.go('/reset-password');
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
              // const AppHeader(),
              // const SizedBox(height: AppSize.p32),
              // Form Card
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSize.p24, 0, AppSize.p24, AppSize.p32),
                child: Container(
                  padding: const EdgeInsets.all(AppSize.p24),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppSize.r12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 5,
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: const OtpForm(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OtpForm extends StatelessWidget {
  const OtpForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.lock_open_outlined, size: 48, color: AppColors.primary.withOpacity(0.5)),
        const SizedBox(height: AppSize.p16),
        const Text('Xác thực OTP', style: AppStyles.h1, textAlign: TextAlign.center),
        const SizedBox(height: AppSize.p8),
        const Text(
          'Nhập mã OTP đã được gửi đến email của bạn',
          style: AppStyles.bodyLg,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSize.p32),
        const Text('Mã OTP', style: AppStyles.bodyBold),
        const SizedBox(height: AppSize.p8),
        _OtpInput(),
        const SizedBox(height: AppSize.p12),
        
        BlocBuilder<AuthFormBloc, AuthFormState>(
          buildWhen: (previous, current) => previous.email != current.email,
          builder: (context, state) {
            return Text(
              'Mã OTP đã được gửi đến:\n${state.email}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textGrey, height: 1.5),
            );
          },
        ),

        const SizedBox(height: AppSize.p24),
        _SubmitButton(),
        const SizedBox(height: AppSize.p16),
        _ChangeEmailButton(),
        const SizedBox(height: AppSize.p8),
        _BackToLoginLink(),
      ],
    );
  }
}

class _OtpInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 55,
      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(AppSize.r12),
        border: Border.all(color: Colors.transparent),
      ),
    );

    return Pinput(
      length: 6,
      defaultPinTheme: defaultPinTheme,
      
      focusedPinTheme: defaultPinTheme.copyWith(
        decoration: defaultPinTheme.decoration!.copyWith(
          border: Border.all(color: AppColors.primary),
        ),
      ),
      
      submittedPinTheme: defaultPinTheme,

      autofocus: true,
      showCursor: true,

      onChanged: (value) {
        context.read<AuthFormBloc>().add(OtpChanged(value));
      },
      // có thể dùng onCompleted nếu chỉ muốn gửi khi đã nhập đủ 6 số
      // onCompleted: (pin) {
      //   context.read<AuthFormBloc>().add(OtpChanged(pin));
      // },
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
              : () => context.read<AuthFormBloc>().add(OtpSubmitted()),
          child: state.status == FormStatus.inProgress
              ? const SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                )
              : const Text('Xác thực', style: AppStyles.button),
        );
      },
    );
  }
}

class _ChangeEmailButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: AppSize.p16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSize.r12),
        ),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      onPressed: () => context.pop(),
      child: const Text('Thay đổi email', style: TextStyle(fontSize: 16, color: Colors.black87)),
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