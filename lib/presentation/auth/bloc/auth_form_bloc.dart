import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/auth_repository.dart';

part 'auth_form_event.dart';
part 'auth_form_state.dart';

class AuthFormBloc extends Bloc<AuthFormEvent, AuthFormState> {
  final AuthRepository _authRepository;

  AuthFormBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthFormState()) {
    // Register event handlers
    on<NameChanged>((event, emit) => emit(state.copyWith(name: event.name)));
    on<EmailChanged>((event, emit) => emit(state.copyWith(email: event.email)));
    on<PasswordChanged>((event, emit) => emit(state.copyWith(password: event.password)));
    on<ConfirmPasswordChanged>((event, emit) => emit(state.copyWith(confirmPassword: event.confirmPassword)));
    on<OtpChanged>((event, emit) => emit(state.copyWith(otp: event.otp)));

    on<LoginSubmitted>(_onLoginSubmitted);
    on<SignUpSubmitted>(_onSignUpSubmitted);
    on<ForgotPasswordSubmitted>(_onForgotPasswordSubmitted);
    on<OtpSubmitted>(_onOtpSubmitted);
    on<ResetPasswordSubmitted>(_onResetPasswordSubmitted);
  }


  Future<void> _onLoginSubmitted(LoginSubmitted event, Emitter<AuthFormState> emit) async {
    emit(state.copyWith(status: FormStatus.inProgress));
    try {
      await _authRepository.login(email: state.email, password: state.password);
      // Login success is handled by the global AuthBloc, so we don't emit success here.
      // We could emit a success state if we needed to show a temporary message.
    } catch (e) {
      emit(state.copyWith(status: FormStatus.failure, errorMessage: e.toString()));
    } finally {
      // Reset status to initial to allow for another submission
      emit(state.copyWith(status: FormStatus.initial));
    }
  }

  Future<void> _onSignUpSubmitted(SignUpSubmitted event, Emitter<AuthFormState> emit) async {
    if (state.password != state.confirmPassword) {
      emit(state.copyWith(status: FormStatus.failure, errorMessage: 'Mật khẩu xác nhận không khớp.'));
      emit(state.copyWith(status: FormStatus.initial)); // Reset status
      return;
    }
    emit(state.copyWith(status: FormStatus.inProgress));
    try {
      await _authRepository.register(
        name: state.name,
        email: state.email,
        password: state.password,
      );
      emit(state.copyWith(status: FormStatus.success, successMessage: 'Đăng ký thành công!'));
    } catch (e) {
      emit(state.copyWith(status: FormStatus.failure, errorMessage: e.toString()));
    } finally {
      emit(state.copyWith(status: FormStatus.initial));
    }
  }

  Future<void> _onForgotPasswordSubmitted(ForgotPasswordSubmitted event, Emitter<AuthFormState> emit) async {
    emit(state.copyWith(status: FormStatus.inProgress));
    try {
      await _authRepository.sendPasswordResetEmail(email: state.email);
      emit(state.copyWith(status: FormStatus.success, successMessage: 'Đã gửi mã khôi phục đến email của bạn.'));
    } catch (e) {
      emit(state.copyWith(status: FormStatus.failure, errorMessage: e.toString()));
    } finally {
      emit(state.copyWith(status: FormStatus.initial));
    }
  }

  Future<void> _onOtpSubmitted(OtpSubmitted event, Emitter<AuthFormState> emit) async {
    emit(state.copyWith(status: FormStatus.inProgress));
    try {
      final isSuccess = await _authRepository.verifyOtp(otp: state.otp);
      if (isSuccess) {
        emit(state.copyWith(status: FormStatus.success, successMessage: 'Xác thực thành công!'));
      } else {
        emit(state.copyWith(status: FormStatus.failure, errorMessage: 'Mã OTP không chính xác.'));
      }
    } catch (e) {
      emit(state.copyWith(status: FormStatus.failure, errorMessage: e.toString()));
    } finally {
      emit(state.copyWith(status: FormStatus.initial));
    }
  }

  Future<void> _onResetPasswordSubmitted(ResetPasswordSubmitted event, Emitter<AuthFormState> emit) async {
    if (state.password != state.confirmPassword) {
      emit(state.copyWith(status: FormStatus.failure, errorMessage: 'Mật khẩu xác nhận không khớp.'));
      emit(state.copyWith(status: FormStatus.initial));
      return;
    }
    if (state.password.length < 6) {
        emit(state.copyWith(status: FormStatus.failure, errorMessage: 'Mật khẩu phải có ít nhất 6 ký tự.'));
        emit(state.copyWith(status: FormStatus.initial));
        return;
    }

    emit(state.copyWith(status: FormStatus.inProgress));
    try {
      await _authRepository.resetPassword(newPassword: state.password);
      emit(state.copyWith(status: FormStatus.success, successMessage: 'Đổi mật khẩu thành công!'));
    } catch (e) {
      emit(state.copyWith(status: FormStatus.failure, errorMessage: e.toString()));
    } finally {
      emit(state.copyWith(status: FormStatus.initial));
    }
  }
}