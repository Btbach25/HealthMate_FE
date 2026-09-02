import 'package:fe/data/mock_data/mock_family_data.dart';
import 'package:fe/data/mock_data/mock_medications_data.dart';
import 'package:fe/data/mock_data/mock_users.dart';
import 'package:fe/data/models/health/medication_progress.dart';
import 'package:fe/data/models/home_data.dart';
import 'package:fe/data/models/medication/medication.dart';
import 'package:fe/data/models/user/user.dart';
import 'package:fe/data/services/home_service.dart';
import 'package:fe/data/services/local_storage_service.dart';
import 'package:fe/data/services/medication_service.dart';

/// [HomeService] giả lập cho chế độ DEMO.
///
/// Dữ liệu lấy từ `lib/data/mock_data/`:
/// - Người dùng: ưu tiên user đang đăng nhập trong [LocalStorageService],
///   fallback về `MockUsers.demoUser`.
/// - Tiến độ uống thuốc: tính **trực tiếp** từ [MedicationService] đang dùng
///   nên đánh dấu "đã uống" ở màn hình Thuốc là trang chủ đổi theo ngay.
/// - Thông báo: `MockFamilyData.notifications`.
///
/// Cả hai tham số đều tuỳ chọn để `MockHomeService()` vẫn dùng được ở nhánh
/// live (`AppDependencies._live`) như trước đây.
class MockHomeService implements HomeService {
  final LocalStorageService? _localStorage;
  final MedicationService? _medicationService;

  MockHomeService({
    LocalStorageService? localStorage,
    MedicationService? medicationService,
  }) : _localStorage = localStorage,
       _medicationService = medicationService;

  @override
  Future<HomeData> getHomeData() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    return HomeData(
      user: await _resolveUser(),
      medicationProgress: await _resolveProgress(),
      notifications: MockFamilyData.notifications,
    );
  }

  Future<User> _resolveUser() async {
    final storage = _localStorage;
    if (storage != null) {
      final stored = await storage.getUser();
      if (stored != null && stored.isNotEmpty) return stored;
    }
    return MockUsers.demoUser;
  }

  Future<MedicationProgress> _resolveProgress() async {
    final service = _medicationService;
    final meds = service != null
        ? await service.getMedications()
        : MockMedicationsData.medications;

    var total = 0;
    var completed = 0;
    for (final Medication med in meds) {
      if (!med.isActive) continue;
      for (final reminder in med.reminders) {
        if (!reminder.isEnabled) continue;
        total++;
        if (reminder.isTakenToday) completed++;
      }
    }
    return MedicationProgress(completed: completed, total: total);
  }
}
