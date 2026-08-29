import 'package:fe/data/models/medication/medication.dart';
import 'package:fe/data/models/medication/medication_share.dart';

/// Hợp đồng quản lý thuốc: danh sách thuốc và lịch nhắc, đánh dấu đã uống,
/// chia sẻ thuốc cho thành viên trong nhóm, và đăng ký device token để nhận
/// push nhắc uống thuốc.
///
/// Ánh xạ với nhóm endpoint `/medications/...` của backend.
///
/// Muốn đổi nguồn dữ liệu (mock / API khác), implement lại interface này rồi
/// đăng ký implementation ở `lib/core/di/app_dependencies.dart` (composition root).
abstract class MedicationService {
  Future<List<Medication>> getMedications();
  Future<Medication> addMedication(Medication medication);

  /// Toggle taken status for a specific reminder. Returns updated list.
  Future<List<Medication>> takeMedication(
      String medicationId, String reminderId);

  /// Xóa một thuốc và toàn bộ nhắc liên quan (server).
  Future<void> deleteMedication(String medicationId);

  Future<List<MedicationShare>> getMedicationShares(String medicationId);

  Future<void> addMedicationShare({
    required String medicationId,
    required String groupId,
    required String sharedWithUserId,
    int notifyOffsetMinutes = 0,
  });

  Future<void> deleteMedicationShare({
    required String medicationId,
    required String shareId,
  });

  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  });
}
