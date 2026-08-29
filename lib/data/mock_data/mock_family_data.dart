import 'package:fe/data/enums/group_member_role.dart';
import 'package:fe/data/enums/group_member_status.dart';
import 'package:fe/data/enums/metric_type.dart';
import 'package:fe/data/enums/notification_type.dart';
import 'package:fe/data/mock_data/mock_users.dart';
import 'package:fe/data/models/group/family_group.dart';
import 'package:fe/data/models/group/family_member.dart';
import 'package:fe/data/models/group/family_notification.dart';
import 'package:fe/data/models/group/incoming_invitation.dart';
import 'package:fe/data/models/group/outgoing_invitation.dart';

/// Dữ liệu nhóm gia đình giả cho chế độ DEMO.
///
/// Bố cục được thiết kế để xem được **mọi** tính năng của màn hình Gia đình:
/// - [group1]: user demo là **chủ nhóm** (được sửa nhóm, mời, duyệt, xoá thành viên).
/// - [group2]: user demo chỉ là **thành viên** (chỉ rời nhóm, sửa chia sẻ của mình).
/// - [group3]: nhóm chưa tham gia — nguồn của **lời mời đến** đang chờ xử lý.
/// - [outgoingInvitations]: 1 lời mời đi đang chờ phản hồi.
/// - [pendingApprovals]: 1 người đã đồng ý, đang chờ chủ nhóm duyệt.
///
/// **Muốn đổi dữ liệu demo?** Sửa trực tiếp các getter dưới đây; `MockFamilyService`
/// chỉ sao chép dữ liệu này vào bộ nhớ khi khởi tạo rồi thao tác trên bản sao.
class MockFamilyData {
  const MockFamilyData._();

  static const String group1Id = 'demo-group-1';
  static const String group2Id = 'demo-group-2';
  static const String group3Id = 'demo-group-3';

  static DateTime get _now => DateTime.now();

  // ---------- Nhóm ----------

  /// Nhóm mà user demo làm chủ nhóm.
  static FamilyGroup get group1 {
    final now = _now;
    return FamilyGroup(
      id: group1Id,
      name: 'Gia đình nhà mình',
      memberCount: 4,
      userRole: GroupMemberRole.owner,
      createdAt: now.subtract(const Duration(days: 210)),
      updatedAt: now.subtract(const Duration(hours: 5)),
      lastActivity: now.subtract(const Duration(minutes: 24)),
      pendingInvitations: 2,
      sharedMetrics: const [
        MetricType.heartRate,
        MetricType.stepsCount,
        MetricType.caloriesBurnt,
        MetricType.bloodPressure,
        MetricType.spo2,
      ],
      ownerId: MockUsers.demoUserId,
      medicationSharingAllowed: true,
    );
  }

  /// Nhóm mà user demo chỉ là thành viên (chủ nhóm là bố — ông Hùng).
  static FamilyGroup get group2 {
    final now = _now;
    return FamilyGroup(
      id: group2Id,
      name: 'Ông bà & các cháu',
      memberCount: 3,
      userRole: GroupMemberRole.member,
      createdAt: now.subtract(const Duration(days: 140)),
      updatedAt: now.subtract(const Duration(days: 1)),
      lastActivity: now.subtract(const Duration(hours: 6)),
      pendingInvitations: 0,
      sharedMetrics: const [
        MetricType.heartRate,
        MetricType.bloodPressure,
        MetricType.stepsCount,
      ],
      ownerId: MockUsers.hungId,
      medicationSharingAllowed: false,
    );
  }

  /// Nhóm user demo **chưa** tham gia — kèm trong lời mời đến.
  static FamilyGroup get group3 {
    final now = _now;
    return FamilyGroup(
      id: group3Id,
      name: 'Nhóm chăm sóc mẹ',
      memberCount: 3,
      userRole: GroupMemberRole.member,
      createdAt: now.subtract(const Duration(days: 45)),
      updatedAt: now.subtract(const Duration(days: 2)),
      lastActivity: now.subtract(const Duration(days: 2)),
      pendingInvitations: 0,
      sharedMetrics: const [
        MetricType.heartRate,
        MetricType.bloodPressure,
      ],
      ownerId: MockUsers.thuMaiId,
      medicationSharingAllowed: false,
    );
  }

  /// Các nhóm user demo đang tham gia.
  static List<FamilyGroup> get groups => [group1, group2];

  // ---------- Thành viên ----------

  static FamilyMember _member({
    required String groupId,
    required String userId,
    required String name,
    required String email,
    int? age,
    String? relationship,
    HealthStatus healthStatus = HealthStatus.healthy,
    List<String> healthConditions = const [],
    required List<MetricType> sharedMetrics,
    bool medicationReminderShareAllowed = false,
    int joinedDaysAgo = 100,
    int lastUpdatedMinutesAgo = 30,
  }) {
    final now = _now;
    return FamilyMember(
      id: userId, // Khớp `GroupApiMapper.toFamilyMember`: id thành viên = id người dùng.
      userId: userId,
      groupId: groupId,
      name: name,
      email: email,
      age: age,
      relationship: relationship,
      avatar: null,
      healthStatus: healthStatus,
      lastUpdated: now.subtract(Duration(minutes: lastUpdatedMinutesAgo)),
      healthConditions: healthConditions,
      sharedMetrics: sharedMetrics,
      medicationReminderShareAllowed: medicationReminderShareAllowed,
      createdAt: now.subtract(Duration(days: joinedDaysAgo)),
    );
  }

  /// Thành viên của nhóm "Gia đình nhà mình".
  static List<FamilyMember> get group1Members => [
        _member(
          groupId: group1Id,
          userId: MockUsers.demoUserId,
          name: MockUsers.demoUser.name,
          email: MockUsers.demoEmail,
          age: 37,
          relationship: 'Bố',
          healthStatus: HealthStatus.good,
          sharedMetrics: const [
            MetricType.heartRate,
            MetricType.stepsCount,
            MetricType.caloriesBurnt,
            MetricType.bloodPressure,
            MetricType.spo2,
          ],
          medicationReminderShareAllowed: true,
          joinedDaysAgo: 210,
          lastUpdatedMinutesAgo: 4,
        ),
        _member(
          groupId: group1Id,
          userId: MockUsers.hoaId,
          name: MockUsers.hoa.name,
          email: MockUsers.hoa.email,
          age: 35,
          relationship: 'Mẹ',
          healthStatus: HealthStatus.healthy,
          sharedMetrics: const [
            MetricType.heartRate,
            MetricType.stepsCount,
            MetricType.bloodPressure,
          ],
          medicationReminderShareAllowed: true,
          joinedDaysAgo: 208,
          lastUpdatedMinutesAgo: 12,
        ),
        _member(
          groupId: group1Id,
          userId: MockUsers.minhAnhId,
          name: MockUsers.minhAnh.name,
          email: MockUsers.minhAnh.email,
          age: 15,
          relationship: 'Con gái',
          healthStatus: HealthStatus.good,
          sharedMetrics: const [
            MetricType.stepsCount,
            MetricType.caloriesBurnt,
            MetricType.heartRate,
          ],
          joinedDaysAgo: 195,
          lastUpdatedMinutesAgo: 48,
        ),
        _member(
          groupId: group1Id,
          userId: MockUsers.baoLongId,
          name: MockUsers.baoLong.name,
          email: MockUsers.baoLong.email,
          age: 30,
          relationship: 'Em trai',
          healthStatus: HealthStatus.needsAttention,
          healthConditions: const ['Huyết áp cao'],
          sharedMetrics: const [
            MetricType.heartRate,
            MetricType.bloodPressure,
            MetricType.spo2,
          ],
          joinedDaysAgo: 60,
          lastUpdatedMinutesAgo: 95,
        ),
      ];

  /// Thành viên của nhóm "Ông bà & các cháu".
  static List<FamilyMember> get group2Members => [
        _member(
          groupId: group2Id,
          userId: MockUsers.hungId,
          name: MockUsers.hung.name,
          email: MockUsers.hung.email,
          age: 68,
          relationship: 'Ông',
          healthStatus: HealthStatus.needsAttention,
          healthConditions: const ['Tiểu đường tuýp 2', 'Huyết áp cao'],
          sharedMetrics: const [
            MetricType.heartRate,
            MetricType.bloodPressure,
            MetricType.stepsCount,
          ],
          medicationReminderShareAllowed: true,
          joinedDaysAgo: 140,
          lastUpdatedMinutesAgo: 18,
        ),
        _member(
          groupId: group2Id,
          userId: MockUsers.demoUserId,
          name: MockUsers.demoUser.name,
          email: MockUsers.demoEmail,
          age: 37,
          relationship: 'Con trai',
          healthStatus: HealthStatus.good,
          sharedMetrics: const [
            MetricType.heartRate,
            MetricType.stepsCount,
          ],
          joinedDaysAgo: 138,
          lastUpdatedMinutesAgo: 4,
        ),
        _member(
          groupId: group2Id,
          userId: MockUsers.minhAnhId,
          name: MockUsers.minhAnh.name,
          email: MockUsers.minhAnh.email,
          age: 15,
          relationship: 'Cháu gái',
          healthStatus: HealthStatus.healthy,
          sharedMetrics: const [MetricType.stepsCount],
          joinedDaysAgo: 130,
          lastUpdatedMinutesAgo: 48,
        ),
      ];

  /// Thành viên nhóm chưa tham gia (xem trước khi bấm Đồng ý lời mời).
  static List<FamilyMember> get group3Members => [
        _member(
          groupId: group3Id,
          userId: MockUsers.thuMaiId,
          name: MockUsers.thuMai.name,
          email: MockUsers.thuMai.email,
          age: 40,
          relationship: 'Chị',
          healthStatus: HealthStatus.healthy,
          sharedMetrics: const [
            MetricType.heartRate,
            MetricType.bloodPressure,
          ],
          joinedDaysAgo: 45,
          lastUpdatedMinutesAgo: 120,
        ),
        _member(
          groupId: group3Id,
          userId: MockUsers.hoaId,
          name: MockUsers.hoa.name,
          email: MockUsers.hoa.email,
          age: 35,
          relationship: 'Em dâu',
          healthStatus: HealthStatus.healthy,
          sharedMetrics: const [MetricType.heartRate],
          joinedDaysAgo: 40,
          lastUpdatedMinutesAgo: 12,
        ),
        _member(
          groupId: group3Id,
          userId: MockUsers.baoLongId,
          name: MockUsers.baoLong.name,
          email: MockUsers.baoLong.email,
          age: 30,
          relationship: 'Em trai',
          healthStatus: HealthStatus.needsAttention,
          sharedMetrics: const [MetricType.bloodPressure],
          joinedDaysAgo: 38,
          lastUpdatedMinutesAgo: 95,
        ),
      ];

  /// Thành viên ban đầu của từng nhóm.
  static Map<String, List<FamilyMember>> get membersByGroup => {
        group1Id: group1Members,
        group2Id: group2Members,
        group3Id: group3Members,
      };

  // ---------- Lời mời ----------

  /// Lời mời **đến** đang chờ user demo xử lý (đồng ý / từ chối).
  static List<IncomingInvitation> get incomingInvitations {
    final now = _now;
    return [
      IncomingInvitation(
        id: 'demo-inv-in-1',
        groupId: group3Id,
        group: group3,
        inviter: MockUsers.thuMai,
        sentAt: now.subtract(const Duration(hours: 20)),
        sharedMetrics: const [
          MetricType.heartRate,
          MetricType.bloodPressure,
          MetricType.spo2,
        ],
        memberCount: 3,
      ),
    ];
  }

  /// Lời mời **đi** user demo đã gửi, đang chờ người kia phản hồi.
  static List<OutgoingInvitation> get outgoingInvitations {
    final now = _now;
    return [
      OutgoingInvitation(
        id: 'demo-inv-out-1',
        groupId: group1Id,
        group: group1,
        invitee: MockUsers.quocDat,
        relationship: 'Anh',
        status: GroupMemberStatus.pending,
        sentAt: now.subtract(const Duration(days: 2)),
        sharedMetrics: const [
          MetricType.heartRate,
          MetricType.stepsCount,
        ],
      ),
    ];
  }

  // ---------- Thông báo hiển thị ở trang chủ ----------

  /// Danh sách thông báo giả cho trang chủ (nhắc thuốc, cảnh báo chỉ số,
  /// hoạt động của người nhà). Sửa ở đây để đổi nội dung thông báo demo.
  static List<FamilyNotification> get notifications => [
        FamilyNotification(
          id: 'demo-noti-1',
          message:
              'Bạn chưa uống Vitamin D3 lúc 12:00. Nhớ uống cùng bữa trưa nhé!',
          timeAgo: '12:00',
          type: NotificationType.important,
        ),
        FamilyNotification(
          id: 'demo-noti-2',
          message:
              '${MockUsers.baoLong.name} có huyết áp 142/92 mmHg, cao hơn bình thường',
          timeAgo: '1 giờ trước',
          type: NotificationType.urgent,
        ),
        FamilyNotification(
          id: 'demo-noti-3',
          message:
              '${MockUsers.thuMai.name} đã mời bạn vào nhóm "Nhóm chăm sóc mẹ"',
          timeAgo: '20 giờ trước',
          type: NotificationType.info,
        ),
        FamilyNotification(
          id: 'demo-noti-4',
          message:
              '${MockUsers.hoa.name} đã hoàn thành 10.240 bước hôm nay — vượt mục tiêu!',
          timeAgo: 'Sáng nay',
          type: NotificationType.info,
        ),
      ];

  /// Yêu cầu đang chờ **chủ nhóm duyệt** (người được mời đã bấm Đồng ý).
  static List<OutgoingInvitation> get pendingApprovals {
    final now = _now;
    return [
      OutgoingInvitation(
        id: 'demo-inv-approval-1',
        groupId: group1Id,
        group: group1,
        invitee: MockUsers.thanhLan,
        relationship: 'Em gái',
        status: GroupMemberStatus.pendingOwnerApproval,
        sentAt: now.subtract(const Duration(days: 1, hours: 4)),
        sharedMetrics: const [
          MetricType.heartRate,
          MetricType.stepsCount,
          MetricType.spo2,
        ],
      ),
    ];
  }
}
