part of 'family_bloc.dart';

/// Lớp cha của mọi event trong miền nhóm gia đình.
/// Xem [FamilyBloc] để biết event nào dẫn tới status nào và kéo theo reload gì.
abstract class FamilyEvent extends Equatable {
  const FamilyEvent();

  @override
  List<Object?> get props => [];
}

/// Tải danh sách nhóm của người dùng (GET /groups) và bắn kèm 2 event lời mời.
/// Lưu ý: xoá `currentGroupId`/`groupDetails` nên đừng gọi khi đang ở màn chi tiết nhóm.
class FetchFamilyGroups extends FamilyEvent {
  /// True khi đây là lần gọi lại sau 401 (tránh retry vô hạn).
  final bool isRetryAfter401;
  const FetchFamilyGroups({this.isRetryAfter401 = false});

  @override
  List<Object?> get props => [isRetryAfter401];
}

/// Đưa bloc về trạng thái ban đầu (sau đăng xuất / trước khi đăng nhập lại) để không giữ màn lỗi 401 cũ.
class ResetFamily extends FamilyEvent {
  const ResetFamily();
}

/// Bước 1 của 2-step create: chỉ POST /groups với tên. Bước 2 PUT permissions qua UpdateGroup.
class CreateGroupName extends FamilyEvent {
  final String name;

  const CreateGroupName({required this.name});

  @override
  List<Object?> get props => [name];
}

/// Tạo nhóm trong một lần gọi (tên + quyền chia sẻ). Luồng UI hiện tại dùng
/// [CreateGroupName] rồi [UpdateGroup]; event này giữ cho các lối vào tạo nhanh.
class CreateGroup extends FamilyEvent {
  final String name;
  final List<String> sharedMetrics;
  final bool enableMedicationReminderShare;

  const CreateGroup({
    required this.name,
    required this.sharedMetrics,
    this.enableMedicationReminderShare = false,
  });

  @override
  List<Object?> get props => [
    name,
    sharedMetrics,
    enableMedicationReminderShare,
  ];
}

/// Sửa cài đặt chung của nhóm (chỉ chủ nhóm). Cũng là bước 2 của luồng tạo nhóm.
/// Field nào để `null` thì không đụng tới trên server.
class UpdateGroup extends FamilyEvent {
  final String groupId;
  final String? name;
  final List<String>? sharedMetrics;
  final bool? enableMedicationReminderShare;

  const UpdateGroup({
    required this.groupId,
    this.name,
    this.sharedMetrics,
    this.enableMedicationReminderShare,
  });

  @override
  List<Object?> get props => [
    groupId,
    name,
    sharedMetrics,
    enableMedicationReminderShare,
  ];
}

/// Xoá hẳn nhóm (chỉ chủ nhóm). Dùng khi chủ nhóm rời lúc chỉ còn một mình.
class DeleteGroup extends FamilyEvent {
  final String groupId;

  const DeleteGroup({required this.groupId});

  @override
  List<Object?> get props => [groupId];
}

/// Tự rời nhóm. Chủ nhóm phải chuyển quyền trước (xem [TransferOwnership]).
/// 404 được coi là thành công vì nghĩa là đã không còn trong nhóm.
class LeaveGroup extends FamilyEvent {
  final String groupId;

  const LeaveGroup({required this.groupId});

  @override
  List<Object?> get props => [groupId];
}

/// Tải chi tiết một nhóm (thành viên + quyền). Đồng thời đồng bộ lại
/// `memberCount` của nhóm đó trong summary để 2 màn hình không lệch nhau.
class FetchGroupDetails extends FamilyEvent {
  final String groupId;

  /// True khi đây là lần gọi lại sau 401 (tránh retry vô hạn).
  final bool isRetryAfter401;

  const FetchGroupDetails({
    required this.groupId,
    this.isRetryAfter401 = false,
  });

  @override
  List<Object?> get props => [groupId, isRetryAfter401];
}

/// Chủ nhóm mời một tài khoản đã đăng ký vào nhóm bằng email.
/// Lời mời sinh ra ở trạng thái `pending`, chờ người được mời phản hồi.
class InviteMember extends FamilyEvent {
  final String groupId;
  final String email;

  /// Chỉ dùng mock; BE mời bằng email — tên lấy từ tài khoản khi người được mời tham gia.
  final String name;
  final String? relationship;
  final int? age;
  final List<String> sharedMetrics;

  /// Id người được mời (bắt buộc khi gọi máy chủ). Nếu null, lời mời có thể thất bại.
  final String? userId;

  const InviteMember({
    required this.groupId,
    required this.email,
    this.name = '',
    this.relationship,
    this.age,
    required this.sharedMetrics,
    this.userId,
  });

  @override
  List<Object?> get props => [
    groupId,
    email,
    name,
    relationship,
    age,
    sharedMetrics,
    userId,
  ];
}

/// Chủ nhóm chuyển quyền sở hữu cho thành viên khác (PUT /groups/:id/owner).
/// Bắt buộc trước khi chủ nhóm rời một nhóm còn thành viên khác.
class TransferOwnership extends FamilyEvent {
  final String groupId;
  final String newOwnerId;

  const TransferOwnership({
    required this.groupId,
    required this.newOwnerId,
  });

  @override
  List<Object?> get props => [groupId, newOwnerId];
}

/// Tải lời mời người khác gửi cho mình (tab "Lời mời tham gia").
class FetchIncomingInvitations extends FamilyEvent {
  const FetchIncomingInvitations();
}

/// Tải lời mời mình đã gửi đi (tab "Lời mời đã gửi"), gồm cả các yêu cầu
/// đang ở trạng thái `pendingOwnerApproval` chờ chính mình duyệt.
class FetchOutgoingInvitations extends FamilyEvent {
  const FetchOutgoingInvitations();
}

/// Xem trước nhóm trước khi chấp nhận lời mời. Ghi vào cặp field riêng
/// (`invitationPreview*`) để không đè lên `groupDetails` của nhóm đang mở.
class FetchInvitationPreview extends FamilyEvent {
  final String groupId;
  final bool isRetryAfter401;

  const FetchInvitationPreview({
    required this.groupId,
    this.isRetryAfter401 = false,
  });

  @override
  List<Object?> get props => [groupId, isRetryAfter401];
}

/// Người được mời chấp nhận lời mời.
/// BE: `PUT /groups/:groupId/members/me` body `{"status":"accepted"}`, sau đó
/// PUT quyền chia sẻ theo kiểu best-effort (lỗi ở bước quyền không làm hỏng việc chấp nhận).
/// Sau bước này người dùng **chưa** phải thành viên: trạng thái là `pendingOwnerApproval`,
/// còn chờ chủ nhóm bấm duyệt ([ApproveJoinRequest]).
class AcceptInvitation extends FamilyEvent {
  final String groupId;
  final List<String> sharedMetrics;

  /// Số thành viên hiện tại trong nhóm (không tính người đang nhận lời mời).
  /// Dùng để cập nhật optimistic UI ngay sau khi chấp nhận.
  final int? currentMemberCount;

  const AcceptInvitation({
    required this.groupId,
    required this.sharedMetrics,
    this.currentMemberCount,
  });

  @override
  List<Object?> get props => [groupId, sharedMetrics, currentMemberCount];
}

/// Người được mời từ chối lời mời.
/// BE: `PUT /groups/:groupId/members/me` body `{"status":"rejected"}`.
/// 404 nghĩa là nhóm đã bị xoá — UI báo lỗi rồi tải lại danh sách lời mời.
class DeclineInvitation extends FamilyEvent {
  final String groupId;

  const DeclineInvitation({required this.groupId});

  @override
  List<Object?> get props => [groupId];
}

/// Chủ nhóm loại một thành viên khỏi nhóm (DELETE /groups/:id/members/:memberId).
/// Cạm bẫy: nơi gọi truyền `FamilyMember.id`, nơi khác truyền `FamilyMember.userId`,
/// nhưng `GroupApiMapper.toFamilyMember` gán `id = userId` nên hai đường hiện cho
/// ra cùng một giá trị. Đừng dựa vào sự trùng khớp đó: nếu sau này BE trả `id`
/// riêng cho bản ghi thành viên thì mọi chỗ dùng `member.id` sẽ hỏng âm thầm.
class RemoveMember extends FamilyEvent {
  final String groupId;
  final String memberId;

  const RemoveMember({
    required this.groupId,
    required this.memberId,
  });

  @override
  List<Object?> get props => [groupId, memberId];
}

/// Chỉ chủ nhóm: tải danh sách người đã chấp nhận lời mời và đang chờ mình duyệt
/// (GET /groups/:id/pending-approvals). Lỗi được nuốt và trả danh sách rỗng —
/// khu vực "Yêu cầu chờ duyệt" không đáng làm hỏng cả màn chi tiết nhóm.
class FetchPendingApprovals extends FamilyEvent {
  final String groupId;

  const FetchPendingApprovals({required this.groupId});

  @override
  List<Object?> get props => [groupId];
}

/// Chủ nhóm duyệt yêu cầu tham gia — chặng cuối để invitee thành thành viên thật.
/// Endpoint: POST /groups/:groupId/approve/:memberId ([memberId] là user id của invitee).
class ApproveJoinRequest extends FamilyEvent {
  final String groupId;
  final String memberId;

  const ApproveJoinRequest({required this.groupId, required this.memberId});

  @override
  List<Object?> get props => [groupId, memberId];
}

/// Chủ nhóm từ chối yêu cầu tham gia.
/// Endpoint: POST /groups/:groupId/reject-approval/:memberId ([memberId] là user id của invitee).
class RejectJoinRequest extends FamilyEvent {
  final String groupId;
  final String memberId;

  const RejectJoinRequest({required this.groupId, required this.memberId});

  @override
  List<Object?> get props => [groupId, memberId];
}

/// Người dùng tự đặt bộ chỉ số mình chia sẻ với cả nhóm (ai cũng gọi được cho
/// chính mình). Đây là tầng chung; muốn thu hẹp riêng với một người thì dùng
/// [UpdateMemberPermissions].
class UpdateMySharing extends FamilyEvent {
  final String groupId;
  final List<String> sharedMetrics;

  const UpdateMySharing({
    required this.groupId,
    required this.sharedMetrics,
  });

  @override
  List<Object?> get props => [groupId, sharedMetrics];
}

/// Thu hẹp bộ chỉ số mà **tôi** chia sẻ riêng cho một thành viên cụ thể,
/// trong phạm vi những chỉ số đã bật ở tầng nhóm.
/// [memberId] được gửi lên dưới dạng `target_user_id`, nên phải là `FamilyMember.userId`.
class UpdateMemberPermissions extends FamilyEvent {
  final String groupId;
  final String memberId;
  final List<String> sharedMetrics;
  final bool? allowMedicationReminderShare;

  const UpdateMemberPermissions({
    required this.groupId,
    required this.memberId,
    required this.sharedMetrics,
    this.allowMedicationReminderShare,
  });

  @override
  List<Object?> get props => [
    groupId,
    memberId,
    sharedMetrics,
    allowMedicationReminderShare,
  ];
}
