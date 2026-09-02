import 'package:equatable/equatable.dart';
import 'package:fe/core/utils/user_facing_error.dart';
import 'package:fe/data/enums/user_status.dart';
import 'package:fe/data/repositories/auth_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'auth_form_event.dart';
part 'auth_form_state.dart';

/// Bloc điều khiển các form xác thực (login, đăng ký, quên mật khẩu, OTP,
/// đặt lại mật khẩu).
///
/// Mỗi màn auth tạo một instance riêng (xem BlocProvider trong từng
/// `*_page.dart`), nên state KHÔNG chia sẻ giữa các màn: email cần mang sang
/// màn OTP phải truyền qua `GoRouter.extra` rồi nạp lại bằng
/// [AuthFormInitialized].
///
/// Quy ước: mọi event "đổi input" đều reset [FormStatus] về `initial` để
/// `BlocListener` không bắn lại toast lỗi cũ ngay khi người dùng bắt đầu sửa.
/// Lỗi từ repository luôn đi qua [UserFacingError.message] trước khi vào
/// [AuthFormState.errorMessage] — không hiển thị raw exception cho người dùng.
class AuthFormBloc extends Bloc<AuthFormEvent, AuthFormState> {
  final AuthRepository _authRepository;

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
      emit(
        state.copyWith(
          email: event.email,
          status: FormStatus.initial,
          errorMessage: '',
          successMessage: '',
        ),
      );
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
      emit(
        state.copyWith(
          status: FormStatus.failure,
          errorMessage: UserFacingError.message(e),
        ),
      );
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
      // Hợp đồng với BE: tài khoản chưa xác thực trả về message chứa
      // "account not verified". BE chưa có error code riêng nên buộc phải khớp
      // chuỗi — nếu BE đổi wording, phải cập nhật danh sách dưới đây.
      final msg = e.toString().toLowerCase();
      if (msg.contains('account not verified') ||
          msg.contains('not verified') ||
          msg.contains('chưa xác thực')) {
        // Gửi lại OTP giúp người dùng luôn. Nuốt lỗi ở đây là cố ý: kể cả khi
        // resend fail (rate limit), vẫn nên đưa họ sang màn OTP để tự bấm
        // "Gửi lại" thay vì kẹt ở màn login.
        try {
          await _authRepository.resendOtp(email: state.email);
        } catch (_) {}
        emit(
          state.copyWith(
            status: FormStatus.success,
            successMessage:
                'Tài khoản chưa xác thực. Đã gửi lại OTP, vui lòng kiểm tra email.',
            needsVerification: true,
            verificationEmail: state.email,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: FormStatus.failure,
            errorMessage: UserFacingError.message(e),
          ),
        );
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

      // BE có thể bật/tắt bước xác thực email: nếu user trả về ở trạng thái
      // unverified thì phải qua màn OTP, ngược lại đăng ký xong là dùng được.
      if (user != null && user.status == UserStatus.unverified) {
        emit(
          state.copyWith(
            status: FormStatus.success,
            successMessage:
                'Registration successful. Please check your email to verify your account.',
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
        state.copyWith(
          status: FormStatus.failure,
          errorMessage: UserFacingError.message(e),
        ),
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
        state.copyWith(
          status: FormStatus.failure,
          errorMessage: UserFacingError.message(e),
        ),
      );
    }
  }

  Future<void> _onOtpSubmitted(
    OtpSubmitted event,
    Emitter<AuthFormState> emit,
  ) async {
    // Người dùng thường copy mã từ email kèm khoảng trắng → chuẩn hoá trước
    // khi đếm độ dài, nếu không mã 6 số dán vào sẽ bị coi là sai định dạng.
    final otp = state.otp.trim().replaceAll(RegExp(r'\s+'), '');
    if (otp.length != 6) {
      emit(
        state.copyWith(
          status: FormStatus.failure,
          errorMessage: 'Mã OTP phải đủ 6 chữ số.',
        ),
      );
      return;
    }
    // Email rỗng nghĩa là màn OTP được mở mà thiếu AuthFormInitialized.
    if (state.email.trim().isEmpty) {
      emit(
        state.copyWith(
          status: FormStatus.failure,
          errorMessage: 'Thiếu email. Vui lòng quay lại và thử đăng nhập lại.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: FormStatus.inProgress));
    try {
      await _authRepository.verifyOtp(email: state.email.trim(), otp: otp);
      emit(
        state.copyWith(
          status: FormStatus.success,
          successMessage: 'Xác thực thành công!',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: FormStatus.failure,
          errorMessage: UserFacingError.message(e),
        ),
      );
    }
  }

  /// Cố ý KHÔNG emit `FormStatus.success` khi gửi lại OTP thành công: màn OTP
  /// điều hướng ngay khi thấy `success`, emit ở đây sẽ đá người dùng ra khỏi
  /// màn hình trước khi họ kịp nhập mã. Chỉ lỗi mới được emit.
  Future<void> _onOtpResendRequested(
    OtpResendRequested event,
    Emitter<AuthFormState> emit,
  ) async {
    try {
      await _authRepository.resendOtp(email: state.email);
    } catch (e) {
      emit(
        state.copyWith(
          status: FormStatus.failure,
          errorMessage: UserFacingError.message(e),
        ),
      );
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
      // Không truyền OTP/token ở đây: repository dùng token tạm đã lưu khi
      // verifyOtp thành công ở bước trước của luồng quên mật khẩu.
      await _authRepository.resetPassword(newPassword: state.password);
      emit(
        state.copyWith(
          status: FormStatus.success,
          successMessage: 'Đổi mật khẩu thành công!',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: FormStatus.failure,
          errorMessage: UserFacingError.message(e),
        ),
      );
    }
  }
}
