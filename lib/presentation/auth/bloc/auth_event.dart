part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable{
  const AuthEvent();

  @override
  List<Object> get props => [];
}

// Event được gửi khi trạng thái đăng nhập từ repository thay đổi
class AuthStatusChanged extends AuthEvent {
  final AuthStatus status;

  const AuthStatusChanged(this.status);

  @override
  List<Object> get props => [status];
}

// Event được gửi khi người dùng yêu cầu đăng xuất
class AuthLogoutRequested extends AuthEvent {}
