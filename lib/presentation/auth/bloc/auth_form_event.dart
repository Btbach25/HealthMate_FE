part of 'auth_form_bloc.dart';

/// Base class cho mọi event của [AuthFormBloc].
///
/// Nhóm 1 — event "đổi giá trị input": do các `TextField`/`Pinput` bắn mỗi lần
/// gõ, chỉ cập nhật state và reset [FormStatus] về `initial` (xoá thông báo lỗi
/// cũ). Nhóm 2 — event "submit": do nút bấm bắn, gọi `AuthRepository`.
abstract class AuthFormEvent extends Equatable {
  const AuthFormEvent();

  @override
  List<Object> get props => [];
}

// --- Nhóm 1: thay đổi giá trị input ---

class NameChanged extends AuthFormEvent {
  final String name;
  const NameChanged(this.name);
  @override
  List<Object> get props => [name];
}

class EmailChanged extends AuthFormEvent {
  final String email;
  const EmailChanged(this.email);
  @override
  List<Object> get props => [email];
}

class PasswordChanged extends AuthFormEvent {
  final String password;
  const PasswordChanged(this.password);
  @override
  List<Object> get props => [password];
}

class ConfirmPasswordChanged extends AuthFormEvent {
  final String confirmPassword;
  const ConfirmPasswordChanged(this.confirmPassword);
  @override
  List<Object> get props => [confirmPassword];
}

class OtpChanged extends AuthFormEvent {
  final String otp;
  const OtpChanged(this.otp);
  @override
  List<Object> get props => [otp];
}

/// Nạp sẵn email vào state ngay khi mở màn OTP.
///
/// Bắt buộc phải có: mỗi màn auth tạo một [AuthFormBloc] mới, nên email người
/// dùng vừa nhập ở màn trước không tự có ở màn OTP — nếu thiếu, `OtpSubmitted`
/// sẽ fail vì state.email rỗng.
class AuthFormInitialized extends AuthFormEvent {
  final String email;
  const AuthFormInitialized({required this.email});
  @override
  List<Object> get props => [email];
}

// --- Nhóm 2: submit ---

class LoginSubmitted extends AuthFormEvent {}

/// [idToken] null trên native (plugin tự lấy token), có giá trị trên web
/// (Google Identity Services trả về idToken cho JS callback).
class GoogleLoginSubmitted extends AuthFormEvent {
  final String? idToken;
  const GoogleLoginSubmitted({this.idToken});
  @override
  List<Object> get props => [if (idToken != null) idToken!];
}

class SignUpSubmitted extends AuthFormEvent {}

class ForgotPasswordSubmitted extends AuthFormEvent {}

class OtpSubmitted extends AuthFormEvent {}

/// Gửi lại OTP. Khi thành công bloc KHÔNG emit state mới (tránh
/// `BlocListener` của màn OTP hiểu nhầm là xác thực thành công rồi điều hướng);
/// UI tự hiện toast "đang gửi lại".
class OtpResendRequested extends AuthFormEvent {}

class ResetPasswordSubmitted extends AuthFormEvent {}
