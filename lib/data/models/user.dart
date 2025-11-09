import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:fe/core/utils/converter.dart';

import '../enums/login_provider.dart';
import '../enums/user_role.dart';
import '../enums/user_status.dart';

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

  User.empty()
      : this(
          id: '',
          email: '',
          name: '',
          role: UserRole.user,
          status: UserStatus.unverified,
          provider: LoginProvider.email,
          createdAt: DateTime(0),
          updatedAt: DateTime(0),
        );
        
  bool get isEmpty => id == '';
  bool get isNotEmpty => id != '';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      picture: json['picture'] as String?,
      role: UserRole.fromValue(json['role'] as String?),
      status: UserStatus.fromValue(json['status'] as String?),
      provider: LoginProvider.fromValue(json['provider'] as String?),
      googleId: json['google_id'] as String?,
      passwordHash: json['password_hash'] as String?,
      createdAt: cvToDateRequired(json['created_at'] as String),
      updatedAt: cvToDateRequired(json['updated_at'] as String),
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
    final map = jsonDecode(source) as Map<String, dynamic>;
    return User.fromJson(map);
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
        id,
        email,
        name,
        picture,
        role,
        status,
        provider,
        googleId,
        passwordHash,
        createdAt,
        updatedAt
      ];
}