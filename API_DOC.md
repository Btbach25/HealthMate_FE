# HealthMate — API Documentation for Frontend

## Base URL

Tất cả request đều đi qua **Nginx Gateway**:

```
http://localhost:8080
```

> Swagger UI chi tiết:
> - Auth & Group: `http://localhost:8080/auth/swagger/index.html`
> - Realtime: `http://localhost:5001/swagger/index.html`

---

## Authentication

Hầu hết các API yêu cầu JWT trong header:

```
Authorization: Bearer <access_token>
```

Token có được sau khi đăng nhập (Google hoặc Email/Password).

---

## Response format chung

**Success:**
```json
{ "message": "..." }
```

**Error:**
```json
{ "error": "mô tả lỗi" }
```

---

## 1. Auth APIs

Base path: `/auth/*`
Proxy tới `auth-service` (port 5000). Prefix thực tế: `/api/v1/auth/...`

### 1.1 Đăng ký tài khoản

```
POST /auth/register
```

**Body:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "name": "Nguyen Van A"
}
```

**Response 201:**
```json
{
  "message": "Registration successful. Please check your email to verify your account.",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "name": "Nguyen Van A",
    "role": "user",
    "status": "unverified",
    "created_at": "...",
    "updated_at": "..."
  }
}
```

> Sau khi đăng ký, user nhận OTP qua email. Phải xác thực OTP mới dùng được.

---

### 1.2 Xác thực OTP

```
POST /auth/otp/verify
```

**Body:**
```json
{
  "email": "user@example.com",
  "otp": "123456"
}
```

**Response 200:** Trả về `access_token`, `refresh_token` và thông tin user (tương tự login).

---

### 1.3 Gửi lại OTP

```
POST /auth/otp/resend
```

**Body:**
```json
{
  "email": "user@example.com"
}
```

**Response 200:**
```json
{ "message": "If your account exists and hasn't been verified yet, we've sent you a new OTP..." }
```

---

### 1.4 Đăng nhập Email/Password

```
POST /auth/app
```

**Body:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response 200:**
```json
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "name": "Nguyen Van A",
    "picture": "",
    "role": "user",
    "status": "verified",
    "created_at": "...",
    "updated_at": "..."
  }
}
```

> Lưu `access_token` và `refresh_token` vào storage (localStorage / SecureStorage).

---

### 1.5 Đăng nhập Google

```
POST /auth/google
```

**Body:**
```json
{
  "id_token": "<Google ID Token từ Google Sign-In SDK>"
}
```

**Response 200:** Tương tự 1.4.

---

### 1.6 Làm mới Access Token

```
POST /auth/refresh
```

**Body:**
```json
{
  "refresh_token": "eyJ..."
}
```

**Response 200:**
```json
{
  "access_token": "eyJ..."
}
```

> Gọi API này khi `access_token` hết hạn (nhận lỗi 401).

---

### 1.7 Đăng xuất

```
POST /auth/logout
```
**Header:** `Authorization: Bearer <access_token>`

**Body:**
```json
{
  "refresh_token": "eyJ..."
}
```

**Response 200:**
```json
{ "message": "Logged out successfully" }
```

---

### 1.8 Đặt mật khẩu (dành cho user đăng nhập Google muốn thêm mật khẩu)

```
POST /auth/password
```
**Header:** `Authorization: Bearer <access_token>`

**Body:**
```json
{
  "password": "newpassword123"
}
```

**Response 200:**
```json
{ "message": "password set successfully" }
```

---

## 2. User APIs

Base path: `/users/*`
**Header bắt buộc:** `Authorization: Bearer <access_token>`

---

### 2.1 Lấy profile của tôi

```
GET /users/profile
```

**Response 200:**
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "name": "Nguyen Van A",
  "picture": "",
  "role": "user",
  "status": "verified",
  "phone": "0901234567",
  "address": "Hanoi, Vietnam",
  "gender": "male",
  "birthday": "1995-08-20",
  "weight": 65.5,
  "height": 170.0,
  "blood_group": "O+",
  "created_at": "...",
  "updated_at": "..."
}
```

> Các field `phone`, `address`, `gender`, `birthday`, `weight`, `height`, `blood_group` chỉ có khi đã được cập nhật.

---

### 2.2 Cập nhật profile của tôi

```
PUT /users/profile
```

**Body:** (tất cả optional — chỉ gửi field cần thay đổi)
```json
{
  "name":        "Nguyen Van A",
  "picture":     "https://...",
  "phone":       "0901234567",
  "address":     "Hanoi, Vietnam",
  "gender":      "male",
  "birthday":    "1995-08-20",
  "weight":      65.5,
  "height":      170.0,
  "blood_group": "O+"
}
```

**Response 200:** `(empty body)`

---

### 2.3 Tìm kiếm / danh sách người dùng

```
GET /users?search=keyword&limit=20&offset=0
```

| Query param | Kiểu   | Mô tả |
|-------------|--------|-------|
| `search`    | string | Tìm theo tên hoặc email (optional) |
| `limit`     | int    | Số lượng kết quả (mặc định 20) |
| `offset`    | int    | Vị trí bắt đầu (mặc định 0) |

**Response 200:** `[User]` — mảng User (tương tự 2.1, có thể thiếu profile fields)

---

## 3. Group APIs

Base path: `/groups/*`
**Header bắt buộc:** `Authorization: Bearer <access_token>`

---

### 2.1 Tạo nhóm

```
POST /groups
```

**Body:**
```json
{
  "name": "Gia dinh toi",
  "description": "Nhom theo doi suc khoe gia dinh"
}
```

**Response 201:**
```json
{
  "id": "uuid",
  "name": "Gia dinh toi",
  "description": "Nhom theo doi suc khoe gia dinh",
  "owner_id": "uuid",
  "created_at": "...",
  "updated_at": "..."
}
```

---

### 2.2 Danh sách nhóm của tôi

```
GET /groups
```

**Response 200:** `[Group]`

---

### 2.3 Lấy thông tin nhóm

```
GET /groups/:id
```

**Response 200:** `Group`

---

### 2.4 Cập nhật nhóm (Owner)

```
PUT /groups/:id
```

**Body:** (tất cả optional)
```json
{
  "name": "Tên mới",
  "description": "Mô tả mới"
}
```

**Response 200:**
```json
{ "message": "Group updated successfully" }
```

---

### 2.5 Xóa nhóm (Owner)

```
DELETE /groups/:id
```

**Response 200:**
```json
{ "message": "Group deleted successfully" }
```

---

### 2.6 Mời thành viên

```
POST /groups/:id/members
```

**Body:**
```json
{
  "email": "member@example.com"
}
```

**Response 200:**
```json
{ "message": "Invitation sent" }
```

---

### 2.7 Danh sách thành viên

```
GET /groups/:id/members
```

**Response 200:**
```json
[
  {
    "group_id": "uuid",
    "user_id": "uuid",
    "role": "owner | member",
    "status": "pending | accepted | rejected",
    "invited_by": "uuid",
    "joined_at": "...",
    "created_at": "...",
    "updated_at": "..."
  }
]
```

---

### 2.8 Chấp nhận / Từ chối lời mời

```
PUT /groups/:id/members/me
```

**Body:**
```json
{
  "status": "accepted"
}
```
> `status` chỉ nhận `"accepted"` hoặc `"rejected"`.

**Response 200:**
```json
{ "message": "Membership status updated" }
```

---

### 2.9 Rời nhóm

```
DELETE /groups/:id/members/me
```

**Response 200:**
```json
{ "message": "Left group successfully" }
```

---

### 2.10 Kick thành viên (Owner)

```
DELETE /groups/:id/members/:member_id
```

> `:member_id` là `user_id` của thành viên cần kick.

**Response 200:**
```json
{ "message": "Member removed" }
```

---

### 2.11 Chuyển quyền Owner

```
PUT /groups/:id/owner
```

**Body:**
```json
{
  "new_owner_id": "uuid-cua-thanh-vien"
}
```

**Response 200:**
```json
{ "message": "Ownership transferred successfully" }
```

---

### 2.12 Danh sách lời mời đang chờ (của tôi)

```
GET /groups/invitations
```

**Response 200:**
```json
[
  {
    "id": "uuid",
    "group_id": "uuid",
    "sent_at": "...",
    "member_count": 5,
    "shared_metrics": ["heart_rate", "steps_count"],
    "group": {
      "id": "uuid",
      "name": "Gia dinh toi",
      "member_count": 5
    },
    "inviter": {
      "id": "uuid",
      "name": "Nguyen Van A",
      "email": "a@example.com"
    }
  }
]
```

---

### 2.13 Danh sách metric types có thể chia sẻ

```
GET /groups/metric-types
```

**Response 200:**
```json
["heart_rate", "steps_count", "calories_burned", "blood_pressure", "spo2"]
```

---

### 2.14 Xem quyền chia sẻ của tôi trong nhóm

```
GET /groups/:id/permissions
```

**Response 200:**
```json
[
  { "group_id": "uuid", "user_id": "uuid", "metric_type": "heart_rate" },
  { "group_id": "uuid", "user_id": "uuid", "metric_type": "steps_count" }
]
```

---

### 2.15 Bật/tắt chia sẻ một loại metric

```
POST /groups/:id/permissions
```

**Body:**
```json
{
  "metric_type": "heart_rate",
  "enabled": true
}
```

**Response 200:**
```json
{ "message": "Permission updated" }
```

---

### 2.16 Cập nhật toàn bộ danh sách metric chia sẻ

```
PUT /groups/:id/permissions
```

**Body:**
```json
{
  "metric_types": ["heart_rate", "steps_count"]
}
```
> Danh sách này sẽ **thay thế hoàn toàn** permissions hiện tại.

**Response 200:**
```json
{ "message": "Permissions updated" }
```

---

## 4. Real-time WebSocket

**Endpoint:** `ws://localhost:8080/ws?token=<access_token>`

> Kết nối qua Nginx. Không dùng header `Authorization` — token truyền qua query string.

---

### Kết nối

```js
const ws = new WebSocket(`ws://localhost:8080/ws?token=${accessToken}`);
```

---

### Message từ Client gửi lên Server

**Dạng 1 — Subscribe/Unsubscribe (nhận dữ liệu của user khác):**

```json
{
  "action": "subscribe",
  "items": [
    {
      "target_user_id": "uuid-cua-nguoi-duoc-theo-doi",
      "metric_type": "heart_rate"
    }
  ]
}
```

```json
{
  "action": "unsubscribe",
  "items": [
    {
      "target_user_id": "uuid",
      "metric_type": "heart_rate"
    }
  ]
}
```

> Yêu cầu: user phải có permission (được cấp trong nhóm) mới subscribe được.

**Dạng 2 — Push metric (gửi dữ liệu của chính mình lên):**

```json
{
  "user_id": "uuid-cua-ban",
  "metric_type": "heart_rate",
  "value": 75.0,
  "timestamp": "2026-03-07T10:00:00Z"
}
```

> `timestamp` có thể bỏ qua — server sẽ tự điền thời gian hiện tại.
> `user_id` **phải trùng** với user trong JWT, không thể push thay người khác.

---

### Message từ Server gửi về Client

```json
{
  "type": "success | error | metric",
  "payload": "..."
}
```

| `type`    | Ý nghĩa |
|-----------|---------|
| `success` | Thao tác thành công (subscribe/unsubscribe) |
| `error`   | Lỗi (không có quyền, sai format...) |
| `metric`  | Dữ liệu metric broadcast từ user được theo dõi |

**Ví dụ payload metric broadcast:**
```json
{
  "user_id": "uuid",
  "metric_type": "heart_rate",
  "value": 75.0,
  "timestamp": "2026-03-07T10:00:00Z"
}
```

---

## 5. Metrics API

Base path: `/metrics` — qua Nginx proxy tới `storage-service`.
**Header bắt buộc:** `Authorization: Bearer <access_token>`

---

### 5.1 Lấy dữ liệu biểu đồ sức khỏe theo range

```
GET /metrics/charts
```

**Query params:**

| Param | Kiểu | Bắt buộc | Mô tả |
|-------|------|----------|-------|
| `user_id` | string | ✅ | UUID của user cần lấy data |
| `metric_type` | string | ✅ | Loại chỉ số: `heart_rate`, `steps_count`, `calories_burned`, `blood_pressure`, `spo2` |
| `range` | string | ✅ | Khoảng thời gian: `24h`, `7d`, `30d`, hoặc `custom` |
| `start_time` | string | Chỉ khi `range=custom` | Thời gian bắt đầu, định dạng RFC3339 (VD: `2026-03-01T00:00:00Z`) |
| `end_time` | string | Chỉ khi `range=custom` | Thời gian kết thúc, định dạng RFC3339 |

**Bucket size tự động theo range:**

| Range | Bucket |
|-------|--------|
| `24h` | 15 phút |
| `7d` | 1 ngày |
| `30d` | 1 ngày |
| `custom` (≤ 2 ngày) | 1 giờ |
| `custom` (≤ 30 ngày) | 1 ngày |
| `custom` (≤ 365 ngày) | 1 tuần |

**Ví dụ request:**
```
GET /metrics/charts?user_id=uuid&metric_type=heart_rate&range=7d
GET /metrics/charts?user_id=uuid&metric_type=steps_count&range=custom&start_time=2026-03-01T00:00:00Z&end_time=2026-03-19T00:00:00Z
```

**Response 200:**
```json
{
  "data": [
    { "timestamp": "2026-03-13T00:00:00Z", "value": 75.0 },
    { "timestamp": "2026-03-14T00:00:00Z", "value": 78.5 },
    { "timestamp": "2026-03-15T00:00:00Z", "value": 72.0 }
  ]
}
```

**Response 400:** Thiếu `user_id`, `metric_type`, hoặc `start_time`/`end_time` khi dùng `range=custom`.

---

### 5.2 Dự đoán điểm sẵn sàng thể chất

```
POST /metrics/readiness
```

**Body:**
```json
{
  "heart_rate":       75.0,
  "sleep_duration":   7.5,
  "stress_level":     "Low",
  "blood_oxygen":     97.0,
  "steps":            8000,
  "calories_burned":  450
}
```

| Field            | Kiểu     | Bắt buộc | Mô tả |
|------------------|----------|----------|-------|
| `heart_rate`     | float    | ✅       | Nhịp tim (bpm) |
| `sleep_duration` | float    | ✅       | Số giờ ngủ |
| `stress_level`   | string   | ✅       | `"None"` / `"Low"` / `"Moderate"` / `"High"` / `"Very High"` |
| `blood_oxygen`   | float    | ✅       | SpO2 % (tự động clip về [85, 100]) |
| `steps`          | float    | ❌       | Số bước/ngày (mặc định 0) |
| `calories_burned`| float    | ❌       | Calories tiêu thụ kcal (mặc định 0) |

**Response 200:**
```json
{
  "readiness_score": 72.4
}
```

> `readiness_score` là số thực trong khoảng **[0, 100]** — do model ONNX tính toán trên server.
> Giá trị càng cao, cơ thể càng sẵn sàng vận động.

**Response 400:** Body thiếu field bắt buộc.
**Response 500:** Model chưa khởi tạo hoặc lỗi inference.

---

## 6. Gợi ý flow tích hợp cho Frontend

### Flow lấy & cập nhật profile:
1. `GET /users/profile` — lấy thông tin hiện tại
2. `PUT /users/profile` — cập nhật các field cần thiết

### Flow tìm người dùng để mời vào nhóm:
1. `GET /users?search=email_hoặc_tên` — tìm user
2. `POST /groups/:id/members` — mời bằng email

### Flow đăng ký + xác thực:
1. `POST /auth/register` — nhận message, chờ OTP
2. `POST /auth/otp/verify` — nhận token, lưu storage
3. Redirect vào app

### Flow đăng nhập:
1. `POST /auth/app` hoặc `POST /auth/google`
2. Lưu `access_token` + `refresh_token`
3. Nếu 401 → gọi `POST /auth/refresh` → lưu token mới → retry

### Flow quản lý nhóm & theo dõi sức khỏe:
1. Tạo nhóm (`POST /groups`)
2. Mời người dùng (`POST /groups/:id/members`)
3. Người được mời xem lời mời (`GET /groups/invitations`), chấp nhận (`PUT /groups/:id/members/me`)
4. Người theo dõi lấy danh sách metric types (`GET /groups/metric-types`)
5. User chia sẻ metric types của mình (`PUT /groups/:id/permissions`)
6. Kết nối WebSocket, subscriber gửi `subscribe`, target user push metric data

---

## 7. Các Metric Types hiện có

| Giá trị | Ý nghĩa |
|---------|---------|
| `heart_rate` | Nhịp tim |
| `steps_count` | Số bước chân |
| `calories_burned` | Calories tiêu thụ |
| `blood_pressure` | Huyết áp |
| `spo2` | Nồng độ oxy trong máu |

> Danh sách chính xác lấy từ API: `GET /groups/metric-types`
