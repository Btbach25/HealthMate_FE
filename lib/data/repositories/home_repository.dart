import 'package:fe/data/exceptions/api_exception.dart';
import 'package:fe/data/models/home_data.dart';
import 'package:fe/data/services/home_service.dart';

/// Cổng vào của trang chủ; uỷ quyền cho [HomeService].
///
/// Bọc mọi lỗi ngoài [ApiException] thành [UnknownException] kèm message
/// tiếng Việt để UI hiển thị được ngay.
///
/// Đổi nguồn dữ liệu bằng cách đăng ký một [HomeService] khác ở
/// `lib/core/di/app_dependencies.dart` (composition root).
class HomeRepository {
  final HomeService _homeService;

  HomeRepository({required HomeService homeService})
      : _homeService = homeService;

  Future<HomeData> getHomeData() async {
    try {
      return await _homeService.getHomeData();
    } on ApiException {
      // ApiException đã có message hiển thị được -> giữ nguyên.
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Lỗi khi tải dữ liệu trang chủ.',
        originalError: e,
      );
    }
  }
}