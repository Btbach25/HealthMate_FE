import 'package:fe/core/utils/converter.dart';

class Group {
  final String id;
  final String name;
  final String? description;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Group({
    required this.id,
    required this.name,
    this.description,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      ownerId: json['owner_id'] as String,
      createdAt: cvToDateRequired(json['created_at'] as String),
      updatedAt: cvToDateRequired(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'owner_id': ownerId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Group copyWith({
    String? id,
    String? name,
    String? description,
    String? ownerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}