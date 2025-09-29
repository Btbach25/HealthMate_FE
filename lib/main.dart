// import 'package:flutter/material.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       theme: ThemeData(
//         // This is the theme of your application.
//         //
//         // TRY THIS: Try running your application with "flutter run". You'll see
//         // the application has a purple toolbar. Then, without quitting the app,
//         // try changing the seedColor in the colorScheme below to Colors.green
//         // and then invoke "hot reload" (save your changes or press the "hot
//         // reload" button in a Flutter-supported IDE, or press "r" if you used
//         // the command line to start the app).
//         //
//         // Notice that the counter didn't reset back to zero; the application
//         // state is not lost during the reload. To reset the state, use hot
//         // restart instead.
//         //
//         // This works for code too, not just values: Most code changes can be
//         // tested with just a hot reload.
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//       ),
//       home: const MyHomePage(title: 'Flutter Demo Home Page'),
//     );
//   }
// }

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});

//   // This widget is the home page of your application. It is stateful, meaning
//   // that it has a State object (defined below) that contains fields that affect
//   // how it looks.

//   // This class is the configuration for the state. It holds the values (in this
//   // case the title) provided by the parent (in this case the App widget) and
//   // used by the build method of the State. Fields in a Widget subclass are
//   // always marked "final".

//   final String title;

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   int _counter = 0;

//   void _incrementCounter() {
//     setState(() {
//       // This call to setState tells the Flutter framework that something has
//       // changed in this State, which causes it to rerun the build method below
//       // so that the display can reflect the updated values. If we changed
//       // _counter without calling setState(), then the build method would not be
//       // called again, and so nothing would appear to happen.
//       _counter++;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     // This method is rerun every time setState is called, for instance as done
//     // by the _incrementCounter method above.
//     //
//     // The Flutter framework has been optimized to make rerunning build methods
//     // fast, so that you can just rebuild anything that needs updating rather
//     // than having to individually change instances of widgets.
//     return Scaffold(
//       appBar: AppBar(
//         // TRY THIS: Try changing the color here to a specific color (to
//         // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
//         // change color while the other colors stay the same.
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//         // Here we take the value from the MyHomePage object that was created by
//         // the App.build method, and use it to set our appbar title.
//         title: Text(widget.title),
//       ),
//       body: Center(
//         // Center is a layout widget. It takes a single child and positions it
//         // in the middle of the parent.
//         child: Column(
//           // Column is also a layout widget. It takes a list of children and
//           // arranges them vertically. By default, it sizes itself to fit its
//           // children horizontally, and tries to be as tall as its parent.
//           //
//           // Column has various properties to control how it sizes itself and
//           // how it positions its children. Here we use mainAxisAlignment to
//           // center the children vertically; the main axis here is the vertical
//           // axis because Columns are vertical (the cross axis would be
//           // horizontal).
//           //
//           // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
//           // action in the IDE, or press "p" in the console), to see the
//           // wireframe for each widget.
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             const Text('You have pushed the button this many times:'),
//             Text(
//               '$_counter',
//               style: Theme.of(context).textTheme.headlineMedium,
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _incrementCounter,
//         tooltip: 'Increment',
//         child: const Icon(Icons.add),
//       ), // This trailing comma makes auto-formatting nicer for build methods.
//     );
//   }
// }

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
    // Xác định khoảng thời gian bạn muốn tính tổng
    // Ví dụ: từ đầu ngày hôm nay cho đến bây giờ
    DateTime now = DateTime.now();
    DateTime midnight = DateTime(now.year, now.month, now.day); // 00:00 hôm nay

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

  // SỬA LỖI 4: Xử lý các loại HealthValue khác nhau
  String _formatHealthValue(HealthValue value) {
    if (value is NumericHealthValue) {
      return value.numericValue.toStringAsFixed(2);
    } else if (value is AudiogramHealthValue) {
      return 'Dữ liệu thính lực đồ';
    } else if (value is WorkoutHealthValue) {
      return '${value.workoutActivityType.name.split('.').last} - ${value.totalEnergyBurned?.toStringAsFixed(2) ?? 'N/A'} kcal';
    }
    // Đối với các loại dữ liệu khác không xác định (như trạng thái ngủ),
    // hãy sử dụng phương thức toString() mặc định của chúng.
    return value.toString();
  }

  // @override
  // Widget build(BuildContext context) {
  //   return MaterialApp(
  //     title: 'Health App Demo',
  //     theme: ThemeData(
  //       primarySwatch: Colors.blue,
  //     ),
  //     home: Scaffold(
  //       appBar: AppBar(
  //         title: const Text('Health Data Demo'),
  //       ),
  //       body: _isAuthorizing || _healthDataList.isEmpty
  //           ? const Center(
  //               child: Column(
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 children: [
  //                   CircularProgressIndicator(),
  //                   SizedBox(height: 20),
  //                   Text('Đang yêu cầu quyền hoặc đọc dữ liệu...'),
  //                   Text('Hãy đảm bảo bạn đã cấp quyền cho ứng dụng trên thiết bị.'),
  //                 ],
  //               ),
  //             )
  //           : ListView.builder(
  //               itemCount: _healthDataList.length,
  //               itemBuilder: (context, index) {
  //                 HealthDataPoint data = _healthDataList[index];
  //                 return Card(
  //                   margin: const EdgeInsets.all(8.0),
  //                   child: Padding(
  //                     padding: const EdgeInsets.all(16.0),
  //                     child: Column(
  //                       crossAxisAlignment: CrossAxisAlignment.start,
  //                       children: [
  //                         Text(
  //                           '${data.type.name}: ${_formatHealthValue(data.value)} ${data.unit?.name ?? ''}',
  //                           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
  //                         ),
  //                         const SizedBox(height: 4),
  //                         Text('Từ: ${data.dateFrom.toLocal().toString().split('.')[0]}'),
  //                         Text('Đến: ${data.dateTo.toLocal().toString().split('.')[0]}'),
  //                         Text('Nguồn: ${data.sourceName} (${data.sourceId})'),
  //                       ],
  //                     ),
  //                   ),
  //                 );
  //               },
  //             ),
  //       floatingActionButton: Column(
  //         mainAxisAlignment: MainAxisAlignment.end,
  //         children: [
  //           FloatingActionButton.extended(
  //             onPressed: _checkAndRequestPermissions,
  //             label: const Text('Yêu cầu lại quyền'),
  //             icon: const Icon(Icons.privacy_tip),
  //           ),
  //           const SizedBox(height: 10),
  //           FloatingActionButton.extended(
  //             onPressed: _fetchHealthData,
  //             label: const Text('Làm mới dữ liệu'),
  //             icon: const Icon(Icons.refresh),
  //           ),
  //           const SizedBox(height: 10),
  //           FloatingActionButton.extended(
  //             onPressed: () => _writeSteps(100), // Ghi thử 100 bước chân
  //             label: const Text('Ghi 100 bước'),
  //             icon: const Icon(Icons.add),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
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
                                      '${data.type.name}: ${_formatHealthValue(data.value)} ${data.unit?.name ?? ''}',
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

