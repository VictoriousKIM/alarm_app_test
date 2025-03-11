import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import '../models/alarm.dart';

class AlarmService extends ChangeNotifier {
  static const String _storageKey = 'alarms';

  final List<Alarm> _alarms = [];
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  List<Alarm> get alarms => List.unmodifiable(_alarms);

  // 초기화
  Future<void> init() async {
    await _initializeNotifications();
    await _initializeTimezone();
    await loadAlarms();
  }

  // 알림 초기화
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // 알림 권한 요청
    if (Platform.isAndroid) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }
  }

  // 시간대 초기화
  Future<void> _initializeTimezone() async {
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  }

  // 알림 탭 처리
  void _onNotificationTapped(NotificationResponse response) {
    // 알림 탭 시 처리 로직
  }

  // 알람 목록 불러오기
  Future<void> loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final String? alarmsJson = prefs.getString(_storageKey);

    if (alarmsJson != null) {
      final List<dynamic> decoded = jsonDecode(alarmsJson);
      _alarms.clear();
      _alarms.addAll(decoded.map((item) => Alarm.fromJson(item)).toList());
      _alarms.sort((a, b) => a.time.compareTo(b.time));
      notifyListeners();
    }
  }

  // 알람 목록 저장
  Future<void> _saveAlarms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String alarmsJson = jsonEncode(
        _alarms.map((a) => a.toJson()).toList(),
      );
      final bool success = await prefs.setString(_storageKey, alarmsJson);
      print('알람 저장 결과: $success, 알람 개수: ${_alarms.length}');

      // 저장된 데이터 확인
      final String? savedData = prefs.getString(_storageKey);
      if (savedData != null) {
        print(
          '저장된 데이터 확인: ${savedData.substring(0, min(100, savedData.length))}...',
        );
      } else {
        print('저장된 데이터가 없습니다.');
      }
    } catch (e) {
      print('알람 저장 중 오류 발생: $e');
      // 오류 처리
      rethrow;
    }
  }

  // 알람 추가
  Future<void> addAlarm(Alarm alarm) async {
    try {
      _alarms.add(alarm);
      _alarms.sort((a, b) => a.time.compareTo(b.time));
      await _saveAlarms();

      if (alarm.isEnabled) {
        await scheduleAlarm(alarm);
      }

      notifyListeners();
      print('알람이 성공적으로 추가되었습니다: ${alarm.title}, ${alarm.time}');
    } catch (e) {
      print('알람 추가 중 오류 발생: $e');
      // 오류 처리
      rethrow;
    }
  }

  // 알람 업데이트
  Future<void> updateAlarm(Alarm updatedAlarm) async {
    final index = _alarms.indexWhere((a) => a.id == updatedAlarm.id);

    if (index != -1) {
      // 기존 알람 취소
      await cancelAlarm(updatedAlarm.id);

      // 알람 업데이트
      _alarms[index] = updatedAlarm;
      await _saveAlarms();

      // 활성화된 경우 다시 스케줄링
      if (updatedAlarm.isEnabled) {
        await scheduleAlarm(updatedAlarm);
      }

      notifyListeners();
    }
  }

  // 알람 삭제
  Future<void> deleteAlarm(int id) async {
    await cancelAlarm(id);
    _alarms.removeWhere((a) => a.id == id);
    await _saveAlarms();
    notifyListeners();
  }

  // 알람 활성화/비활성화
  Future<void> toggleAlarm(int id, bool isEnabled) async {
    final index = _alarms.indexWhere((a) => a.id == id);

    if (index != -1) {
      final alarm = _alarms[index];
      final updatedAlarm = alarm.copyWith(isEnabled: isEnabled);

      await cancelAlarm(id);
      _alarms[index] = updatedAlarm;

      if (isEnabled) {
        await scheduleAlarm(updatedAlarm);
      }

      await _saveAlarms();
      notifyListeners();
    }
  }

  // 알람 스케줄링
  Future<void> scheduleAlarm(Alarm alarm) async {
    final DateTime nextAlarmTime = alarm.getNextAlarmTime();

    // 알람 시간이 현재보다 이전이면 스케줄링하지 않음
    if (nextAlarmTime.isBefore(DateTime.now())) {
      return;
    }

    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
      nextAlarmTime,
      tz.local,
    );

    // 디버그 로그 추가
    print('알람 스케줄링: ID=${alarm.id}, 제목=${alarm.title}, 소리=${alarm.soundPath}');

    // 알림 내용 설정
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'alarm_channel',
          '알람',
          channelDescription: '알람 앱 알림 채널',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          // 소리 설정 수정
          playSound: alarm.soundPath != 'none',
          sound:
              alarm.soundPath != 'none' && alarm.soundPath != 'default'
                  ? RawResourceAndroidNotificationSound(alarm.soundPath)
                  : null,
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          vibrationPattern:
              alarm.vibrate ? Int64List.fromList([0, 500, 500, 500]) : null,
        );

    // 디버그 로그 추가
    print(
      '알람 소리 설정: playSound=${alarm.soundPath != 'none'}, sound=${alarm.soundPath != 'none' && alarm.soundPath != 'default' ? alarm.soundPath : 'null'}',
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: alarm.soundPath != 'none',
      // iOS에서도 커스텀 소리 사용 (iOS에서는 다른 방식으로 구현해야 할 수 있음)
      sound:
          alarm.soundPath != 'none' && alarm.soundPath != 'default'
              ? alarm.soundPath
              : null,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // 알림 스케줄링
    try {
      await _notificationsPlugin.zonedSchedule(
        alarm.id,
        alarm.title,
        alarm.description,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents:
            alarm.isRepeating ? DateTimeComponents.dayOfWeekAndTime : null,
      );
      print('알람 스케줄링 성공: ID=${alarm.id}');
    } catch (e) {
      print('알람 스케줄링 실패: ID=${alarm.id}, 오류=$e');
      rethrow;
    }
  }

  // 알람 취소
  Future<void> cancelAlarm(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  // 모든 알람 다시 스케줄링 (앱 시작 시 호출)
  Future<void> rescheduleAllAlarms() async {
    for (final alarm in _alarms) {
      if (alarm.isEnabled) {
        await cancelAlarm(alarm.id);
        await scheduleAlarm(alarm);
      }
    }
  }

  // 새 알람 ID 생성
  int generateNewId() {
    if (_alarms.isEmpty) {
      return 1;
    }
    return _alarms.map((a) => a.id).reduce((max, id) => id > max ? id : max) +
        1;
  }
}
