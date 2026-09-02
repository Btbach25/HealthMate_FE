import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/presentation/settings/tabs/general_settings_tab.dart';
import 'package:fe/presentation/settings/tabs/health_sync_tab.dart';
import 'package:fe/presentation/settings/tabs/notifications_settings_tab.dart';
import 'package:fe/presentation/settings/tabs/privacy_security_tab.dart';
import 'package:fe/presentation/settings/tabs/profile_settings_tab.dart';
import 'package:flutter/material.dart';

/// Màn hình Cài đặt: header cố định + 5 tab cuộn ngang.
///
/// Chỉ lo phần khung (tiêu đề, [TabBar], [TabBarView]); mọi logic đọc/ghi cài
/// đặt nằm trong từng tab con ở `lib/presentation/settings/tabs/`.
///
/// Thêm một tab cài đặt mới: thêm một phần tử vào [_SettingsViewState._tabs]
/// (icon + nhãn) VÀ thêm widget tab tương ứng vào `children` của [TabBarView],
/// **cùng vị trí**. Hai danh sách này khớp nhau theo chỉ số, lệch là bấm tab
/// này ra nội dung tab khác. `TabController.length` tự lấy theo `_tabs` nên
/// không phải sửa.
class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView>
    with SingleTickerProviderStateMixin {
  static const double _contentMaxWidth = 800;
  late TabController _tabController;

  /// Nhãn các tab, theo đúng thứ tự với `children` của [TabBarView] trong
  /// [build]. Bề rộng mỗi tab bị ghim cứng 98px ở dưới nên nhãn phải ngắn.
  final List<({IconData icon, String label})> _tabs = const [
    (icon: Icons.person_outline, label: 'Hồ sơ'),
    (icon: Icons.notifications_outlined, label: 'Thông báo'),
    (icon: Icons.shield_outlined, label: 'Bảo mật'),
    (icon: Icons.sync, label: 'Đồng bộ'),
    (icon: Icons.settings_outlined, label: 'Chung'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildTab(IconData icon, String label) {
    return Tab(
      height: 52,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11.5),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.cardBorder,
                        width: 0.8,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cài đặt',
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Quản lý hồ sơ, bảo mật và tuỳ chọn ứng dụng',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textGrey,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          indicator: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: AppColors.buttonShadow,
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: AppColors.textGrey,
                          labelStyle: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                          ),
                          padding: EdgeInsets.zero,
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 3,
                          ),
                          tabs: [
                            for (final t in _tabs)
                              SizedBox(
                                width: 98,
                                child: _buildTab(t.icon, t.label),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    physics: const BouncingScrollPhysics(),
                    children: const [
                      ProfileSettingsTab(),
                      NotificationsSettingsTab(),
                      PrivacySecurityTab(),
                      HealthSyncTab(),
                      GeneralSettingsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
