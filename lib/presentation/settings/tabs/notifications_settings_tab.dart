import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class NotificationsSettingsTab extends StatefulWidget {
  const NotificationsSettingsTab({super.key});

  @override
  State<NotificationsSettingsTab> createState() =>
      _NotificationsSettingsTabState();
}

class _NotificationsSettingsTabState extends State<NotificationsSettingsTab> {
  bool _medicationReminders = true;
  bool _healthAlerts = true;
  bool _groupNotifications = true;
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  double _reminderVolume = 70.0;

  void _updateSetting(String key, dynamic value) {
    setState(() {
      switch (key) {
        case 'medicationReminders':
          _medicationReminders = value;
          break;
        case 'healthAlerts':
          _healthAlerts = value;
          break;
        case 'groupNotifications':
          _groupNotifications = value;
          break;
        case 'pushNotifications':
          _pushNotifications = value;
          break;
        case 'emailNotifications':
          _emailNotifications = value;
          break;
        case 'soundEnabled':
          _soundEnabled = value;
          break;
        case 'vibrationEnabled':
          _vibrationEnabled = value;
          break;
        case 'reminderVolume':
          _reminderVolume = value;
          break;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã cập nhật cài đặt'),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSize.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notification Types Card
          _buildCard(
            icon: Icons.notifications_outlined,
            title: 'Cài đặt thông báo',
            children: [
              _buildSwitchRow(
                title: 'Nhắc nhở uống thuốc',
                description: 'Nhận thông báo khi đến giờ uống thuốc',
                value: _medicationReminders,
                onChanged: (value) => _updateSetting('medicationReminders', value),
              ),
              const Divider(height: 24),
              _buildSwitchRow(
                title: 'Cảnh báo sức khỏe',
                description: 'Thông báo khi chỉ số vượt ngưỡng',
                value: _healthAlerts,
                onChanged: (value) => _updateSetting('healthAlerts', value),
              ),
              const Divider(height: 24),
              _buildSwitchRow(
                title: 'Thông báo nhóm',
                description: 'Nhận thông báo từ các nhóm chia sẻ',
                value: _groupNotifications,
                onChanged: (value) => _updateSetting('groupNotifications', value),
              ),
              const Divider(height: 24),
              _buildSwitchRow(
                title: 'Push notifications',
                description: 'Nhận thông báo đẩy từ ứng dụng',
                value: _pushNotifications,
                onChanged: (value) => _updateSetting('pushNotifications', value),
              ),
              const Divider(height: 24),
              _buildSwitchRow(
                title: 'Thông báo email',
                description: 'Nhận thông báo qua email',
                value: _emailNotifications,
                onChanged: (value) => _updateSetting('emailNotifications', value),
              ),
            ],
          ),
          
          const SizedBox(height: AppSize.spacing24),
          
          // Sound & Vibration Card
          _buildCard(
            icon: Icons.volume_up_outlined,
            title: 'Âm thanh & rung',
            children: [
              _buildSwitchRow(
                title: 'Âm thanh thông báo',
                description: 'Phát âm thanh khi có thông báo',
                icon: Icons.volume_up_outlined,
                value: _soundEnabled,
                onChanged: (value) => _updateSetting('soundEnabled', value),
              ),
              const Divider(height: 24),
              _buildSwitchRow(
                title: 'Rung',
                description: 'Rung thiết bị khi có thông báo',
                icon: Icons.vibration,
                value: _vibrationEnabled,
                onChanged: (value) => _updateSetting('vibrationEnabled', value),
              ),
              const Divider(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Âm lượng nhắc nhở',
                        style: AppTextStyles.labelLarge,
                      ),
                      Text(
                        '${_reminderVolume.toInt()}%',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _reminderVolume,
                    min: 0,
                    max: 100,
                    divisions: 10,
                    label: '${_reminderVolume.toInt()}%',
                    onChanged: (value) => _updateSetting('reminderVolume', value),
                  ),
                ],
              ),
            ],
          ),
          
          SizedBox(height: MediaQuery.of(context).padding.bottom + 100),
        ],
      ),
    );
  }

  Widget _buildCard({
    IconData? icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadowList,
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: AppTextStyles.h4.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchRow({
    required String title,
    required String description,
    IconData? icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: AppColors.textGrey),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: Colors.transparent,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            splashRadius: 0,
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.white;
              }
              return Colors.grey[300];
            }),
          ),
        ),
      ],
    );
  }
}

