part of 'auth_bloc.dart';

/// Base class cho mọi event của [AuthBloc].
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

/// Do chính [AuthBloc] tự bắn khi stream `AuthRepository.status` phát giá trị
/// mới (login/logout/refresh token hết hạn). UI không bao giờ add event này.
class AuthStatusChanged extends AuthEvent {
  final AuthStatus status;

  const AuthStatusChanged(this.status);

  @override
  List<Object> get props => [status];
}

/// UI (màn Cài đặt) bắn khi người dùng bấm đăng xuất. Bloc không emit state
/// trực tiếp: nó gọi repository, repository đẩy `AuthStatus.unauthenticated`
/// xuống stream và vòng lặp quay lại [AuthStatusChanged].
class AuthLogoutRequested extends AuthEvent {}

/// UI bắn sau khi sửa hồ sơ thành công để đồng bộ [User] trong state mà không
/// cần gọi lại API `getCurrentUser`.
class AuthUserUpdated extends AuthEvent {
  final User user;

  const AuthUserUpdated(this.user);

  @override
  List<Object> get props => [user];
}
