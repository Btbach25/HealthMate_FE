enum LoginProvider {
  email,
  google;

  String get value => name;

  static LoginProvider fromValue(String? value) {
    switch (value) {
      case 'google':
        return google;
      case 'email':
      default:
        return email;
    }
  }
}
