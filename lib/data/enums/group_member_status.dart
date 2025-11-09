enum GroupMemberStatus {
  pending,
  accepted,
  declined,
  revoked;

  String get value => name;

  static GroupMemberStatus fromValue(String? value) {
      switch (value) {
        case 'accepted':
          return accepted;
        case 'declined':
          return declined;
        case 'revoked':
          return revoked;
        case 'pending':
        default:
          return pending;
    }
  }
}