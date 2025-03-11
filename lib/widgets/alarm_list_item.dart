import 'package:flutter/material.dart';

import '../models/alarm.dart';
import '../utils/time_utils.dart';

class AlarmListItem extends StatelessWidget {
  final Alarm alarm;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const AlarmListItem({
    Key? key,
    required this.alarm,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: onDelete,
      ),
      title: Text(
        alarm.title,
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatTime24Hour(alarm.time),
            style: const TextStyle(color: Colors.grey),
          ),
          if (alarm.repeatDays.any((element) => element))
            Text(
              formatWeekdays(alarm.repeatDays),
              style: const TextStyle(color: Colors.grey),
            ),
          Text(
            getRemainingTime(alarm.time),
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
      trailing: Switch(
        value: alarm.isEnabled,
        onChanged: onToggle,
        activeColor: Colors.indigo,
      ),
    );
  }
}
