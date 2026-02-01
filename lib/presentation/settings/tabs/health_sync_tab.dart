import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/core/widgets/settings_card.dart';
import 'package:fe/core/widgets/settings_dropdown.dart';
import 'package:fe/core/widgets/settings_switch_row.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HealthSyncTab extends StatefulWidget {
  const HealthSyncTab({super.key});

  @override
  State<HealthSyncTab> createState() => _HealthSyncTabState();
}

class _HealthSyncTabState extends State<HealthSyncTab> {
  final bool _isHealthConnectAvailable = true;
  bool _hasPermissions = false;
  bool _autoSyncEnabled = false;
  String _syncInterval = '5 phút';
  bool _isSyncing = false;
  // ignore: unused_field
  DateTime? _lastSyncTime; // Reserved for future use
  
  final Map<String, bool> _healthDataTypes = {
    'heart_rate': true,
    'steps': true,
    'calories': true,
    'sleep': false,
  };

  Future<void> _requestPermissions() async {
    // Simulate permission request
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _hasPermissions = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cấp quyền truy cập dữ liệu sức khỏe'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _performSync() async {
    if (!_hasPermissions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng cấp quyền truy cập trước'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSyncing = true;
    });

    // Simulate sync
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isSyncing = false;
        _lastSyncTime = DateTime.now();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đồng bộ dữ liệu thành công'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSize.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sync Header Card
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.cardShadowList,
              border: Border.all(color: AppColors.cardBorder, width: 0.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.sync,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Đồng bộ dữ liệu sức khỏe',
                            style: AppTextStyles.h4.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (!_hasPermissions) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Chưa cấp quyền',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (!_hasPermissions && _isHealthConnectAvailable)
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: AppColors.buttonShadow,
                    ),
                    child: ElevatedButton(
                      onPressed: _requestPermissions,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      child: const Text(
                        'Cấp quyền',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                else if (_hasPermissions)
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: AppColors.buttonShadow,
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _isSyncing ? null : _performSync,
                      icon: _isSyncing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.sync, size: 18),
                      label: Text(
                        _isSyncing ? 'Đang đồng bộ...' : 'Đồng bộ ngay',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          if (!_hasPermissions) ...[
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withValues(alpha:0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ứng dụng cần quyền truy cập Health Connect để đồng bộ dữ liệu sức khỏe. Vui lòng cấp quyền để sử dụng tính năng này.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: AppSize.spacing24),
          
          // Auto Sync Card
          SettingsCard(
            icon: Icons.settings_outlined,
            title: 'Cài đặt đồng bộ tự động',
            children: [
              SettingsSwitchRow(
                title: 'Đồng bộ tự động',
                description: 'Tự động đồng bộ dữ liệu theo chu kỳ',
                value: _autoSyncEnabled,
                enabled: _hasPermissions,
                onChanged: (value) {
                  setState(() {
                    _autoSyncEnabled = value;
                  });
                },
              ),
              if (_autoSyncEnabled && _hasPermissions) ...[
                const Divider(height: 24),
                SettingsDropdown(
                  label: 'Chu kỳ đồng bộ',
                  value: _syncInterval,
                  items: const ['1 phút', '5 phút', '10 phút', '30 phút', '1 giờ'],
                  onChanged: (value) {
                    setState(() {
                      _syncInterval = value ?? '5 phút';
                    });
                  },
                ),
              ],
            ],
          ),
          
          const SizedBox(height: AppSize.spacing24),
          
          // Health Data Types Card
          SettingsCard(
            icon: Icons.favorite,
            title: 'Dữ liệu sức khỏe',
            children: [
              _buildHealthDataTypeRow(
                name: 'Nhịp tim',
                icon: Icons.favorite,
                key: 'heart_rate',
                enabled: _healthDataTypes['heart_rate'] ?? false,
              ),
              const Divider(height: 24),
              _buildHealthDataTypeRow(
                name: 'Số bước chân',
                icon: Icons.directions_walk,
                key: 'steps',
                enabled: _healthDataTypes['steps'] ?? false,
              ),
              const Divider(height: 24),
              _buildHealthDataTypeRow(
                name: 'Lượng calo',
                icon: Icons.local_fire_department,
                key: 'calories',
                enabled: _healthDataTypes['calories'] ?? false,
              ),
              const Divider(height: 24),
              _buildHealthDataTypeRow(
                name: 'Giấc ngủ',
                icon: Icons.bedtime,
                key: 'sleep',
                enabled: _healthDataTypes['sleep'] ?? false,
              ),
            ],
          ),
          
          SizedBox(height: MediaQuery.of(context).padding.bottom + 100),
        ],
      ),
    );
  }

  // Removed _buildCard and _buildSwitchRow - now using SettingsCard and SettingsSwitchRow widgets


  Widget _buildHealthDataTypeRow({
    required String name,
    required IconData icon,
    required String key,
    required bool enabled,
  }) {
    final now = DateTime.now();
    final sampleValue = _getSampleValue(key);
    final updateTime = enabled 
        ? DateFormat('dd/MM/yyyy HH:mm').format(now)
        : 'Chưa đồng bộ';
    
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled ? AppColors.primary.withValues(alpha:0.3) : AppColors.cardBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: enabled 
                  ? AppColors.primaryContainer 
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: enabled ? AppColors.primary : AppColors.textGrey,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.labelLarge,
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      enabled ? Icons.check_circle : Icons.error_outline,
                      size: 16,
                      color: enabled ? AppColors.success : AppColors.error,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Cập nhật: $updateTime',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textGrey,
                    fontSize: 12,
                  ),
                ),
                if (enabled && sampleValue != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    sampleValue,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: Switch(
              value: enabled,
              onChanged: _hasPermissions
                  ? (value) {
                      setState(() {
                        _healthDataTypes[key] = value;
                      });
                    }
                  : null,
              activeThumbColor: AppColors.primary,
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
      ),
    );
  }

  String? _getSampleValue(String key) {
    switch (key) {
      case 'heart_rate':
        return '72 bpm';
      case 'steps':
        return '8,432 bước';
      case 'calories':
        return '2,150 kcal';
      case 'sleep':
        return null;
      default:
        return null;
    }
  }
}

