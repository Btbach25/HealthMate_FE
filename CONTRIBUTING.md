# Hướng dẫn đóng góp

Cảm ơn bạn đã tham gia HealthMate. Tài liệu này mô tả quy trình làm việc; phần
"code được tổ chức ra sao" nằm ở [ARCHITECTURE.md](ARCHITECTURE.md).

---

## 1. Chuẩn bị môi trường

```bash
git clone <repo-url> && cd HealthMate_FE
make setup          # tạo .env từ .env.example + flutter pub get
```

Windows chưa có `make`? Dùng `.\tool\dev.ps1 setup` — mọi lệnh trong tài liệu
này đều có bản tương đương.

Chưa có backend? Chạy bằng dữ liệu giả lập:

```bash
make run-demo
```

---

## 2. Quy trình nhánh

```
master   ← chỉ nhận merge từ dev, là bản đang chạy thật
  ↑
dev      ← nhánh tích hợp, mọi PR đều target vào đây
  ↑
feat/… fix/… refactor/…
```

- Luôn tạo nhánh **từ `dev`**, không bao giờ push thẳng vào `master` hay `dev`.
- Đặt tên nhánh: `feat/<tên-tính-năng>`, `fix/<tên-lỗi>`, `refactor/<phạm-vi>`,
  `docs/<phạm-vi>`, `chore/<phạm-vi>`.
- Rebase/merge `dev` vào nhánh của bạn trước khi mở PR.

---

## 3. Trước khi mở PR

```bash
make check     # = dart format --set-exit-if-changed + flutter analyze + flutter test
```

CI chạy đúng ba lệnh này. PR có CI đỏ sẽ không được review.

---

## 4. Quy ước code

**Import** — luôn dùng đường dẫn tuyệt đối, không dùng `../`:

```dart
import 'package:fe/core/theme/app_colors.dart';   // ✅
import '../../core/theme/app_colors.dart';        // ❌
```

Thứ tự: `dart:` → `package:` (alphabet), cách nhau một dòng trống.

**Comment** — viết bằng tiếng Việt, và chỉ viết khi nó nói được điều mà code
không tự nói:

```dart
// ❌ Lặp lại code, vô giá trị
// Lấy danh sách thuốc
Future<List<Medication>> getMedications() { ... }

// ✅ Giải thích ràng buộc không hiển nhiên
/// BE giới hạn ~512 byte mỗi tin nhắn WebSocket → phải gửi subscribe theo lô nhỏ.
static const int _maxSubscribeItemsPerMessage = 2;
```

Mọi class/hàm **public** trong `core/widgets/`, `core/utils/`, `data/services/`,
`data/repositories/` phải có doc comment `///` nói rõ: dùng để làm gì, khi nào
nên tái sử dụng.

**Hằng số** — không hard-code số đo/màu trong widget. Dùng `AppSize`,
`AppColors`, `AppTextStyles` trong `lib/core/`.

**Cấu hình** — không hard-code URL/khoá. Thêm getter vào `AppConfig` và mô tả
biến mới trong `.env.example`.

**State** — dùng `Equatable` cho mọi Model, Event, State.

**Log** — dùng `debugPrint('[Tên] …')` với prefix nhất quán (`[Auth]`, `[API]`,
`[FCM]`, `[Settings]`…). `print()` bị chặn bởi analyzer.

**TUYỆT ĐỐI không log dữ liệu nhạy cảm.** `debugPrint` *không* bị Flutter loại
bỏ khi build release: mọi thứ nó in ra đều hiện trong Console của trình duyệt
(F12 → Console) và trong logcat. `main.dart` có chặn toàn bộ log ở bản release,
nhưng đó chỉ là lớp phòng thủ thứ hai — bản debug mà cả nhóm chạy hằng ngày thì
không có lớp đó.

```dart
// ❌ Response của /auth/* chứa access_token và refresh_token
debugPrint('[Auth] ← body=${response.body}');

// ✅ Đủ để chẩn đoán mà không lộ gì
debugPrint('[Auth] ← ${response.statusCode} (${response.body.length}B)');
```

Không log: token (access/refresh/FCM/idToken), response body, request body,
mật khẩu, email, tên người dùng, và bất kỳ chỉ số sức khoẻ nào. Cần biết cái gì
xảy ra thì log **hình dạng** chứ đừng log **nội dung**: status code, độ dài,
số phần tử, tên trường.

---

## 5. Thêm một tính năng mới

1. **UI** — tạo `lib/presentation/<feature>/` với `bloc/`, `view/`, `widgets/`.
   Tách `<feature>_page.dart` (cung cấp Bloc) và `<feature>_view.dart` (vẽ UI).
2. **Model** — `lib/data/models/<feature>/`, có `fromJson`/`toJson` + `Equatable`.
3. **Service** — viết `abstract class XService` + `ApiXService implements XService`
   trong `lib/data/services/`.
4. **Repository** — `lib/data/repositories/x_repository.dart`, nhận service qua
   constructor.
5. **Đăng ký** — thêm vào `lib/core/di/app_dependencies.dart` (cả nhánh live lẫn
   demo) và `RepositoryProvider` trong `lib/app.dart` nếu UI cần đọc.
6. **Route** — khai báo trong `lib/core/routing/app_router.dart`.
7. **Mock** — thêm `MockXService` + dữ liệu trong `lib/data/mock_data/` để chế độ
   demo vẫn xem được tính năng mới.

Bước 7 không phải tuỳ chọn: chế độ demo là cách người mới và người review xem
được tính năng mà không cần dựng backend.

---

## 6. Thêm một chỉ số sức khoẻ mới

1. Thêm giá trị vào `MetricType` (`lib/data/enums/metric_type.dart`) và phần
   extension đi kèm (nhãn tiếng Việt, đơn vị, icon, ngưỡng cảnh báo).
2. Tạo model trong `lib/data/models/health/`.
3. Cập nhật `device_health_service.dart` (đọc từ Health Connect/HealthKit) và
   `health_ws_service.dart` (`_metricMap`) nếu chỉ số này gửi realtime.
4. Thêm dữ liệu mẫu vào `lib/data/mock_data/`.

---

## 7. Commit & Pull Request

Commit theo [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(medications): thêm nhắc nhở theo giờ tuỳ chỉnh
fix(family): sửa lỗi 401 khi chuyển quyền sở hữu nhóm
refactor(core): gom cấu hình env vào AppConfig
docs(readme): bổ sung hướng dẫn chạy chế độ demo
```

PR nên có: mô tả thay đổi, cách kiểm thử thủ công, ảnh chụp màn hình nếu đụng
UI, và link tới issue liên quan.

---

## 8. Bảo mật

- **Không bao giờ commit `.env`**, `google-services.json` của môi trường thật,
  keystore, hay bất kỳ khoá riêng nào.
- Thêm biến môi trường mới thì phải cập nhật `.env.example` với giá trị **rỗng**
  và một dòng mô tả.
- Phát hiện khoá bị lộ trong lịch sử git → báo maintainer để thu hồi khoá, đừng
  chỉ xoá ở commit mới.
