enum GroupMemberRole {
  member,
  owner,

  /// Backward-compat: some mocks/old BE used "admin".
  admin;

  String get value => name;

  static GroupMemberRole fromValue(String? value) {
    switch (value) {
      case 'owner':
        return owner;
      case 'admin':
        return admin;
      default:
        return member;
    }
  }
}
