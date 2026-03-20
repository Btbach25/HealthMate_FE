import 'package:fe/data/core/api_client.dart';
import 'package:fe/data/core/api_endpoints.dart';
import 'package:fe/data/exceptions/api_exception.dart';
import 'package:fe/data/models/user/user.dart';
import 'package:fe/data/services/user_service.dart';

/// Implementation [UserService] gọi API Users qua [ApiClient].
class ApiUserService implements UserService {
  final ApiClient _apiClient;

  ApiUserService({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<User> getProfile() async {
    try {
      final data = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.usersProfile,
        parser: (d) => d is Map<String, dynamic> ? d : <String, dynamic>{},
      );
      return User.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Lỗi khi tải hồ sơ.',
        originalError: e,
      );
    }
  }

  @override
  Future<void> updateProfile({String? name, String? picture}) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (picture != null) body['picture'] = picture;
      if (body.isEmpty) return;
      await _apiClient.put<void>(
        ApiEndpoints.usersProfile,
        body: body,
        parser: (_) {},
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Lỗi khi cập nhật hồ sơ.',
        originalError: e,
      );
    }
  }

  @override
  Future<List<User>> listUsers({
    String? search,
    int? limit,
    int? offset,
  }) async {
    try {
      final query = <String>[];
      if (search != null && search.isNotEmpty) query.add('search=$search');
      if (limit != null) query.add('limit=$limit');
      if (offset != null) query.add('offset=$offset');
      final path =
          query.isEmpty ? ApiEndpoints.users : '${ApiEndpoints.users}?${query.join('&')}';
      final list = await _apiClient.get<List<dynamic>>(
        path,
        parser: (d) => d is List ? d : [],
      );
      return list
          .whereType<Map<String, dynamic>>()
          .map((e) => User.fromJson(e))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Lỗi khi tải danh sách người dùng.',
        originalError: e,
      );
    }
  }
}
