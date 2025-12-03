import 'package:equatable/equatable.dart';
import 'package:fe/core/utils/converter.dart';
import 'package:fe/data/enums/metric_type.dart';

class FamilyMember extends Equatable {
  final String id;
  final String userId;
  final String groupId;
  final String name;
  final String? email;
  final int? age;
  final String? relationship; // Bố, Mẹ, Con trai, Con gái, etc.
  final String? avatar;
  final HealthStatus healthStatus;
  final DateTime? lastUpdated;
  final List<String> healthConditions; // Huyết áp cao, Tiểu đường, etc.
  final List<MetricType> sharedMetrics;
  final DateTime createdAt;

  const FamilyMember({
    required this.id,
    required this.userId,
    required this.groupId,
    required this.name,
    this.email,
    this.age,
    this.relationship,
    this.avatar,
    required this.healthStatus,
    this.lastUpdated,
    this.healthConditions = const [],
    required this.sharedMetrics,
    required this.createdAt,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      groupId: json['group_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      age: json['age'] as int?,
      relationship: json['relationship'] as String?,
      avatar: json['avatar'] as String?,
      healthStatus: HealthStatus.fromValue(json['health_status'] as String?),
      lastUpdated: cvToDate(json['last_updated'] as String?),
      healthConditions: (json['health_conditions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      sharedMetrics: (json['shared_metrics'] as List<dynamic>?)
              ?.map((e) => MetricType.fromValue(e as String))
              .toList() ??
          [],
      createdAt: cvToDateRequired(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'group_id': groupId,
      'name': name,
      'email': email,
      'age': age,
      'relationship': relationship,
      'avatar': avatar,
      'health_status': healthStatus.value,
      'last_updated': lastUpdated?.toIso8601String(),
      'health_conditions': healthConditions,
      'shared_metrics': sharedMetrics.map((e) => e.value).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  FamilyMember copyWith({
    String? id,
    String? userId,
    String? groupId,
    String? name,
    String? email,
    int? age,
    String? relationship,
    String? avatar,
    HealthStatus? healthStatus,
    DateTime? lastUpdated,
    List<String>? healthConditions,
    List<MetricType>? sharedMetrics,
    DateTime? createdAt,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      relationship: relationship ?? this.relationship,
      avatar: avatar ?? this.avatar,
      healthStatus: healthStatus ?? this.healthStatus,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      healthConditions: healthConditions ?? this.healthConditions,
      sharedMetrics: sharedMetrics ?? this.sharedMetrics,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        groupId,
        name,
        email,
        age,
        relationship,
        avatar,
        healthStatus,
        lastUpdated,
        healthConditions,
        sharedMetrics,
        createdAt,
      ];
}

enum HealthStatus {
  good,
  needsAttention,
  healthy;

  String get value {
    switch (this) {
      case HealthStatus.good:
        return 'good';
      case HealthStatus.needsAttention:
        return 'needs_attention';
      case HealthStatus.healthy:
        return 'healthy';
    }
  }

  static HealthStatus fromValue(String? value) {
    switch (value) {
      case 'good':
        return good;
      case 'needs_attention':
        return needsAttention;
      case 'healthy':
        return healthy;
      default:
        return healthy;
    }
  }
}

