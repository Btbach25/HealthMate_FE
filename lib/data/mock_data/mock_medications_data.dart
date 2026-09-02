import 'package:fe/data/mock_data/mock_family_data.dart';
import 'package:fe/data/mock_data/mock_users.dart';
import 'package:fe/data/models/medication/medication.dart';
import 'package:fe/data/models/medication/medication_frequency.dart';
import 'package:fe/data/models/medication/medication_reminder.dart';
import 'package:fe/data/models/medication/medication_share.dart';

/// Dữ liệu thuốc & nhắc uống thuốc giả cho chế độ DEMO.
///
/// Bộ dữ liệu cố tình đa dạng để xem được mọi trạng thái của màn hình Thuốc:
/// - 1 lần/ngày, 2 lần/ngày, theo giờ cụ thể và loại "khi cần thiết";
/// - có liều **đã uống** hôm nay và liều **chưa uống**;
/// - có thuốc đang **được chia sẻ** cho người nhà (xem [sharesByMedicationId]).
///
/// **Muốn đổi dữ liệu demo?** Sửa danh sách trong [medications]; `MockMedicationService`
/// chỉ sao chép danh sách này vào bộ nhớ lúc khởi tạo rồi thao tác trên bản sao.
class MockMedicationsData {
  const MockMedicationsData._();

  static const String med1Id = 'demo-med-001';
  static const String med2Id = 'demo-med-002';
  static const String med3Id = 'demo-med-003';
  static const String med4Id = 'demo-med-004';
  static const String med5Id = 'demo-med-005';

  /// Mốc giờ trong **ngày hôm nay** — dùng để đánh dấu liều đã uống.
  static DateTime todayAt(int hour, int minute) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  /// Ngày ở dạng `yyyy-MM-dd`, lệch [daysFromNow] ngày so với hôm nay.
  static String dateString(int daysFromNow) {
    final d = DateTime.now().add(Duration(days: daysFromNow));
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  /// Danh sách thuốc của tài khoản demo.
  static List<Medication> get medications => [
    // 1 lần/ngày — đã uống sáng nay.
    Medication(
      id: med1Id,
      userId: MockUsers.demoUserId,
      name: 'Losartan',
      dosage: '50mg',
      frequency: const MedicationFrequency(
        type: MedicationFrequencyType.daily,
        timesPerDay: 1,
        specificTimes: ['07:30'],
      ),
      startDate: dateString(-120),
      instructions: 'Uống sau ăn sáng, không dùng chung với nước bưởi',
      prescribedBy: 'BS. Trần Quang Huy',
      reminders: [
        MedicationReminder(
          id: '$med1Id-r1',
          medicationId: med1Id,
          time: '07:30',
          lastTaken: todayAt(7, 34),
        ),
      ],
    ),

    // 2 lần/ngày — sáng đã uống, tối chưa.
    Medication(
      id: med2Id,
      userId: MockUsers.demoUserId,
      name: 'Metformin',
      dosage: '500mg',
      frequency: const MedicationFrequency(
        type: MedicationFrequencyType.daily,
        timesPerDay: 2,
        specificTimes: ['08:00', '19:30'],
      ),
      startDate: dateString(-60),
      instructions: 'Uống ngay sau bữa ăn để tránh cồn ruột',
      prescribedBy: 'BS. Trần Quang Huy',
      reminders: [
        MedicationReminder(
          id: '$med2Id-r1',
          medicationId: med2Id,
          time: '08:00',
          lastTaken: todayAt(8, 6),
        ),
        const MedicationReminder(
          id: '$med2Id-r2',
          medicationId: med2Id,
          time: '19:30',
          missedCount: 2,
        ),
      ],
    ),

    // 1 lần/ngày buổi trưa — chưa uống hôm nay.
    Medication(
      id: med3Id,
      userId: MockUsers.demoUserId,
      name: 'Vitamin D3',
      dosage: '1000 IU',
      frequency: const MedicationFrequency(
        type: MedicationFrequencyType.daily,
        timesPerDay: 1,
        specificTimes: ['12:00'],
      ),
      startDate: dateString(-90),
      instructions: 'Uống cùng bữa có chất béo để hấp thu tốt hơn',
      reminders: const [
        MedicationReminder(
          id: '$med3Id-r1',
          medicationId: med3Id,
          time: '12:00',
          missedCount: 1,
        ),
      ],
    ),

    // 2 lần/ngày — sáng đã uống, tối chưa.
    Medication(
      id: med4Id,
      userId: MockUsers.demoUserId,
      name: 'Omega-3',
      dosage: '1000mg',
      frequency: const MedicationFrequency(
        type: MedicationFrequencyType.daily,
        timesPerDay: 2,
        specificTimes: ['08:00', '20:00'],
      ),
      startDate: dateString(-30),
      instructions: 'Uống sau ăn',
      reminders: [
        MedicationReminder(
          id: '$med4Id-r1',
          medicationId: med4Id,
          time: '08:00',
          lastTaken: todayAt(8, 10),
        ),
        const MedicationReminder(
          id: '$med4Id-r2',
          medicationId: med4Id,
          time: '20:00',
        ),
      ],
    ),

    // Khi cần thiết — không nhắc định kỳ, có ngày kết thúc.
    Medication(
      id: med5Id,
      userId: MockUsers.demoUserId,
      name: 'Paracetamol',
      dosage: '500mg',
      frequency: const MedicationFrequency(
        type: MedicationFrequencyType.asNeeded,
        timesPerDay: 1,
        specificTimes: ['21:00'],
      ),
      startDate: dateString(-7),
      endDate: dateString(14),
      instructions: 'Chỉ uống khi sốt trên 38.5°C, cách nhau ít nhất 6 giờ',
      prescribedBy: 'BS. Lê Thị Ngọc',
      reminders: const [
        MedicationReminder(
          id: '$med5Id-r1',
          medicationId: med5Id,
          time: '21:00',
          isEnabled: false,
        ),
      ],
    ),
  ];

  /// Các bản ghi chia sẻ thuốc ban đầu (thuốc → danh sách người được chia sẻ).
  ///
  /// Chia sẻ mặc định: Losartan và Metformin được báo cho vợ (Trần Thị Hoa)
  /// trong nhóm "Gia đình nhà mình".
  static Map<String, List<MedicationShare>> get sharesByMedicationId => {
    med1Id: [
      const MedicationShare(
        id: 'demo-share-001',
        medicationId: med1Id,
        groupId: MockFamilyData.group1Id,
        sharedWithUserId: MockUsers.hoaId,
        notifyOffsetMinutes: 0,
      ),
    ],
    med2Id: [
      const MedicationShare(
        id: 'demo-share-002',
        medicationId: med2Id,
        groupId: MockFamilyData.group1Id,
        sharedWithUserId: MockUsers.hoaId,
        notifyOffsetMinutes: 15,
      ),
    ],
  };
}
