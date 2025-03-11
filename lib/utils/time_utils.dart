import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// 시간 포맷 (12시간제)
String formatTime12Hour(DateTime time) {
  return DateFormat('h:mm a').format(time);
}

// 시간 포맷 (24시간제)
String formatTime24Hour(DateTime time) {
  return DateFormat('HH:mm').format(time);
}

// 요일 이름 가져오기
List<String> getWeekdayNames() {
  return ['월', '화', '수', '목', '금', '토', '일'];
}

// 요일 약어 가져오기
List<String> getWeekdayShortNames() {
  return ['월', '화', '수', '목', '금', '토', '일'];
}

// 요일 표시
String formatWeekdays(List<bool> repeatDays) {
  final List<String> weekdayNames = getWeekdayNames();
  final List<String> selectedDays = [];

  for (int i = 0; i < repeatDays.length; i++) {
    if (repeatDays[i]) {
      selectedDays.add(weekdayNames[i]);
    }
  }

  if (selectedDays.isEmpty) {
    return '반복 없음';
  } else if (selectedDays.length == 7) {
    return '매일';
  } else if (selectedDays.length == 5 &&
      repeatDays[0] &&
      repeatDays[1] &&
      repeatDays[2] &&
      repeatDays[3] &&
      repeatDays[4]) {
    return '주중';
  } else if (selectedDays.length == 2 && repeatDays[5] && repeatDays[6]) {
    return '주말';
  } else {
    return selectedDays.join(', ');
  }
}

// 남은 시간 계산
String getRemainingTime(DateTime alarmTime) {
  final now = DateTime.now();
  DateTime nextAlarm = DateTime(
    now.year,
    now.month,
    now.day,
    alarmTime.hour,
    alarmTime.minute,
  );

  if (nextAlarm.isBefore(now)) {
    nextAlarm = nextAlarm.add(const Duration(days: 1));
  }

  final difference = nextAlarm.difference(now);
  final hours = difference.inHours;
  final minutes = difference.inMinutes % 60;

  if (hours > 0) {
    return '$hours시간 $minutes분 후';
  } else {
    return '$minutes분 후';
  }
}

// 시간 선택기 표시
Future<TimeOfDay?> showTimePickerDialog(
  BuildContext context,
  TimeOfDay initialTime,
) async {
  return showTimePicker(
    context: context,
    initialTime: initialTime,
    builder: (BuildContext context, Widget? child) {
      return Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: Colors.indigo,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      );
    },
  );
}
