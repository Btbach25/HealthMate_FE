import 'dart:ui';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_icons.dart';
import 'package:fe/core/widgets/clickable.dart';
import 'package:fe/presentation/auth/bloc/auth_bloc.dart';
import 'package:fe/presentation/home/bloc/device_health_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Khung (shell) bottom-navigation bao toàn bộ phần đã đăng nhập của app.
///
/// Được `StatefulShellRoute.indexedStack` trong `lib/core/routing/app_router.dart`
/// dựng lên một lần và sống suốt phiên: AppBar chung ở trên, thanh nav tuỳ biến
/// nổi ở dưới, ở giữa là [navigationShell] — chính là IndexedStack giữ state
/// riêng cho từng tab (cuộn tới đâu, form đang gõ dở… đều được giữ khi đổi tab).
///
/// ## Thêm một tab mới
///
/// Thứ tự tab được quy định ở HAI nơi và **phải khớp nhau tuyệt đối**; không có
/// gì kiểm tra hộ, lệch một chỉ số là bấm tab này ra màn hình khác:
///
/// 1. `app_router.dart` → thêm một [StatefulShellBranch] vào danh sách
///    `branches` của `StatefulShellRoute.indexedStack`, đúng vị trí mong muốn.
///    Mỗi branch có `GoRoute` với path riêng (`/stats`, `/meds`…). Branch đầu
///    tiên phải giữ path `/` vì đó là route mặc định sau khi đăng nhập.
///    Nếu tab cần một Bloc sống theo tab, bọc `ShellRoute` + `BlocProvider`
///    bên trong branch — xem nhánh Thuốc làm mẫu.
/// 2. File này → thêm một `Expanded(child: _NavItem(...))` vào
///    [_CustomBottomNavBar] **cùng vị trí đó**, truyền
///    `isSelected: currentIndex == i` và `onTap: () => onTap(i)` với `i` là
///    chỉ số của tab mới, rồi cập nhật lại chỉ số của mọi tab nằm sau nó.
///
/// Lưu ý khi thêm:
/// * Icon lấy từ `AppIcons` (`lib/core/theme/app_icons.dart`), không hardcode.
/// * Nhãn tab ngắn — `_NavItem` giới hạn 1 dòng và cắt bằng dấu "…", 5 tab đã
///   gần chật trên máy hẹp; thêm tab thứ 6 nên cân nhắc lại layout.
/// * Không cần đụng tới `navBarHeight` trừ khi đổi kích thước icon/chữ.
/// * Điều hướng giữa các tab luôn qua [_onTap] / `navigationShell.goBranch`,
///   đừng `context.go()` sang path của tab khác — làm vậy sẽ mất state tab.
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  /// Đổi tab. `initialLocation: true` khi bấm lại chính tab đang mở nghĩa là
  /// "về màn hình gốc của tab" — ví dụ đang ở `/family/group/123` mà bấm lại
  /// tab Gia đình thì quay về `/family`.
  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Chiều cao thanh nav: icon(28) + chữ(14) + khoảng cách(2) + padding item(12)
    // + padding ngoài(16) ≈ 72px.
    //
    // Thanh nav nằm trong Stack (nền mờ, trôi trên nội dung) chứ không phải
    // `bottomNavigationBar` của Scaffold, nên Flutter không tự chừa chỗ cho nó.
    // Vì vậy phải tự cộng con số này vào `MediaQuery.padding.bottom` của phần
    // thân — thiếu bước đó là đáy mọi trang bị thanh nav che. Đổi layout của
    // [_NavItem] thì phải chỉnh lại con số này.
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
///
/// Vì nằm ngoài [AppShell.navigationShell], nó KHÔNG đổi theo tab: đừng nhét
/// action riêng của một tab vào đây, hãy để tab đó tự dựng AppBar của mình.
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
                    ? const Icon(
                        AppIcons.userAvatar,
                        color: AppColors.primary,
                        size: 18,
                      )
                    : null,
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Thanh điều hướng dưới cùng, tự dựng thay vì dùng `NavigationBar` của
/// Material để có nền mờ (BackdropFilter) và "bong bóng" chọn bo tròn.
///
/// **Thứ tự các [_NavItem] dưới đây phải khớp thứ tự `branches` trong
/// `app_router.dart`** — xem hướng dẫn thêm tab ở doc của [AppShell].
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
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 8.0,
              ),
              child: Row(
                // Expanded cho từng tab để chia đều bề rộng: vùng chạm phủ kín ô
                // của tab, không co giãn theo độ dài nhãn.
                children: [
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

/// Một tab trong [_CustomBottomNavBar]: icon + nhãn, có "bong bóng" nền khi
/// đang được chọn.
///
/// Không tự biết mình là tab thứ mấy — [_CustomBottomNavBar] truyền sẵn
/// `isSelected` và `onTap`.
class _NavItem extends StatelessWidget {
  /// Bo góc của vùng hover/ripple một tab. Đặt nhỏ hơn nửa chiều cao ô để vệt
  /// hover ra hình viên thuốc chứ không thành hình tròn méo.
  static const double _navItemRadius = 18;

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

    // InkWell (không phải GestureDetector) để trên web có hover + con trỏ bàn
    // tay; `borderRadius` phải khớp bo góc ở đây, nếu không vệt hover sẽ là
    // hình chữ nhật vuông góc đè lên thanh nav bo tròn.
    //
    // InkWell phủ CẢ ô Expanded để vùng chạm không co lại chỉ còn "bong bóng".
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(_navItemRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_navItemRadius),
        hoverColor: AppColors.primary.withValues(alpha: 0.06),
        splashColor: AppColors.primary.withValues(alpha: 0.12),
        highlightColor: AppColors.primary.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Center(
            // "Bong bóng" chỉ ôm sát icon + nhãn, hẹp hơn vùng chạm ở trên.
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.tagImportantBg
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                // BẮT BUỘC min: Column này nằm trong thanh nav cao cố định
                // (navBarHeight), để max là tràn layout.
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 28),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
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
      ),
    );
  }
}

// ── Health Connect badge ──────────────────────────────────────────────────────

/// Trạng thái hiển thị của [_HCConnectionBadge].
///
/// [hidden] là trạng thái khởi đầu và cũng là trạng thái kết thúc sau khi báo
/// kết nối thành công — badge chỉ xuất hiện khi có chuyện cần nói.
enum _BadgeMode { hidden, error, success }

/// Huy hiệu nhỏ trên AppBar báo tình trạng kết nối Health Connect.
///
/// Nghe [DeviceHealthCubit]:
/// * `isHealthConnectConnected == false` → hiện chấm đỏ nhấp nháy, tự bung nhãn
///   "Chưa kết nối HC" khoảng 3,5 giây rồi thu lại; bấm vào mở
///   [_HealthConnectDialog].
/// * chuyển sang `true` → đổi sang màu xanh "Đã kết nối HC" một lúc rồi tự ẩn
///   hẳn, không bấm được nữa.
/// * `null` (chưa biết) → không hiện gì, tránh doạ người dùng lúc app mới mở.
///
/// Cờ `_busy` chặn chuỗi animation thành công bị kích hoạt chồng nhau khi
/// cubit phát trạng thái liên tiếp.
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
      final connected = context
          .read<DeviceHealthCubit>()
          .state
          .isHealthConnectConnected;
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
    if (!mounted) {
      _busy = false;
      return;
    }
    setState(() => _mode = _BadgeMode.success);
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) {
      _busy = false;
      return;
    }
    await _expandCtrl.reverse();
    if (!mounted) {
      _busy = false;
      return;
    }
    setState(() => _mode = _BadgeMode.hidden);
    _busy = false;
  }

  void _openDialog(BuildContext ctx) {
    showDialog(context: ctx, builder: (_) => const _HealthConnectDialog());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DeviceHealthCubit, DeviceHealthState>(
      listenWhen: (p, c) =>
          p.isHealthConnectConnected != c.isHealthConnectConnected,
      listener: (_, state) {
        if (state.isHealthConnectConnected == false) {
          _enterError();
        } else if (state.isHealthConnectConnected == true) {
          _enterSuccess();
        }
      },
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (ctx, _) {
          if (_mode == _BadgeMode.hidden) return const SizedBox.shrink();

          final isSuccess = _mode == _BadgeMode.success;
          final pulse = 0.65 + 0.35 * _pulseCtrl.value;

          final dotColor = isSuccess
              ? const Color(0xFF43A047)
              : const Color(0xFFE53935);
          final bgColor = isSuccess
              ? const Color(0xFFF1F8E9)
              : const Color(0xFFFFF0F0);
          final rimColor = isSuccess
              ? const Color(0xFFA5D6A7)
              : const Color(0xFFFFCDD2);
          final textColor = isSuccess
              ? const Color(0xFF2E7D32)
              : const Color(0xFFB71C1C);
          final label = isSuccess ? 'Đã kết nối HC' : 'Chưa kết nối HC';

          return Clickable(
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

/// Hộp thoại giải thích vì sao cần Health Connect, mở từ [_HCConnectionBadge].
///
/// CHƯA HOÀN THIỆN: nút "Xem hướng dẫn kết nối" hiện chỉ đóng hộp thoại — chưa
/// có màn hình hướng dẫn để điều hướng tới. Khi làm tiếp, thay `Navigator.pop`
/// bằng lệnh mở màn hình đó (và đóng hộp thoại sau).
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
                  borderRadius: BorderRadius.circular(12),
                ),
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
