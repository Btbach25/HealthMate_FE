import 'package:fe/data/exceptions/api_exception.dart';
import 'package:fe/data/models/medication/medication.dart';
import 'package:fe/data/services/medication_service.dart';

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
      String medicationId, String reminderId) async {
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
}
