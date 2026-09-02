import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fe/data/models/user/user.dart';
import 'package:fe/data/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Bloc phiên đăng nhập, sống suốt vòng đời app (provide ở `main.dart`).
///
/// Luồng: [AuthRepository.status] là nguồn sự thật duy nhất. Bloc lắng nghe
/// stream đó và tự bắn [AuthStatusChanged] cho chính mình, nên mọi thay đổi
/// phiên (login, logout, token hết hạn từ interceptor) đều đi qua một chỗ.
/// UI chỉ được add [AuthLogoutRequested] và [AuthUserUpdated].
///
/// `AppRouter` redirect dựa trên [AuthState.status], vì vậy đừng emit state
/// trung gian nào khác ngoài ba trạng thái trong [AuthState].
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

  Future<void> _onAuthStatusChanged(
    AuthStatusChanged event,
    Emitter<AuthState> emit,
  ) async {
    switch (event.status) {
      case AuthStatus.unauthenticated:
        return emit(AuthState.unauthenticated());
      case AuthStatus.authenticated:
        // Token hợp lệ nhưng hồ sơ có thể lấy hỏng (BE lỗi, user bị xoá) →
        // coi như chưa đăng nhập để router đá về /login thay vì crash UI.
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

  /// Không emit state ở đây: repository sẽ đẩy `unauthenticated` xuống stream
  /// và [_onAuthStatusChanged] mới là nơi đổi state.
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
