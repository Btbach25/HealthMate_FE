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

  const AuthFormState({
    this.status = FormStatus.initial,
    this.name = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.otp = '',
    this.successMessage = '',
    this.errorMessage = '',
  });

  AuthFormState copyWith({
    FormStatus? status,
    String? name,
    String? email,
    String? password,
    String? confirmPassword,
    String? otp,
    String? successMessage,
    String? errorMessage,
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
      ];
}