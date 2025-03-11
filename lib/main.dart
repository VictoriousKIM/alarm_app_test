import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import 'services/alarm_service.dart';
import 'screens/alarm_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 세로 모드로 고정
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // AlarmService 초기화
  final alarmService = AlarmService();
  await alarmService.init();

  runApp(MyApp(alarmService: alarmService));
}

class MyApp extends StatelessWidget {
  final AlarmService alarmService;

  const MyApp({super.key, required this.alarmService});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: alarmService,
      child: MaterialApp(
        title: '알람 앱',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        ),
        home: const AlarmListScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
