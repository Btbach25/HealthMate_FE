import 'package:fe/data/mock_data/mock_users.dart';
import 'package:fe/data/models/user/user.dart';
import 'package:fe/data/services/local_storage_service.dart';
import 'package:fe/data/services/user_service.dart';
import 'package:flutter/foundation.dart';

/// [UserService] giả lập cho chế độ DEMO.
///
/// Hồ sơ được giữ **trong bộ nhớ** và đồng bộ xuống [LocalStorageService] nên
/// mọi thay đổi ở màn hình Cài đặt → Hồ sơ đều có hiệu lực ngay trong phiên
/// chạy (tên hiển thị ở trang chủ đổi theo, danh sách dị ứng được lưu lại…).
class MockUserService implements UserService {
  final LocalStorageService _localStorage;

  MockUserService(this._localStorage);

  User? _profile;

  Future<void> _delay([int milliseconds = 350]) =>
      Future<void>.delayed(Duration(milliseconds: milliseconds));

  /// Ưu tiên user đang lưu trong local storage (đúng với người vừa đăng nhập),
  /// nếu không có thì dùng hồ sơ demo mặc định.
  Future<User> _currentProfile() async {
    if (_profile != null) return _profile!;
    final stored = await _localStorage.getUser();
    _profile = (stored != null && stored.isNotEmpty)
        ? stored
        : MockUsers.demoUser;
    return _profile!;
  }

  @override
  Future<User> getProfile() async {
    await _delay();
    return _currentProfile();
  }

  @override
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
  }) async {
    await _delay(400);
    final current = await _currentProfile();

    final updated = current.copyWith(
      name: name,
      picture: picture,
      phone: phone,
      address: address,
      gender: gender,
      // `birthday: ''` là quy ước "xoá ngày sinh" của API thật → giữ nguyên ở đây.
      birthday: birthday,
      weight: weight,
      height: height,
      bloodGroup: bloodGroup,
      timezone: timezone,
      allergies: allergies,
      updatedAt: DateTime.now(),
    );

    _profile = updated;
    await _localStorage.saveUser(updated);
    if (allergies != null) {
      await _localStorage.saveAllergies(allergies);
    }
    debugPrint('[MockUserService] Đã cập nhật hồ sơ DEMO: ${updated.name}');
  }

  @override
  Future<void> syncTimezoneAfterLogin() async {
    // Demo không có backend để đồng bộ — không làm gì cả.
    await _delay(120);
  }

  @override
  Future<List<User>> listUsers({
    String? search,
    int? limit,
    int? offset,
  }) async {
    await _delay(300);

    final keyword = (search ?? '').trim().toLowerCase();
    var result = MockUsers.all;
    if (keyword.isNotEmpty) {
      result = result
          .where(
            (u) =>
                u.name.toLowerCase().contains(keyword) ||
                u.email.toLowerCase().contains(keyword),
          )
          .toList();
    }

    final start = (offset ?? 0).clamp(0, result.length).toInt();
    result = result.sublist(start);
    if (limit != null && limit >= 0 && limit < result.length) {
      result = result.sublist(0, limit);
    }
    return result;
  }
}
