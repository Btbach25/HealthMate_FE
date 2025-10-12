import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fe/data/models/user.dart';
import 'package:fe/data/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  late StreamSubscription<AuthStatus> _authStatusSubscription;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthState.unknown()) {
    on<AuthStatusChanged>(_onAuthStatusChanged);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);

    // Lắng nghe sự thay đổi trạng thái từ repository
    _authStatusSubscription = _authRepository.status.listen(
      (status) => add(AuthStatusChanged(status)),
    );
  }

  void _onAuthStatusChanged(AuthStatusChanged event, Emitter<AuthState> emit) {
    switch (event.status) {
      case AuthStatus.unauthenticated:
        return emit(const AuthState.unauthenticated());
      case AuthStatus.authenticated:
        // Trong ứng dụng thực tế, bạn sẽ lấy thông tin user từ repository
        const user = User(id: '1', name: 'Flutter Developer'); 
        return emit(const AuthState.authenticated(user));
      case AuthStatus.unknown:
        return emit(const AuthState.unknown());
    }
  }

  void _onAuthLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) {
    _authRepository.logout();
  }

  @override
  Future<void> close() {
    _authStatusSubscription.cancel();
    _authRepository.dispose();
    return super.close();
  }
}