# HealthMate - Frontend

Ứng dụng theo dõi sức khỏe cá nhân và gia đình, xây dựng bằng Flutter. Hỗ trợ theo dõi các chỉ số sức khỏe (nhịp tim, bước chân, calo), quản lý nhóm gia đình, nhắc nhở uống thuốc và xem thống kê sức khỏe.

## Yêu cầu hệ thống

- **Flutter SDK**: 3.24.0 trở lên
- **Dart SDK**: 3.8.1 trở lên
- **IDE**: Android Studio, Visual Studio Code (khuyên dùng với extension Flutter)
- **Hệ điều hành**: Windows, macOS, hoặc Linux
- Để build iOS: Xcode 15+ và CocoaPods
- Để build Android: Android SDK (API 21+)

## Cài đặt

1. **Clone repository**:
   ```bash
   git clone <URL của repository>
   cd HealthMate_FE
   ```

2. **Cài đặt dependencies**:
   ```bash
   flutter pub get
   ```

3. **Cấu hình môi trường**:

   Tạo file `.env` ở thư mục gốc (có thể copy từ `.env.dev`):
   ```bash
   cp .env.dev .env
   ```

   Chỉnh sửa `BASE_URL` trong `.env` cho phù hợp với backend của bạn:
   ```env
   BASE_URL=http://localhost:8080
   ```

4. **Kiểm tra cài đặt**:
   ```bash
   flutter doctor
   ```

## Chạy ứng dụng

- **Chạy trên emulator/thiết bị thật**:
  ```bash
  flutter run
  ```

- **Chạy với môi trường cụ thể**:
  ```bash
  # Development
  flutter run --dart-define-from-file=.env.dev

  # Production
  flutter run --dart-define-from-file=.env.prod
  ```

- **Build APK cho Android**:
  ```bash
  flutter build apk --dart-define-from-file=.env.prod
  ```

- **Build IPA cho iOS**:
  ```bash
  flutter build ios --dart-define-from-file=.env.prod
  ```

## Cấu trúc thư mục

Dự án áp dụng **Clean Architecture** với 3 lớp chính:

```
lib/
├── core/                        # Thành phần dùng chung toàn app
│   ├── constants/               # Hằng số (kích thước, style, icon path)
│   ├── extensions/              # Extension cho Dart/Flutter
│   ├── routing/                 # Cấu hình điều hướng (GoRouter)
│   ├── theme/                   # Theme, màu sắc, font chữ
│   └── utils/                   # Hàm tiện ích (converter, toast)
│
├── data/                        # Lớp dữ liệu
│   ├── constant/                # Hằng số liên quan đến data (API paths, ...)
│   ├── enums/                   # Enum dùng trong domain (MetricType, UserRole, ...)
│   ├── models/                  # Data model (User, Group, HealthMetrics, ...)
│   ├── repositories/            # Repository - trung gian giữa service và UI
│   └── services/                # Service kết nối API, local storage
│
├── presentation/                # Lớp giao diện
│   ├── auth/                    # Luồng xác thực (đăng nhập, đăng ký, OTP, đổi mật khẩu)
│   │   ├── bloc/                # AuthBloc, AuthFormBloc
│   │   ├── view/                # Các màn hình auth
│   │   └── widgets/             # Widget dùng trong auth
│   ├── home/                    # Màn hình tổng quan sức khỏe
│   │   ├── view/
│   │   └── widgets/
│   └── main_tabs/               # Shell điều hướng chính (bottom nav)
│       └── tabs/                # Family, Stats, Medications, Settings
│
└── main.dart                    # Entry point của ứng dụng
```

## Điều hướng

Ứng dụng sử dụng **GoRouter** với 5 tab chính sau khi đăng nhập:

| Tab | Route | Mô tả |
|-----|-------|--------|
| Tổng quan | `/home` | Chỉ số sức khỏe hôm nay |
| Gia đình | `/family` | Quản lý nhóm gia đình |
| Chỉ số | `/stats` | Thống kê dài hạn |
| Thuốc | `/medications` | Nhắc nhở uống thuốc |
| Cài đặt | `/settings` | Cài đặt tài khoản |

Router tự động redirect về màn hình đăng nhập nếu chưa xác thực.

## Công nghệ sử dụng

| Package | Phiên bản | Mục đích |
|---------|-----------|----------|
| `flutter_bloc` | ^8.1.5 | State management (BLoC pattern) |
| `go_router` | ^16.2.5 | Điều hướng khai báo |
| `shared_preferences` | ^2.5.3 | Lưu trữ local (token, session) |
| `get_it` | ^7.6.7 | Service locator / Dependency injection |
| `equatable` | ^2.0.5 | So sánh object theo giá trị |
| `json_annotation` | ^4.9.0 | Serialization JSON |
| `permission_handler` | ^12.0.1 | Xin quyền truy cập thiết bị |
| `pinput` | ^5.0.2 | Widget nhập mã OTP |
| `health` | ^13.2.0 | Đọc dữ liệu sức khỏe từ thiết bị |

## Hướng dẫn phát triển

### Thêm màn hình mới

1. Tạo thư mục trong `presentation/<feature>/` với cấu trúc:
   ```
   <feature>/
   ├── bloc/        # Event, State, Bloc
   ├── view/        # Page widget
   └── widgets/     # Widget nhỏ dùng trong feature này
   ```
2. Khai báo route trong `lib/core/routing/app_router.dart`.
3. Nếu cần dữ liệu từ API, tạo service trong `data/services/` và repository trong `data/repositories/`.

### Thêm chỉ số sức khỏe mới

1. Thêm giá trị vào enum `MetricType` trong `data/enums/`.
2. Tạo model tương ứng trong `data/models/health_metrics.dart`.
3. Cập nhật service đọc dữ liệu thiết bị.

### Quy ước code

- Mỗi BLoC chỉ xử lý một domain logic cụ thể.
- Không gọi API trực tiếp từ UI — luôn thông qua Repository.
- Dùng `Equatable` cho tất cả BLoC Event/State và Model.
- Chạy `flutter analyze` trước khi commit để đảm bảo code style.

### Tài khoản mock (development)

Khi chưa kết nối backend, ứng dụng dùng `MockAuthService`:
- **Email**: `admin@gmail.com`
- **Mật khẩu**: `admin`

### Kiểm thử

```bash
# Chạy toàn bộ unit test
flutter test

# Kiểm tra code style
flutter analyze
```
