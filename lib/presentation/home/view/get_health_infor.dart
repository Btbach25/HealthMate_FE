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

  // TẠO MỘT DANH SÁCH BAO GỒM TẤT CẢ CÁC LOẠI DỮ LIỆU
  // Đây là gần như tất cả các loại mà package 'health' hỗ trợ
  final List<HealthDataType> allHealthDataTypes = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.WEIGHT,
    HealthDataType.HEIGHT,
    HealthDataType.BODY_MASS_INDEX,
    HealthDataType.BODY_FAT_PERCENTAGE,
    HealthDataType.WAIST_CIRCUMFERENCE,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.BASAL_ENERGY_BURNED,
    HealthDataType.TOTAL_CALORIES_BURNED,
    HealthDataType.BLOOD_GLUCOSE,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    HealthDataType.RESTING_HEART_RATE, 
    HealthDataType.HEART_RATE_VARIABILITY_SDNN,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.BODY_TEMPERATURE,
    HealthDataType.RESPIRATORY_RATE,
    HealthDataType.WATER,
    
    HealthDataType.SLEEP_IN_BED,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
    
    HealthDataType.WORKOUT,
    HealthDataType.EXERCISE_TIME,
    HealthDataType.DISTANCE_DELTA,
    HealthDataType.DISTANCE_WALKING_RUNNING,
    HealthDataType.DIETARY_ENERGY_CONSUMED,

    // Khác
    HealthDataType.MINDFULNESS, // Thiền
  ];


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

    // Yêu cầu quyền cho Health Connect/HealthKit
    // Sử dụng danh sách allHealthDataTypes đã tạo
    bool? hasPermissions = await health.requestAuthorization(allHealthDataTypes);

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
    // Lấy dữ liệu trong 3 ngày qua (thay vì 7 để giảm tải)
    DateTime earlier = now.subtract(const Duration(days: 3));

    // Sử dụng danh sách allHealthDataTypes để fetch
    List<HealthDataType> typesToFetch = allHealthDataTypes;

    try {
      // Kiểm tra xem Health Connect có khả dụng không (chỉ Android)
      bool isAvailable = await health.isHealthConnectAvailable();
      if (!isAvailable) {
        print('Health Connect không có sẵn trên thiết bị này.');
        // Hiển thị thông báo hoặc yêu cầu người dùng cài đặt Health Connect
        await health.installHealthConnect();
        return;
      }

      // Lấy dữ liệu
      List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(
        startTime: earlier,
        endTime: now,
        types: typesToFetch,
      );

      // Lọc dữ liệu trùng lặp (code của bạn đã tốt)
      final uniqueData = <String, HealthDataPoint>{};
      for (var data in healthData) {
        final key = '${data.dateFrom}-${data.dateTo}-${data.typeString}-${data.value}';
        uniqueData[key] = data;
      }

      setState(() {
        _healthDataList = uniqueData.values.toList();
        // Sắp xếp: mới nhất lên đầu
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
        _fetchHealthData(); // Tải lại dữ liệu sau khi ghi
      } else {
        print('Không thể ghi bước chân.');
      }
    } else {
      print('Không có quyền ghi bước chân.');
    }
  }

  String _formatHealthValue(HealthDataPoint data) {
    final value = data.value;
    final unit = data.unit.name;
    final type = data.type; // Rất quan trọng

    if (type == HealthDataType.SLEEP_ASLEEP ||
        type == HealthDataType.SLEEP_AWAKE ||
        type == HealthDataType.SLEEP_DEEP ||
        type == HealthDataType.SLEEP_REM ||
        type == HealthDataType.SLEEP_IN_BED) {
      
      return 'Giai đoạn: ${type.name.replaceAll('SLEEP_', '')}';
    }

    // 2. XỬ LÝ CÁC LOẠI VALUE CỤ THỂ TỪ FILE CỦA BẠN
    if (value is WorkoutHealthValue) {
      return '${value.workoutActivityType.name.split('.').last} - ${value.totalEnergyBurned?.toStringAsFixed(2) ?? 'N/A'} kcal';
    } 
    else if (value is NutritionHealthValue) {
      // Ví dụ hiển thị chi tiết hơn cho Dinh dưỡng
      final meal = value.name ?? 'Không tên';
      final calories = value.calories?.toStringAsFixed(0) ?? 'N/A';
      return 'Bữa ăn: $meal, $calories kcal';
    }
    else if (value is AudiogramHealthValue) {
      return 'Dữ liệu thính lực đồ (${value.frequencies.length} tần số)';
    }
    else if (value is MenstruationFlowHealthValue) {
      return 'Kinh nguyệt: ${value.flow?.name ?? 'N/A'}';
    }
    // Bạn có thể thêm 'else if' cho ElectrocardiogramHealthValue, v.v.

    // 3. XỬ LÝ LOẠI PHỔ BIẾN NHẤT (NUMERIC)
    // Hầu hết các loại (Tim, Bước chân, Cân nặng) sẽ rơi vào đây
    if (value is NumericHealthValue) {
      return '${value.numericValue.toStringAsFixed(2)} $unit';
    }
    
    // 4. MẶC ĐỊNH
    return '$value $unit';
  }

  IconData _getIconForType(HealthDataType type) {
    switch (type) {
      case HealthDataType.STEPS:
      case HealthDataType.DISTANCE_WALKING_RUNNING:
        return Icons.directions_walk;
      
      case HealthDataType.HEART_RATE:
      case HealthDataType.RESTING_HEART_RATE:
      case HealthDataType.HEART_RATE_VARIABILITY_SDNN:
        return Icons.favorite;
      
      case HealthDataType.WEIGHT:
        return Icons.monitor_weight;
      
      case HealthDataType.BLOOD_PRESSURE_SYSTOLIC:
      case HealthDataType.BLOOD_PRESSURE_DIASTOLIC:
        return Icons.bloodtype;

      case HealthDataType.SLEEP_ASLEEP:
      case HealthDataType.SLEEP_DEEP:
      case HealthDataType.SLEEP_REM:
      case HealthDataType.SLEEP_IN_BED:
      case HealthDataType.SLEEP_AWAKE:
        return Icons.bedtime;
      
      case HealthDataType.ACTIVE_ENERGY_BURNED:
      case HealthDataType.TOTAL_CALORIES_BURNED:
      case HealthDataType.BASAL_ENERGY_BURNED:
        return Icons.local_fire_department;
      
      case HealthDataType.WORKOUT:
      case HealthDataType.EXERCISE_TIME:
        return Icons.fitness_center;
      case HealthDataType.BLOOD_OXYGEN:
      case HealthDataType.RESPIRATORY_RATE:
        return Icons.air;
      
      case HealthDataType.BODY_TEMPERATURE:
        return Icons.thermostat;
      
      case HealthDataType.WATER:
        return Icons.water_drop;
      case HealthDataType.DIETARY_ENERGY_CONSUMED:
        return Icons.restaurant;
        
      default:
        return Icons.monitor_heart;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HealthMate',
      theme: ThemeData(
        primarySwatch: Colors.indigo, // Đổi màu
        brightness: Brightness.dark, // Thử theme tối
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          bodyLarge: TextStyle(color: Colors.white70),
          titleMedium: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Dữ liệu sức khỏe'),
        ),
        body: Column(
          children: [
            // Card hiển thị tổng số bước chân
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Card(
                color: Colors.indigo[700],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.directions_walk, size: 30, color: Colors.white),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tổng số bước hôm nay',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          Text(
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

            // Dòng chữ tiêu đề cho danh sách
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Dữ liệu chi tiết (3 ngày qua)',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.indigoAccent),
              ),
            ),

            // Danh sách chi tiết
            Expanded(
              child: _isAuthorizing
                  ? const Center(
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
                      ? const Center(
                          child: Text(
                            'Không có dữ liệu chi tiết.\nHãy thử làm mới hoặc tạo dữ liệu bằng Toolbox.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80.0), // Để không bị FAB che
                          itemCount: _healthDataList.length,
                          itemBuilder: (context, index) {
                            HealthDataPoint data = _healthDataList[index];
                            return Card(
                              child: ListTile( // Sử dụng ListTile để đẹp hơn
                                leading: CircleAvatar(
                                  backgroundColor: Colors.indigoAccent,
                                  child: Icon(
                                    _getIconForType(data.type), 
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  '${data.type.name}: ${_formatHealthValue(data)}',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                subtitle: Text(
                                  '${data.dateFrom.toLocal().toString().split('.')[0]}\nNguồn: ${data.sourceName}',
                                  style: Theme.of(context).textTheme.bodySmall,
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
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton.extended(
              onPressed: _checkAndRequestPermissions,
              label: const Text('Xin quyền'),
              icon: const Icon(Icons.privacy_tip),
              heroTag: 'btn1', // Thêm heroTag để tránh lỗi
            ),
            const SizedBox(height: 10),
            FloatingActionButton.extended(
              onPressed: _fetchHealthData,
              label: const Text('Làm mới'),
              icon: const Icon(Icons.refresh),
              heroTag: 'btn2',
            ),
            const SizedBox(height: 10),
            FloatingActionButton.extended(
              onPressed: () => _writeSteps(100), // Ghi thử 100 bước chân
              label: const Text('Ghi 100 bước'),
              icon: const Icon(Icons.add),
              heroTag: 'btn3',
            ),
          ],
        ),
      ),
    );
  }
}