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
      id: cvToString(json['id']),
      userId: cvToString(json['user_id']),
      groupId: cvToString(json['group_id']),
      name: cvToString(json['name']),
      email: cvToStringOrNull(json['email']),
      age: cvToIntOrNull(json['age']),
      relationship: cvToStringOrNull(json['relationship']),
      avatar: cvToStringOrNull(json['avatar']),
      healthStatus: HealthStatus.fromValue(cvToStringOrNull(json['health_status'])),
      lastUpdated: cvToDateOrNull(json['last_updated']),
      healthConditions: cvToList(
        json['health_conditions'],
        (e) => cvToString(e),
      ),
      sharedMetrics: cvToList(
        json['shared_metrics'],
        (e) => MetricType.fromValue(cvToString(e)),
      ),
      createdAt: cvToDateRequired(json['created_at']),
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

  /// Converts FamilyMember to JSON string
  String toJsonString() {
    return cvJsonToString(toJson());
  }

  /// Creates FamilyMember from JSON string
  factory FamilyMember.fromJsonString(String source) {
    final json = cvStringToJson(source);
    return FamilyMember.fromJson(json);
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

