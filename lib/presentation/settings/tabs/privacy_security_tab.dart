import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/utils/settings_management_helper.dart';
import 'package:fe/core/widgets/settings_card.dart';
import 'package:fe/core/widgets/settings_dropdown.dart';
import 'package:fe/core/widgets/settings_switch_row.dart';
import 'package:fe/data/models/settings/privacy_security_settings.dart';
import 'package:fe/data/services/settings_service.dart';
import 'package:flutter/material.dart';

class PrivacySecurityTab extends StatefulWidget {
  const PrivacySecurityTab({super.key});

  @override
  State<PrivacySecurityTab> createState() => _PrivacySecurityTabState();
}

class _PrivacySecurityTabState extends State<PrivacySecurityTab> {
  final SettingsService _settingsService = SettingsService();
  PrivacySecuritySettings _settings = const PrivacySecuritySettings();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await SettingsManagementHelper.loadSettingsWithErrorHandling(
      context: context,
      loadFunction: () => _settingsService.loadPrivacySecuritySettings(),
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

  Future<void> _updateSetting(
    PrivacySecuritySettings Function(PrivacySecuritySettings) update,
  ) async {
    await SettingsManagementHelper.updateSettingWithErrorHandling<PrivacySecuritySettings>(
      context: context,
      currentSettings: _settings,
      update: update,
      saveFunction: (settings) => _settingsService.savePrivacySecuritySettings(settings),
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

  void _showComingSoonSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng đang phát triển')),
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
          // Privacy Settings Card
          SettingsCard(
            icon: Icons.shield_outlined,
            title: 'Quyền riêng tư',
            children: [
              SettingsSwitchRow(
                title: 'Chia sẻ dữ liệu',
                description: 'Cho phép chia sẻ dữ liệu với nhóm',
                icon: Icons.shield_outlined,
                value: _settings.dataSharing,
                onChanged: (value) => _updateSetting(
                  (settings) => settings.copyWith(dataSharing: value),
                ),
              ),
              const Divider(height: 24, thickness: 0.8, color: AppColors.cardBorder),
              SettingsSwitchRow(
                title: 'Phân tích ẩn danh',
                description: 'Gửi dữ liệu ẩn danh để cải thiện ứng dụng',
                value: _settings.anonymousAnalytics,
                onChanged: (value) => _updateSetting(
                  (settings) => settings.copyWith(anonymousAnalytics: value),
                ),
              ),
              const Divider(height: 24, thickness: 0.8, color: AppColors.cardBorder),
              SettingsSwitchRow(
                title: 'Theo dõi vị trí',
                description: 'Cho phép ứng dụng truy cập vị trí',
                value: _settings.locationTracking,
                onChanged: (value) => _updateSetting(
                  (settings) => settings.copyWith(locationTracking: value),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSize.spacing24),
          
          // Security Settings Card
          SettingsCard(
            icon: Icons.lock_outlined,
            title: 'Bảo mật ứng dụng',
            children: [
              SettingsSwitchRow(
                title: 'Xác thực sinh trắc học',
                description: 'Sử dụng vân tay hoặc Face ID',
                icon: Icons.lock_outlined,
                value: _settings.biometricAuth,
                onChanged: (value) {
                  _updateSetting(
                    (settings) => settings.copyWith(biometricAuth: value),
                  );
                  _showComingSoonSnack();
                },
              ),
              const Divider(height: 24, thickness: 0.8, color: AppColors.cardBorder),
              SettingsSwitchRow(
                title: 'Tự động khóa',
                description: 'Khóa ứng dụng khi không sử dụng',
                value: _settings.autoLock,
                onChanged: (value) => _updateSetting(
                  (settings) => settings.copyWith(autoLock: value),
                ),
              ),
              if (_settings.autoLock) ...[
                const Divider(height: 24, thickness: 0.8, color: AppColors.cardBorder),
                SettingsDropdown(
                  label: 'Thời gian tự động khóa',
                  value: _settings.lockTimeout,
                  items: const ['1 phút', '5 phút', '10 phút', '30 phút'],
                  onChanged: (value) {
                    if (value != null) {
                      _updateSetting(
                        (settings) => settings.copyWith(lockTimeout: value),
                      );
                    }
                  },
                ),
              ],
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

