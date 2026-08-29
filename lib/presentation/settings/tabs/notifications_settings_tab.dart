import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/core/utils/settings_management_helper.dart';
import 'package:fe/core/widgets/settings_card.dart';
import 'package:fe/core/widgets/settings_switch_row.dart';
import 'package:fe/data/models/settings/notification_settings.dart';
import 'package:fe/data/services/settings_service.dart';
import 'package:flutter/material.dart';

/// Tab "Thông báo" trong [SettingsView]: bật/tắt từng loại nhắc (thuốc, chỉ
/// số, nhóm gia đình…).
///
/// Không nhận tham số; tự nạp [NotificationSettings] qua [SettingsService] ở
/// [State.initState] và tự lưu mỗi khi người dùng gạt công tắc (cập nhật lạc
/// quan, hoàn tác nếu API lỗi).
class NotificationsSettingsTab extends StatefulWidget {
  const NotificationsSettingsTab({super.key});

  @override
  State<NotificationsSettingsTab> createState() =>
      _NotificationsSettingsTabState();
}

class _NotificationsSettingsTabState extends State<NotificationsSettingsTab> {
  final SettingsService _settingsService = SettingsService();
  NotificationSettings _settings = const NotificationSettings();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await SettingsManagementHelper.loadSettingsWithErrorHandling(
      context: context,
      loadFunction: () => _settingsService.loadNotificationSettings(),
      onSuccess: (settings) {
        setState(() {
          _settings = settings;
          _isLoading = false;
        });
      },
      onError: () {
        setState(() {
          _isLoading = false;
        });
      },
    );
  }

  /// Lưu một thay đổi cài đặt.
  ///
  /// Cạm bẫy: tham số kiểu `T Function(...)` rồi ép kiểu ngay bên dưới, nên
  /// hàm `update` truyền vào BẮT BUỘC phải trả về [NotificationSettings] —
  /// trả kiểu khác sẽ không lỗi biên dịch mà nổ lúc chạy. Thấy `<T>` ở đây thì
  /// đừng tưởng nó nhận được kiểu khác.
  Future<void> _updateSetting<T>(T Function(NotificationSettings) update) async {
    await SettingsManagementHelper.updateSettingWithErrorHandling<NotificationSettings>(
      context: context,
      currentSettings: _settings,
      update: update as NotificationSettings Function(NotificationSettings),
      saveFunction: (settings) => _settingsService.saveNotificationSettings(settings),
      onUpdate: (settings) {
        setState(() {
          _settings = settings;
        });
      },
      onRevert: (settings) {
        setState(() {
          _settings = settings;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SettingsManagementHelper.buildLoadingIndicator();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSize.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notification Types Card
          SettingsCard(
            icon: Icons.notifications_outlined,
            title: 'Cài đặt thông báo',
            children: [
              SettingsSwitchRow(
                title: 'Nhắc nhở uống thuốc',
                description: 'Nhận thông báo khi đến giờ uống thuốc',
                value: _settings.medicationReminders,
                onChanged: (value) => _updateSetting(
                  (settings) => settings.copyWith(medicationReminders: value),
                ),
              ),
              const Divider(height: 24, thickness: 0.8, color: AppColors.cardBorder),
              SettingsSwitchRow(
                title: 'Cảnh báo sức khỏe',
                description: 'Thông báo khi chỉ số vượt ngưỡng',
                value: _settings.healthAlerts,
                onChanged: (value) => _updateSetting(
                  (settings) => settings.copyWith(healthAlerts: value),
                ),
              ),
              const Divider(height: 24, thickness: 0.8, color: AppColors.cardBorder),
              SettingsSwitchRow(
                title: 'Thông báo nhóm',
                description: 'Nhận thông báo từ các nhóm chia sẻ',
                value: _settings.groupNotifications,
                onChanged: (value) => _updateSetting(
                  (settings) => settings.copyWith(groupNotifications: value),
                ),
              ),
              const Divider(height: 24, thickness: 0.8, color: AppColors.cardBorder),
              SettingsSwitchRow(
                title: 'Thông báo đẩy',
                description: 'Nhận thông báo đẩy từ ứng dụng',
                value: _settings.pushNotifications,
                onChanged: (value) => _updateSetting(
                  (settings) => settings.copyWith(pushNotifications: value),
                ),
              ),
              const Divider(height: 24, thickness: 0.8, color: AppColors.cardBorder),
              SettingsSwitchRow(
                title: 'Thông báo email',
                description: 'Nhận thông báo qua email',
                value: _settings.emailNotifications,
                onChanged: (value) => _updateSetting(
                  (settings) => settings.copyWith(emailNotifications: value),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSize.spacing24),
          
          // Sound & Vibration Card
          SettingsCard(
            icon: Icons.volume_up_outlined,
            title: 'Âm thanh & rung',
            children: [
              SettingsSwitchRow(
                title: 'Âm thanh thông báo',
                description: 'Phát âm thanh khi có thông báo',
                icon: Icons.volume_up_outlined,
                value: _settings.soundEnabled,
                onChanged: (value) => _updateSetting(
                  (settings) => settings.copyWith(soundEnabled: value),
                ),
              ),
              const Divider(height: 24, thickness: 0.8, color: AppColors.cardBorder),
              SettingsSwitchRow(
                title: 'Rung',
                description: 'Rung thiết bị khi có thông báo',
                icon: Icons.vibration,
                value: _settings.vibrationEnabled,
                onChanged: (value) => _updateSetting(
                  (settings) => settings.copyWith(vibrationEnabled: value),
                ),
              ),
              const Divider(height: 24, thickness: 0.8, color: AppColors.cardBorder),
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
                        '${_settings.reminderVolume.toInt()}%',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _settings.reminderVolume,
                    min: 0,
                    max: 100,
                    divisions: 10,
                    label: '${_settings.reminderVolume.toInt()}%',
                    onChanged: (value) => _updateSetting(
                      (settings) => settings.copyWith(reminderVolume: value),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          SizedBox(
            height: MediaQuery.of(context).padding.bottom +
                AppSize.bottomTabSafeInset,
          ),
        ],
      ),
    );
  }

}

