part of 'auth_bloc.dart';

class AuthState extends Equatable {
  final AuthStatus status;
  final User user;

  const AuthState._({
    this.status = AuthStatus.unknown,
    this.user = const User(id: '', name: ''),
  });

  // Trạng thái khởi tạo
  const AuthState.unknown() : this._();

  // Trạng thái đã đăng nhập
  const AuthState.authenticated(User user)
      : this._(status: AuthStatus.authenticated, user: user);

  // Trạng thái chưa đăng nhập
  const AuthState.unauthenticated()
      : this._(status: AuthStatus.unauthenticated);

  @override
  List<Object> get props => [status, user];
}