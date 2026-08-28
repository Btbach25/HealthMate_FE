import 'package:fe/data/models/home_data.dart';

/// Hợp đồng lấy dữ liệu tổng hợp cho trang chủ ([HomeData]: user, tiến độ uống
/// thuốc, thông báo từ nhóm). Đây là dữ liệu ghép từ nhiều endpoint nên được
/// gom về một lời gọi duy nhất cho UI.
///
/// Muốn đổi nguồn dữ liệu (mock / API khác), implement lại interface này rồi
/// đăng ký implementation ở `lib/core/di/app_dependencies.dart` (composition root).
abstract class HomeService {
  Future<HomeData> getHomeData();
}