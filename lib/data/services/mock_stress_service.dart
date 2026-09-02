import 'package:fe/data/models/health/stress_prediction.dart';
import 'package:fe/data/services/stress_service.dart';

/// [StressService] giả lập cho chế độ DEMO — suy luận mức căng thẳng ngay trên
/// máy thay vì gọi API `/metrics/stress/predict`.
///
/// Quy ước nhãn giống backend: `label == 2` nghĩa là đang căng thẳng.
class MockStressService extends StressService {
  MockStressService(super.localStorage);

  @override
  Future<StressPrediction?> predict({
    required double hrMean,
    double hrStd = 0,
    required double rmssd,
    double tempMean = 33.0,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    // Nhịp tim cao + biến thiên nhịp tim (RMSSD) thấp => nhiều khả năng stress.
    final hrFactor = ((hrMean - 68) / 40).clamp(0.0, 1.0).toDouble();
    final rmssdFactor = ((45 - rmssd) / 40).clamp(0.0, 1.0).toDouble();
    final probStress = double.parse(
      ((hrFactor * 0.6 + rmssdFactor * 0.4))
          .clamp(0.05, 0.95)
          .toStringAsFixed(2),
    );

    final isStress = probStress >= 0.5;
    return StressPrediction(
      label: isStress ? 2 : 1,
      labelName: isStress ? 'Căng thẳng' : 'Bình thường',
      probStress: probStress,
      probBaseline: double.parse((1 - probStress).toStringAsFixed(2)),
      calibrated: true,
    );
  }
}
