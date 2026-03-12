part of 'auth_form_bloc.dart';

enum FormStatus { initial, inProgress, success, failure }

class AuthFormState extends Equatable{
  final FormStatus status;
  final String name;
  final String email;
  final String password;
  final String confirmPassword;
  final String otp;
  final String successMessage;
  final String errorMessage;
  final bool needsVerification;
  final String verificationEmail;

  const AuthFormState({
    this.status = FormStatus.initial,
    this.name = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.otp = '',
    this.successMessage = '',
    this.errorMessage = '',
    this.needsVerification = false,
    this.verificationEmail = '',
  });

  bool get isValidLogin => email.contains('@') && password.length >= 6;

  bool get isValidSignUp =>
      isValidLogin &&
      name.isNotEmpty &&
      password == confirmPassword;

  bool get isValidResetPassword => password.length >= 6 && password == confirmPassword;

  bool get isValidOtp => otp.length == 6;

  AuthFormState copyWith({
    FormStatus? status,
    String? name,
    String? email,
    String? password,
    String? confirmPassword,
    String? otp,
    String? successMessage,
    String? errorMessage,
    bool? needsVerification,
    String? verificationEmail,
  }) {
    return AuthFormState(
      status: status ?? this.status,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      otp: otp ?? this.otp,
      successMessage: successMessage ?? this.successMessage,
      errorMessage: errorMessage ?? this.errorMessage,
      needsVerification: needsVerification ?? this.needsVerification,
      verificationEmail: verificationEmail ?? this.verificationEmail,
    );
  }

  @override
  List<Object> get props => [
        status,
        name,
        email,
        password,
        confirmPassword,
        otp,
        successMessage,
      errorMessage,
      needsVerification,
      verificationEmail,
      ];
}