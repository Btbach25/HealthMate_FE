import '../models/medication/medication.dart';
import '../models/medication/medication_share.dart';

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
