import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class LocalStorageService {
  static const String _userKey = 'current_user';

  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, user.toJsonString());
  }

  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString(_userKey);
    if (userString != null) {
      return User.fromJsonString(userString);
    }
    return null;
  }

  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
}