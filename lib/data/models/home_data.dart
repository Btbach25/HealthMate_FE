import 'package:equatable/equatable.dart';
import 'package:fe/data/models/group/family_notification.dart';
import 'package:fe/data/models/health/medication_progress.dart';
import 'package:fe/data/models/user/user.dart';

/// Dữ liệu tổng hợp cho trang chủ.
///
/// Không phải response của một endpoint duy nhất: `HomeService` ghép từ
/// profile user, tiến độ uống thuốc và thông báo nhóm.
class HomeData extends Equatable {
  final User user;
  final MedicationProgress? medicationProgress;
  final List<FamilyNotification> notifications;

  const HomeData({
    required this.user,
    this.medicationProgress,
    required this.notifications,
  });

  factory HomeData.empty() {
    return HomeData(
      user: User.empty(),
      medicationProgress: null,
      notifications: const [],
    );
  }

  HomeData copyWith({
    User? user,
    MedicationProgress? medicationProgress,
    List<FamilyNotification>? notifications,
  }) {
    return HomeData(
      user: user ?? this.user,
      medicationProgress: medicationProgress ?? this.medicationProgress,
      notifications: notifications ?? this.notifications,
    );
  }

  @override
  List<Object?> get props => [
    user,
    medicationProgress,
    notifications,
  ];
}
