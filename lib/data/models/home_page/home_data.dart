import 'package:fe/data/models/health/health_overview.dart';

import '../user/user.dart';

class HomeData {
  final User user; 
  
  final HealthOverview healthOverview; 
  
  final List<dynamic> notifications;
  final double? medicationProgress;

  HomeData({
    required this.user,
    required this.healthOverview,
    this.notifications = const [],
    this.medicationProgress,
  });

  factory HomeData.empty() {
    return HomeData(
      user: User.empty(),
      healthOverview: const HealthOverview(),
      notifications: [],
    );
  }
}