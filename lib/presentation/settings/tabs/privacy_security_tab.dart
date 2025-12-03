import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class PrivacySecurityTab extends StatefulWidget {
  const PrivacySecurityTab({super.key});

  @override
  State<PrivacySecurityTab> createState() => _PrivacySecurityTabState();
}

class _PrivacySecurityTabState extends State<PrivacySecurityTab> {
  bool _dataSharing = true;
  bool _anonymousAnalytics = false;
  bool _locationTracking = false;
  bool _biometricAuth = false;
  bool _autoLock = true;
  String _lockTimeout = '5 phút';

  void _updateSetting(String key, dynamic value) {
    setState(() {
      switch (key) {
        case 'dataSharing':
          _dataSharing = value;
          break;
        case 'anonymousAnalytics':
          _anonymousAnalytics = value;
          break;
        case 'locationTracking':
          _locationTracking = value;
          break;
        case 'biometricAuth':
          _biometricAuth = value;
          break;
        case 'autoLock':
          _autoLock = value;
          break;
        case 'lockTimeout':
          _lockTimeout = value;
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
          // Privacy Settings Card
          _buildCard(
            icon: Icons.shield_outlined,
            title: 'Quyền riêng tư',
            children: [
              _buildSwitchRow(
                title: 'Chia sẻ dữ liệu',
                description: 'Cho phép chia sẻ dữ liệu với nhóm',
                icon: Icons.shield_outlined,
                value: _dataSharing,
                onChanged: (value) => _updateSetting('dataSharing', value),
              ),
              const Divider(height: 24),
              _buildSwitchRow(
                title: 'Phân tích ẩn danh',
                description: 'Gửi dữ liệu ẩn danh để cải thiện ứng dụng',
                value: _anonymousAnalytics,
                onChanged: (value) => _updateSetting('anonymousAnalytics', value),
              ),
              const Divider(height: 24),
              _buildSwitchRow(
                title: 'Theo dõi vị trí',
                description: 'Cho phép ứng dụng truy cập vị trí',
                value: _locationTracking,
                onChanged: (value) => _updateSetting('locationTracking', value),
              ),
            ],
          ),
          
          const SizedBox(height: AppSize.spacing24),
          
          // Security Settings Card
          _buildCard(
            icon: Icons.lock_outlined,
            title: 'Bảo mật ứng dụng',
            children: [
              _buildSwitchRow(
                title: 'Xác thực sinh trắc học',
                description: 'Sử dụng vân tay hoặc Face ID',
                icon: Icons.lock_outlined,
                value: _biometricAuth,
                onChanged: (value) {
                  // TODO: Implement biometric auth
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tính năng đang phát triển'),
                    ),
                  );
                },
              ),
              const Divider(height: 24),
              _buildSwitchRow(
                title: 'Tự động khóa',
                description: 'Khóa ứng dụng khi không sử dụng',
                value: _autoLock,
                onChanged: (value) => _updateSetting('autoLock', value),
              ),
              if (_autoLock) ...[
                const Divider(height: 24),
                _buildDropdown(
                  label: 'Thời gian tự động khóa',
                  value: _lockTimeout,
                  items: const ['1 phút', '5 phút', '10 phút', '30 phút'],
                  onChanged: (value) => _updateSetting('lockTimeout', value),
                ),
              ],
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

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}

