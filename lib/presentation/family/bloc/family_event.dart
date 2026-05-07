part of 'family_bloc.dart';

abstract class FamilyEvent extends Equatable {
  const FamilyEvent();

  @override
  List<Object?> get props => [];
}

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
  List<Object?> get props =>
      [name, sharedMetrics, enableMedicationReminderShare];
}

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
  List<Object?> get props =>
      [groupId, name, sharedMetrics, enableMedicationReminderShare];
}

class DeleteGroup extends FamilyEvent {
  final String groupId;

  const DeleteGroup({required this.groupId});

  @override
  List<Object?> get props => [groupId];
}

class LeaveGroup extends FamilyEvent {
  final String groupId;

  const LeaveGroup({required this.groupId});

  @override
  List<Object?> get props => [groupId];
}

class FetchGroupDetails extends FamilyEvent {
  final String groupId;
  /// True khi đây là lần gọi lại sau 401 (tránh retry vô hạn).
  final bool isRetryAfter401;

  const FetchGroupDetails({required this.groupId, this.isRetryAfter401 = false});

  @override
  List<Object?> get props => [groupId, isRetryAfter401];
}

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
  List<Object?> get props => [groupId, email, name, relationship, age, sharedMetrics, userId];
}

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

class FetchIncomingInvitations extends FamilyEvent {
  const FetchIncomingInvitations();
}

class FetchOutgoingInvitations extends FamilyEvent {
  const FetchOutgoingInvitations();
}

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

/// BE dùng group ID trong path: POST /groups/:id/accept.
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

/// BE dùng group ID trong path: POST /groups/:id/reject.
class DeclineInvitation extends FamilyEvent {
  final String groupId;

  const DeclineInvitation({required this.groupId});

  @override
  List<Object?> get props => [groupId];
}

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

/// Owner: fetch danh sách thành viên đang chờ duyệt từ GET /groups/:id/pending-approvals.
class FetchPendingApprovals extends FamilyEvent {
  final String groupId;

  const FetchPendingApprovals({required this.groupId});

  @override
  List<Object?> get props => [groupId];
}

/// Chủ nhóm duyệt yêu cầu tham gia.
/// Endpoint: POST /groups/:groupId/approve/:memberId
class ApproveJoinRequest extends FamilyEvent {
  final String groupId;
  final String memberId;

  const ApproveJoinRequest({required this.groupId, required this.memberId});

  @override
  List<Object?> get props => [groupId, memberId];
}

/// Chủ nhóm từ chối yêu cầu tham gia.
/// Endpoint: POST /groups/:groupId/reject-approval/:memberId
class RejectJoinRequest extends FamilyEvent {
  final String groupId;
  final String memberId;

  const RejectJoinRequest({required this.groupId, required this.memberId});

  @override
  List<Object?> get props => [groupId, memberId];
}

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
  List<Object?> get props =>
      [groupId, memberId, sharedMetrics, allowMedicationReminderShare];
}


