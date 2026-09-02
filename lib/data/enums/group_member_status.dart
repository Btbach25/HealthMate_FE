enum GroupMemberStatus {
  pending,
  // Invitee đã đồng ý, chờ chủ nhóm duyệt.
  // BE trả về 'pending_owner_approval'. [BE-REQ-03]
  pendingOwnerApproval,
  accepted,
  declined,
  revoked;

  String get value {
    if (this == pendingOwnerApproval) return 'pending_owner_approval';
    return name;
  }

  static GroupMemberStatus fromValue(String? value) {
    switch (value) {
      case 'accepted':
        return accepted;
      case 'declined':
        return declined;
      case 'revoked':
        return revoked;
      case 'pending_owner_approval':
        return pendingOwnerApproval;
      case 'pending':
      default:
        return pending;
    }
  }
}
