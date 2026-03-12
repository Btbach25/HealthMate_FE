import 'package:fe/data/models/user/user.dart';

/// Service gọi API Users (profile, list).
abstract class UserService {
  /// Lấy profile user hiện tại. GET /users/profile
  Future<User> getProfile();

  /// Cập nhật profile. PUT /users/profile body { name?, picture? }
  Future<void> updateProfile({String? name, String? picture});

  /// Danh sách users (tìm kiếm). GET /users?search=&limit=&offset=
  Future<List<User>> listUsers({String? search, int? limit, int? offset});
}
