import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/auth_repository.dart';
import 'package:fe/data/enums/user_status.dart';

part 'auth_form_event.dart';
part 'auth_form_state.dart';

class AuthFormBloc extends Bloc<AuthFormEvent, AuthFormState> {
  final AuthRepository _authRepository;

  /// Loại bỏ tiền tố "Exception: " khi hiển thị lỗi cho người dùng.
  static String _cleanErrorMessage(dynamic e) {
    final s = e.toString();
    return s.startsWith('Exception: ') ? s.substring(11) : s;
  }

  AuthFormBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const AuthFormState()) {
    on<NameChanged>(
      (event, emit) => emit(
        state.copyWith(
          name: event.name,
          status: FormStatus.initial,
          errorMessage: '',
        ),
      ),
    );

    on<EmailChanged>(
      (event, emit) => emit(
        state.copyWith(
          email: event.email,
          status: FormStatus.initial,
          errorMessage: '',
        ),
      ),
    );

    on<PasswordChanged>(
      (event, emit) => emit(
        state.copyWith(
          password: event.password,
          status: FormStatus.initial,
          errorMessage: '',
        ),
      ),
    );
    on<ConfirmPasswordChanged>(
      (event, emit) => emit(
        state.copyWith(
          confirmPassword: event.confirmPassword,
          status: FormStatus.initial,
        ),
      ),
    );
    on<OtpChanged>(
      (event, emit) =>
          emit(state.copyWith(otp: event.otp, status: FormStatus.initial)),
    );

    on<AuthFormInitialized>((event, emit) {
      emit(state.copyWith(
        email: event.email,
        status: FormStatus.initial,
        errorMessage: '',
        successMessage: '',
      ));
    });

    on<LoginSubmitted>(_onLoginSubmitted);
    on<GoogleLoginSubmitted>(_onGoogleLoginSubmitted);
    on<SignUpSubmitted>(_onSignUpSubmitted);
    on<ForgotPasswordSubmitted>(_onForgotPasswordSubmitted);
    on<OtpSubmitted>(_onOtpSubmitted);
    on<ResetPasswordSubmitted>(_onResetPasswordSubmitted);
    on<OtpResendRequested>(_onOtpResendRequested);
  }

  Future<void> _onGoogleLoginSubmitted(
    GoogleLoginSubmitted event,
    Emitter<AuthFormState> emit,
  ) async {
    emit(state.copyWith(status: FormStatus.inProgress));
    try {
      await _authRepository.loginWithGoogle(idToken: event.idToken);
      emit(state.copyWith(status: FormStatus.success));
    } catch (e) {
      emit(state.copyWith(status: FormStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthFormState> emit,
  ) async {
    if (state.email.isEmpty || state.password.isEmpty) return;

    emit(state.copyWith(status: FormStatus.inProgress));
    try {
      await _authRepository.login(email: state.email, password: state.password);
      emit(state.copyWith(status: FormStatus.success));
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('account not verified') ||
          msg.contains('not verified') ||
          msg.contains('chưa xác thực')) {
        // Auto resend OTP then guide user to verification
        try {
          await _authRepository.resendOtp(email: state.email);
        } catch (_) {}
        emit(state.copyWith(
          status: FormStatus.success,
          successMessage: 'Tài khoản chưa xác thực. Đã gửi lại OTP, vui lòng kiểm tra email.',
          needsVerification: true,
          verificationEmail: state.email,
        ));
      } else {
        emit(state.copyWith(status: FormStatus.failure, errorMessage: _cleanErrorMessage(e)));
      }
    }
  }

  Future<void> _onSignUpSubmitted(
    SignUpSubmitted event,
    Emitter<AuthFormState> emit,
  ) async {
    if (state.password != state.confirmPassword) {
      emit(
        state.copyWith(
          status: FormStatus.failure,
          errorMessage: 'Mật khẩu xác nhận không khớp.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: FormStatus.inProgress));
    try {
      final user = await _authRepository.register(
        name: state.name,
        email: state.email,
        password: state.password,
      );

      if (user != null && user.status == UserStatus.unverified) {
        emit(
          state.copyWith(
            status: FormStatus.success,
            successMessage: 'Registration successful. Please check your email to verify your account.',
            needsVerification: true,
            verificationEmail: user.email,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: FormStatus.success,
            successMessage: 'Đăng ký thành công!',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(status: FormStatus.failure, errorMessage: _cleanErrorMessage(e)),
      );
    }
  }

  Future<void> _onForgotPasswordSubmitted(
    ForgotPasswordSubmitted event,
    Emitter<AuthFormState> emit,
  ) async {
    emit(state.copyWith(status: FormStatus.inProgress));
    try {
      await _authRepository.sendPasswordResetEmail(email: state.email);
      emit(
        state.copyWith(
          status: FormStatus.success,
          successMessage: 'Đã gửi mã khôi phục đến email của bạn.',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: FormStatus.failure, errorMessage: _cleanErrorMessage(e)),
      );
    }
  }

  Future<void> _onOtpSubmitted(OtpSubmitted event, Emitter<AuthFormState> emit) async {
    final otp = state.otp.trim().replaceAll(RegExp(r'\s+'), '');
    if (otp.length != 6) {
      emit(state.copyWith(
        status: FormStatus.failure,
        errorMessage: 'Mã OTP phải đủ 6 chữ số.',
      ));
      return;
    }
    if (state.email.trim().isEmpty) {
      emit(state.copyWith(
        status: FormStatus.failure,
        errorMessage: 'Thiếu email. Vui lòng quay lại và thử đăng nhập lại.',
      ));
      return;
    }

    emit(state.copyWith(status: FormStatus.inProgress));
    try {
      await _authRepository.verifyOtp(email: state.email.trim(), otp: otp);
      emit(state.copyWith(status: FormStatus.success, successMessage: 'Xác thực thành công!'));
    } catch (e) {
      emit(state.copyWith(status: FormStatus.failure, errorMessage: _cleanErrorMessage(e)));
    }
  }

  Future<void> _onOtpResendRequested(OtpResendRequested event, Emitter<AuthFormState> emit) async {
    try {
      await _authRepository.resendOtp(email: state.email);
    } catch (e) {
      emit(state.copyWith(status: FormStatus.failure, errorMessage: _cleanErrorMessage(e)));
    }
  }

  Future<void> _onResetPasswordSubmitted(
    ResetPasswordSubmitted event,
    Emitter<AuthFormState> emit,
  ) async {
    if (state.password != state.confirmPassword) {
      emit(
        state.copyWith(
          status: FormStatus.failure,
          errorMessage: 'Mật khẩu xác nhận không khớp.',
        ),
      );
      return;
    }
    if (state.password.length < 6) {
      emit(
        state.copyWith(
          status: FormStatus.failure,
          errorMessage: 'Mật khẩu phải có ít nhất 6 ký tự.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: FormStatus.inProgress));
    try {
      await _authRepository.resetPassword(newPassword: state.password);
      emit(
        state.copyWith(
          status: FormStatus.success,
          successMessage: 'Đổi mật khẩu thành công!',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: FormStatus.failure, errorMessage: _cleanErrorMessage(e)),
      );
    }
  }
}
