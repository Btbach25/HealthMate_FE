import 'package:fe/data/models/user/user.dart';

/// Hợp đồng đọc/ghi hồ sơ người dùng và tìm kiếm user (nhóm endpoint
/// `/users/...`).
///
/// Muốn đổi nguồn dữ liệu (mock / API khác), implement lại interface này rồi
/// đăng ký implementation ở `lib/core/di/app_dependencies.dart` (composition root).
abstract class UserService {
  /// Lay profile user hien tai. GET /users/profile
  Future<User> getProfile();

  /// Cap nhat profile. PUT /users/profile (email khong doi qua API nay).
  /// [gender] gui len BE: `male` | `female` | `other`.
  /// [birthday] `yyyy-MM-dd` hoac `''` de xoa ngay sinh tren server.
  /// [allergies] non-null = ghi de; null = khong doi.
  Future<void> updateProfile({
    required String name,
    String? picture,
    String? phone,
    String? address,
    String? gender,
    String? birthday,
    double? weight,
    double? height,
    String? bloodGroup,
    String? timezone,
    List<String>? allergies,
  });

  /// Dong bo timezone sau login de BE trigger notification dung gio.
  Future<void> syncTimezoneAfterLogin();

  /// Danh sach users (tim kiem). GET /users?search=&limit=&offset=
  Future<List<User>> listUsers({String? search, int? limit, int? offset});
}
