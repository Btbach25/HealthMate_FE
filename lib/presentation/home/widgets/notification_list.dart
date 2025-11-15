import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/data/models/group/family_notification.dart';
import 'package:fe/presentation/home/widgets/notification_tile.dart';
import 'package:flutter/material.dart';

class NotificationList extends StatelessWidget {
  final List<FamilyNotification> notifications;
  const NotificationList({super.key, required this.notifications});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông báo gia đình',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textBlack,
            ),
          ),
          if (notifications.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: Text(
                'Không có thông báo mới.',
                style: TextStyle(color: AppColors.textGrey),
              ),
            )
          else
            ListView.separated(
              itemCount: notifications.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8),
              itemBuilder: (context, index) {
                return NotificationTile(
                  notification: notifications[index],
                );
              },
              separatorBuilder: (context, index) {
                return const Divider(color: Colors.black12);
              },
            ),
        ],
      ),
    );
  }
}