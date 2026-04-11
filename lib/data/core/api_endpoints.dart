/// Path API cho **Groups** (khớp BE origin/main).
/// Base URL do [ApiClient.baseUrl] cung cấp. Auth không dùng file này.
class ApiEndpoints {
  ApiEndpoints._();

  // ---------- Groups (cần Bearer) ----------
  static const String groups = '/groups/';
  // Chỗ này không rõ tại sao máy t khi để / mới chạy bình thường
  static const String groupMetricTypes = '/groups/metric-types';

  /// Danh sách lời mời đang chờ (của tôi). API_DOC: GET /groups/invitations
  static const String groupIncomingInvitations = '/groups/invitations';

  static String groupById(String id) => '/groups/$id';

  /// Lời mời pending của một nhóm (BE: GET /groups/:id/invitations, SentInvitationResponse).
  static String groupInvitations(String groupId) =>
      '/groups/$groupId/invitations';
  static String groupMembers(String groupId) => '/groups/$groupId/members';

  /// Cập nhật trạng thái thành viên (accept/reject lời mời): PUT body {"status":"accepted"|"rejected"}.
  static String groupMembersMe(String groupId) => '/groups/$groupId/members/me';
  static String groupMemberById(String groupId, String memberId) =>
      '/groups/$groupId/members/$memberId';
  static String groupPermissions(String groupId) =>
      '/groups/$groupId/permissions';
  static String groupOwner(String groupId) => '/groups/$groupId/owner';

  // ---------- Users (cần Bearer) ----------
  static const String usersProfile = '/users/profile';
  static const String users = '/users';

  // ---------- Medications (storage-service qua gateway, Bearer) ----------
  static const String medications = '/medications';
}
