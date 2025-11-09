enum UserRole {
  user,
  admin;

  String get value => name;

  static UserRole fromValue(String? value) {
    return value == 'admin' ? admin : user;
  }
}