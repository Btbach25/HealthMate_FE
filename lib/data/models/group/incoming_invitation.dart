import 'package:equatable/equatable.dart';
import 'package:fe/data/enums/metric_type.dart';

class IncomingInvitation extends Equatable {
  final String id;
  final String groupId;
  final String groupName;
  final String inviterName;
  final String inviterEmail;
  final DateTime sentAt;
  final List<MetricType> sharedMetrics;
  final int memberCount;

  const IncomingInvitation({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.inviterName,
    required this.inviterEmail,
    required this.sentAt,
    required this.sharedMetrics,
    required this.memberCount,
  });

  @override
  List<Object?> get props => [
        id,
        groupId,
        groupName,
        inviterName,
        inviterEmail,
        sentAt,
        sharedMetrics,
        memberCount,
      ];
}

