import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:fe/core/utils/converter.dart';
import 'package:fe/data/enums/login_provider.dart';
import 'package:fe/data/enums/user_role.dart';
import 'package:fe/data/enums/user_status.dart';

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
      createdAt: DateTime(0),
      updatedAt: DateTime(0),
    );
  }

  bool get isEmpty => id == '';
  bool get isNotEmpty => id != '';

  factory User.fromJson(Map<String, dynamic> json) {
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id, email, name, picture, role, status, 
        provider, googleId, passwordHash, createdAt, updatedAt
      ];
}