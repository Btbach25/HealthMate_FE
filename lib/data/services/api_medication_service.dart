import 'package:fe/data/core/api_client.dart';
import 'package:fe/data/core/api_endpoints.dart';
import 'package:fe/data/exceptions/api_exception.dart';
import 'package:fe/data/models/medication/medication.dart';
import 'package:fe/data/models/medication/medication_share.dart';
import 'package:fe/data/services/medication_service.dart';

/// Gọi storage-service qua api-gateway: [ApiEndpoints.medications].
class ApiMedicationService implements MedicationService {
  final ApiClient _apiClient;

  ApiMedicationService({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<List<Medication>> getMedications() async {
    try {
      final raw = await _apiClient.get<List<dynamic>>(
        ApiEndpoints.medications,
        parser: (data) => data is List ? data : <dynamic>[],
      );
      return raw
          .map((e) => Medication.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Lỗi khi tải danh sách thuốc.',
        originalError: e,
      );
    }
  }

  @override
  Future<Medication> addMedication(Medication medication) async {
    try {
      final body = _createBody(medication);
      final data = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.medications,
        body: body,
        parser: (d) => d as Map<String, dynamic>,
      );
      return Medication.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Lỗi khi thêm thuốc.',
        originalError: e,
      );
    }
  }

  /// Payload khớp BE; bỏ id/user_id để server gán.
  Map<String, dynamic> _createBody(Medication medication) {
    return {
      'name': medication.name,
      'dosage': medication.dosage,
      'frequency': medication.frequency.toJson(),
      'start_date': medication.startDate,
      'end_date': medication.endDate,
      'instructions': medication.instructions,
      'prescribed_by': medication.prescribedBy,
      'is_active': medication.isActive,
      'reminders': medication.reminders
          .map(
            (r) => {
              'time': r.time,
              'is_enabled': r.isEnabled,
            },
          )
          .toList(),
    };
  }

  @override
  Future<void> deleteMedication(String medicationId) async {
    try {
      final path = '${ApiEndpoints.medications}/$medicationId';
      await _apiClient.delete<Null>(
        path,
        parser: (_) => null,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Lỗi khi xóa thuốc.',
        originalError: e,
      );
    }
  }

  @override
  Future<List<Medication>> takeMedication(
    String medicationId,
    String reminderId,
  ) async {
    try {
      final path =
          '${ApiEndpoints.medications}/$medicationId/reminders/$reminderId/take';
      final raw = await _apiClient.post<List<dynamic>>(
        path,
        parser: (data) => data is List ? data : <dynamic>[],
      );
      return raw
          .map((e) => Medication.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Lỗi khi cập nhật trạng thái thuốc.',
        originalError: e,
      );
    }
  }

  @override
  Future<List<MedicationShare>> getMedicationShares(String medicationId) async {
    try {
      final raw = await _apiClient.get<List<dynamic>>(
        ApiEndpoints.medicationShares(medicationId),
        parser: (data) => data is List ? data : <dynamic>[],
      );
      return raw
          .map((e) => MedicationShare.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message: 'Lỗi khi tải danh sách chia sẻ thuốc.',
        originalError: e,
      );
    }
  }

  @override
  Future<void> addMedicationShare({
    required String medicationId,
    required String groupId,
    required String sharedWithUserId,
    int notifyOffsetMinutes = 0,
  }) async {
    try {
      await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.medicationShares(medicationId),
        body: {
          'group_id': groupId,
          'shared_with_user_id': sharedWithUserId,
          'notify_offset_minutes': notifyOffsetMinutes,
        },
        parser: (d) => d as Map<String, dynamic>,
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

  @override
  Future<void> deleteMedicationShare({
    required String medicationId,
    required String shareId,
  }) async {
    try {
      await _apiClient.delete<Null>(
        ApiEndpoints.medicationShareById(medicationId, shareId),
        parser: (_) => null,
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

  @override
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    try {
      await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.medicationsDeviceToken,
        body: {
          'token': token,
          'platform': platform,
        },
        parser: (d) => d as Map<String, dynamic>,
      );
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
