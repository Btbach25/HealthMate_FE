<h1 align="center">HealthMate — Frontend</h1>

<p align="center">
  Ứng dụng Flutter đa nền tảng theo dõi sức khoẻ cá nhân và gia đình.<br>
  Android · iOS · Web
</p>

<p align="center">
  <a href="https://btbach25.github.io/HealthMate_FE/"><b>▶ Dùng thử trực tiếp trên trình duyệt</b></a>
</p>

<p align="center">
  <a href="https://github.com/Btbach25/HealthMate_FE/actions/workflows/ci.yml">
    <img alt="CI" src="https://github.com/Btbach25/HealthMate_FE/actions/workflows/ci.yml/badge.svg?branch=master">
  </a>
  <a href="https://github.com/Btbach25/HealthMate_FE/actions/workflows/deploy-demo.yml">
    <img alt="Deploy demo" src="https://github.com/Btbach25/HealthMate_FE/actions/workflows/deploy-demo.yml/badge.svg?branch=master">
  </a>
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.47.2-02569B?logo=flutter&logoColor=white">
</p>

<p align="center">
  <a href="#dùng-thử-ngay">Dùng thử</a> ·
  <a href="#cài-đặt-đầy-đủ">Cài đặt</a> ·
  <a href="#deploy">Deploy</a> ·
  <a href="ARCHITECTURE.md">Kiến trúc</a> ·
  <a href="CONTRIBUTING.md">Đóng góp</a> ·
  <a href="API_DOC.md">API</a>
</p>

---

> [!IMPORTANT]
> **Backend hiện chưa hoạt động.** Máy chủ API đã bị tắt và tên miền cũng đã gỡ,
> nên mọi tính năng cần dữ liệu thật (đăng nhập bằng tài khoản thật, đồng bộ chỉ
> số, nhóm gia đình, nhắc thuốc) tạm thời không dùng được.
>
> **Chế độ demo vẫn chạy bình thường** vì nó không gọi mạng —
> [dùng thử tại đây](https://btbach25.github.io/HealthMate_FE/) hoặc `make run-demo`.
>
> Khi dựng lại backend, xem [Kết nối lại backend](#kết-nối-lại-backend) bên dưới.

---

## Tính năng

| Nhóm | Mô tả |
|---|---|
| **Chỉ số sức khoẻ** | Nhịp tim, bước chân, calo, huyết áp, SpO₂, nhiệt độ, cân nặng — đồng bộ từ Health Connect (Android) / HealthKit (iOS), cập nhật realtime qua WebSocket |
| **Thống kê** | Biểu đồ 7 / 30 / 90 ngày cho từng chỉ số, kèm tóm tắt xu hướng |
| **Nhóm gia đình** | Tạo nhóm, mời thành viên, duyệt yêu cầu tham gia, phân quyền xem từng chỉ số, chuyển quyền chủ nhóm |
| **Nhắc uống thuốc** | Lịch uống theo ngày/giờ, chia sẻ thuốc cho người thân, push notification qua FCM |
| **Quét đơn thuốc (OCR)** | Chụp ảnh đơn thuốc → tự nhận diện tên thuốc, liều và tần suất |
| **Tài khoản** | Đăng nhập email/mật khẩu hoặc Google, xác thực OTP, quên/đặt lại mật khẩu |

---

## Dùng thử ngay

### Cách nhanh nhất — không cần cài gì

**https://btbach25.github.io/HealthMate_FE/**

Bản demo chạy trên trình duyệt bằng **dữ liệu giả lập**, không gọi backend, mở
là dùng được ngay. Email và mật khẩu đã được điền sẵn, chỉ cần bấm *Đăng nhập*.

### Hoặc chạy tại máy

```bash
git clone https://github.com/Btbach25/HealthMate_FE.git && cd HealthMate_FE
make setup
make run-demo
```

Đăng nhập bằng tài khoản demo:

```
Email    : demo@healthmate.vn
Mật khẩu : demo1234
Mã OTP   : 123456
```

Chế độ demo dùng toàn bộ dữ liệu trong [`lib/data/mock_data/`](lib/data/mock_data/)
và **không phát sinh request mạng nào**. Đây là cách nhanh nhất để xem hết tính
năng — dùng khi onboarding người mới hoặc review PR mà chưa dựng backend.

> **Windows chưa cài `make`?** Mọi lệnh đều có bản PowerShell tương đương:
> `.\tool\dev.ps1 setup`, `.\tool\dev.ps1 run-demo`, …

---

## Cài đặt đầy đủ

### Yêu cầu

| Thành phần | Phiên bản |
|---|---|
| Flutter SDK | **3.47.2** (bản đã kiểm chứng; CI pin đúng bản này) |
| Dart SDK | 3.13+ (đi kèm Flutter) |
| Android | SDK API 21+ |
| iOS | macOS + Xcode 15+ + CocoaPods |
| Web | Chrome |

Kiểm tra môi trường: `make doctor`

### Các bước

```bash
git clone https://github.com/Btbach25/HealthMate_FE.git && cd HealthMate_FE
make setup            # tạo .env từ .env.example + flutter pub get
```

Mở `.env` và điền:

```dotenv
BASE_URL=http://<địa-chỉ-api-gateway>          # KHÔNG có dấu / ở cuối
GOOGLE_CLIENT_ID=<oauth-web-client-id>.apps.googleusercontent.com
DEMO_MODE=false
```

Rồi chạy:

```bash
make run          # thiết bị / emulator đang kết nối
make run-web      # Chrome, cố định port 5000 cho Google OAuth
```

> **Quan trọng:** `.env` được khai báo là *asset* trong `pubspec.yaml` nên
> **bắt buộc phải tồn tại**, thiếu là build báo lỗi asset. `make setup` tạo sẵn
> cho bạn. File này **không được commit**.

---

## Bảng lệnh

Xem đầy đủ bằng `make` (hoặc `.\tool\dev.ps1`).

| Lệnh | Việc |
|---|---|
| `make setup` | Cài đặt lần đầu sau khi clone |
| `make run` · `make run-web` | Chạy app (API thật) |
| `make run-demo` · `make run-web-demo` | Chạy app bằng dữ liệu giả lập |
| `make check` | `dart format` + `flutter analyze` + `flutter test` — **chạy trước khi mở PR** |
| `make fmt` | Format toàn bộ code |
| `make build-apk` · `build-aab` · `build-web` | Build bản release |
| `make build-demo-apk` · `build-demo-web` | Build bản demo mock data để chia sẻ |
| `make adb-reverse` | Trỏ `localhost:8080` của máy Android thật về máy tính |
| `make icons` · `make splash` | Sinh lại app icon / splash screen |
| `make reset` | `clean` + `pub get` khi build lỗi lạ |

---

## Cấu hình môi trường

Toàn bộ URL và khoá nằm trong `.env` (không commit). Template đầy đủ kèm mô tả
từng biến: [`.env.example`](.env.example).

| Biến | Bắt buộc | Ý nghĩa |
|---|---|---|
| `BASE_URL` | ✅ | URL gốc api-gateway, không có `/` ở cuối. **Hiện chưa có giá trị dùng được — backend đang tắt.** |
| `GOOGLE_CLIENT_ID` | ✅ | OAuth 2.0 **Web** client ID (mobile dùng lại qua `serverClientId`) |
| `DEMO_MODE` | — | `true` → chạy bằng mock data |
| `FIREBASE_*` | Chỉ Web | `FirebaseOptions` cho push notification trên trình duyệt |

Trong code, **chỉ đọc cấu hình qua [`AppConfig`](lib/core/config/app_config.dart)** —
không gọi `dotenv.env[...]` trực tiếp ở bất kỳ đâu khác.

Chọn `BASE_URL` theo môi trường chạy:

| Chạy ở đâu | `BASE_URL` |
|---|---|
| Backend đã deploy | `http://<ip-hoặc-domain>` |
| Web / desktop, backend local | `http://localhost:8080` |
| Android **emulator** | `http://10.0.2.2:8080` (`localhost` là chính máy ảo) |
| Android **máy thật** qua USB | `make adb-reverse` rồi dùng `http://localhost:8080` |

> Sửa `.env` xong phải **hot-restart** (`R`), không phải hot-reload — asset chỉ
> được đọc một lần lúc khởi động.

---

## Cấu trúc thư mục

```
lib/
├── main.dart                 # entry point: nạp config → dựng dependency → runApp
├── app.dart                  # root widget: Provider + MaterialApp.router + auth listener
│
├── core/                     # dùng chung, KHÔNG phụ thuộc feature nào
│   ├── config/               # AppConfig (biến môi trường) · khởi tạo Firebase
│   ├── di/                   # AppDependencies — composition root duy nhất
│   ├── routing/              # GoRouter + auth guard
│   ├── theme/                # AppTheme · AppColors · AppTextStyles
│   ├── constants/            # AppSize, AppStyles
│   ├── widgets/              # widget dùng chung nhiều feature
│   ├── utils/                # helper thuần (converter, validation, toast, …)
│   ├── mixins/               # mixin tái sử dụng
│   ├── allergy/              # đối chiếu dị ứng thuốc
│   └── prescription/         # OCR đơn thuốc (conditional import io/web)
│
├── data/                     # dữ liệu — KHÔNG import gì từ presentation/
│   ├── core/                 # ApiClient (base) + ApiClientImpl (token, retry 401)
│   ├── models/               # model bất biến + fromJson/toJson
│   ├── enums/                # MetricType, UserRole, GroupMemberStatus, …
│   ├── exceptions/           # cây ApiException theo status code
│   ├── services/             # gọi REST / WebSocket / SharedPreferences / Health Connect
│   ├── repositories/         # điều phối service, là API duy nhất Bloc được gọi
│   └── mock_data/            # dữ liệu giả lập cho chế độ demo
│
└── presentation/             # UI + state, mỗi feature một thư mục
    ├── auth/                 # đăng nhập, đăng ký, OTP, quên mật khẩu
    ├── home/                 # tổng quan sức khoẻ hôm nay
    ├── details/              # thống kê chi tiết theo chỉ số
    ├── family/               # nhóm gia đình
    ├── medications/          # thuốc, nhắc nhở, OCR đơn
    ├── settings/             # cài đặt tài khoản, thông báo, bảo mật, đồng bộ
    └── main_tabs/            # shell bottom-navigation
```

Mỗi feature trong `presentation/` theo cùng một khuôn:

```
<feature>/
├── bloc/       # <feature>_bloc.dart · _event.dart · _state.dart
├── view/       # <feature>_page.dart (cung cấp Bloc) + <feature>_view.dart (vẽ UI)
└── widgets/    # widget riêng của feature này
```

Quy tắc phụ thuộc giữa các lớp, vòng đời Bloc, cách thêm tính năng mới:
xem **[ARCHITECTURE.md](ARCHITECTURE.md)**.

---

## Điều hướng

| Tab | Route | Màn hình |
|---|---|---|
| Tổng quan | `/home` | Chỉ số sức khoẻ hôm nay |
| Gia đình | `/family` | Nhóm gia đình |
| Chỉ số | `/stats` | Thống kê dài hạn |
| Thuốc | `/medications` | Lịch uống thuốc |
| Cài đặt | `/settings` | Tài khoản và tuỳ chọn |

Router tự redirect về `/login` khi chưa đăng nhập hoặc phiên hết hạn —
[`app_router.dart`](lib/core/routing/app_router.dart).

---

## Công nghệ chính

| Package | Dùng để |
|---|---|
| `flutter_bloc` · `bloc` · `equatable` | State management |
| `go_router` | Điều hướng khai báo + auth guard |
| `http` · `web_socket_channel` | REST + realtime |
| `shared_preferences` | Lưu token và hồ sơ ở local |
| `flutter_dotenv` | Nạp `.env` (chạy được cả trên Web) |
| `health` · `permission_handler` | Health Connect / HealthKit |
| `firebase_core` · `firebase_messaging` | Push notification |
| `google_sign_in` · `google_sign_in_web` | Đăng nhập Google |
| `google_mlkit_text_recognition` · `image_picker` | OCR đơn thuốc (mobile) |
| `fl_chart` | Biểu đồ |
| `pinput` · `intl` | Nhập OTP · định dạng tiếng Việt |

Danh sách đầy đủ kèm ghi chú: [`pubspec.yaml`](pubspec.yaml).

---

## Đăng nhập Google

Dùng GIS credential flow. Phải đăng ký origin trong
[Google Cloud Console](https://console.cloud.google.com/) →
**APIs & Services** → **Credentials** → OAuth 2.0 Web client →
**Authorized JavaScript origins**:

| Môi trường | Origin |
|---|---|
| Development | `http://localhost:5000` |
| Production | `https://<domain-thật>` |

Client ID lấy được điền vào `GOOGLE_CLIENT_ID` trong `.env`. Trên Android/iOS,
cùng client ID này được dùng làm `serverClientId` để backend verify `idToken`.

---

## Push notification (Firebase)

- **Android / iOS** — đọc cấu hình từ `android/app/google-services.json` và
  `ios/Runner/GoogleService-Info.plist`. Đây là *client config*, không phải khoá
  bí mật, nhưng đổi project Firebase thì phải thay hai file này.
- **Web** — bắt buộc truyền `FirebaseOptions` thủ công; điền các biến
  `FIREBASE_*` trong `.env`. Thiếu thì app vẫn chạy bình thường, chỉ không có
  push notification.

---

## Deploy

Có hai đường, dùng cái nào cũng được — hoặc cả hai.

### A. GitHub Pages — bản demo, không cần cài gì

Đã có sẵn workflow [`.github/workflows/deploy-demo.yml`](.github/workflows/deploy-demo.yml).
Bật một lần rồi thôi:

1. **Settings → Pages → Source** chọn **GitHub Actions**.
2. Đẩy lên `master` (hoặc chạy tay workflow *Deploy demo lên GitHub Pages*).
3. URL nhận được: **https://btbach25.github.io/HealthMate_FE/**

Bản này build với `--dart-define=DEMO_MODE=true` nên chạy hoàn toàn bằng mock
data: **không gọi backend, không cần secret, an toàn để public**. Đây là bản
nên gửi cho người khác xem thử hoặc gắn vào README/CV.

> `--base-href` được đặt tự động theo tên repo. Đổi tên repo thì không phải sửa gì.

### B. Firebase Hosting — bản chạy API thật

Dự án đã có sẵn [`firebase.json`](firebase.json) và [`.firebaserc`](.firebaserc)
trỏ tới project `healthmate-6734d` (SPA rewrite + cache header đã cấu hình).

Cần Firebase CLI. Máy không có Node vẫn cài được bằng bản standalone:

```powershell
# Windows — tải firebase-tools-instant-win.exe từ https://firebase.tools
# hoặc nếu đã có Node:
npm install -g firebase-tools
```

Rồi:

```bash
firebase login
make deploy-demo     # bản mock data
make deploy-web      # bản gọi API thật tại BASE_URL
```

**Trước khi deploy bản API thật, đọc kỹ:**

- **`.env` được deploy nguyên văn thành một file tĩnh đọc được công khai.**
  `flutter build web` copy nó thành `build/web/assets/.env`, nên bất kỳ ai cũng
  mở được `https://<domain>/assets/.env` và đọc toàn bộ — kể cả comment. Đây
  không phải "nhúng vào JavaScript đã minify" mà là plain text ở đường dẫn đoán
  được. Hệ quả:
  - Chỉ để trong `.env` những giá trị **vốn dĩ đã public** (`BASE_URL`,
    OAuth *Web* client ID). Tuyệt đối không có khoá server, secret, token.
  - Trước khi build bản public, kiểm tra lại file sẽ ship:
    ```bash
    flutter build web --release && cat build/web/assets/.env
    ```
  - Workflow GitHub Pages đã an toàn sẵn: nó dựng `.env` từ `.env.example`
    (toàn giá trị rỗng) nên không có gì rò rỉ.
- Backend phải bật CORS cho domain vừa deploy, nếu không mọi request đều chết ở
  preflight.
- Domain mới phải được thêm vào **Authorized JavaScript origins** của OAuth Web
  client, nếu không đăng nhập Google sẽ báo `Error 400: origin_mismatch`.
- `BASE_URL` đang là `http://` mà trang deploy là `https://` → trình duyệt chặn
  mixed content. Backend phải có HTTPS trước khi deploy bản API thật.

### Điều kiện bắt buộc: backend phải chạy HTTPS

Trang deploy luôn được phục vụ qua `https://` (GitHub Pages, Firebase Hosting,
Netlify… đều ép HTTPS). Trình duyệt **chặn thẳng** mọi request từ trang HTTPS
sang `http://`, gọi là *mixed content* — không có cách nào tắt cho người dùng
cuối. Vì vậy `BASE_URL` phải là `https://` trước khi deploy bản live.

Trở ngại: **Let's Encrypt không cấp chứng chỉ cho địa chỉ IP trần.** Phải có
tên miền. Ba cách, xếp theo độ dễ:

**1. Cloudflare Tunnel — không cần mở cổng, không cần quản lý chứng chỉ**

```bash
# trên máy chủ backend
cloudflared tunnel --url http://localhost:8080
```

Trả về ngay một địa chỉ `https://<ngẫu-nhiên>.trycloudflare.com`. Đủ để demo,
nhưng địa chỉ đổi mỗi lần chạy lại. Muốn cố định thì gắn một domain vào
Cloudflare rồi tạo named tunnel.

**2. Caddy + tên miền — HTTPS tự động, phù hợp cho chạy thật**

Tên miền miễn phí lấy ở [DuckDNS](https://www.duckdns.org) (trỏ về IP máy chủ),
rồi trên máy chủ:

```caddyfile
# /etc/caddy/Caddyfile
healthmate.duckdns.org {
    reverse_proxy localhost:8080
}
```

```bash
sudo systemctl reload caddy
```

Caddy tự xin và tự gia hạn chứng chỉ Let's Encrypt. Cần mở cổng 80 và 443.

**3. AWS ALB + ACM** — nếu backend chạy trên EC2. Chứng chỉ miễn phí nhưng
Load Balancer tốn khoảng 16 USD/tháng, vẫn phải có tên miền.

> **Cách chữa cháy KHÔNG nên dùng lâu dài:** Netlify/Vercel cho phép rewrite
> `/api/*` sang `http://<ip>/...` phía máy chủ, nên trình duyệt chỉ thấy HTTPS
> và hết báo mixed content. Nhưng chặng từ proxy tới backend **vẫn là plaintext**
> — access token và dữ liệu sức khoẻ đi trần trên Internet. Với một ứng dụng y
> tế thì đây chỉ là giải pháp tạm trong lúc dựng HTTPS thật.

### Sau khi backend đã có HTTPS

Bốn việc, thiếu một là hỏng:

1. `.env` → `BASE_URL=https://<tên-miền>` (không có `/` ở cuối).
2. Backend bật CORS cho đúng origin của trang FE (`https://btbach25.github.io`).
3. Thêm origin đó vào **Authorized JavaScript origins** của OAuth Web client,
   nếu không đăng nhập Google báo `Error 400: origin_mismatch`.
4. Build lại rồi deploy — `.env` cũ đã nằm trong bundle, không sửa lại là vẫn
   trỏ về địa chỉ cũ.

### Nền tảng khác

`build/web` là thư mục tĩnh thuần, kéo thả lên Netlify / Vercel / Cloudflare
Pages đều chạy. Chỉ cần cấu hình rewrite mọi đường dẫn về `/index.html` (SPA).

---

## Kết nối lại backend

Backend đang tắt. Khi dựng lại, làm đủ các bước sau — thiếu bước nào là hỏng
bước đó, không phải lỗi frontend:

1. **Dựng lại API gateway** và mở cổng cho truy cập từ ngoài (kiểm tra cả
   firewall lẫn security group của nhà cung cấp).

2. **Cấp HTTPS cho backend.** Bắt buộc, không phải tuỳ chọn: trang FE chạy trên
   `https://` nên trình duyệt chặn thẳng mọi request sang `http://`. Xem
   [Điều kiện bắt buộc: backend phải chạy HTTPS](#điều-kiện-bắt-buộc-backend-phải-chạy-https).
   Vì Let's Encrypt không cấp chứng chỉ cho IP trần nên cần một tên miền mới —
   tên miền cũ đã bị gỡ.

3. **Cập nhật `BASE_URL`** trong `.env` thành tên miền HTTPS mới.

4. **Bật CORS** ở backend cho origin của trang FE
   (`https://btbach25.github.io`).

5. **Đăng ký lại OAuth origin.** Google Cloud Console → Credentials → OAuth Web
   client → *Authorized JavaScript origins*. Thiếu bước này thì đăng nhập Google
   báo `Error 400: origin_mismatch`.

6. **Kiểm tra lại trước khi công bố:** `curl -I https://<tên-miền-mới>` phải trả
   về mã 2xx/3xx, không phải timeout.

Trong lúc chờ, mọi thứ vẫn phát triển tiếp được bằng chế độ demo — xem
[Dùng thử ngay](#dùng-thử-ngay).

---

## Troubleshooting

| Triệu chứng | Nguyên nhân và cách xử lý |
|---|---|
| Build báo thiếu asset `.env` | Chưa tạo `.env` → chạy `make setup` |
| Emulator Android gọi API luôn timeout | `BASE_URL` đang là `localhost` → đổi sang `http://10.0.2.2:8080` |
| Máy Android thật không gọi được backend local | `make adb-reverse`, giữ cáp USB, bật USB debugging |
| Web báo lỗi CORS / `err_failed` | App và API khác origin. Dùng `localhost` cho cả hai, hoặc bật CORS ở gateway |
| `Error 400: origin_mismatch` khi đăng nhập Google | Origin chưa đăng ký, hoặc chạy web không dùng `--web-port=5000` |
| Nút Google không hiện trên Web | `GOOGLE_CLIENT_ID` rỗng trong `.env` |
| Sửa `.env` mà không thấy tác dụng | Hot-reload không nạp lại asset → hot-restart (`R`) |
| Hot-reload lỗi sau khi thêm Bloc provider | Hot-restart (`R`) |
| Build lỗi linh tinh sau khi đổi nhánh | `make reset` |
| Không đọc được dữ liệu sức khoẻ trên Android | Máy chưa cài Health Connect, hoặc chưa cấp quyền trong Cài đặt |

---

## Đóng góp

Đọc **[CONTRIBUTING.md](CONTRIBUTING.md)** trước khi mở PR. Tóm tắt:

- Tạo nhánh từ `dev`: `feat/…`, `fix/…`, `refactor/…`
- Chạy `make check` — CI chạy đúng bộ lệnh này
- PR target `dev`, không push thẳng vào `master`
- Tính năng mới nên kèm mock data để chế độ demo vẫn xem được
