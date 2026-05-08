import 'package:fe/data/models/medication/medication.dart';
import 'package:fe/data/models/medication/medication_frequency.dart';
import 'package:fe/data/models/medication/medication_reminder.dart';
import 'package:fe/data/models/medication/medication_share.dart';
import 'package:fe/data/services/medication_service.dart';

class MockMedicationService implements MedicationService {
  final List<Medication> _medications;
  final Map<String, List<MedicationShare>> _sharesByMedicationId = {};

  MockMedicationService() : _medications = _buildMockData();

  static List<Medication> _buildMockData() {
    final now = DateTime.now();
    final takenAt8 = DateTime(now.year, now.month, now.day, 8, 5);

    return [
      Medication(
        id: 'med-001',
        userId: 'c7b5a32a-1b4e-4b8d-9c3a-3f3a2b1b9c0d',
        name: 'Lisinopril',
        dosage: '10mg',
        frequency: const MedicationFrequency(
          type: MedicationFrequencyType.daily,
          timesPerDay: 1,
          specificTimes: ['08:00'],
        ),
        startDate: '2026-02-01',
        instructions: 'Uống trước ăn',
        prescribedBy: 'BS. Nguyễn Văn A',
        reminders: [
          MedicationReminder(
            id: 'rem-001',
            medicationId: 'med-001',
            time: '08:00',
            lastTaken: takenAt8,
          ),
        ],
      ),
      Medication(
        id: 'med-002',
        userId: 'c7b5a32a-1b4e-4b8d-9c3a-3f3a2b1b9c0d',
        name: 'Omega-3',
        dosage: '1000mg',
        frequency: const MedicationFrequency(
          type: MedicationFrequencyType.daily,
          timesPerDay: 2,
          specificTimes: ['08:00', '20:00'],
        ),
        startDate: '2026-02-01',
        instructions: 'Uống sau ăn',
        reminders: [
          MedicationReminder(
            id: 'rem-002',
            medicationId: 'med-002',
            time: '08:00',
            lastTaken: takenAt8,
          ),
          const MedicationReminder(
            id: 'rem-003',
            medicationId: 'med-002',
            time: '20:00',
          ),
        ],
      ),
      const Medication(
        id: 'med-003',
        userId: 'c7b5a32a-1b4e-4b8d-9c3a-3f3a2b1b9c0d',
        name: 'Vitamin D3',
        dosage: '1000 IU',
        frequency: MedicationFrequency(
          type: MedicationFrequencyType.daily,
          timesPerDay: 1,
          specificTimes: ['19:00'],
        ),
        startDate: '2026-02-01',
        instructions: 'Uống sau ăn',
        reminders: [
          MedicationReminder(
            id: 'rem-004',
            medicationId: 'med-003',
            time: '19:00',
          ),
        ],
      ),
    ];
  }

  @override
  Future<List<Medication>> getMedications() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return List.from(_medications);
  }

  @override
  Future<Medication> addMedication(Medication medication) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _medications.add(medication);
    return medication;
  }

  @override
  Future<void> deleteMedication(String medicationId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _medications.removeWhere((m) => m.id == medicationId);
  }

  @override
  Future<List<Medication>> takeMedication(
      String medicationId, String reminderId) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final medIndex = _medications.indexWhere((m) => m.id == medicationId);
    if (medIndex < 0) return List.from(_medications);

    final med = _medications[medIndex];
    final reminderIndex =
        med.reminders.indexWhere((r) => r.id == reminderId);
    if (reminderIndex < 0) return List.from(_medications);

    final reminder = med.reminders[reminderIndex];
    final updated = reminder.isTakenToday
        ? reminder.copyWith(clearLastTaken: true)
        : reminder.copyWith(lastTaken: DateTime.now());

    final updatedReminders = List<MedicationReminder>.from(med.reminders);
    updatedReminders[reminderIndex] = updated;
    _medications[medIndex] = med.copyWith(reminders: updatedReminders);

    return List.from(_medications);
  }

  @override
  Future<List<MedicationShare>> getMedicationShares(String medicationId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List<MedicationShare>.from(_sharesByMedicationId[medicationId] ?? []);
  }

  @override
  Future<void> addMedicationShare({
    required String medicationId,
    required String groupId,
    required String sharedWithUserId,
    int notifyOffsetMinutes = 0,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final current = _sharesByMedicationId.putIfAbsent(medicationId, () => []);
    current.add(
      MedicationShare(
        id: 'share-${current.length + 1}',
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
    await Future.delayed(const Duration(milliseconds: 100));
    final current = _sharesByMedicationId[medicationId];
    if (current == null) return;
    current.removeWhere((s) => s.id == shareId);
  }

  @override
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    await Future.delayed(const Duration(milliseconds: 120));
  }
}
