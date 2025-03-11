import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';

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

class MyApp extends StatefulWidget {
  final AlarmService alarmService;

  const MyApp({Key? key, required this.alarmService}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkExactAlarmPermission();
    });
  }

  Future<void> _checkExactAlarmPermission() async {
    if (Platform.isAndroid) {
      // Delay to ensure context is ready
      await Future.delayed(const Duration(seconds: 1));
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("정확한 알람 권한 필요"),
            content: const Text("정확한 알람을 위해 SCHEDULE_EXACT_ALARM 권한을 활성화해주세요."),
            actions: [
              TextButton(
                onPressed: () {
                  _openExactAlarmSettings();
                  Navigator.of(context).pop();
                },
                child: const Text("권한 활성화"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("나중에"),
              ),
            ],
          );
        },
      );
    }
  }

  void _openExactAlarmSettings() {
    final intent = AndroidIntent(
      action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
      data: 'package:com.example.alarm_app_test',
    );
    intent.launch();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.alarmService,
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
