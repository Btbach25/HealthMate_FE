# Kiến trúc HealthMate FE

Tài liệu này giải thích **tại sao** code được sắp xếp như hiện tại, để bạn thêm
tính năng mới mà không phá vỡ cấu trúc. Xem [README.md](README.md) nếu bạn chỉ
cần chạy được app.

---

## 1. Ba lớp

```
┌─────────────────────────────────────────────────────────────┐
│  presentation/   Widget · Bloc/Cubit · Event · State        │
│                  Biết về UI. KHÔNG biết HTTP tồn tại.        │
├─────────────────────────────────────────────────────────────┤
│  data/           Repository · Service · Model · Exception    │
│                  Biết về HTTP/WebSocket/SharedPreferences.   │
│                  KHÔNG import gì từ presentation/.           │
├─────────────────────────────────────────────────────────────┤
│  core/           Config · DI · Routing · Theme · Widget dùng │
│                  chung · Util. KHÔNG phụ thuộc feature nào.  │
└─────────────────────────────────────────────────────────────┘
```

**Quy tắc phụ thuộc — chỉ được trỏ xuống dưới:**

| Lớp | Được import | Bị cấm import |
|---|---|---|
| `presentation/` | `core/`, `data/` | lẫn nhau giữa các feature (xem §5) |
| `data/` | `core/` | `presentation/` |
| `core/` | (không gì trong repo) | `data/`, `presentation/` |

Ngoại lệ duy nhất: `lib/core/di/app_dependencies.dart` import `data/` vì nó là
composition root (§3).

Dòng chảy dữ liệu một chiều:

```
Widget --event--> Bloc --gọi--> Repository --gọi--> Service --HTTP--> API
Widget <--state-- Bloc <--Model-- Repository <--Model-- Service <--JSON--
```

---

## 2. Vai trò từng thành phần

| Thành phần | Trách nhiệm | Không được làm |
|---|---|---|
| **Service** (`data/services/`) | Nói chuyện với đúng **một** nguồn dữ liệu (REST, WebSocket, SharedPreferences, Health Connect). Parse JSON → Model. | Chứa quy tắc nghiệp vụ |
| **Repository** (`data/repositories/`) | Điều phối nhiều service, cache, quyết định lấy dữ liệu từ đâu. Là API duy nhất mà Bloc được gọi. | Biết về `http.Response` |
| **Model** (`data/models/`) | Cấu trúc dữ liệu bất biến + `fromJson`/`toJson`. | Gọi mạng |
| **Bloc/Cubit** (`presentation/*/bloc/`) | Nhận Event → gọi Repository → phát State. | Gọi service/HTTP trực tiếp |
| **View/Page** (`presentation/*/view/`) | `*_page.dart` cung cấp Bloc; `*_view.dart` vẽ UI theo State. | Chứa logic nghiệp vụ |
| **Widget** (`presentation/*/widgets/`) | Mảnh UI tái sử dụng trong **một** feature. | Đọc Bloc của feature khác |

Widget dùng chung **nhiều feature** thì đặt ở `core/widgets/` và không được
phụ thuộc Bloc nào.

---

## 3. Composition root — `lib/core/di/app_dependencies.dart`

Đây là **nơi duy nhất** được phép `new` service và repository.

```dart
final dependencies = AppDependencies.bootstrap();   // main.dart
runApp(HealthMateApp(dependencies: dependencies));  // cắm vào cây widget
```

`bootstrap()` chọn một trong hai object graph dựa trên `AppConfig.isDemoMode`:

- **live** — service thật, gọi API tại `BASE_URL`.
- **demo** — mock service đọc dữ liệu từ `lib/data/mock_data/`, không phát sinh
  request mạng nào.

Nhờ vậy đổi nguồn dữ liệu chỉ cần sửa một file, không đụng tới UI. Đây cũng là
lý do mọi service đều nên có `abstract class` interface.

**Thêm dependency mới:**
1. Khai báo `final` field trong `AppDependencies`.
2. Khởi tạo ở cả nhánh live lẫn demo.
3. Nếu UI cần đọc, thêm `RepositoryProvider.value` tương ứng trong `lib/app.dart`.

---

## 4. Cấu hình & bí mật — `lib/core/config/`

- `app_config.dart` — **điểm truy cập duy nhất** cho biến môi trường. Không
  file nào khác được gọi `dotenv.env[...]` trực tiếp.
- `firebase_config.dart` — khởi tạo Firebase; Web đọc `FirebaseOptions` từ
  `.env`, mobile đọc từ `google-services.json` / `GoogleService-Info.plist`.

Không hard-code URL hay khoá trong `lib/`. Thêm biến mới:
thêm getter vào `AppConfig` → thêm dòng mô tả vào `.env.example`.

---

## 5. Vòng đời Bloc: app-level vs màn hình

| Đặt ở | Khi nào | Ví dụ |
|---|---|---|
| `lib/app.dart` | Sống suốt vòng đời app, nhiều màn hình cùng đọc | `AuthBloc`, `FamilyBloc`, `DeviceHealthCubit` |
| `*_page.dart` | Chỉ phục vụ một màn hình, cần tự huỷ khi rời màn hình | `StatsBloc`, `MedicationBloc`, `AuthFormBloc` |

Bloc app-level **phải tự dọn state khi đăng xuất** — màn hình tương ứng có thể
chưa mount nên không lắng nghe được sự kiện logout. Xem `_onAuthChanged` trong
`lib/app.dart` (nó bắn `ResetFamily` vì lý do này).

Pattern `*_page.dart` + `*_view.dart`:

```dart
// medication_page.dart — chỉ lo dependency
class MedicationPage extends StatelessWidget {
  Widget build(_) => BlocProvider(
        create: (ctx) => MedicationBloc(repository: ctx.read<MedicationRepository>()),
        child: const MedicationView(),
      );
}

// medication_view.dart — chỉ lo vẽ, dễ test widget vì không tự tạo Bloc
class MedicationView extends StatelessWidget { ... }
```

---

## 6. Điều hướng — `lib/core/routing/app_router.dart`

`go_router` với `refreshListenable` gắn vào `AuthBloc`: mọi thay đổi trạng thái
đăng nhập sẽ chạy lại `redirect`, tự đá về `/login` khi hết phiên.

Router được tạo **một lần** trong `initState` của `_AppView`. Tạo lại trong
`build()` sẽ reset toàn bộ navigation stack mỗi lần rebuild.

Thêm route mới → khai báo trong `app_router.dart`; thêm tab mới → xem
`lib/presentation/main_tabs/shell/view/app_shell.dart`.

---

## 7. Xử lý lỗi

`data/exceptions/api_exception.dart` định nghĩa cây exception theo status code
(`UnauthorizedException`, `ValidationException`, `NetworkException`, …).
`ApiClient` chuyển HTTP response → exception; Bloc bắt exception → chuyển thành
state lỗi; UI đọc state để hiện thông báo tiếng Việt.

**401 tự động refresh token:** `ApiClientImpl` gọi `onRefreshToken` rồi retry
đúng một lần, và bỏ qua chính endpoint `/auth/refresh` để tránh đệ quy vô hạn.

---

## 8. Code phụ thuộc nền tảng

Dùng pattern **conditional import** thay vì `if (kIsWeb)` rải rác:

```
prescription_ocr.dart        // export có điều kiện, phần còn lại của app chỉ import file này
├── prescription_ocr_io.dart   // mobile — google_mlkit_text_recognition
└── prescription_ocr_web.dart  // web    — Tesseract.js nạp từ CDN trong web/index.html
```

Tương tự với `google_web_button_stub.dart` / `google_web_button_impl.dart`.
Lý do: code `dart:js_interop` không compile được trên mobile và ngược lại.

---

## 9. Nợ kỹ thuật đã biết

| Vấn đề | Ghi chú |
|---|---|
| Một số view > 800 dòng | `family_group_management_view.dart`, `prescription_scan_dialog.dart`, `profile_settings_tab.dart` — nên tách dần thành widget con |
| `get_it` có trong pubspec nhưng chưa dùng | Hiện DI làm thủ công qua `AppDependencies`; hoặc dùng get_it, hoặc gỡ dependency |
| **Backend đang tắt, tên miền đã gỡ** | Chỉ chế độ demo chạy được. Dựng lại phải kèm HTTPS — xem README, mục "Kết nối lại backend" |
| `HomeRepository` vẫn dùng `MockHomeService` ở chế độ live | Chờ endpoint `/home` từ backend |
| Log chẩn đoán không bị loại khỏi bản release | `debugPrint` vẫn chạy ở release; `auth_service` đang in cả response body của login (chứa token). Vô hại lúc này vì bản deploy là demo, nhưng phải sửa TRƯỚC khi trỏ vào backend thật |
| `fontFamily: 'Inter'` nhưng pubspec bundle font `Lato` | Font Inter không tồn tại → đang fallback về font hệ thống. Sửa thì giao diện sẽ đổi, cần chủ động quyết định |
| Độ phủ test gần bằng 0 | Ưu tiên viết test cho `data/models` (fromJson) và các helper trong `core/utils` trước |
