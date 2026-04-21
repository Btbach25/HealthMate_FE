import 'package:fe/data/models/user/user.dart';

/// Service goi API Users (profile, list).
abstract class UserService {
  /// Lay profile user hien tai. GET /users/profile
  Future<User> getProfile();

  /// Cap nhat profile. PUT /users/profile (email khong doi qua API nay).
  /// [gender] gui len BE: `male` | `female` | `other`.
  /// [birthday] `yyyy-MM-dd` hoac `''` de xoa ngay sinh tren server.
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
  });

  /// Danh sach users (tim kiem). GET /users?search=&limit=&offset=
  Future<List<User>> listUsers({String? search, int? limit, int? offset});
}
