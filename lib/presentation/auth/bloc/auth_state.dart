part of 'auth_bloc.dart';

class AuthState extends Equatable {
  final AuthStatus status;
  final User user;

  AuthState._({
    this.status = AuthStatus.unknown,
    User? user,
  }): user = user ?? User.empty();

  AuthState.unknown() : this._();

  AuthState.authenticated(User user)
      : this._(status: AuthStatus.authenticated, user: user);

  AuthState.unauthenticated()
      : this._(status: AuthStatus.unauthenticated);

  @override
  List<Object> get props => [status, user];
}