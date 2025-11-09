import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<HealthDataPoint> _healthDataList = [];
  int? _totalSteps;
  bool _isAuthorizing = false;

  // Khởi tạo health factory ngay từ đầu để dễ sử dụng
  final Health health = Health();

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions();
  }

  Future<void> _checkAndRequestPermissions() async {
    if (_isAuthorizing) return;
    setState(() {
      _isAuthorizing = true;
    });

    // Yêu cầu quyền Activity Recognition (cần cho bước chân trên Android 10+)
    var status = await Permission.activityRecognition.status;
    if (status.isDenied) {
      status = await Permission.activityRecognition.request();
    }

    if (status.isGranted) {
      print('Quyền Activity Recognition đã được cấp.');
    } else {
      print('Quyền Activity Recognition không được cấp.');
    }

    // Các loại dữ liệu sức khỏe chúng ta muốn truy cập
    List<HealthDataType> types = [
      HealthDataType.STEPS,
      HealthDataType.HEART_RATE,
      HealthDataType.WEIGHT,
      HealthDataType.BODY_FAT_PERCENTAGE,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      HealthDataType.BLOOD_GLUCOSE,
      HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
      HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
      HealthDataType.HEIGHT,
      // HealthDataType.SLEEP_IN_BED,
      HealthDataType.SLEEP_ASLEEP,
      // Thêm các loại dữ liệu khác nếu cần
    ];

    // Yêu cầu quyền cho Health Connect/HealthKit
    bool? hasPermissions = await health.requestAuthorization(types);

    if (hasPermissions == true) {
      print("Đã có quyền truy cập dữ liệu sức khỏe.");
      _fetchHealthData();
    } else {
      print("Không được cấp quyền truy cập dữ liệu sức khỏe.");
    }
    setState(() {
      _isAuthorizing = false;
    });
  }

  Future<void> _fetchHealthData() async {
    DateTime now = DateTime.now();
    DateTime earlier = now.subtract(const Duration(days: 7));

    List<HealthDataType> typesToFetch = [
      HealthDataType.STEPS,
      HealthDataType.HEART_RATE,
      HealthDataType.WEIGHT,
      HealthDataType.BODY_FAT_PERCENTAGE,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      HealthDataType.BLOOD_GLUCOSE,
      HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
      HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
      HealthDataType.HEIGHT,
      // HealthDataType.SLEEP_IN_BED,
      HealthDataType.SLEEP_ASLEEP,
    ];

    try {
      // SỬA LỖI 1: Sử dụng isHealthConnectAvailable()
      bool isAvailable = await health.isHealthConnectAvailable();
      if (!isAvailable) {
        print('Health Connect không có sẵn trên thiết bị này.');
        // Hiển thị thông báo hoặc yêu cầu người dùng cài đặt Health Connect
        await health.installHealthConnect();
        return;
      }

      // Lấy dữ liệu
      // SỬA LỖI 2 & 3: Sử dụng startTime và endTime thay vì startDate và endDate
      List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(
        startTime: earlier,
        endTime: now,
        types: typesToFetch,
      );

      final uniqueData = <String, HealthDataPoint>{};
      for (var data in healthData) {
        final key = '${data.dateFrom}-${data.dateTo}-${data.typeString}-${data.value}';
        uniqueData[key] = data;
      }

      setState(() {
        _healthDataList = uniqueData.values.toList();
        _healthDataList.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      });
      print('Đã đọc được ${_healthDataList.length} điểm dữ liệu.');
      _fetchTotalSteps();

    } catch (e) {
      print("Lỗi khi đọc dữ liệu sức khỏe: $e");
    }
  }
    Future<void> _fetchTotalSteps() async {
    DateTime now = DateTime.now();
    DateTime midnight = DateTime(now.year, now.month, now.day);

    // Kiểm tra quyền trước khi lấy dữ liệu
    bool? hasPermissions = await health.hasPermissions([HealthDataType.STEPS]);
    if (hasPermissions == false) {
      print("Không có quyền đọc số bước chân để tính tổng.");
      return;
    }

    try {
      int? steps = await health.getTotalStepsInInterval(midnight, now);
      
      setState(() {
        _totalSteps = steps;
      });

      print('Tổng số bước chân trong ngày hôm nay: $_totalSteps');

    } catch (e) {
      print("Lỗi khi lấy tổng số bước chân: $e");
    }
  }

  Future<void> _writeSteps(int steps) async {
    bool? hasPermissions = await health.requestAuthorization([HealthDataType.STEPS]);
    if (hasPermissions == true) {
      DateTime now = DateTime.now();
      bool success = await health.writeHealthData(
        value: steps.toDouble(),
        type: HealthDataType.STEPS,
        startTime: now.subtract(const Duration(minutes: 1)),
        endTime: now,
      );
      if (success) {
        print('Đã ghi thành công $steps bước chân.');
        _fetchHealthData();
      } else {
        print('Không thể ghi bước chân.');
      }
    } else {
      print('Không có quyền ghi bước chân.');
    }
  }

  String _formatHealthValue(HealthValue value) {
    if (value is NumericHealthValue) {
      return value.numericValue.toStringAsFixed(2);
    } else if (value is AudiogramHealthValue) {
      return 'Dữ liệu thính lực đồ';
    } else if (value is WorkoutHealthValue) {
      return '${value.workoutActivityType.name.split('.').last} - ${value.totalEnergyBurned?.toStringAsFixed(2) ?? 'N/A'} kcal';
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health App Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: const TextTheme( // Thêm theme để chữ đẹp hơn
          headlineSmall: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Health Data Demo'),
        ),
        // SỬA ĐỔI TỪ ĐÂY
        body: Column( // 1. Bọc toàn bộ body trong một Column
          children: [
            // 2. Thêm Card hiển thị tổng số bước chân ở đây
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.directions_walk, size: 30, color: Colors.blueAccent),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tổng số bước hôm nay',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          Text(
                            // Hiển thị giá trị hoặc "Đang tải..."
                            _totalSteps?.toString() ?? '...',
                            style: Theme.of((context)).textTheme.headlineSmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Phần danh sách chi tiết được bọc trong Expanded
            Expanded(
              child: _isAuthorizing
                  ? const Center( // Hiển thị loading khi đang xin quyền
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 20),
                          Text('Đang yêu cầu quyền...'),
                        ],
                      ),
                    )
                  : _healthDataList.isEmpty
                      ? const Center( // Hiển thị thông báo khi không có dữ liệu
                          child: Text(
                            'Không có dữ liệu chi tiết.\nHãy thử làm mới hoặc tạo dữ liệu bằng Toolbox.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder( // Danh sách chi tiết
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          itemCount: _healthDataList.length,
                          itemBuilder: (context, index) {
                            HealthDataPoint data = _healthDataList[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6.0),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${data.type.name}: ${_formatHealthValue(data.value)} ${data.unit.name}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Từ: ${data.dateFrom.toLocal().toString().split('.')[0]}'),
                                    Text('Đến: ${data.dateTo.toLocal().toString().split('.')[0]}'),
                                    Text('Nguồn: ${data.sourceName} (${data.sourceId})'),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton.extended(
              onPressed: _checkAndRequestPermissions,
              label: const Text('Yêu cầu lại quyền'),
              icon: const Icon(Icons.privacy_tip),
            ),
            const SizedBox(height: 10),
            FloatingActionButton.extended(
              onPressed: _fetchHealthData,
              label: const Text('Làm mới dữ liệu'),
              icon: const Icon(Icons.refresh),
            ),
            const SizedBox(height: 10),
            FloatingActionButton.extended(
              onPressed: () => _writeSteps(100), // Ghi thử 100 bước chân
              label: const Text('Ghi 100 bước'),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  
  }
}

