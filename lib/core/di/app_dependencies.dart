import 'package:fe/core/config/app_config.dart';
import 'package:fe/data/core/api_client.dart';
import 'package:fe/data/core/api_client_impl.dart';
import 'package:fe/data/repositories/auth_repository.dart';
import 'package:fe/data/repositories/family_repository.dart';
import 'package:fe/data/repositories/health_repository.dart';
import 'package:fe/data/repositories/home_repository.dart';
import 'package:fe/data/repositories/medication_repository.dart';
import 'package:fe/data/repositories/stats_repository.dart';
import 'package:fe/data/services/api_family_service.dart';
import 'package:fe/data/services/api_medication_service.dart';
import 'package:fe/data/services/api_stats_service.dart';
import 'package:fe/data/services/api_user_service.dart';
import 'package:fe/data/services/auth_service.dart';
import 'package:fe/data/services/device_health_service.dart';
import 'package:fe/data/services/fcm_service.dart';
import 'package:fe/data/services/health_service.dart';
import 'package:fe/data/services/health_ws_service.dart';
import 'package:fe/data/services/local_storage_service.dart';
import 'package:fe/data/services/mock_auth_service.dart';
import 'package:fe/data/services/mock_device_health_service.dart';
import 'package:fe/data/services/mock_family_service.dart';
import 'package:fe/data/services/mock_fcm_service.dart';
import 'package:fe/data/services/mock_health_service.dart';
import 'package:fe/data/services/mock_health_ws_service.dart';
import 'package:fe/data/services/mock_home_service.dart';
import 'package:fe/data/services/mock_medication_service.dart';
import 'package:fe/data/services/mock_readiness_service.dart';
import 'package:fe/data/services/mock_stats_service.dart';
import 'package:fe/data/services/mock_stress_service.dart';
import 'package:fe/data/services/mock_user_service.dart';
import 'package:fe/data/services/readiness_service.dart';
import 'package:fe/data/services/stress_service.dart';
import 'package:fe/data/services/user_service.dart';

/// Object graph của toàn app, dựng một lần trong `main()`.
///
/// Đây là "composition root": chỗ **duy nhất** được phép `new` service/repository.
/// Mọi tầng khác chỉ nhận dependency qua constructor hoặc `context.read<T>()`,
/// nhờ vậy có thể thay implementation (mock/API) mà không sửa UI.
///
/// Thêm dependency mới:
/// 1. Khai báo `final` field ở đây.
/// 2. Khởi tạo trong **cả hai** nhánh [AppDependencies._live] và
///    [AppDependencies._demo].
/// 3. Nếu UI cần đọc, thêm `RepositoryProvider.value` tương ứng trong `app.dart`.
///
/// ## Chế độ DEMO
/// Khi `AppConfig.isDemoMode == true`, [bootstrap] dựng graph toàn bộ bằng các
/// `Mock*Service` đọc dữ liệu từ `lib/data/mock_data/` — **không phát sinh
/// request HTTP/WebSocket/Firebase nào**.
///
/// Bật demo mode:
/// ```bash
/// flutter run --dart-define=DEMO_MODE=true
/// ```
/// hoặc thêm `DEMO_MODE=true` vào file `.env` rồi chạy `flutter run` như thường.
///
/// Tài khoản demo: `demo@healthmate.vn` / `demo1234` (mã OTP demo: `123456`).
///
/// Thêm một mock mới:
/// 1. Tạo `lib/data/services/mock_<tên>_service.dart` — `implements` interface
///    nếu có, ngược lại `extends` class thật rồi `@override` method public.
/// 2. Đặt dữ liệu thuần vào `lib/data/mock_data/` (không nhúng vào service).
/// 3. Cắm vào [AppDependencies._demo]; **đừng đụng** [AppDependencies._live].
class AppDependencies {
  final LocalStorageService localStorage;
  final ApiClient apiClient;

  final AuthRepository authRepository;
  final HomeRepository homeRepository;
  final StatsRepository statsRepository;
  final FamilyRepository familyRepository;
  final HealthRepository healthRepository;
  final MedicationRepository medicationRepository;

  final UserService userService;
  final DeviceHealthService deviceHealthService;
  final HealthWsService healthWsService;
  final ReadinessService readinessService;
  final StressService stressService;
  final FcmService fcmService;

  const AppDependencies._({
    required this.localStorage,
    required this.apiClient,
    required this.authRepository,
    required this.homeRepository,
    required this.statsRepository,
    required this.familyRepository,
    required this.healthRepository,
    required this.medicationRepository,
    required this.userService,
    required this.deviceHealthService,
    required this.healthWsService,
    required this.readinessService,
    required this.stressService,
    required this.fcmService,
  });

  /// Dựng toàn bộ object graph. Không có I/O chặn ở đây — các service tự khởi
  /// động lazily để `main()` không giữ splash screen quá lâu.
  ///
  /// Chọn nhánh theo `AppConfig.isDemoMode` (nhớ gọi `AppConfig.load()` trước).
  factory AppDependencies.bootstrap() =>
      AppConfig.isDemoMode ? AppDependencies._demo() : AppDependencies._live();

  /// Graph thật: gọi API/WebSocket/Firebase như bình thường.
  factory AppDependencies._live() {
    final localStorage = LocalStorageService();

    final authRepository = AuthRepository(
      authService: AuthApiService(localStorage),
      localStorageService: localStorage,
    );

    // Nhiều service tự refresh access token khi gặp 401 → dùng chung một hàm.
    Future<String?> refreshToken() => authRepository.refreshToken();

    final apiClient = ApiClientImpl(
      localStorageService: localStorage,
      onRefreshToken: () async => await refreshToken() != null,
    );

    return AppDependencies._(
      localStorage: localStorage,
      apiClient: apiClient,
      authRepository: authRepository,
      // TODO(backend): đổi sang ApiHomeService khi endpoint /home sẵn sàng.
      homeRepository: HomeRepository(homeService: MockHomeService()),
      statsRepository: StatsRepository(
        statsService: ApiStatsService(localStorage, onRefresh: refreshToken),
      ),
      familyRepository: FamilyRepository(
        familyService: ApiFamilyService(apiClient: apiClient),
      ),
      healthRepository: HealthRepository(
        service: HealthService(localStorage, onRefresh: refreshToken),
      ),
      medicationRepository: MedicationRepository(
        service: ApiMedicationService(apiClient: apiClient),
      ),
      userService: ApiUserService(apiClient: apiClient),
      deviceHealthService: DeviceHealthService(),
      healthWsService: HealthWsService(localStorage, onRefresh: refreshToken),
      readinessService: ReadinessService(localStorage, onRefresh: refreshToken),
      stressService: StressService(localStorage, onRefresh: refreshToken),
      fcmService: FcmService(localStorage),
    );
  }

  /// Graph DEMO: mọi service đều là mock, dữ liệu lấy từ `lib/data/mock_data/`.
  ///
  /// [LocalStorageService] vẫn dùng bản thật (`shared_preferences`) để token và
  /// hồ sơ giả được lưu như thật — nhờ đó auth-guard của router hoạt động đúng.
  factory AppDependencies._demo() {
    final localStorage = LocalStorageService();

    final authRepository = AuthRepository(
      authService: MockAuthService(localStorage),
      localStorageService: localStorage,
    );

    // Giữ nguyên field `apiClient` của graph để UI/DI không phải phân nhánh.
    // Ở chế độ demo không mock nào dùng tới nó nên không có request nào được gửi.
    final apiClient = ApiClientImpl(localStorageService: localStorage);

    // Dùng chung một instance để trang chủ đọc đúng tiến độ uống thuốc mà màn
    // hình Thuốc vừa cập nhật (state nằm trong bộ nhớ của service).
    final medicationService = MockMedicationService();

    return AppDependencies._(
      localStorage: localStorage,
      apiClient: apiClient,
      authRepository: authRepository,
      homeRepository: HomeRepository(
        homeService: MockHomeService(
          localStorage: localStorage,
          medicationService: medicationService,
        ),
      ),
      statsRepository: StatsRepository(
        statsService: MockStatsService(localStorage: localStorage),
      ),
      familyRepository: FamilyRepository(
        familyService: MockFamilyService(localStorage: localStorage),
      ),
      healthRepository: HealthRepository(
        service: MockHealthService(localStorage),
      ),
      medicationRepository: MedicationRepository(service: medicationService),
      userService: MockUserService(localStorage),
      deviceHealthService: MockDeviceHealthService(),
      healthWsService: MockHealthWsService(localStorage),
      readinessService: MockReadinessService(localStorage),
      stressService: MockStressService(localStorage),
      fcmService: MockFcmService(localStorage),
    );
  }
}
