enum GroupMemberRole {
  member,
  admin;

  String get value => name;

  static GroupMemberRole fromValue(String? value) {
    return value == 'admin' ? admin : member;
  }
}