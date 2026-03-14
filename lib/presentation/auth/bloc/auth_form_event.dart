part of 'auth_form_bloc.dart';

abstract class AuthFormEvent extends Equatable {
  const AuthFormEvent();
  @override
  List<Object> get props => [];
}

// Events thay đổi giá trị input
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
// Thêm event này để init email khi vào màn hình OTP
class AuthFormInitialized extends AuthFormEvent {
  final String email;
  const AuthFormInitialized({required this.email});
  @override
  List<Object> get props => [email];
}

class OtpResendRequested extends AuthFormEvent {}
// Events nhấn nút submit
class LoginSubmitted extends AuthFormEvent {}
class GoogleLoginSubmitted extends AuthFormEvent {
  final String? idToken;
  const GoogleLoginSubmitted({this.idToken});
  @override
  List<Object> get props => [if (idToken != null) idToken!];
}
class SignUpSubmitted extends AuthFormEvent {}
class ForgotPasswordSubmitted extends AuthFormEvent {}
class OtpSubmitted extends AuthFormEvent {}
class ResetPasswordSubmitted extends AuthFormEvent {}