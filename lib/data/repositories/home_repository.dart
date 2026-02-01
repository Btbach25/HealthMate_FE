import 'package:fe/data/exceptions/api_exception.dart';
import 'package:fe/data/models/home_data.dart';
import 'package:fe/data/services/home_service.dart';

/// Repository for home data operations
class HomeRepository {
  final HomeService _homeService;

  HomeRepository({required HomeService homeService})
      : _homeService = homeService;

  Future<HomeData> getHomeData() async {
    try {
      return await _homeService.getHomeData();
    } on ApiException {
      // Re-throw ApiException as-is (already has proper error messages)
      rethrow;
    } catch (e) {
      // Wrap unexpected errors
      throw UnknownException(
        message: 'Lỗi khi tải dữ liệu trang chủ.',
        originalError: e,
      );
    }
  }
}