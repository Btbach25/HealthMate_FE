import 'dart:ui';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_icons.dart';
import 'package:fe/presentation/auth/bloc/auth_bloc.dart';
import 'package:fe/presentation/home/bloc/device_health_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Nav bar height: icon(28) + text(14) + spacing(2) + item padding(12) + outer padding(16) ≈ 72px
    const double navBarHeight = 72;
    final mq = MediaQuery.of(context);
    return Scaffold(
      appBar: _ShellAppBar(),
      body: Stack(
        clipBehavior: Clip.hardEdge,
        fit: StackFit.expand,
        children: [
          MediaQuery(
            data: mq.copyWith(
              padding: mq.padding.copyWith(
                bottom: mq.padding.bottom + navBarHeight,
              ),
            ),
            child: navigationShell,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _CustomBottomNavBar(
              currentIndex: navigationShell.currentIndex,
              onTap: _onTap,
            ),
          ),
        ],
      ),
    );
  }
}

/// Thanh trên cố định — dùng chung cho mọi tab trong shell.
class _ShellAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ShellAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 1,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Row(
        children: [
          Image.asset(
            AppAssets.appLogo,
            width: 28,
            height: 28,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.health_and_safety_outlined,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'HealthMate',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
      actions: [
        const Padding(
          padding: EdgeInsets.only(right: 6),
          child: _HCConnectionBadge(),
        ),
        Container(
          width: 36,
          height: 36,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.textGrey,
            size: 20,
          ),
        ),
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final user = state.user;
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryContainer,
                backgroundImage: user.picture != null
                    ? NetworkImage(user.picture!)
                    : null,
                child: user.picture == null
                    ? const Icon(AppIcons.userAvatar,
                        color: AppColors.primary, size: 18)
                    : null,
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Widget thanh điều hướng tùy chỉnh
class _CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _CustomBottomNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          color: AppColors.background.withValues(alpha: 0.8),
          child: SafeArea(
            top: false,
            child: Padding(
              // Thêm padding ngang để các item không bị sát viền
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              child: Row(
                // Bỏ spaceAround, dùng Expanded để chia đều
                children: [
                  // --- THAY ĐỔI: BỌC TỪNG ITEM BẰNG EXPANDED ---
                  Expanded(
                    child: _NavItem(
                      icon: AppIcons.home,
                      label: 'Tổng quan',
                      isSelected: currentIndex == 0,
                      onTap: () => onTap(0),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: AppIcons.family,
                      label: 'Gia đình',
                      isSelected: currentIndex == 1,
                      onTap: () => onTap(1),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: AppIcons.stats,
                      label: 'Chỉ số',
                      isSelected: currentIndex == 2,
                      onTap: () => onTap(2),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: AppIcons.medication,
                      label: 'Thuốc',
                      isSelected: currentIndex == 3,
                      onTap: () => onTap(3),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: AppIcons.settings,
                      label: 'Cài đặt',
                      isSelected: currentIndex == 4,
                      onTap: () => onTap(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget cho từng item trong thanh điều hướng
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = isSelected ? AppColors.primary : AppColors.textGrey;

    // --- THAY ĐỔI: GESTUREDETECTOR LÀ GỐC ---
    // Nó sẽ chiếm toàn bộ không gian của Expanded
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      // Container trong suốt để bắt tap
      child: Container(
        color: Colors.transparent, 
        // Đặt padding dọc ở đây để căn giữa toàn bộ item
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          // Bọc "bong bóng" trong Center để nó nằm giữa
          child: Container(
            // Đây là "bong bóng" có nền màu
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.tagImportantBg : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Cực kỳ quan trọng
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Health Connect badge ──────────────────────────────────────────────────────

enum _BadgeMode { hidden, error, success }

class _HCConnectionBadge extends StatefulWidget {
  const _HCConnectionBadge();

  @override
  State<_HCConnectionBadge> createState() => _HCConnectionBadgeState();
}

class _HCConnectionBadgeState extends State<_HCConnectionBadge>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _expandCtrl;

  _BadgeMode _mode = _BadgeMode.hidden;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _expandCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final connected = context.read<DeviceHealthCubit>().state.isHealthConnectConnected;
      if (connected == false) _enterError();
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _expandCtrl.dispose();
    super.dispose();
  }

  void _enterError() {
    if (_mode == _BadgeMode.error) return;
    setState(() => _mode = _BadgeMode.error);
    _autoExpand();
  }

  Future<void> _autoExpand() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted || _mode != _BadgeMode.error) return;
    await _expandCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 3500));
    if (!mounted || _mode != _BadgeMode.error) return;
    await _expandCtrl.reverse();
  }

  Future<void> _enterSuccess() async {
    if (_mode == _BadgeMode.hidden || _busy) return;
    _busy = true;
    // Mở rộng banner nếu đang thu nhỏ
    if (_expandCtrl.value < 1) await _expandCtrl.forward();
    if (!mounted) { _busy = false; return; }
    setState(() => _mode = _BadgeMode.success);
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) { _busy = false; return; }
    await _expandCtrl.reverse();
    if (!mounted) { _busy = false; return; }
    setState(() => _mode = _BadgeMode.hidden);
    _busy = false;
  }

  void _openDialog(BuildContext ctx) {
    showDialog(context: ctx, builder: (_) => const _HealthConnectDialog());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DeviceHealthCubit, DeviceHealthState>(
      listenWhen: (p, c) => p.isHealthConnectConnected != c.isHealthConnectConnected,
      listener: (_, state) {
        if (state.isHealthConnectConnected == false) { _enterError(); }
        else if (state.isHealthConnectConnected == true) { _enterSuccess(); }
      },
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (ctx, _) {
          if (_mode == _BadgeMode.hidden) return const SizedBox.shrink();

          final isSuccess = _mode == _BadgeMode.success;
          final pulse = 0.65 + 0.35 * _pulseCtrl.value;

          final dotColor   = isSuccess ? const Color(0xFF43A047) : const Color(0xFFE53935);
          final bgColor    = isSuccess ? const Color(0xFFF1F8E9) : const Color(0xFFFFF0F0);
          final rimColor   = isSuccess ? const Color(0xFFA5D6A7) : const Color(0xFFFFCDD2);
          final textColor  = isSuccess ? const Color(0xFF2E7D32) : const Color(0xFFB71C1C);
          final label      = isSuccess ? 'Đã kết nối HC' : 'Chưa kết nối HC';

          return GestureDetector(
            onTap: isSuccess ? null : () => _openDialog(ctx),
            child: Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: rimColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: isSuccess ? 1.0 : pulse,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _expandCtrl,
                    builder: (_, child) => ClipRect(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: CurvedAnimation(
                          parent: _expandCtrl,
                          curve: Curves.easeOut,
                        ).value,
                        child: child,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Health Connect dialog ─────────────────────────────────────────────────────

class _HealthConnectDialog extends StatelessWidget {
  const _HealthConnectDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      title: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF0F0),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.link_off_rounded,
              color: Color(0xFFE53935),
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Chưa kết nối\nHealth Connect',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: const Text(
        'Ứng dụng chưa được kết nối với Health Connect. '
        'Cần cấp quyền để HealthMate có thể đọc và đồng bộ dữ liệu sức khỏe từ thiết bị của bạn.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13.5,
          color: Color(0xFF757575),
          height: 1.5,
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.menu_book_rounded, size: 18),
              label: const Text('Xem hướng dẫn kết nối'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Đóng',
                style: TextStyle(color: Color(0xFF9E9E9E)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}