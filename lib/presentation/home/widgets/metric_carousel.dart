import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_icons.dart';
import 'package:fe/core/widgets/clickable.dart';
import 'package:fe/data/models/health/blood_pressure.dart';
import 'package:fe/data/models/health/health_overview.dart';
import 'package:fe/data/models/health/heart_rate.dart';
import 'package:fe/data/models/user/user.dart';
import 'package:fe/data/services/user_service.dart';
import 'package:fe/presentation/auth/bloc/auth_bloc.dart';
import 'package:fe/presentation/home/bloc/device_health_cubit.dart';
import 'package:fe/presentation/home/bloc/health_overview_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Khoá metric backend quy ước cho kênh WebSocket. Chuỗi phải khớp đúng phía server
// (xem DeviceHealthCubit.pushManualMetric) — gõ sai thì gói tin bị bỏ im lặng, không lỗi.
const _kHeartRate = 'heart_rate';
const _kBloodPressure = 'blood_pressure';
const _kSpo2 = 'spo2';
const _kSteps = 'steps_count';

/// Đường ghi dữ liệu người dùng nhập tay: [ws] đẩy chỉ số đo được qua WebSocket,
/// [profile] gọi REST cập nhật hồ sơ (cân nặng, chiều cao). Hai đường khác nhau vì
/// chỉ số đo là chuỗi thời gian, còn hồ sơ là thuộc tính của tài khoản.
enum _UpdateType { ws, profile }

/// Băng chuyền tám thẻ chỉ số sức khoẻ, vuốt ngang, cuộn vô hạn hai chiều.
///
/// Không nhận tham số — tự đọc [DeviceHealthCubit], [HealthOverviewBloc], [AuthBloc]
/// và [UserService] từ context, nên chỉ đặt được bên dưới các provider đó.
///
/// Mỗi thẻ tự biết cách nhập tay giá trị của mình (hoặc chỉ đọc từ thiết bị); xem
/// [_CardData]. Muốn thêm chỉ số mới thì thêm một [_CardData] trong [_buildCards],
/// không cần đụng vào phần dựng PageView.
class MetricCarousel extends StatefulWidget {
  const MetricCarousel({super.key});

  @override
  State<MetricCarousel> createState() => _MetricCarouselState();
}

class _MetricCarouselState extends State<MetricCarousel> {
  late final PageController _controller;
  int _currentPage = 0;

  // Cuộn vô hạn: PageView không hỗ trợ vòng lặp, nên bắt đầu ở giữa một dải trang rất
  // lớn và lấy modulo số thẻ. Người dùng vuốt ngược từ thẻ đầu vẫn còn trang để đi.
  static const int _virtualBase = 50000;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: _virtualBase);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_CardData> _buildCards(
    DeviceHealthState dev,
    HealthOverview ov,
    User user,
  ) {
    final reached = dev.totalSteps != null && dev.totalSteps! >= 10000;
    return [
      // 1. Bước chân
      _CardData(
        type: _CardType.steps,
        icon: AppIcons.steps,
        iconColor: reached ? AppColors.success : AppColors.primary,
        iconBgColor: reached
            ? AppColors.successLight
            : AppColors.primaryContainer,
        label: 'Bước chân hôm nay',
        value: dev.totalSteps?.toString(),
        unit: 'bước',
        updateType: _UpdateType.ws,
        wsKey: _kSteps,
        inputLabel: 'Số bước',
        inputUnit: 'bước',
        isInteger: true,
        extra: dev,
      ),
      // 2. Nhịp tim
      _CardData(
        type: _CardType.simple,
        icon: AppIcons.heart,
        iconColor: AppColors.heartIconColor,
        iconBgColor: AppColors.heartIconBg,
        label: 'Nhịp tim',
        value: ov.heartRate?.value.round().toString(),
        unit: 'bpm',
        updateType: _UpdateType.ws,
        wsKey: _kHeartRate,
        inputLabel: 'Nhịp tim',
        inputUnit: 'bpm',
        isInteger: true,
      ),
      // 3. Huyết áp
      _CardData(
        type: _CardType.bloodPressure,
        icon: AppIcons.bloodPressure,
        iconColor: AppColors.primary,
        iconBgColor: AppColors.primaryContainer,
        label: 'Huyết áp',
        value: _bpDisplay(ov),
        unit: 'mmHg',
        updateType: _UpdateType.ws,
        wsKey: _kBloodPressure,
        inputLabel: 'Huyết áp',
        inputUnit: 'mmHg',
      ),
      // 4. SpO2
      _CardData(
        type: _CardType.simple,
        icon: AppIcons.spo2,
        iconColor: AppColors.info,
        iconBgColor: AppColors.infoLight,
        label: 'SpO2',
        value: dev.bloodOxygen?.toStringAsFixed(1),
        unit: '%',
        updateType: _UpdateType.ws,
        wsKey: _kSpo2,
        inputLabel: 'SpO2',
        inputUnit: '%',
      ),
      // 5. Cân nặng — từ profile, update qua REST
      _CardData(
        type: _CardType.simple,
        icon: AppIcons.weight,
        iconColor: AppColors.weightIconColor,
        iconBgColor: AppColors.weightIconBg,
        label: 'Cân nặng',
        value: user.weight?.toStringAsFixed(1),
        unit: 'kg',
        updateType: _UpdateType.profile,
        profileField: _ProfileField.weight,
        inputLabel: 'Cân nặng',
        inputUnit: 'kg',
      ),
      // 6. Chiều cao — từ profile, update qua REST
      _CardData(
        type: _CardType.simple,
        icon: Icons.height,
        iconColor: const Color(0xFF26A69A),
        iconBgColor: const Color(0xFFE0F2F1),
        label: 'Chiều cao',
        value: user.height?.toStringAsFixed(0),
        unit: 'cm',
        updateType: _UpdateType.profile,
        profileField: _ProfileField.height,
        inputLabel: 'Chiều cao',
        inputUnit: 'cm',
        isInteger: true,
      ),
      // 7. Nhiệt độ — chỉ hiển thị, thiết bị
      _CardData(
        type: _CardType.simple,
        icon: AppIcons.temperature,
        iconColor: AppColors.tempIconColor,
        iconBgColor: AppColors.tempIconBg,
        label: 'Nhiệt độ',
        value: ov.temperature?.value?.toStringAsFixed(1),
        unit: '°C',
        updateType: null,
      ),
      // 8. Giấc ngủ — thiết bị
      _CardData(
        type: _CardType.sleep,
        icon: AppIcons.sleep,
        iconColor: const Color(0xFF5C6BC0),
        iconBgColor: const Color(0xFFE8EAF6),
        label: 'Giấc ngủ',
        value: dev.sleepHours?.toStringAsFixed(1),
        unit: 'giờ',
        updateType: null,
        extra: dev,
      ),
    ];
  }

  static String? _bpDisplay(HealthOverview ov) {
    final bp = ov.bloodPressure;
    if (bp == null) return null;
    if (bp.systolic == null && bp.diastolic == null) return null;
    return '${bp.systolic ?? '—'}/${bp.diastolic ?? '—'}';
  }

  @override
  Widget build(BuildContext context) {
    final dev = context.watch<DeviceHealthCubit>().state;
    final ov =
        context.watch<HealthOverviewBloc>().state.overview ??
        HealthOverview.empty();
    final user = context.select((AuthBloc b) => b.state.user);
    final cards = _buildCards(dev, ov, user);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 148,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (i) =>
                setState(() => _currentPage = i % cards.length),
            itemBuilder: (context, i) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: _MetricCard(data: cards[i % cards.length]),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        _DotIndicator(count: cards.length, current: _currentPage),
      ],
    );
  }
}

/// Dãy chấm chỉ vị trí; chấm đang chọn giãn thành gạch ngang.
class _DotIndicator extends StatelessWidget {
  final int count;
  final int current;
  const _DotIndicator({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.inputBorder,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

/// Kiểu bố cục của thẻ — quyết định [_MetricCard] dựng widget nào.
enum _CardType { steps, simple, bloodPressure, sleep }

/// Trường hồ sơ được cập nhật khi [_UpdateType.profile].
enum _ProfileField { weight, height }

/// Mô tả đầy đủ một thẻ chỉ số: hiển thị gì, và nhập tay bằng đường nào.
///
/// Bất biến cần giữ khi thêm thẻ mới:
/// - [updateType] null  -> thẻ chỉ đọc từ thiết bị, không hiện nút thêm/sửa.
/// - [updateType] ws    -> phải có [wsKey].
/// - [updateType] profile -> phải có [profileField].
/// [value] null nghĩa là "chưa có dữ liệu" và làm thẻ chuyển sang [_EmptyState].
class _CardData {
  final _CardType type;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String label;
  final String? value;
  final String unit;
  final _UpdateType? updateType;
  final String? wsKey;
  final _ProfileField? profileField;
  final String? inputLabel;
  final String? inputUnit;
  final bool isInteger;
  final DeviceHealthState? extra;

  const _CardData({
    required this.type,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.label,
    required this.value,
    required this.unit,
    required this.updateType,
    this.wsKey,
    this.profileField,
    this.inputLabel,
    this.inputUnit,
    this.isInteger = false,
    this.extra,
  });

  bool get isEmpty => value == null;
  bool get canManualAdd => updateType != null;
}

/// Chọn bố cục thẻ theo [_CardData.type].
class _MetricCard extends StatelessWidget {
  final _CardData data;
  const _MetricCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return switch (data.type) {
      _CardType.steps => _StepsCard(data: data),
      _CardType.bloodPressure => _BloodPressureCard(data: data),
      _CardType.sleep => _SleepCard(data: data),
      _CardType.simple => _SimpleCard(data: data),
    };
  }
}

/// Phần thân thẻ khi chưa có số liệu: nút "Thêm thủ công" nếu chỉ số đó nhập tay
/// được, ngược lại chỉ ghi chú rằng dữ liệu đến từ thiết bị.
class _EmptyState extends StatelessWidget {
  final _CardData data;
  const _EmptyState({required this.data});

  void _openDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _ManualEntryDialog(
        data: data,
        cubit: context.read<DeviceHealthCubit>(),
        overviewBloc: context.read<HealthOverviewBloc>(),
        userService: context.read<UserService>(),
        authBloc: context.read<AuthBloc>(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'Chưa có thông tin',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textGrey.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 8),
        if (data.canManualAdd)
          SizedBox(
            height: 32,
            child: ElevatedButton.icon(
              onPressed: () => _openDialog(context),
              icon: const Icon(Icons.add, size: 15),
              label: const Text(
                'Thêm thủ công',
                style: TextStyle(fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          )
        else
          Row(
            children: const [
              Icon(
                Icons.devices_outlined,
                size: 13,
                color: AppColors.textLight,
              ),
              SizedBox(width: 4),
              Text(
                'Cập nhật từ thiết bị',
                style: TextStyle(fontSize: 12, color: AppColors.textLight),
              ),
            ],
          ),
      ],
    );
  }
}

/// Nút bút chì mở dialog nhập tay cho thẻ đã có sẵn giá trị.
class _EditButton extends StatelessWidget {
  final _CardData data;
  const _EditButton({required this.data});

  void _openDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _ManualEntryDialog(
        data: data,
        cubit: context.read<DeviceHealthCubit>(),
        overviewBloc: context.read<HealthOverviewBloc>(),
        userService: context.read<UserService>(),
        authBloc: context.read<AuthBloc>(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Clickable(
      onTap: () => _openDialog(context),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(
          Icons.edit_outlined,
          size: 14,
          color: AppColors.textGrey,
        ),
      ),
    );
  }
}

/// Thẻ bước chân: số bước, thanh tiến độ so với mục tiêu, và thời điểm đồng bộ gần nhất.
class _StepsCard extends StatelessWidget {
  final _CardData data;
  const _StepsCard({required this.data});

  static const int _goal = 10000;

  String _syncLabel() {
    final ts = data.extra?.lastUpdated;
    if (ts == null) return '';
    final diff = DateTime.now().difference(ts);
    if (diff.inMinutes < 1) return 'Vừa cập nhật';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    return '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final steps = data.extra?.totalSteps;
    final dataCount = data.extra?.dataCount ?? 0;
    final pct = steps != null ? (steps / _goal).clamp(0.0, 1.0) : 0.0;
    final reached = steps != null && steps >= _goal;

    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _IconBadge(data: data),
              const SizedBox(width: 8),
              Text(
                data.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textBlack,
                ),
              ),
              const Spacer(),
              Text(
                _syncLabel(),
                style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
              ),
            ],
          ),
          if (data.isEmpty)
            _EmptyState(data: data)
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  steps!.toString(),
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: reached ? AppColors.success : AppColors.textBlack,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 5),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    'bước',
                    style: TextStyle(
                      fontSize: 13,
                      color: reached ? AppColors.success : AppColors.textGrey,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '/ ${_goal ~/ 1000}k',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: AppColors.inputBackground,
                    color: reached ? AppColors.success : AppColors.primary,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      Icons.devices_outlined,
                      size: 11,
                      color: AppColors.textLight,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '$dataCount chỉ số từ thiết bị',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textLight,
                      ),
                    ),
                    if (reached) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Đạt mục tiêu! 🎉',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Thẻ huyết áp. Tách khỏi [_SimpleCard] vì giá trị là cặp "tâm thu/tâm trương"
/// nên chữ dài hơn và luôn hiện nút sửa kể cả khi đã có dữ liệu.
class _BloodPressureCard extends StatelessWidget {
  final _CardData data;
  const _BloodPressureCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _IconBadge(data: data),
              const SizedBox(width: 8),
              Text(
                data.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textBlack,
                ),
              ),
              const Spacer(),
              if (data.canManualAdd) _EditButton(data: data),
            ],
          ),
          if (data.isEmpty)
            _EmptyState(data: data)
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      data.value!,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: data.iconColor,
                        height: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    data.unit,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(),
        ],
      ),
    );
  }
}

/// Thẻ một-giá-trị-một-đơn-vị, dùng cho nhịp tim, SpO2, cân nặng, chiều cao, nhiệt độ.
class _SimpleCard extends StatelessWidget {
  final _CardData data;
  const _SimpleCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _IconBadge(data: data),
              const SizedBox(width: 8),
              Text(
                data.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textBlack,
                ),
              ),
              const Spacer(),
              if (!data.isEmpty && data.canManualAdd) _EditButton(data: data),
            ],
          ),
          if (data.isEmpty)
            _EmptyState(data: data)
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      data.value!,
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: data.iconColor,
                        height: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    data.unit,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(),
        ],
      ),
    );
  }
}

/// Thẻ giấc ngủ; chỉ đọc từ thiết bị, không cho nhập tay.
class _SleepCard extends StatelessWidget {
  final _CardData data;
  const _SleepCard({required this.data});

  static const Color _color = Color(0xFF5C6BC0);

  String _qualityLabel(double h) {
    if (h >= 7) return 'Đủ giấc';
    if (h >= 5) return 'Hơi ít';
    return 'Thiếu ngủ';
  }

  Color _qualityColor(double h) {
    if (h >= 7) return AppColors.success;
    if (h >= 5) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final hours = data.extra?.sleepHours;
    final pct = hours != null ? (hours / 8).clamp(0.0, 1.0) : 0.0;

    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _IconBadge(data: data),
              const SizedBox(width: 8),
              Text(
                data.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textBlack,
                ),
              ),
              if (hours != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _qualityColor(hours).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _qualityLabel(hours),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _qualityColor(hours),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (data.isEmpty)
            _EmptyState(data: data)
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  hours!.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: _color,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 5),
                const Padding(
                  padding: EdgeInsets.only(bottom: 5),
                  child: Text(
                    'giờ',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                const Text(
                  'Mục tiêu: 8h',
                  style: TextStyle(fontSize: 11, color: AppColors.textGrey),
                ),
              ],
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: AppColors.inputBackground,
                color: _color,
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Hộp thoại nhập tay một chỉ số.
///
/// Nhận sẵn bloc/cubit/service qua constructor thay vì đọc từ context, vì dialog được
/// dựng bởi [showDialog] ở một nhánh cây widget khác, nơi các provider của trang Home
/// không còn nhìn thấy được.
class _ManualEntryDialog extends StatefulWidget {
  final _CardData data;
  final DeviceHealthCubit cubit;
  final HealthOverviewBloc overviewBloc;
  final UserService userService;
  final AuthBloc authBloc;
  const _ManualEntryDialog({
    required this.data,
    required this.cubit,
    required this.overviewBloc,
    required this.userService,
    required this.authBloc,
  });

  @override
  State<_ManualEntryDialog> createState() => _ManualEntryDialogState();
}

class _ManualEntryDialogState extends State<_ManualEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _ctrl1 = TextEditingController();
  final _ctrl2 =
      TextEditingController(); // chỉ dùng cho tâm trương của huyết áp

  bool _loading = false;

  bool get _isBP => widget.data.type == _CardType.bloodPressure;

  @override
  void dispose() {
    _ctrl1.dispose();
    _ctrl2.dispose();
    super.dispose();
  }

  /// Ghi giá trị vừa nhập vào state ngay, không chờ vòng đọc thiết bị kế tiếp.
  ///
  /// Chỉ gọi sau khi WebSocket báo gửi thành công. Backend vẫn là nguồn sự thật; lần
  /// poll sau sẽ ghi đè giá trị này nếu server hiểu khác.
  void _applyOptimisticUpdate(double v1) {
    final now = DateTime.now();
    final userId = widget.authBloc.state.user.id;
    switch (widget.data.wsKey) {
      case _kHeartRate:
        widget.overviewBloc.add(
          HealthOverviewManualPatched(
            heartRate: HeartRate(time: now, userId: userId, value: v1),
          ),
        );
      case _kBloodPressure:
        final dia = double.tryParse(_ctrl2.text.trim());
        widget.overviewBloc.add(
          HealthOverviewManualPatched(
            bloodPressure: BloodPressure(
              time: now,
              userId: userId,
              systolic: v1.toInt(),
              diastolic: dia?.toInt(),
            ),
          ),
        );
      case _kSpo2:
        widget.cubit.patchBloodOxygen(v1);
      case _kSteps:
        widget.cubit.patchTotalSteps(v1.toInt());
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    bool ok = false;
    try {
      final v1 = double.parse(_ctrl1.text.trim());

      switch (widget.data.updateType) {
        case _UpdateType.ws:
          ok = await widget.cubit.pushManualMetric(widget.data.wsKey!, v1);
          if (ok) _applyOptimisticUpdate(v1);

        case _UpdateType.profile:
          final name = widget.authBloc.state.user.name;
          if (widget.data.profileField == _ProfileField.weight) {
            await widget.userService.updateProfile(name: name, weight: v1);
          } else {
            await widget.userService.updateProfile(name: name, height: v1);
          }
          final updated = await widget.userService.getProfile();
          widget.authBloc.add(AuthUserUpdated(updated));
          ok = true;

        case null:
          break;
      }
    } catch (_) {
      ok = false;
    }

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Đã cập nhật ${widget.data.label}'
              : 'Gửi thất bại, kiểm tra kết nối',
        ),
        backgroundColor: ok ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String? _validate(String? v) {
    if (v == null || v.trim().isEmpty) return 'Vui lòng nhập giá trị';
    final n = double.tryParse(v.trim());
    if (n == null || n <= 0) return 'Giá trị không hợp lệ';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.data.inputLabel ?? widget.data.label;
    final unit = widget.data.inputUnit ?? widget.data.unit;
    final isProfile = widget.data.updateType == _UpdateType.profile;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: widget.data.iconBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              widget.data.icon,
              color: widget.data.iconColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Nhập $label',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFCC02), width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 15,
                    color: Color(0xFFF57C00),
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Vui lòng nhập đúng thông tin. Dữ liệu sai sẽ ảnh hưởng đến kết quả dự báo và thông báo sức khỏe.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFF57C00),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _ctrl1,
              autofocus: true,
              keyboardType: TextInputType.numberWithOptions(
                decimal: !widget.data.isInteger,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  widget.data.isInteger ? RegExp(r'\d') : RegExp(r'[\d.]'),
                ),
              ],
              decoration: InputDecoration(
                labelText: _isBP ? 'Tâm thu (Systolic)' : label,
                suffixText: unit,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
              validator: _validate,
            ),
            if (_isBP) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _ctrl2,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: false,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'\d')),
                ],
                decoration: InputDecoration(
                  labelText: 'Tâm trương (Diastolic)',
                  suffixText: unit,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
            if (isProfile) ...[
              const SizedBox(height: 8),
              Row(
                children: const [
                  Icon(Icons.info_outline, size: 13, color: AppColors.textGrey),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Lưu vào hồ sơ cá nhân và đồng bộ lên hệ thống.',
                      style: TextStyle(fontSize: 11, color: AppColors.textGrey),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Huỷ', style: TextStyle(color: AppColors.textGrey)),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Lưu'),
        ),
      ],
    );
  }
}

/// Nền, bo góc và đổ bóng dùng chung cho mọi thẻ trong băng chuyền.
class _CardShell extends StatelessWidget {
  final Widget child;
  const _CardShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadowList,
      ),
      child: child,
    );
  }
}

/// Ô icon vuông bo góc ở góc trên trái mỗi thẻ.
class _IconBadge extends StatelessWidget {
  final _CardData data;
  const _IconBadge({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: data.iconBgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(data.icon, color: data.iconColor, size: 15),
    );
  }
}
