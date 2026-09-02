part of 'auth_form_bloc.dart';

/// Vòng đời một lần submit form: `initial` → `inProgress` → `success` hoặc
/// `failure`. `success` và `failure` là hai trạng thái terminal mà
/// `BlocListener` ở các màn auth lắng nghe để hiện toast / điều hướng.
enum FormStatus { initial, inProgress, success, failure }

/// State dùng chung cho TẤT CẢ form auth (login, đăng ký, quên mật khẩu, OTP,
/// đặt lại mật khẩu) — mỗi màn tạo một [AuthFormBloc] riêng nên chỉ vài field
/// trong đây được dùng ở mỗi màn, phần còn lại giữ giá trị mặc định.
class AuthFormState extends Equatable {
  final FormStatus status;
  final String name;
  final String email;
  final String password;
  final String confirmPassword;
  final String otp;
  final String successMessage;
  final String errorMessage;

  /// Bật khi BE báo tài khoản chưa xác thực (login) hoặc vừa đăng ký xong.
  /// Màn login/đăng ký dựa vào cờ này để đẩy sang `/otp` thay vì vào home.
  final bool needsVerification;

  /// Email mà BE thực sự gửi OTP tới. Có thể khác [email] người dùng gõ (BE
  /// chuẩn hoá chữ hoa/thường), nên luôn ưu tiên field này khi điều hướng.
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

  /// Validate phía client chỉ để bật/tắt nút submit; BE vẫn validate lại.
  bool get isValidLogin => email.contains('@') && password.length >= 6;

  bool get isValidSignUp =>
      isValidLogin && name.isNotEmpty && password == confirmPassword;

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
