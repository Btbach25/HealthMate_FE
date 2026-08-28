import 'package:fe/data/services/local_storage_service.dart';
import 'package:fe/data/services/readiness_service.dart';

/// [ReadinessService] giả lập cho chế độ DEMO — tính điểm sẵn sàng **cục bộ**,
/// không gọi API `/metrics/readiness`.
///
/// Công thức chấm điểm giống hệt phần fallback trong `DeviceHealthCubit`
/// (nhịp tim 40đ, giấc ngủ 30đ, bước chân 20đ, SpO2 10đ) nên số hiển thị luôn
/// hợp lý và ổn định với cùng một bộ đầu vào.
class MockReadinessService extends ReadinessService {
  MockReadinessService(LocalStorageService localStorage) : super(localStorage);

  @override
  Future<double?> getScore({
    required double heartRate,
    required double sleepDuration,
    required String stressLevel,
    required double bloodOxygen,
    double? steps,
    double? caloriesBurned,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));

    final hrScore = (40 - ((heartRate - 75).abs() / 25 * 40)).clamp(0, 40).toDouble();
    final sleepScore = (sleepDuration / 8 * 30).clamp(0, 30).toDouble();
    final stepsScore =
        steps != null ? (steps / 10000 * 20).clamp(0, 20).toDouble() : 14.0;
    final spo2Score = bloodOxygen >= 95
        ? 10.0
        : (bloodOxygen / 95 * 10).clamp(0, 10).toDouble();

    final total = hrScore + sleepScore + stepsScore + spo2Score;
    return double.parse(total.toStringAsFixed(1));
  }
}
