/// Path API cho **Groups** (khớp BE origin/main).
/// Base URL do [ApiClient.baseUrl] cung cấp. Auth không dùng file này.
class ApiEndpoints {
  ApiEndpoints._();

  // ---------- Groups (cần Bearer) ----------

  /// Lưu ý: PHẢI giữ dấu `/` ở cuối. BE trả 404 nếu bỏ dấu `/` cuối
  /// (chưa rõ nguyên nhân — nghi do cấu hình redirect/route của gateway).
  /// Đừng "dọn dẹp" dấu `/` này.
  static const String groups = '/groups/';

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

  /// Danh sách thành viên đang chờ chủ nhóm duyệt (owner only).
  static String groupPendingApprovals(String groupId) =>
      '/groups/$groupId/pending-approvals';

  /// Metrics mà người dùng hiện tại được xem của từng thành viên trong nhóm
  /// (dựa theo quyền chia sẻ của từng thành viên, không phải quyền của viewer).
  static String groupMembersVisibleMetrics(String groupId) =>
      '/groups/$groupId/members/visible-metrics';

  /// Chủ nhóm duyệt một yêu cầu tham gia.
  static String groupApprove(String groupId, String memberId) =>
      '/groups/$groupId/approve/$memberId';

  /// Chủ nhóm từ chối một yêu cầu tham gia.
  static String groupRejectApproval(String groupId, String memberId) =>
      '/groups/$groupId/reject-approval/$memberId';

  // ---------- Users (cần Bearer) ----------
  static const String usersProfile = '/users/profile';
  static const String users = '/users';

  // ---------- Medications (storage-service qua gateway, Bearer) ----------
  static const String medications = '/medications';
  static const String medicationsDeviceToken = '/medications/device-token';

  static String medicationShares(String medicationId) =>
      '/medications/$medicationId/shares';

  static String medicationShareById(String medicationId, String shareId) =>
      '/medications/$medicationId/shares/$shareId';

  // ---------- OCR (ocr-service qua api-gateway; Bearer bắt buộc — route nằm trong nhóm JWT) ----------
  static const String ocrPrescriptionParse = '/ocr/prescriptions/parse';
}
