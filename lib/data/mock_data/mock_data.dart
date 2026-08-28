/// Kho **dữ liệu giả** cho chế độ DEMO của HealthMate.
///
/// ## Chế độ DEMO là gì?
/// Khi `DEMO_MODE=true`, `AppDependencies.bootstrap()` dựng object graph toàn
/// bộ bằng các `Mock*Service` trong `lib/data/services/mock_*.dart`. Những
/// service đó **không gọi API/WebSocket/Firebase**, chúng chỉ đọc dữ liệu từ
/// thư mục này. Nhờ vậy có thể demo đầy đủ tính năng mà không cần backend.
///
/// ## Bật demo mode
/// ```bash
/// flutter run --dart-define=DEMO_MODE=true
/// ```
/// hoặc thêm `DEMO_MODE=true` vào file `.env`.
///
/// Tài khoản demo: `demo@healthmate.vn` / `demo1234` (mã OTP demo: `123456`).
///
/// ## Cấu trúc thư mục
/// | File | Nội dung |
/// |---|---|
/// | `mock_users.dart` | Tài khoản demo + danh bạ người dùng giả |
/// | `mock_health_data.dart` | Bộ sinh chỉ số sức khoẻ (nhịp tim, bước chân, huyết áp…) |
/// | `mock_stats_data.dart` | Tóm tắt & biểu đồ cho màn hình Thống kê |
/// | `mock_family_data.dart` | Nhóm gia đình, thành viên, lời mời, thông báo |
/// | `mock_medications_data.dart` | Thuốc, lịch nhắc, chia sẻ thuốc |
///
/// ## Nguyên tắc khi sửa dữ liệu demo
/// 1. **Chỉ chứa dữ liệu thuần** — không đặt logic gọi mạng ở đây.
/// 2. **Không dùng `Random()`**: mọi chuỗi số sinh bằng hàm sin xác định
///    (xem `MockHealthData.valueAt`) để mỗi lần mở app dữ liệu như nhau.
/// 3. **Thời gian luôn tương đối với `DateTime.now()`** (ví dụ
///    `now.subtract(const Duration(days: 2))`) để dữ liệu không bao giờ bị cũ.
/// 4. **Id phải nhất quán giữa các file** — `MockUsers.demoUserId` là chủ nhóm
///    `MockFamilyData.group1` và là chủ sở hữu toàn bộ thuốc trong
///    `MockMedicationsData`; đổi id ở một chỗ thì phải đổi ở mọi chỗ.
///
/// ## Thêm dữ liệu cho một tính năng mới
/// 1. Tạo file `mock_<tên_domain>_data.dart` trong thư mục này và export ở đây.
/// 2. Tạo `lib/data/services/mock_<tên>_service.dart` đọc dữ liệu đó.
/// 3. Cắm mock vào nhánh `AppDependencies._demo()`.
library;

export 'mock_family_data.dart';
export 'mock_health_data.dart';
export 'mock_medications_data.dart';
export 'mock_stats_data.dart';
export 'mock_users.dart';
