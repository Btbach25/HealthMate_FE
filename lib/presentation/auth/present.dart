/// Barrel export của feature Auth.
///
/// Tồn tại để `lib/core/routing/app_router.dart` khai báo toàn bộ route xác
/// thực (`/login`, `/signup`, `/forgot-password`, `/otp`, `/reset-password`)
/// chỉ bằng một import duy nhất, thay vì 5 import lẻ.
///
/// Lưu ý khi thêm màn hình auth mới: nhớ export ở đây, nếu không router sẽ
/// không thấy class page tương ứng.
library;

export 'bloc/auth_form_bloc.dart';
export 'view/forgot_password_page.dart';
export 'view/login_page.dart';
export 'view/otp_page.dart';
export 'view/reset_password_page.dart';
export 'view/signup_page.dart';
