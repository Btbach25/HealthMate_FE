import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fe/data/models/user/user.dart';
import 'package:fe/data/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  late StreamSubscription<AuthStatus> _authStatusSubscription;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AuthState.unknown()) {
    on<AuthStatusChanged>(_onAuthStatusChanged);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthUserUpdated>(_onAuthUserUpdated);

    _authStatusSubscription = _authRepository.status.listen(
      (status) => add(AuthStatusChanged(status)),
    );
  }

  Future<void> _onAuthStatusChanged(AuthStatusChanged event, Emitter<AuthState> emit) async {
    switch (event.status) {
      case AuthStatus.unauthenticated:
        return emit(AuthState.unauthenticated());
      case AuthStatus.authenticated:
        final user = await _authRepository.getCurrentUser();
        return emit(
          user != null
              ? AuthState.authenticated(user)
              : AuthState.unauthenticated(),
        );
      case AuthStatus.unknown:
        return emit(AuthState.unknown());
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();
  }

  void _onAuthUserUpdated(AuthUserUpdated event, Emitter<AuthState> emit) {
    emit(AuthState.authenticated(event.user));
  }

  @override
  Future<void> close() {
    _authStatusSubscription.cancel();
    _authRepository.dispose();
    return super.close();
  }
}