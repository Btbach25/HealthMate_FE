import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/utils/settings_management_helper.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/core/widgets/confirmation_dialog.dart';
import 'package:fe/core/widgets/settings_card.dart';
import 'package:fe/core/widgets/settings_dropdown.dart';
import 'package:fe/data/models/settings/general_settings.dart';
import 'package:fe/data/services/settings_service.dart';
import 'package:fe/presentation/auth/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GeneralSettingsTab extends StatefulWidget {
  const GeneralSettingsTab({super.key});

  @override
  State<GeneralSettingsTab> createState() => _GeneralSettingsTabState();
}

class _GeneralSettingsTabState extends State<GeneralSettingsTab> {
  static const List<String> _languageOptions = ['vi', 'en'];
  static const List<String> _dateFormatOptions = [
    'dd/mm/yyyy',
    'mm/dd/yyyy',
    'yyyy-mm-dd',
  ];
  static const List<String> _timeFormatOptions = ['24h', '12h'];

  final SettingsService _settingsService = SettingsService();
  GeneralSettings _settings = const GeneralSettings();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await SettingsManagementHelper.loadSettingsWithErrorHandling(
      context: context,
      loadFunction: () => _settingsService.loadGeneralSettings(),
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
    GeneralSettings Function(GeneralSettings) update,
  ) async {
    await SettingsManagementHelper.updateSettingWithErrorHandling<GeneralSettings>(
      context: context,
      currentSettings: _settings,
      update: update,
      saveFunction: (settings) => _settingsService.saveGeneralSettings(settings),
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

  void _handleLogout() {
    ConfirmationDialog.showErrorConfirmation(
      context: context,
      title: 'Xác nhận đăng xuất',
      message: 'Bạn có chắc chắn muốn đăng xuất?',
      confirmText: 'Đăng xuất',
      onConfirm: () {
        if (!mounted) return;
        context.read<AuthBloc>().add(AuthLogoutRequested());
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
          // Appearance Settings Card
          SettingsCard(
            icon: Icons.palette_outlined,
            title: 'Giao diện',
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.light_mode, color: Colors.orange),
                      const SizedBox(width: 12),
                      const Text(
                        'Chế độ tối',
                        style: AppTextStyles.labelLarge,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('Sáng'),
                      Material(
                        color: Colors.transparent,
                        child: Switch(
                          value: _settings.darkMode,
                          onChanged: (value) {
                            _updateSetting(
                              (settings) => settings.copyWith(darkMode: value),
                            );
                            _showComingSoonSnack();
                          },
                          activeTrackColor: AppColors.primary,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          splashRadius: 0,
                          thumbColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return AppColors.primary;
                            }
                            return null;
                          }),
                        ),
                      ),
                      const Text('Tối'),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24),
              SettingsDropdown(
                label: 'Ngôn ngữ',
                value: _settings.language,
                items: _languageOptions,
                onChanged: (value) {
                  if (value != null) {
                    _updateSetting(
                      (settings) => settings.copyWith(language: value),
                    );
                    _showComingSoonSnack();
                  }
                },
              ),
              const Divider(height: 24),
              SettingsDropdown(
                label: 'Định dạng ngày',
                value: _settings.dateFormat,
                items: _dateFormatOptions,
                onChanged: (value) {
                  if (value != null) {
                    _updateSetting(
                      (settings) => settings.copyWith(dateFormat: value),
                    );
                  }
                },
              ),
              const Divider(height: 24),
              SettingsDropdown(
                label: 'Định dạng giờ',
                value: _settings.timeFormat,
                items: _timeFormatOptions,
                onChanged: (value) {
                  if (value != null) {
                    _updateSetting(
                      (settings) => settings.copyWith(timeFormat: value),
                    );
                  }
                },
              ),
            ],
          ),
          
          const SizedBox(height: AppSize.spacing24),
          
          // Logout Card
          SettingsCard(
            icon: Icons.logout,
            title: 'Tài khoản',
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.error.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout, size: 20),
                  label: const Text(
                    'Đăng xuất',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
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

