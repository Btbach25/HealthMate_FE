import 'package:equatable/equatable.dart';
import 'dart:convert';

class User extends Equatable {
  final String id;
  final String name;

  const User({required this.id, required this.name});

  // Thêm một constructor rỗng để đại diện cho người dùng chưa đăng nhập
  const User.empty() : this(id: '', name: '');

  bool get isEmpty => this == const User.empty();
  bool get isNotEmpty => this != const User.empty();

  @override
  List<Object> get props => [id, name];

  // --- THÊM CÁC HÀM NÀY ---
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory User.fromJson(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
    );
  }

  String toJsonString() => json.encode(toJson());

  factory User.fromJsonString(String source) => User.fromJson(json.decode(source));
}