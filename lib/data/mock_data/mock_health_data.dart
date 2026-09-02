import 'dart:math' as math;

import 'package:fe/data/mock_data/mock_users.dart';
import 'package:fe/data/models/details/chart_data_point.dart';
import 'package:fe/data/models/health/blood_pressure.dart';
import 'package:fe/data/models/health/health_overview.dart';
import 'package:fe/data/models/health/heart_rate.dart';
import 'package:fe/data/models/health/temperature.dart';
import 'package:fe/data/models/health/weight.dart';
import 'package:health/health.dart';

/// Cấu hình sinh dữ liệu cho **một** chỉ số sức khoẻ trong chế độ DEMO.
///
/// Giá trị được sinh bằng tổ hợp hai sóng sin (xác định, không random) nên:
/// - biểu đồ mượt và có xu hướng, không giật cục;
/// - mở app bao nhiêu lần cũng ra cùng một chuỗi số.
class MockMetricProfile {
  /// Tên chỉ số theo quy ước backend: `heart_rate`, `steps_count`,
  /// `calories_burned`, `blood_pressure`, `spo2`, `weight`, `temperature`.
  final String type;

  /// Nhãn tiếng Việt hiển thị trên thẻ/biểu đồ.
  final String title;

  /// Đơn vị hiển thị (bpm, bước/ngày, kcal, mmHg, %, kg, °C).
  final String unit;

  /// Tên icon gợi ý cho `MetricSummary.iconName`.
  final String iconName;

  /// Giá trị trung tâm (mức "bình thường" của chỉ số).
  final double base;

  /// Biên độ dao động quanh [base].
  final double amplitude;

  /// Xu hướng cộng dồn theo từng điểm — dương là tăng dần theo thời gian.
  final double trendPerPoint;

  /// Số chữ số thập phân khi làm tròn.
  final int decimals;

  /// Chặn dưới để giá trị luôn nằm trong khoảng sinh lý.
  final double minValue;

  /// Chặn trên để giá trị luôn nằm trong khoảng sinh lý.
  final double maxValue;

  /// `true` khi chỉ số tăng là tốt (bước chân, calo, SpO2).
  final bool isIncreaseGood;

  /// `true` khi chỉ số cộng dồn theo ngày (bước chân, calo) — dùng lưới ngày.
  final bool isDailyTotal;

  const MockMetricProfile({
    required this.type,
    required this.title,
    required this.unit,
    required this.iconName,
    required this.base,
    required this.amplitude,
    this.trendPerPoint = 0,
    this.decimals = 0,
    required this.minValue,
    required this.maxValue,
    this.isIncreaseGood = false,
    this.isDailyTotal = false,
  });
}

/// Kho dữ liệu sức khoẻ giả cho chế độ DEMO.
///
/// **Muốn đổi dữ liệu demo?**
/// - Sửa [profiles] để đổi khoảng giá trị / nhãn / đơn vị của từng chỉ số.
/// - Sửa [gridFor] để đổi mật độ điểm của biểu đồ theo từng khoảng thời gian.
/// - Mọi mốc thời gian đều tính lùi từ `DateTime.now()` nên dữ liệu không bao
///   giờ bị "cũ".
class MockHealthData {
  const MockHealthData._();

  // ---------- Tên chỉ số (theo quy ước backend) ----------

  static const String heartRate = 'heart_rate';
  static const String stepsCount = 'steps_count';
  static const String caloriesBurned = 'calories_burned';
  static const String bloodPressure = 'blood_pressure';
  static const String spo2 = 'spo2';
  static const String weight = 'weight';
  static const String temperature = 'temperature';
  static const String sleep = 'sleep';

  /// Thứ tự hiển thị các chỉ số trên trang thống kê.
  static const List<String> orderedTypes = [
    heartRate,
    stepsCount,
    caloriesBurned,
    bloodPressure,
    spo2,
    weight,
    sleep,
    temperature,
  ];

  /// Cấu hình sinh dữ liệu của từng chỉ số. Sửa ở đây để đổi dữ liệu demo.
  static const Map<String, MockMetricProfile> profiles = {
    heartRate: MockMetricProfile(
      type: heartRate,
      title: 'Nhịp tim',
      unit: 'bpm',
      iconName: 'heart',
      base: 74,
      amplitude: 8,
      minValue: 60,
      maxValue: 98,
    ),
    stepsCount: MockMetricProfile(
      type: stepsCount,
      title: 'Số bước chân',
      unit: 'bước/ngày',
      iconName: 'steps',
      base: 8200,
      amplitude: 2400,
      trendPerPoint: 18,
      minValue: 3000,
      maxValue: 12000,
      isIncreaseGood: true,
      isDailyTotal: true,
    ),
    caloriesBurned: MockMetricProfile(
      type: caloriesBurned,
      title: 'Calories tiêu thụ',
      unit: 'kcal',
      iconName: 'heart',
      base: 430,
      amplitude: 95,
      trendPerPoint: 1.2,
      minValue: 220,
      maxValue: 720,
      isIncreaseGood: true,
      isDailyTotal: true,
    ),
    bloodPressure: MockMetricProfile(
      type: bloodPressure,
      title: 'Huyết áp tâm thu',
      unit: 'mmHg',
      iconName: 'heart',
      base: 119,
      amplitude: 6,
      minValue: 105,
      maxValue: 132,
    ),
    spo2: MockMetricProfile(
      type: spo2,
      title: 'SpO2',
      unit: '%',
      iconName: 'heart',
      base: 97.4,
      amplitude: 1.1,
      minValue: 95,
      maxValue: 99,
    ),
    weight: MockMetricProfile(
      type: weight,
      title: 'Cân nặng',
      unit: 'kg',
      iconName: 'weight',
      base: 68.4,
      amplitude: 0.6,
      trendPerPoint: -0.01,
      decimals: 1,
      minValue: 55,
      maxValue: 70,
    ),
    sleep: MockMetricProfile(
      type: sleep,
      title: 'Giấc ngủ',
      unit: 'giờ',
      iconName: 'sleep',
      base: 7.4,
      amplitude: 0.8,
      decimals: 1,
      minValue: 5.5,
      maxValue: 8.8,
      isIncreaseGood: true,
      isDailyTotal: true,
    ),
    temperature: MockMetricProfile(
      type: temperature,
      title: 'Nhiệt độ cơ thể',
      unit: '°C',
      iconName: 'heart',
      base: 36.8,
      amplitude: 0.25,
      decimals: 1,
      minValue: 36.5,
      maxValue: 37.2,
    ),
  };

  /// Lấy cấu hình của [type]; mặc định về nhịp tim nếu chưa khai báo.
  static MockMetricProfile profileOf(String type) =>
      profiles[type] ?? profiles[heartRate]!;

  // ---------- Bộ sinh dữ liệu xác định ----------

  /// Chuyển [userId] thành một "hạt giống" ổn định (không dùng `hashCode` vì
  /// giá trị của nó không đảm bảo giống nhau giữa các lần chạy).
  static double seedOf(String userId) {
    var sum = 0;
    for (final code in userId.codeUnits) {
      sum = (sum + code) % 997;
    }
    return (sum % 13) * 0.37;
  }

  /// Giá trị của chỉ số tại vị trí [index] trong chuỗi (0 = xa nhất).
  static double valueAt(MockMetricProfile profile, int index, double seed) {
    final x = index + seed;
    final wave =
        math.sin(x * 0.55) * profile.amplitude +
        math.sin(x * 0.17) * profile.amplitude * 0.35;
    final raw = profile.base + wave + profile.trendPerPoint * index;
    final clamped = raw.clamp(profile.minValue, profile.maxValue).toDouble();
    return double.parse(clamped.toStringAsFixed(profile.decimals));
  }

  /// Số điểm và khoảng cách giữa các điểm theo khoảng thời gian.
  ///
  /// [range] nhận `24h`, `7d`, `30d`, `90d` (mặc định `7d`).
  /// [dailyTotal] = true (bước chân, calo) luôn dùng lưới theo ngày.
  static ({int count, Duration step}) gridFor(
    String range, {
    bool dailyTotal = false,
  }) {
    switch (range) {
      case '24h':
        return dailyTotal
            ? (count: 12, step: const Duration(hours: 2))
            : (count: 24, step: const Duration(hours: 1));
      case '30d':
        return (count: 30, step: const Duration(days: 1));
      case '90d':
        return (count: 45, step: const Duration(days: 2));
      case '7d':
      default:
        return dailyTotal
            ? (count: 7, step: const Duration(days: 1))
            : (count: 28, step: const Duration(hours: 6));
    }
  }

  /// Chuỗi điểm dữ liệu của một chỉ số, sắp xếp tăng dần theo thời gian và
  /// kết thúc ở thời điểm hiện tại.
  static List<ChartDataPoint> series({
    required String type,
    String range = '7d',
    String userId = MockUsers.demoUserId,
  }) {
    final profile = profileOf(type);
    final grid = gridFor(range, dailyTotal: profile.isDailyTotal);
    final seed = seedOf(userId);
    final now = DateTime.now();

    return List<ChartDataPoint>.generate(grid.count, (i) {
      final stepsFromEnd = grid.count - 1 - i;
      return ChartDataPoint(
        time: now.subtract(grid.step * stepsFromEnd),
        value: valueAt(profile, i, seed),
      );
    });
  }

  /// Giá trị mới nhất của một chỉ số (điểm cuối của [series]).
  static double latestValue({
    required String type,
    String range = '7d',
    String userId = MockUsers.demoUserId,
  }) {
    final points = series(type: type, range: range, userId: userId);
    return points.last.value;
  }

  /// Huyết áp tâm trương suy ra từ tâm thu (giữ chênh lệch ~40 mmHg).
  static int diastolicFrom(double systolic) =>
      (systolic - 39).clamp(65.0, 90.0).toDouble().round();

  /// Tổng quan sức khoẻ mới nhất của một người — dùng cho trang chủ.
  static HealthOverview overviewFor(String userId) {
    final now = DateTime.now();
    final systolic = latestValue(type: bloodPressure, userId: userId);

    return HealthOverview(
      heartRate: HeartRate(
        time: now.subtract(const Duration(minutes: 4)),
        userId: userId,
        value: latestValue(type: heartRate, userId: userId),
      ),
      weight: Weight(
        time: now.subtract(const Duration(hours: 9)),
        userId: userId,
        value: latestValue(type: weight, userId: userId),
      ),
      bloodPressure: BloodPressure(
        time: now.subtract(const Duration(minutes: 42)),
        userId: userId,
        systolic: systolic.round(),
        diastolic: diastolicFrom(systolic),
      ),
      temperature: Temperature(
        time: now.subtract(const Duration(minutes: 25)),
        userId: userId,
        value: latestValue(type: temperature, userId: userId),
      ),
      bloodOxygen: latestValue(type: spo2, userId: userId),
    );
  }

  /// Tổng quan sức khoẻ của chính tài khoản demo.
  static HealthOverview get demoOverview => overviewFor(MockUsers.demoUserId);

  /// Tổng số bước hôm nay của tài khoản demo (dùng cho thẻ hoạt động).
  static int get demoStepsToday =>
      latestValue(type: stepsCount, range: '7d').round();

  /// Số giờ ngủ đêm qua — cố định theo ngày để không nhảy số mỗi lần mở app.
  static double get demoSleepHours {
    final dayIndex = DateTime.now().difference(DateTime(2024, 1, 1)).inDays;
    final v = 7.4 + math.sin(dayIndex * 0.4) * 0.6;
    return double.parse(v.toStringAsFixed(1));
  }

  // ---------- Dữ liệu thô kiểu Health Connect / HealthKit ----------

  /// Dựng một [HealthDataPoint] giả.
  ///
  /// `DeviceHealthCubit` đọc thẳng kiểu của package `health`, nên muốn thẻ
  /// "Điểm sẵn sàng" và "Mức độ căng thẳng" có số ở chế độ demo thì phải dựng
  /// đúng kiểu này chứ không thể dùng model riêng của app.
  static HealthDataPoint _point({
    required String id,
    required HealthDataType type,
    required HealthDataUnit unit,
    required num value,
    required DateTime from,
    DateTime? to,
  }) {
    return HealthDataPoint(
      uuid: 'demo-$id',
      value: NumericHealthValue(numericValue: value),
      type: type,
      unit: unit,
      dateFrom: from,
      dateTo: to ?? from,
      sourcePlatform: HealthPlatformType.googleHealthConnect,
      sourceDeviceId: 'demo-device',
      sourceId: 'vn.healthmate.demo',
      sourceName: 'HealthMate Demo',
      recordingMethod: RecordingMethod.automatic,
    );
  }

  /// Dữ liệu thô giả lập trả về từ "thiết bị" trong chế độ DEMO.
  ///
  /// Nội dung được chọn để đủ đầu vào cho cả hai phép tính trong
  /// `DeviceHealthCubit` — thiếu bất kỳ mục nào là thẻ tương ứng sẽ trống:
  ///
  /// | Thẻ | Cần |
  /// |---|---|
  /// | Điểm sẵn sàng | `HEART_RATE` (bắt buộc), `BLOOD_OXYGEN`, các mốc `SLEEP_*`, `ACTIVE_ENERGY_BURNED` |
  /// | Mức độ căng thẳng | `HEART_RATE` (bắt buộc, cần ≥2 điểm để có độ lệch chuẩn), `HEART_RATE_VARIABILITY_RMSSD`, `SKIN_TEMPERATURE` |
  ///
  /// Nhịp tim sinh bằng `sin` nên có độ lệch chuẩn thật (không phải hằng số) —
  /// nếu mọi điểm bằng nhau thì `hrStd = 0` và phần ước tính RMSSD sẽ rơi về
  /// giá trị mặc định cứng.
  ///
  /// Mọi mốc thời gian tính tương đối theo `DateTime.now()` nên dữ liệu không
  /// bao giờ bị "cũ", và giá trị hoàn toàn xác định (không dùng `Random`).
  static List<HealthDataPoint> get deviceDataPoints {
    final now = DateTime.now();
    final points = <HealthDataPoint>[];

    // 24 mẫu nhịp tim rải trong 2 giờ gần nhất, dao động ~62–76 bpm — dùng cho
    // biểu đồ và cho phần readiness.
    for (var i = 0; i < 24; i++) {
      final at = now.subtract(Duration(minutes: (23 - i) * 5));
      final bpm = 69 + math.sin(i * 0.55) * 5 + math.cos(i * 0.23) * 2;
      points.add(
        _point(
          id: 'hr-$i',
          type: HealthDataType.HEART_RATE,
          unit: HealthDataUnit.BEATS_PER_MINUTE,
          value: double.parse(bpm.toStringAsFixed(1)),
          from: at,
        ),
      );
    }

    // Thêm một chùm mẫu dày trong 60 GIÂY gần nhất.
    //
    // Bắt buộc phải có: `DeviceHealthCubit._hrMeanStd` chỉ lấy điểm nhịp tim
    // trong 60 giây đổ lại. Nếu các mẫu cách nhau vài phút thì chỉ đúng một
    // điểm lọt cửa sổ → độ lệch chuẩn ra 0 và phần ước tính RMSSD mất ý nghĩa.
    // Đồng hồ thật ghi liên tục vài giây một lần, nên đây mới là mô phỏng đúng.
    for (var i = 0; i < 12; i++) {
      final at = now.subtract(Duration(seconds: (11 - i) * 5));
      final bpm = 71 + math.sin(i * 1.1) * 4 + math.cos(i * 0.6) * 2.5;
      points.add(
        _point(
          id: 'hr-live-$i',
          type: HealthDataType.HEART_RATE,
          unit: HealthDataUnit.BEATS_PER_MINUTE,
          value: double.parse(bpm.toStringAsFixed(1)),
          from: at,
        ),
      );
    }

    points.add(
      _point(
        id: 'hrv',
        type: HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
        unit: HealthDataUnit.MILLISECOND,
        value: 42.0,
        from: now.subtract(const Duration(minutes: 12)),
      ),
    );

    points.add(
      _point(
        id: 'spo2',
        type: HealthDataType.BLOOD_OXYGEN,
        unit: HealthDataUnit.PERCENT,
        value: 97.0,
        from: now.subtract(const Duration(minutes: 18)),
      ),
    );

    points.add(
      _point(
        id: 'skin-temp',
        type: HealthDataType.SKIN_TEMPERATURE,
        unit: HealthDataUnit.DEGREE_CELSIUS,
        value: 33.4,
        from: now.subtract(const Duration(minutes: 20)),
      ),
    );

    // Giấc ngủ đêm qua, chia ba giai đoạn cộng lại đúng `demoSleepHours`.
    // Cubit cộng khoảng `dateTo - dateFrom`, nên phải đặt mốc chứ không đặt giá trị.
    final wakeUp = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(hours: 6, minutes: 30));
    final totalSleepMinutes = (demoSleepHours * 60).round();
    final bedTime = wakeUp.subtract(Duration(minutes: totalSleepMinutes));

    final deepMinutes = (totalSleepMinutes * 0.25).round();
    final remMinutes = (totalSleepMinutes * 0.22).round();
    final lightMinutes = totalSleepMinutes - deepMinutes - remMinutes;

    var cursor = bedTime;
    for (final stage in <(String, HealthDataType, int)>[
      ('deep', HealthDataType.SLEEP_DEEP, deepMinutes),
      ('rem', HealthDataType.SLEEP_REM, remMinutes),
      ('light', HealthDataType.SLEEP_ASLEEP, lightMinutes),
    ]) {
      final end = cursor.add(Duration(minutes: stage.$3));
      points.add(
        _point(
          id: 'sleep-${stage.$1}',
          type: stage.$2,
          unit: HealthDataUnit.MINUTE,
          value: stage.$3,
          from: cursor,
          to: end,
        ),
      );
      cursor = end;
    }

    // Calo tiêu hao, chia đều 6 khoảng trong ngày.
    for (var i = 0; i < 6; i++) {
      final from = now.subtract(Duration(hours: (6 - i) * 2));
      points.add(
        _point(
          id: 'cal-$i',
          type: HealthDataType.ACTIVE_ENERGY_BURNED,
          unit: HealthDataUnit.KILOCALORIE,
          value: 55 + math.sin(i * 0.9) * 25,
          from: from,
          to: from.add(const Duration(hours: 2)),
        ),
      );
    }

    return points;
  }
}
