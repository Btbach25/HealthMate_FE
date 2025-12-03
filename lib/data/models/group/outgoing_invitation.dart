import 'package:equatable/equatable.dart';
import 'package:fe/data/enums/group_member_status.dart';
import 'package:fe/data/enums/metric_type.dart';

class OutgoingInvitation extends Equatable {
  final String id;
  final String groupId;
  final String groupName;
  final String inviteeEmail;
  final String inviteeName;
  final String? relationship;
  final GroupMemberStatus status;
  final DateTime sentAt;
  final List<MetricType> sharedMetrics;

  const OutgoingInvitation({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.inviteeEmail,
    required this.inviteeName,
    this.relationship,
    required this.status,
    required this.sentAt,
    required this.sharedMetrics,
  });

  @override
  List<Object?> get props => [
        id,
        groupId,
        groupName,
        inviteeEmail,
        inviteeName,
        relationship,
        status,
        sentAt,
        sharedMetrics,
      ];
}

