import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:fe/core/utils/converter.dart';
import 'package:fe/data/enums/login_provider.dart';
import 'package:fe/data/enums/user_role.dart';
import 'package:fe/data/enums/user_status.dart';

/// Hồ sơ người dùng — ánh xạ `GET /users/profile` và khối `user` trong
/// response đăng nhập.
///
/// Cũng là dạng được serialize để lưu phiên đăng nhập trong
/// SharedPreferences (xem [toJsonString] và `LocalStorageService`).
class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? picture;
  final UserRole role;
  final UserStatus status;
  final LoginProvider provider;
  final String? googleId;
  final String? passwordHash;
  final String? phone;
  final String? address;
  final String? gender;
  final String? birthday;
  final double? weight;
  final double? height;
  final String? bloodGroup;
  final String? timezone;
  final List<String> allergies;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.picture,
    required this.role,
    required this.status,
    required this.provider,
    this.googleId,
    this.passwordHash,
    this.phone,
    this.address,
    this.gender,
    this.birthday,
    this.weight,
    this.height,
    this.bloodGroup,
    this.timezone,
    this.allergies = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.empty() {
    return User(
      id: '',
      email: '',
      name: '',
      role: UserRole.user,
      status: UserStatus.unverified,
      provider: LoginProvider.email,
      allergies: const [],
      createdAt: DateTime(0),
      updatedAt: DateTime(0),
    );
  }

  bool get isEmpty => id == '';
  bool get isNotEmpty => id != '';

  factory User.fromJson(Map<String, dynamic> json) {
    final rawAllergies = json['allergies'];
    final List<String> allergiesList = rawAllergies is List
        ? List<String>.from(rawAllergies.whereType<String>())
        : const [];
    return User(
      id: cvToString(json['id']),
      email: cvToString(json['email']),
      name: cvToString(json['name']),
      picture: cvToStringOrNull(json['picture']),
      role: UserRole.fromValue(cvToStringOrNull(json['role'])),
      status: UserStatus.fromValue(cvToStringOrNull(json['status'])),
      provider: LoginProvider.fromValue(cvToStringOrNull(json['provider'])),
      googleId: cvToStringOrNull(json['google_id']),
      passwordHash: cvToStringOrNull(json['password_hash'] ?? json['password']),
      phone: cvToStringOrNull(json['phone']),
      address: cvToStringOrNull(json['address']),
      gender: cvToStringOrNull(json['gender']),
      birthday: cvToStringOrNull(json['birthday']),
      weight: cvToDoubleOrNull(json['weight']),
      height: cvToDoubleOrNull(json['height']),
      bloodGroup: cvToStringOrNull(json['blood_group']),
      timezone: cvToStringOrNull(json['timezone']),
      allergies: allergiesList,
      createdAt: cvToDate(json['created_at'], defaultValue: DateTime(0)),
      updatedAt: cvToDate(json['updated_at'], defaultValue: DateTime(0)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'picture': picture,
      'role': role.value,
      'status': status.value,
      'provider': provider.value,
      'google_id': googleId,
      'password_hash': passwordHash,
      'phone': phone,
      'address': address,
      'gender': gender,
      'birthday': birthday,
      'weight': weight,
      'height': height,
      'blood_group': bloodGroup,
      'timezone': timezone,
      'allergies': allergies,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory User.fromJsonString(String source) {
    final map = jsonDecode(source);
    if (map is Map<String, dynamic>) {
      return User.fromJson(map);
    }
    return User.empty();
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? picture,
    UserRole? role,
    UserStatus? status,
    LoginProvider? provider,
    String? googleId,
    String? passwordHash,
    String? phone,
    String? address,
    String? gender,
    String? birthday,
    double? weight,
    double? height,
    String? bloodGroup,
    String? timezone,
    List<String>? allergies,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      picture: picture ?? this.picture,
      role: role ?? this.role,
      status: status ?? this.status,
      provider: provider ?? this.provider,
      googleId: googleId ?? this.googleId,
      passwordHash: passwordHash ?? this.passwordHash,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      gender: gender ?? this.gender,
      birthday: birthday ?? this.birthday,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      timezone: timezone ?? this.timezone,
      allergies: allergies ?? this.allergies,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        picture,
        role,
        status,
        provider,
        googleId,
        passwordHash,
        phone,
        address,
        gender,
        birthday,
        weight,
        height,
        bloodGroup,
        timezone,
        allergies,
        createdAt,
        updatedAt,
      ];
}
