# Hướng dẫn Tích hợp API

## Cấu trúc Code

Codebase được thiết kế để dễ dàng chuyển từ Mock Services sang Real API calls.

### Kiến trúc

```
Presentation Layer (BLoC/UI)
    ↓
Repository Layer (Business Logic)
    ↓
Service Layer (Data Source - Mock hoặc API)
    ↓
API Client (HTTP Requests)
```

## Các thành phần chính

### 1. API Client (`lib/data/core/api_client.dart`)

Base class cho tất cả API calls:
- Xử lý HTTP requests (GET, POST, PUT, DELETE)
- Error handling tự động
- Authentication token management
- Timeout handling
- Response parsing

### 2. API Exceptions (`lib/data/exceptions/api_exception.dart`)

Custom exceptions cho các loại lỗi:
- `NetworkException` - Lỗi mạng
- `TimeoutException` - Timeout
- `UnauthorizedException` - 401
- `ForbiddenException` - 403
- `NotFoundException` - 404
- `ValidationException` - 422
- `ServerException` - 5xx
- `ClientException` - 4xx khác

### 3. Service Interfaces

Mỗi service có abstract class định nghĩa interface:
- `FamilyService` - Interface cho family operations
- `AuthService` - Interface cho authentication
- `HomeService` - Interface cho home data
- `StatsService` - Interface cho stats data

### 4. Service Implementations

**Mock Services** (hiện tại):
- `MockFamilyService` - Mock data cho development
- `MockAuthService` - Mock authentication
- `MockHomeService` - Mock home data
- `MockStatsService` - Mock stats data

**API Services** (sẵn sàng tích hợp):
- `ApiFamilyService` - Real API calls cho family
- Có thể tạo tương tự cho các services khác

## Cách chuyển từ Mock sang API

### Bước 1: Cấu hình API Client

Trong `lib/main.dart` hoặc dependency injection setup:

```dart
// Tạo API client
final localStorageService = LocalStorageService();
final apiClient = ApiClientImpl(
  baseUrl: 'https://api.yourdomain.com', // Thay bằng API URL thật
  localStorageService: localStorageService,
);

// Tạo API service
final familyService = ApiFamilyService(apiClient: apiClient);

// Inject vào repository (giống như mock service)
final familyRepository = FamilyRepository(familyService: familyService);
```

### Bước 2: Thay đổi Service Implementation

Trong `lib/main.dart`:

**Trước (Mock):**
```dart
final familyService = MockFamilyService();
final familyRepository = FamilyRepository(familyService: familyService);
```

**Sau (API):**
```dart
final apiClient = ApiClientImpl(
  baseUrl: 'https://api.yourdomain.com',
  localStorageService: localStorageService,
);
final familyService = ApiFamilyService(apiClient: apiClient);
final familyRepository = FamilyRepository(familyService: familyService);
```

### Bước 3: Cấu hình Authentication Token

Trong `lib/data/core/api_client_impl.dart`, implement `getAuthToken()`:

```dart
@override
Future<String?> getAuthToken() async {
  // Lấy token từ local storage hoặc secure storage
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('auth_token');
}
```

Hoặc nếu bạn có AuthService riêng:

```dart
@override
Future<String?> getAuthToken() async {
  final user = await _localStorageService.getUser();
  // Giả sử token được lưu trong user object hoặc riêng biệt
  return user?.token; // Hoặc lấy từ nơi khác
}
```

## Error Handling

### Trong Repository

Repositories tự động handle `ApiException`:

```dart
try {
  return await _familyService.getFamilyGroups();
} on ApiException {
  // ApiException đã có message tiếng Việt, rethrow
  rethrow;
} catch (e) {
  // Wrap unexpected errors
  throw UnknownException(
    message: 'Lỗi khi tải dữ liệu.',
    originalError: e,
  );
}
```

### Trong BLoC

BLoC sử dụng `_parseError()` để convert exceptions thành user-friendly messages:

```dart
catch (e) {
  emit(state.copyWith(
    status: FamilyStatus.error,
    errorMessage: _parseError(e),
  ));
}
```

## API Endpoints Structure

### Family Service Endpoints

- `GET /api/family/groups` - Lấy danh sách nhóm
- `POST /api/family/groups` - Tạo nhóm mới
- `GET /api/family/groups/:id` - Lấy chi tiết nhóm
- `PUT /api/family/groups/:id` - Cập nhật nhóm
- `DELETE /api/family/groups/:id` - Xóa nhóm
- `POST /api/family/groups/:id/leave` - Rời nhóm
- `POST /api/family/groups/:id/invitations` - Mời thành viên
- `DELETE /api/family/groups/:id/members/:memberId` - Xóa thành viên
- `POST /api/family/groups/:id/transfer-ownership` - Chuyển quyền sở hữu
- `GET /api/family/invitations/incoming` - Lời mời đến
- `GET /api/family/invitations/outgoing` - Lời mời đã gửi
- `POST /api/family/invitations/:id/accept` - Chấp nhận lời mời
- `POST /api/family/invitations/:id/decline` - Từ chối lời mời

## Response Format

API nên trả về JSON với format:

**Success Response:**
```json
{
  "data": { ... },
  "message": "Success"
}
```

**Error Response:**
```json
{
  "message": "Error message",
  "errors": {
    "field1": ["Error 1", "Error 2"],
    "field2": ["Error 3"]
  }
}
```

## Models

Tất cả models cần implement:
- `fromJson(Map<String, dynamic> json)` - Parse từ API response
- `toJson()` - Convert sang JSON để gửi lên API

Ví dụ:
```dart
class FamilyGroup {
  // ... fields
  
  factory FamilyGroup.fromJson(Map<String, dynamic> json) {
    return FamilyGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      // ... other fields
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      // ... other fields
    };
  }
}
```

## Testing

### Test với Mock Service

```dart
final mockService = MockFamilyService();
final repository = FamilyRepository(familyService: mockService);
// Test logic...
```

### Test với API Service

```dart
final apiClient = ApiClientImpl(
  baseUrl: 'https://test-api.example.com',
  localStorageService: mockLocalStorage,
);
final apiService = ApiFamilyService(apiClient: apiClient);
final repository = FamilyRepository(familyService: apiService);
// Test logic...
```

## Environment Configuration

Tạo file `lib/core/config/app_config.dart`:

```dart
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.yourdomain.com',
  );
  
  static const bool useMockServices = bool.fromEnvironment(
    'USE_MOCK_SERVICES',
    defaultValue: false,
  );
}
```

Sử dụng:
```dart
// Development
flutter run --dart-define=USE_MOCK_SERVICES=true

// Production
flutter run --dart-define=API_BASE_URL=https://api.yourdomain.com
```

## Best Practices

1. **Luôn sử dụng Repository pattern** - Không gọi Service trực tiếp từ BLoC
2. **Handle ApiException riêng** - Để có error messages tốt hơn
3. **Validate data** - Trước khi gửi lên API và sau khi nhận về
4. **Use type-safe models** - Luôn parse JSON thành models
5. **Handle loading states** - Trong BLoC để UX tốt hơn
6. **Cache khi cần** - Repository layer là nơi tốt để cache
7. **Retry logic** - Có thể thêm vào ApiClient cho network errors

## Troubleshooting

### Lỗi "Type 'Null' is not a subtype of type 'String'"

- Kiểm tra `fromJson` có handle null values không
- Sử dụng null-aware operators: `json['field'] as String?`

### Lỗi "Connection refused"

- Kiểm tra API base URL
- Kiểm tra network connectivity
- Kiểm tra CORS settings (cho web)

### Lỗi "Unauthorized"

- Kiểm tra token có được set đúng không
- Kiểm tra token có expired không
- Implement token refresh logic nếu cần

## Next Steps

1. Implement các API services còn lại (Auth, Home, Stats)
2. Thêm token refresh logic
3. Thêm request/response interceptors nếu cần
4. Thêm caching layer
5. Thêm retry logic cho network errors
6. Thêm logging cho API calls (development only)

