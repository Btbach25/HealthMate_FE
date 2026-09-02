import 'package:fe/data/exceptions/api_exception.dart';
import 'package:fe/data/models/medication/medication.dart';
import 'package:fe/data/models/medication/medication_share.dart';
import 'package:fe/data/services/medication_service.dart';

/// Cổng vào của tính năng quản lý thuốc; uỷ quyền cho [MedicationService].
///
/// Mỗi method bọc lỗi ngoài [ApiException] thành [UnknownException] với
/// message tiếng Việt riêng cho từng thao tác, để UI hiển thị đúng ngữ cảnh.
///
/// Đổi nguồn dữ liệu bằng cách đăng ký một [MedicationService] khác ở
/// `lib/core/di/app_dependencies.dart` (composition root).
class MedicationRepository {
  final MedicationService _service;

  MedicationRepository({required MedicationService service})
    : _service = service;

  Future<List<Medication>> getMedications() async {
    try {
      return await _service.getMedications();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Lỗi khi tải danh sách thuốc.',
        originalError: e,
      );
    }
  }

  Future<Medication> addMedication(Medication medication) async {
    try {
      return await _service.addMedication(medication);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Lỗi khi thêm thuốc.',
        originalError: e,
      );
    }
  }

  Future<List<Medication>> takeMedication(
    String medicationId,
    String reminderId,
  ) async {
    try {
      return await _service.takeMedication(medicationId, reminderId);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Lỗi khi cập nhật trạng thái thuốc.',
        originalError: e,
      );
    }
  }

  Future<void> deleteMedication(String medicationId) async {
    try {
      return await _service.deleteMedication(medicationId);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Lỗi khi xóa thuốc.',
        originalError: e,
      );
    }
  }

  Future<List<MedicationShare>> getMedicationShares(String medicationId) async {
    try {
      return await _service.getMedicationShares(medicationId);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Lỗi khi tải danh sách chia sẻ thuốc.',
        originalError: e,
      );
    }
  }

  Future<void> addMedicationShare({
    required String medicationId,
    required String groupId,
    required String sharedWithUserId,
    int notifyOffsetMinutes = 0,
  }) async {
    try {
      await _service.addMedicationShare(
        medicationId: medicationId,
        groupId: groupId,
        sharedWithUserId: sharedWithUserId,
        notifyOffsetMinutes: notifyOffsetMinutes,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Lỗi khi chia sẻ thuốc.',
        originalError: e,
      );
    }
  }

  Future<void> deleteMedicationShare({
    required String medicationId,
    required String shareId,
  }) async {
    try {
      await _service.deleteMedicationShare(
        medicationId: medicationId,
        shareId: shareId,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Lỗi khi hủy chia sẻ thuốc.',
        originalError: e,
      );
    }
  }

  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    try {
      await _service.registerDeviceToken(token: token, platform: platform);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message:
            'Lỗi khi bật thông báo nhắc trên điện thoại. Vui lòng thử lại.',
        originalError: e,
      );
    }
  }
}
