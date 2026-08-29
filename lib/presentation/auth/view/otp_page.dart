import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/constants/app_styles.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/utils/toast_utils.dart';
import 'package:fe/data/repositories/auth_repository.dart';
import 'package:fe/presentation/auth/bloc/auth_form_bloc.dart';
import 'package:fe/presentation/auth/widgets/auth_form_layout.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

/// Luồng nào dẫn tới màn OTP — quyết định điều hướng SAU KHI xác thực thành
/// công, chứ không đổi giao diện.
///
/// - [login] / [signup]: verify xong BE đã cấp token nên vào thẳng `/`.
/// - [forgot]: verify xong mới sang `/reset-password` để đặt mật khẩu mới.
///
/// Giá trị này đi kèm email trong `GoRouter.extra` dạng
/// `{ 'email': String, 'flow': String }`.
enum OtpFlow { login, signup, forgot }

/// Màn nhập OTP 6 số (route `/otp`).
///
/// [email] bắt buộc và được nạp ngay vào bloc bằng [AuthFormInitialized]: mỗi
/// màn auth có [AuthFormBloc] riêng, nếu không nạp thì state.email rỗng và mọi
/// lần submit đều fail.
class OtpPage extends StatelessWidget {
  final String email;
  final OtpFlow flow;

  const OtpPage({super.key, required this.email, required this.flow});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (context) => AuthFormBloc(
          authRepository: RepositoryProvider.of<AuthRepository>(context),
        )..add(AuthFormInitialized(email: email)),
        child: OtpView(flow: flow),
      ),
    );
  }
}

class OtpView extends StatelessWidget {
  final OtpFlow flow;
  const OtpView({super.key, required this.flow});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthFormBloc, AuthFormState>(
      listener: (context, state) {
        if (!context.mounted) return;
        if (state.status == FormStatus.failure) {
          ToastUtils.showCustomToast(context, state.errorMessage, ToastType.error);
        }
        // Chỉ OtpSubmitted mới emit success. OtpResendRequested cố ý không emit
        // success, nếu không người dùng sẽ bị điều hướng đi ngay khi vừa bấm
        // "Gửi lại".
        if (state.status == FormStatus.success) {
          ToastUtils.showCustomToast(context, 'Xác thực thành công!', ToastType.success);
          if (flow == OtpFlow.forgot) {
            context.go('/reset-password');
          } else {
            // Login/signup: BE đã lưu token khi verify nên vào thẳng trang chủ.
            context.go('/');
          }
        }
      },
      child: const AuthFormLayout(
        cardColor: AppColors.background,
        child: OtpForm(),
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
        BlocBuilder<AuthFormBloc, AuthFormState>(
          buildWhen: (previous, current) => previous.email != current.email,
          // ValueKey theo email: khi email đổi (người dùng quay lại đổi email),
          // widget bị dựng mới nên controller và các ô nhập được xoá sạch thay
          // vì giữ lại mã cũ.
          builder: (context, state) => _OtpInput(key: ValueKey('otp_${state.email}'), email: state.email),
        ),
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
        _ResendButton(),
        const SizedBox(height: AppSize.p16),
        _ChangeEmailButton(),
        const SizedBox(height: AppSize.p8),
        _BackToLoginLink(),
      ],
    );
  }
}

class _OtpInput extends StatefulWidget {
  final String email;

  const _OtpInput({super.key, required this.email});

  @override
  State<_OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<_OtpInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 55,
      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(AppSize.r12),
        // Viền trong suốt (thay vì bỏ hẳn viền) để ô không nhảy 1px khi
        // focusedPinTheme thêm viền màu vào lúc focus.
        border: Border.all(color: Colors.transparent),
      ),
    );

    return Pinput(
      key: ValueKey('pinput_${widget.email}'),
      length: 6,
      controller: _controller,
      defaultPinTheme: defaultPinTheme,
      focusedPinTheme: defaultPinTheme.copyWith(
        decoration: defaultPinTheme.decoration!.copyWith(
          border: Border.all(color: AppColors.primary),
        ),
      ),
      submittedPinTheme: defaultPinTheme,
      // Trên web autofocus làm trang tự cuộn và có thể cướp focus khỏi phần
      // còn lại của form, nên chỉ bật trên native.
      autofocus: !kIsWeb,
      showCursor: true,
      onChanged: (value) {
        context.read<AuthFormBloc>().add(OtpChanged(value));
      },
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
      // pop() chứ không go(): quay lại đúng màn đã đẩy tới đây (login, đăng ký
      // hoặc quên mật khẩu) để người dùng sửa email rồi gửi lại.
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

class _ResendButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        context.read<AuthFormBloc>().add(OtpResendRequested());
        ToastUtils.showCustomToast(context, "Đang gửi lại mã...", ToastType.info);
      },
      child: const Text('Chưa nhận được mã? Gửi lại'),
    );
  }
}
