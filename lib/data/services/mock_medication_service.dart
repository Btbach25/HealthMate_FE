import 'package:fe/data/mock_data/mock_medications_data.dart';
import 'package:fe/data/models/medication/medication.dart';
import 'package:fe/data/models/medication/medication_reminder.dart';
import 'package:fe/data/models/medication/medication_share.dart';
import 'package:fe/data/services/medication_service.dart';
import 'package:flutter/foundation.dart';

/// [MedicationService] giả lập cho chế độ DEMO — **có state trong bộ nhớ**.
///
/// Dữ liệu khởi tạo lấy từ `MockMedicationsData`; sau đó mọi thao tác (thêm,
/// xoá, đánh dấu đã uống, chia sẻ/huỷ chia sẻ) đều thay đổi thật trên bản sao
/// trong RAM nên demo có cảm giác như app thật. State mất khi tắt app.
class MockMedicationService implements MedicationService {
  final List<Medication> _medications;
  final Map<String, List<MedicationShare>> _sharesByMedicationId;

  MockMedicationService()
      : _medications = List<Medication>.from(MockMedicationsData.medications),
        _sharesByMedicationId = {
          for (final entry in MockMedicationsData.sharesByMedicationId.entries)
            entry.key: List<MedicationShare>.from(entry.value),
        };

  int _shareCounter = 0;

  Future<void> _delay([int milliseconds = 300]) =>
      Future<void>.delayed(Duration(milliseconds: milliseconds));

  @override
  Future<List<Medication>> getMedications() async {
    await _delay(450);
    return List<Medication>.from(_medications);
  }

  @override
  Future<Medication> addMedication(Medication medication) async {
    await _delay();

    // UI thường tạo sẵn reminders; nếu thiếu thì suy ra từ giờ uống đã chọn.
    final withReminders = medication.reminders.isNotEmpty
        ? medication
        : medication.copyWith(
            reminders: medication.frequency.specificTimes
                .asMap()
                .entries
                .map(
                  (e) => MedicationReminder(
                    id: '${medication.id}-r${e.key + 1}',
                    medicationId: medication.id,
                    time: e.value,
                  ),
                )
                .toList(),
          );

    _medications.add(withReminders);
    debugPrint('[MockMedication] Đã thêm thuốc DEMO: ${withReminders.name}');
    return withReminders;
  }

  @override
  Future<List<Medication>> takeMedication(
    String medicationId,
    String reminderId,
  ) async {
    await _delay(150);

    final medIndex = _medications.indexWhere((m) => m.id == medicationId);
    if (medIndex < 0) return List<Medication>.from(_medications);

    final med = _medications[medIndex];
    final reminderIndex = med.reminders.indexWhere((r) => r.id == reminderId);
    if (reminderIndex < 0) return List<Medication>.from(_medications);

    final reminder = med.reminders[reminderIndex];
    // Bấm lại lần nữa = bỏ đánh dấu (giống hành vi của service thật).
    final updated = reminder.isTakenToday
        ? reminder.copyWith(clearLastTaken: true)
        : reminder.copyWith(lastTaken: DateTime.now());

    final updatedReminders = List<MedicationReminder>.from(med.reminders);
    updatedReminders[reminderIndex] = updated;
    _medications[medIndex] = med.copyWith(reminders: updatedReminders);

    return List<Medication>.from(_medications);
  }

  @override
  Future<void> deleteMedication(String medicationId) async {
    await _delay(250);
    _medications.removeWhere((m) => m.id == medicationId);
    _sharesByMedicationId.remove(medicationId);
  }

  @override
  Future<List<MedicationShare>> getMedicationShares(String medicationId) async {
    await _delay(200);
    return List<MedicationShare>.from(
      _sharesByMedicationId[medicationId] ?? const <MedicationShare>[],
    );
  }

  @override
  Future<void> addMedicationShare({
    required String medicationId,
    required String groupId,
    required String sharedWithUserId,
    int notifyOffsetMinutes = 0,
  }) async {
    await _delay(250);
    final shares =
        _sharesByMedicationId.putIfAbsent(medicationId, () => <MedicationShare>[]);
    _shareCounter++;
    shares.add(
      MedicationShare(
        id: 'demo-share-new-$_shareCounter',
        medicationId: medicationId,
        groupId: groupId,
        sharedWithUserId: sharedWithUserId,
        notifyOffsetMinutes: notifyOffsetMinutes,
      ),
    );
  }

  @override
  Future<void> deleteMedicationShare({
    required String medicationId,
    required String shareId,
  }) async {
    await _delay(200);
    _sharesByMedicationId[medicationId]?.removeWhere((s) => s.id == shareId);
  }

  @override
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    await _delay(120);
    // No-op: demo không có backend để đăng ký token.
  }
}
