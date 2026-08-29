enum UserStatus {
  unverified,
  verified;

  String get value => name;

  static UserStatus fromValue(String? value) {
    switch (value) {
      case 'verified':
        return verified;
      case 'unverified':
      default:
        return unverified;
    }
  }
}