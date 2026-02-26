import 'package:fe/data/enums/login_provider.dart';
import 'package:fe/data/enums/notification_type.dart';
import 'package:fe/data/enums/user_role.dart';
import 'package:fe/data/enums/user_status.dart';
import 'package:fe/data/models/group/family_notification.dart';
import 'package:fe/data/models/home_data.dart';
import 'package:fe/data/models/health/medication_progress.dart';
import 'package:fe/data/models/user/user.dart';
import 'package:fe/data/services/home_service.dart';

class MockHomeService implements HomeService {
  @override
  Future<HomeData> getHomeData() async {
    await Future.delayed(const Duration(milliseconds: 800));

    final now = DateTime.now();
    const mockUserId = 'c7b5a32a-1b4e-4b8d-9c3a-3f3a2b1b9c0d'; 

    final mockUser = User(
      id: mockUserId,
      name: 'Nguyễn Văn Minh',
      email: 'admin@gmail.com',
      role: UserRole.admin,
      status: UserStatus.verified,
      provider: LoginProvider.email,
      createdAt: DateTime(2023, 10, 1),
      updatedAt: now,
    );

    final medicationProgress = MedicationProgress(completed: 2, total: 4);

    final notifications = [
      FamilyNotification(
        id: '1',
        message: 'Bạn chưa uống Vitamin D3 lúc 19:00',
        timeAgo: '19:00',
        type: NotificationType.important,
      ),
      FamilyNotification(
        id: '2',
        message: 'Huyết áp 145/95 mmHg cao hơn bình thường',
        timeAgo: 'Sáng nay',
        type: NotificationType.urgent,
      ),
      FamilyNotification(
        id: '3',
        message: 'Đã đến giờ đo huyết áp buổi sáng',
        timeAgo: '7:00',
        type: NotificationType.info,
      ),
    ];

    return HomeData(
      user: mockUser,
      medicationProgress: medicationProgress,
      notifications: notifications,
    );
  }
}