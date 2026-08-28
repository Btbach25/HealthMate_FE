import 'package:fe/core/config/app_config.dart';
import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/constants/app_styles.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/utils/toast_utils.dart';
import 'package:fe/core/widgets/demo_mode_banner.dart';
import 'package:fe/data/mock_data/mock_users.dart';
import 'package:fe/data/repositories/auth_repository.dart';
import 'package:fe/presentation/auth/bloc/auth_form_bloc.dart';
import 'package:fe/presentation/auth/widgets/auth_logo_header.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// Conditional import: bản `_impl` dùng dart:js_interop nên chỉ compile được
// trên Web; mobile lấy bản `_stub` trả về widget rỗng.
import 'package:fe/presentation/auth/view/google_web_button_stub.dart'
    if (dart.library.html) 'package:fe/presentation/auth/view/google_web_button_impl.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (context) {
          final bloc = AuthFormBloc(
            authRepository: RepositoryProvider.of<AuthRepository>(context),
          );
          // Chế độ DEMO: điền sẵn tài khoản mẫu để bấm "Đăng nhập" là vào luôn.
          if (AppConfig.isDemoMode) {
            bloc
              ..add(EmailChanged(MockUsers.demoEmail))
              ..add(PasswordChanged(MockUsers.demoPassword));
          }
          return bloc;
        },
        child: const LoginView(),
      ),
    );
  }
}

class LoginView extends StatelessWidget {
  const LoginView({super.key});

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
        if (state.status == FormStatus.success && state.needsVerification) {
          ToastUtils.showCustomToast(
            context,
            state.successMessage.isNotEmpty ? state.successMessage : 'Đã gửi OTP, vui lòng kiểm tra email',
            ToastType.success,
          );
          final emailToVerify = state.verificationEmail.isNotEmpty ? state.verificationEmail : state.email;
          context.go('/otp', extra: {'email': emailToVerify, 'flow': 'login'});
        }
      },
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthLogoHeader(),
              // Chỉ hiện khi DEMO_MODE=true, ngoài ra là SizedBox.shrink().
              const DemoModeBanner(),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSize.p24,
                  0,
                  AppSize.p24,
                  AppSize.p32,
                ),
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
                  child: const LoginForm(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginForm extends StatelessWidget {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Đăng nhập',
          style: AppStyles.h1,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSize.p8),
        const Text(
          'Truy cập vào ứng dụng HealthMate',
          style: AppStyles.bodyLg,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSize.p32),
        const Text('Email', style: AppStyles.bodyBold),
        const SizedBox(height: AppSize.p8),
        _EmailInput(),
        const SizedBox(height: AppSize.p16),
        const Text('Mật khẩu', style: AppStyles.bodyBold),
        const SizedBox(height: AppSize.p8),
        _PasswordInput(),
        const SizedBox(height: AppSize.p8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.go('/forgot-password'),
            child: const Text('Quên mật khẩu?'),
          ),
        ),
        const SizedBox(height: AppSize.p16),
        _LoginButton(),
        const SizedBox(height: AppSize.p24),
        _OrDivider(),
        const SizedBox(height: AppSize.p24),
        _GoogleLoginButton(),
        const SizedBox(height: AppSize.p32),
        _SignUpPrompt(),
      ],
    );
  }
}

class _EmailInput extends StatefulWidget {
  @override
  State<_EmailInput> createState() => _EmailInputState();
}

class _EmailInputState extends State<_EmailInput> {
  // Chế độ DEMO điền sẵn email mẫu (bloc đã được prefill tương ứng ở LoginPage).
  late final TextEditingController _controller = TextEditingController(
    text: AppConfig.isDemoMode ? MockUsers.demoEmail : '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: (email) =>
          context.read<AuthFormBloc>().add(EmailChanged(email)),
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        hintText: 'Nhập email của bạn',
        prefixIcon: Icon(Icons.email_outlined),
      ),
    );
  }
}

class _PasswordInput extends StatefulWidget {
  @override
  State<_PasswordInput> createState() => _PasswordInputState();
}

class _PasswordInputState extends State<_PasswordInput> {
  bool _isObscured = true;

  // Chế độ DEMO điền sẵn mật khẩu mẫu (bloc đã được prefill ở LoginPage).
  late final TextEditingController _controller = TextEditingController(
    text: AppConfig.isDemoMode ? MockUsers.demoPassword : '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: (password) =>
          context.read<AuthFormBloc>().add(PasswordChanged(password)),
      obscureText: _isObscured,
      decoration: InputDecoration(
        hintText: 'Nhập mật khẩu',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _isObscured
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
          onPressed: () {
            setState(() {
              _isObscured = !_isObscured;
            });
          },
        ),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthFormBloc, AuthFormState>(
      // buildWhen: (previous, current) => previous.status != current.status,
      builder: (context, state) {
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: AppSize.p16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSize.r12),
            ),
          ),
          onPressed:
              (state.isValidLogin && state.status != FormStatus.inProgress)
              ? () => context.read<AuthFormBloc>().add(LoginSubmitted())
              : null,
          child: state.status == FormStatus.inProgress
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : const Text('Đăng nhập', style: AppStyles.button),
        );
      },
    );
  }
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text('HOẶC', style: TextStyle(color: Colors.grey.shade500)),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _GoogleLoginButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Web: dùng renderButton để kích hoạt GIS credential flow → có id_token
    if (kIsWeb) return const Center(child: GoogleWebButton());

    return OutlinedButton.icon(
      icon: Image.asset('assets/icons/google_logo.png', height: 20),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      onPressed: () => context.read<AuthFormBloc>().add(GoogleLoginSubmitted()),
      label: const Text(
        'Đăng nhập với Google',
        style: TextStyle(fontSize: 16, color: Colors.black87),
      ),
    );
  }
}

class _SignUpPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Chưa có tài khoản? '),
        TextButton(
          onPressed: () => context.go('/signup'),
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          child: const Text('Đăng ký ngay', style: AppStyles.link),
        ),
      ],
    );
  }
}
