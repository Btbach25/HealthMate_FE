import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/data/models/group/family_notification.dart';
import 'package:fe/presentation/home/widgets/notification_tile.dart';
import 'package:flutter/material.dart';

/// Danh sách thông báo từ nhóm gia đình, kèm trạng thái rỗng riêng.
///
/// [notifications] bắt buộc, truyền danh sách rỗng là hợp lệ và sẽ hiện phần
/// "Không có thông báo mới".
///
/// Widget tự dựng ListView với `shrinkWrap` và cuộn bị tắt, nên phải đặt bên trong
/// một vùng cuộn khác — không dùng trực tiếp làm body của một trang dài, vì danh sách
/// nhiều phần tử sẽ dựng hết một lượt.
class NotificationList extends StatelessWidget {
  final List<FamilyNotification> notifications;
  const NotificationList({super.key, required this.notifications});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadowList,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.notifications_none_rounded, color: AppColors.primary, size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'Thông báo gia đình',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textBlack,
                ),
              ),
            ],
          ),
          if (notifications.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_off_outlined, color: AppColors.textLight, size: 28),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Không có thông báo mới',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textGrey),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Thông báo từ nhóm gia đình sẽ hiện ở đây',
                      style: TextStyle(fontSize: 12, color: AppColors.textLight),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              itemCount: notifications.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 10),
              itemBuilder: (context, index) {
                return NotificationTile(notification: notifications[index]);
              },
              separatorBuilder: (context, index) {
                return const Divider(color: AppColors.cardBorder, height: 1);
              },
            ),
        ],
      ),
    );
  }
}