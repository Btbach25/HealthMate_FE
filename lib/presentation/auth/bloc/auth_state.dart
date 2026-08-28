part of 'auth_bloc.dart';

/// State toàn cục về phiên đăng nhập, do [AuthBloc] quản lý.
///
/// [AuthStatus.unknown] là state khởi tạo (đang đọc token từ storage) — router
/// dùng nó để giữ splash. [AuthStatus.authenticated] và
/// [AuthStatus.unauthenticated] là hai state terminal mà router redirect theo.
///
/// [user] không bao giờ null: khi chưa đăng nhập nó là `User.empty()`, nhờ vậy
/// UI không phải null-check ở mọi nơi.
class AuthState extends Equatable {
  final AuthStatus status;
  final User user;

  AuthState._({
    this.status = AuthStatus.unknown,
    User? user,
  }) : user = user ?? User.empty();

  AuthState.unknown() : this._();

  AuthState.authenticated(User user)
      : this._(status: AuthStatus.authenticated, user: user);

  AuthState.unauthenticated() : this._(status: AuthStatus.unauthenticated);

  @override
  List<Object> get props => [status, user];
}
