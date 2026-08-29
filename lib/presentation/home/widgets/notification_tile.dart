import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_icons.dart';
import 'package:fe/data/enums/notification_type.dart';
import 'package:fe/data/models/group/family_notification.dart';
import 'package:flutter/material.dart';

/// Một dòng thông báo gia đình: người gửi, thời điểm, nội dung và nhãn mức độ.
///
/// [notification] bắt buộc.
///
/// Hiện tại tên người gửi luôn hiển thị cứng là "Bạn" (xem ghi chú trong build),
/// nên chỉ tái sử dụng được ở nơi mọi thông báo đều của chính người dùng.
class NotificationTile extends StatelessWidget {
  final FamilyNotification notification;
  const NotificationTile({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // TODO(backend): FamilyNotification chưa mang tên người gửi nên tạm
              // hiển thị cứng "Bạn"; đổi khi API trả về trường đó.
              const Text(
                'Bạn',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBlack,
                ),
              ),
              if (notification.timeAgo != null)
                Text(
                  notification.timeAgo!,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            notification.message,
            style: const TextStyle(color: AppColors.textBlack),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          _NotificationTag(type: notification.type),
        ],
      ),
    );
  }
}

/// Nhãn màu theo [NotificationType] (thông tin / quan trọng / khẩn cấp).
class _NotificationTag extends StatelessWidget {
  final NotificationType type;
  const _NotificationTag({required this.type});

  @override
  Widget build(BuildContext context) {
    Color bgColor = AppColors.tagInfoBg;
    Color textColor = AppColors.tagInfoText;
    String text = 'Thông tin';
    IconData? icon = AppIcons.info;

    switch (type) {
      case NotificationType.important:
        bgColor = AppColors.tagImportantBg;
        textColor = AppColors.tagImportantText;
        text = 'Quan trọng';
        icon = AppIcons.important;
        break;
      case NotificationType.urgent:
        bgColor = AppColors.tagUrgentBg;
        textColor = AppColors.tagUrgentText;
        text = 'Khẩn cấp';
        icon = AppIcons.urgent;
        break;
      case NotificationType.info:
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
