import 'dart:convert';

class Alarm {
  final int id;
  final String title;
  final String description;
  final DateTime time;
  final bool isEnabled;
  final List<bool> repeatDays; // [월, 화, 수, 목, 금, 토, 일]
  final String soundPath;
  final bool vibrate;
  final bool snoozeEnabled;
  final int snoozeMinutes;

  Alarm({
    required this.id,
    required this.title,
    required this.time,
    this.description = '',
    this.isEnabled = true,
    List<bool>? repeatDays,
    this.soundPath = 'default',
    this.vibrate = true,
    this.snoozeEnabled = true,
    this.snoozeMinutes = 5,
  }) : repeatDays = repeatDays ?? List.filled(7, false);

  // 요일 반복 여부 확인
  bool get isRepeating => repeatDays.any((day) => day);

  // 다음 알람 시간 계산
  DateTime getNextAlarmTime() {
    final now = DateTime.now();
    DateTime nextAlarm = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // 오늘 알람 시간이 이미 지났으면 내일로 설정
    if (nextAlarm.isBefore(now)) {
      nextAlarm = nextAlarm.add(const Duration(days: 1));
    }

    // 반복 알람이 아니면 바로 반환
    if (!isRepeating) {
      return nextAlarm;
    }

    // 반복 알람이면 다음 반복일 찾기
    int daysToAdd = 0;
    int currentWeekday = nextAlarm.weekday % 7; // 0-6 (일-토)

    while (!repeatDays[currentWeekday]) {
      daysToAdd++;
      currentWeekday = (currentWeekday + 1) % 7;
    }

    return nextAlarm.add(Duration(days: daysToAdd));
  }

  // JSON 변환 메서드
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'time': time.toIso8601String(),
      'isEnabled': isEnabled,
      'repeatDays': repeatDays,
      'soundPath': soundPath,
      'vibrate': vibrate,
      'snoozeEnabled': snoozeEnabled,
      'snoozeMinutes': snoozeMinutes,
    };
  }

  // JSON에서 객체 생성
  factory Alarm.fromJson(Map<String, dynamic> json) {
    return Alarm(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      time: DateTime.parse(json['time']),
      isEnabled: json['isEnabled'],
      repeatDays: List<bool>.from(json['repeatDays']),
      soundPath: json['soundPath'],
      vibrate: json['vibrate'],
      snoozeEnabled: json['snoozeEnabled'],
      snoozeMinutes: json['snoozeMinutes'],
    );
  }

  // 복사본 생성 (속성 변경 시 사용)
  Alarm copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? time,
    bool? isEnabled,
    List<bool>? repeatDays,
    String? soundPath,
    bool? vibrate,
    bool? snoozeEnabled,
    int? snoozeMinutes,
  }) {
    return Alarm(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      time: time ?? this.time,
      isEnabled: isEnabled ?? this.isEnabled,
      repeatDays: repeatDays ?? List.from(this.repeatDays),
      soundPath: soundPath ?? this.soundPath,
      vibrate: vibrate ?? this.vibrate,
      snoozeEnabled: snoozeEnabled ?? this.snoozeEnabled,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
    );
  }
}
