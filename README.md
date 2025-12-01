# HealthMate FE (Flutter)

Một ứng dụng Flutter đa nền tảng (Android, iOS, Web, Desktop) cho sức khỏe cá nhân.

Lưu ý: Phần mô tả/giới thiệu chi tiết dự án sẽ được bổ sung sau.

## Nội dung

- Giới thiệu dự án
- Kiến trúc dự án
- Cài đặt & chạy dự án
- Quản lý môi trường (.env)
- Build & phát hành
- Cấu trúc thư mục
- Công nghệ sử dụng
- Ghi chú/Troubleshooting

---

## Giới thiệu dự án

HealthMate FE là frontend Flutter cho hệ thống theo dõi sức khỏe cá nhân. Ứng dụng cung cấp các tính năng đăng nhập/đăng ký kèm OTP, xem tổng quan sức khỏe, nhắc uống thuốc, thông báo gia đình…

> Placeholder: Bổ sung mô tả business/feature/ảnh chụp màn hình sau.

---

## Kiến trúc dự án

Ứng dụng sử dụng kiến trúc phân lớp + BLoC:

- `core/`: thành phần dùng chung (theme, helpers, định nghĩa dùng lại)
- `data/`: làm việc với dữ liệu
  - `models/`: các cấu trúc dữ liệu/domain models
  - `services/`: gọi API, lưu trữ local
  - `repositories/`: tổng hợp/điều phối nguồn dữ liệu (service + cache) cho UI
- `presentation/`: UI + State (Flutter + flutter_bloc)
  - `bloc/`: BLoC/Cubit quản lý luồng dữ liệu UI
  - `view/` + `widgets/`: màn hình và widget

Các quyết định chính:

- Quản lý trạng thái: `flutter_bloc`
- Điều hướng: `go_router`
- Biến môi trường: `flutter_dotenv`
- Lưu trữ local: `shared_preferences`

Ví dụ dòng chảy dữ liệu:

UI (Widget) ⇄ Bloc ⇄ Repository ⇄ Service ⇄ API

---

## Cài đặt & chạy dự án

Yêu cầu hệ thống:

- Flutter SDK 3.x (khuyến nghị mới nhất)
- Dart 2.17+
- Android Studio hoặc Xcode (tùy nền tảng)
- Trình duyệt Chrome để chạy Web

1) Clone và cài dependencies

```powershell
git clone https://github.com/<owner>/<repo>.git
cd HealthMate_FE
flutter doctor
flutter pub get
```

2) Tạo file môi trường

Tại thư mục gốc, tạo các file `.env` sau (đã được khai báo assets trong `pubspec.yaml`):

```
.env.dev
.env.prod
```

Nội dung tối thiểu:

```
# .env.dev
BASE_URL=http://localhost:8080/api/v1

# .env.prod
BASE_URL=https://api.yourdomain.com/api/v1
```

3) Chạy dự án

Web (Chrome):

```powershell
flutter run -d chrome --dart-define=ENV=dev
```

Android (thiết bị/thử nghiệm):

```powershell
flutter run -d <deviceId> --dart-define=ENV=dev
```

Lưu ý:

- Tham số `--dart-define=ENV=dev|prod` quyết định file `.env.<env>` sẽ được load.
- Nếu vừa thêm Provider mới mà hot-reload lỗi, hãy hot-restart.

---

## Quản lý môi trường (.env)

- Sử dụng `flutter_dotenv` để load biến môi trường làm asset (hỗ trợ Web).
- `main.dart` sẽ đọc biến `ENV` từ `--dart-define` và load tương ứng `.env.dev` hoặc `.env.prod`.
- Biến bắt buộc hiện tại:
  - `BASE_URL`: URL gốc API (bao gồm prefix nếu backend yêu cầu, ví dụ `/api/v1`).

Ví dụ sử dụng trong service:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

final baseUrl = dotenv.env['BASE_URL'];
```

---

## Build & phát hành

Android APK (dev/prod):

```powershell
flutter build apk --dart-define=ENV=prod
```

Web (dev/prod):

```powershell
flutter build web --dart-define=ENV=prod
```

iOS (yêu cầu macOS + Xcode):

```bash
flutter build ios --dart-define=ENV=prod
```

---

## Cấu trúc thư mục (rút gọn)

```
lib/
  core/
    theme/
    utils/
  data/
    models/
    repositories/
    services/
  presentation/
    auth/
    home/
    widgets/
  main.dart
assets/
  fonts/
  icons/
  images/
.env.dev
.env.prod
```

---

## Công nghệ sử dụng

- Flutter, Dart
- flutter_bloc, go_router
- flutter_dotenv, http, shared_preferences, intl, pinput, fl_chart

---

## Ghi chú / Troubleshooting

- ProviderNotFound sau hot-reload: thực hiện hot-restart.
- 404 khi tải `.env` trên Web: đảm bảo đã khai báo `.env.*` trong `pubspec.yaml` → `flutter pub get` → chạy lại.
- Khác biệt API prefix (`/api/v1`): đảm bảo biến `BASE_URL` đã bao gồm đúng prefix theo backend.
- Đăng nhập yêu cầu xác thực OTP: app sẽ điều hướng sang trang OTP theo flow (signup/login/forgot), xác thực xong sẽ điều hướng phù hợp.

---

## Đóng góp (Contribution)

- Format, phân nhánh, commit convention tùy dự án. Chạy `flutter analyze` trước khi gửi PR.
- Test cục bộ bằng `flutter test` khi có unit/widget tests.