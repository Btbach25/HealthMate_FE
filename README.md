# HealthMate - Frontend

Ứng dụng Flutter đa nền tảng (Android, iOS, Web, Desktop) theo dõi sức khỏe cá nhân và gia đình. Hỗ trợ theo dõi các chỉ số sức khỏe (nhịp tim, bước chân, calo, huyết áp, nhiệt độ, cân nặng), quản lý nhóm gia đình, nhắc nhở uống thuốc và xem thống kê sức khỏe.

---

## Nội dung

- [Kiến trúc dự án](#kiến-trúc-dự-án)
- [Cài đặt & chạy dự án](#cài-đặt--chạy-dự-án)
- [Quản lý môi trường (.env)](#quản-lý-môi-trường-env)
- [Build & phát hành](#build--phát-hành)
- [Cấu trúc thư mục](#cấu-trúc-thư-mục)
- [Công nghệ sử dụng](#công-nghệ-sử-dụng)
- [Hướng dẫn phát triển](#hướng-dẫn-phát-triển)
- [Ghi chú / Troubleshooting](#ghi-chú--troubleshooting)

---

## Kiến trúc dự án

Ứng dụng áp dụng **Clean Architecture** với 3 lớp chính, sử dụng BLoC pattern cho state management:

- `core/`: thành phần dùng chung (theme, routing, helpers, widgets tái sử dụng)
- `data/`: làm việc với dữ liệu
  - `models/`: các cấu trúc dữ liệu / domain models
  - `services/`: gọi API, lưu trữ local
  - `repositories/`: điều phối nguồn dữ liệu (service + cache) cho UI
- `presentation/`: UI + State (Flutter + flutter_bloc)
  - `bloc/`: BLoC/Cubit quản lý luồng dữ liệu UI
  - `view/` + `widgets/`: màn hình và widget

Dòng chảy dữ liệu:

```
UI (Widget) ⇄ Bloc ⇄ Repository ⇄ Service ⇄ API
```

---

## Cài đặt & chạy dự án

**Yêu cầu hệ thống:**

- Flutter SDK 3.24.0 trở lên
- Dart SDK 3.8.1 trở lên
- Android Studio hoặc Visual Studio Code (với extension Flutter)
- Để build iOS: macOS + Xcode 15+ + CocoaPods
- Để build Android: Android SDK (API 21+)
- Trình duyệt Chrome để chạy Web

**1) Clone và cài dependencies**

```bash
git clone https://github.com/<owner>/HealthMate_FE.git
cd HealthMate_FE
flutter doctor
flutter pub get
```

**2) Tạo file môi trường**

Các file `.env` đã được khai báo trong `pubspec.yaml` (assets). Tạo tại thư mục gốc nếu chưa có:

```
# .env.dev
BASE_URL=http://localhost:8080

# .env.prod
BASE_URL=https://api.yourdomain.com
```

**3) Chạy dự án**

```bash
# Development (Android/iOS/Desktop)
flutter run --dart-define=ENV=dev

# Development (Web) — dùng port cố định để Google OAuth hoạt động
flutter run -d chrome --web-port=5000 --dart-define=ENV=dev

# Chạy với file env cụ thể
flutter run --dart-define-from-file=.env.dev
```

> Nếu vừa thêm package hoặc BLoC provider mới mà hot-reload lỗi, hãy thực hiện **hot-restart** (`R` trong terminal).

---

## Quản lý môi trường (.env)

Ứng dụng dùng `flutter_dotenv` để load biến môi trường dưới dạng asset (hỗ trợ Web).

- `main.dart` đọc biến `ENV` từ `--dart-define` để load đúng file `.env.dev` hoặc `.env.prod`.
- Biến bắt buộc: `BASE_URL` — URL gốc API (không có trailing slash).

Ví dụ sử dụng trong service:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

final baseUrl = dotenv.env['BASE_URL'];
```

---

## Build & phát hành

```bash
# Android APK
flutter build apk --dart-define=ENV=prod

# Android App Bundle
flutter build appbundle --dart-define=ENV=prod

# iOS (yêu cầu macOS + Xcode)
flutter build ios --dart-define=ENV=prod

# Web
flutter build web --dart-define=ENV=prod
```

---

## Cấu trúc thư mục

```
lib/
├── core/
│   ├── constants/               # Hằng số (kích thước, style, icon path)
│   ├── extensions/              # Extension cho Dart/Flutter
│   ├── mixins/                  # Mixin tái sử dụng
│   ├── routing/                 # Cấu hình điều hướng (GoRouter)
│   ├── theme/                   # Theme, màu sắc, font chữ, text styles
│   ├── utils/                   # Hàm tiện ích (converter, toast, helpers)
│   └── widgets/                 # Widget dùng chung toàn app
│
├── data/
│   ├── core/                    # API client (interface + implementation)
│   ├── enums/                   # Enum domain (MetricType, UserRole, ...)
│   ├── exceptions/              # Custom exceptions (ApiException, ...)
│   ├── models/
│   │   ├── group/               # FamilyGroup, GroupMember, Invitation, ...
│   │   ├── health/              # HeartRate, StepsCount, BloodPressure, ...
│   │   ├── home_page/           # HomeData
│   │   ├── settings/            # GeneralSettings, NotificationSettings, ...
│   │   └── user/                # User, AuthResponse
│   ├── repositories/            # AuthRepository, FamilyRepository, ...
│   └── services/                # AuthService, HomeService, FamilyService, ...
│
├── presentation/
│   ├── auth/                    # Đăng nhập, đăng ký, OTP, đổi mật khẩu
│   │   ├── bloc/
│   │   ├── view/
│   │   └── widgets/
│   ├── home/                    # Tổng quan sức khỏe hôm nay
│   │   ├── bloc/
│   │   ├── view/
│   │   └── widgets/
│   ├── family/                  # Quản lý nhóm gia đình
│   ├── details/                 # Thống kê chi tiết theo chỉ số
│   ├── settings/                # Cài đặt tài khoản, thông báo, bảo mật
│   └── main_tabs/               # Shell điều hướng chính (bottom nav)
│
└── main.dart                    # Entry point

assets/
├── fonts/                       # Lato (Regular, Bold, Italic)
├── icons/
└── images/
```

### Điều hướng (GoRouter)

| Tab | Route | Mô tả |
|-----|-------|--------|
| Tổng quan | `/home` | Chỉ số sức khỏe hôm nay |
| Gia đình | `/family` | Quản lý nhóm gia đình |
| Chỉ số | `/stats` | Thống kê dài hạn |
| Thuốc | `/medications` | Nhắc nhở uống thuốc |
| Cài đặt | `/settings` | Cài đặt tài khoản |

Router tự động redirect về màn hình đăng nhập nếu chưa xác thực.

---

## Công nghệ sử dụng

| Package | Phiên bản | Mục đích |
|---------|-----------|----------|
| `flutter_bloc` | ^8.1.5 | State management (BLoC pattern) |
| `go_router` | ^16.2.5 | Điều hướng khai báo |
| `flutter_dotenv` | ^5.0.2 | Biến môi trường từ file .env |
| `http` | ^1.6.0 | HTTP client gọi REST API |
| `shared_preferences` | ^2.5.3 | Lưu trữ local (token, session) |
| `get_it` | ^7.6.7 | Service locator / Dependency injection |
| `equatable` | ^2.0.5 | So sánh object theo giá trị |
| `json_annotation` | ^4.9.0 | Serialization JSON |
| `permission_handler` | ^12.0.1 | Xin quyền truy cập thiết bị |
| `pinput` | ^5.0.2 | Widget nhập mã OTP |
| `fl_chart` | ^1.1.1 | Biểu đồ sức khỏe |
| `intl` | ^0.20.2 | Định dạng ngày giờ, số |
| `health` | ^13.2.0 | Đọc dữ liệu sức khỏe từ thiết bị |

---

## Hướng dẫn phát triển

### Thêm feature mới

1. Tạo thư mục trong `presentation/<feature>/` với cấu trúc:
   ```
   <feature>/
   ├── bloc/        # Event, State, Bloc/Cubit
   ├── view/        # Page + View widget
   └── widgets/     # Widget nhỏ dùng trong feature này
   ```
2. Tạo model trong `data/models/<feature>/` nếu cần.
3. Tạo service trong `data/services/` và repository trong `data/repositories/`.
4. Khai báo route trong [lib/core/routing/app_router.dart](lib/core/routing/app_router.dart).

### Thêm chỉ số sức khỏe mới

1. Thêm giá trị vào `MetricType` trong `data/enums/metric_type.dart`.
2. Tạo model trong `data/models/health/`.
3. Cập nhật service đọc dữ liệu thiết bị (`device_health_service.dart`).

### Quy ước code

- Mỗi BLoC chỉ xử lý một domain logic cụ thể.
- Không gọi API trực tiếp từ UI — luôn thông qua Repository.
- Dùng `Equatable` cho tất cả BLoC Event/State và Model.
- Chạy `flutter analyze` trước khi tạo PR.

### Tài khoản mock (development)

Khi chưa kết nối backend, ứng dụng dùng `MockAuthService`:
- **Email**: `admin@gmail.com`
- **Mật khẩu**: `admin`

### Kiểm thử

```bash
flutter test          # Chạy unit test
flutter analyze       # Kiểm tra code style
```

---

## Ghi chú / Troubleshooting

- **Hot-reload lỗi sau khi thêm BLoC provider**: thực hiện hot-restart (`R`).
- **404 khi tải `.env` trên Web**: đảm bảo đã khai báo `.env.*` trong `pubspec.yaml` assets → `flutter pub get` → chạy lại.
- **Sai API prefix**: đảm bảo `BASE_URL` trong `.env` không có trailing slash và đúng prefix backend yêu cầu.
- **OTP flow**: sau đăng ký / quên mật khẩu, app tự điều hướng sang màn hình OTP, xác thực xong sẽ redirect phù hợp.

### Google Sign-In (Web)

Đăng nhập Google trên Web dùng GIS credential flow (`renderButton`), yêu cầu đăng ký origin trong [Google Cloud Console](https://console.cloud.google.com/) → **APIs & Services** → **Credentials** → OAuth 2.0 Web client → **Authorized JavaScript origins**.

| Môi trường | Origin cần đăng ký |
|------------|---------------------|
| Development | `http://localhost:5000` |
| Production | `https://your-domain.com` |

> Khi release production: thêm domain thật vào authorized origins trước khi deploy.
>
> Lỗi `Error 400: origin_mismatch` = origin chưa được đăng ký hoặc chạy web không dùng `--web-port=5000`.

---

## Đóng góp

- Tạo branch từ `dev`, đặt tên theo convention: `feat/<tên-feature>` hoặc `fix/<tên-bug>`.
- Chạy `flutter analyze` và `flutter test` trước khi tạo PR.
- PR phải target branch `dev`, không push thẳng vào `master`.
