import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/presentation/settings/tabs/general_settings_tab.dart';
import 'package:fe/presentation/settings/tabs/health_sync_tab.dart';
import 'package:fe/presentation/settings/tabs/notifications_settings_tab.dart';
import 'package:fe/presentation/settings/tabs/privacy_security_tab.dart';
import 'package:fe/presentation/settings/tabs/profile_settings_tab.dart';
import 'package:flutter/material.dart';

enum SettingsTab {
  profile,
  notifications,
  privacy,
  sync,
  general,
}

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildTab(IconData icon, String label) {
    return Tab(
      height: 70,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        title: const Text(
          'Cài đặt',
          style: AppTextStyles.h3,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textGrey,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                height: 1.2,
              ),
              labelPadding: EdgeInsets.zero,
              tabs: [
                _buildTab(Icons.person_outline, 'Hồ sơ'),
                _buildTab(Icons.notifications_outlined, 'Thông báo'),
                _buildTab(Icons.shield_outlined, 'Bảo mật'),
                _buildTab(Icons.sync, 'Đồng bộ'),
                _buildTab(Icons.settings_outlined, 'Chung'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
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
    );
  }
}

