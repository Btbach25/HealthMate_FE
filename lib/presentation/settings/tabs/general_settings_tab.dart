import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/presentation/auth/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GeneralSettingsTab extends StatefulWidget {
  const GeneralSettingsTab({super.key});

  @override
  State<GeneralSettingsTab> createState() => _GeneralSettingsTabState();
}

class _GeneralSettingsTabState extends State<GeneralSettingsTab> {
  bool _darkMode = false;
  String _language = 'vi';
  String _dateFormat = 'dd/mm/yyyy';
  String _timeFormat = '24h';

  void _updateSetting(String key, dynamic value) {
    setState(() {
      switch (key) {
        case 'darkMode':
          _darkMode = value;
          break;
        case 'language':
          _language = value;
          break;
        case 'dateFormat':
          _dateFormat = value;
          break;
        case 'timeFormat':
          _timeFormat = value;
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

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận đăng xuất'),
          content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<AuthBloc>().add(AuthLogoutRequested());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đăng xuất thành công'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Đăng xuất'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSize.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Appearance Settings Card
          _buildCard(
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
                          value: _darkMode,
                          onChanged: (value) {
                            // TODO: Implement dark mode
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Tính năng đang phát triển'),
                              ),
                            );
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
              _buildDropdown(
                label: 'Ngôn ngữ',
                value: _language,
                items: const [
                  DropdownMenuItem(value: 'vi', child: Text('Tiếng Việt')),
                  DropdownMenuItem(value: 'en', child: Text('English')),
                ],
                onChanged: (value) {
                  // TODO: Implement language switching
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tính năng đang phát triển'),
                    ),
                  );
                },
              ),
              const Divider(height: 24),
              _buildDropdown(
                label: 'Định dạng ngày',
                value: _dateFormat,
                items: const [
                  DropdownMenuItem(value: 'dd/mm/yyyy', child: Text('DD/MM/YYYY')),
                  DropdownMenuItem(value: 'mm/dd/yyyy', child: Text('MM/DD/YYYY')),
                  DropdownMenuItem(value: 'yyyy-mm-dd', child: Text('YYYY-MM-DD')),
                ],
                onChanged: (value) => _updateSetting('dateFormat', value),
              ),
              const Divider(height: 24),
              _buildDropdown(
                label: 'Định dạng giờ',
                value: _timeFormat,
                items: const [
                  DropdownMenuItem(value: '24h', child: Text('24 giờ')),
                  DropdownMenuItem(value: '12h', child: Text('12 giờ (AM/PM)')),
                ],
                onChanged: (value) => _updateSetting('timeFormat', value),
              ),
            ],
          ),
          
          const SizedBox(height: AppSize.spacing24),
          
          // Logout Card
          Container(
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
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.error.withOpacity(0.3),
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

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
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
      items: items,
      onChanged: onChanged,
    );
  }
}

