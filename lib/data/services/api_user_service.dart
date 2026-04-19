import 'package:fe/data/core/api_client.dart';
import 'package:fe/data/core/api_endpoints.dart';
import 'package:fe/data/exceptions/api_exception.dart';
import 'package:fe/data/models/user/user.dart';
import 'package:fe/data/services/user_service.dart';

/// Implementation [UserService] goi API Users qua [ApiClient].
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
        message: 'Loi khi tai ho so.',
        originalError: e,
      );
    }
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
  }) async {
    try {
      final body = <String, dynamic>{'name': name};
      if (picture != null) body['picture'] = picture;
      if (phone != null) body['phone'] = phone;
      if (address != null) body['address'] = address;
      if (gender != null) body['gender'] = gender;
      if (birthday != null) body['birthday'] = birthday;
      if (weight != null) body['weight'] = weight;
      if (height != null) body['height'] = height;
      if (bloodGroup != null) body['blood_group'] = bloodGroup;
      await _apiClient.put<void>(
        ApiEndpoints.usersProfile,
        body: body,
        parser: (_) {},
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Loi khi cap nhat ho so.',
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
        message: 'Loi khi tai danh sach nguoi dung.',
        originalError: e,
      );
    }
  }
}
