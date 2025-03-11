import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/alarm.dart';
import '../services/alarm_service.dart';
import '../utils/time_utils.dart';
import '../widgets/alarm_list_item.dart';
import 'alarm_edit_screen.dart';
import 'current_time_widget.dart';

class AlarmListScreen extends StatelessWidget {
  const AlarmListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          '알람',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {
              // 설정 화면으로 이동
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const CurrentTimeWidget(),
          Expanded(
            child: Consumer<AlarmService>(
              builder: (context, alarmService, child) {
                final alarms = alarmService.alarms;
                if (alarms.isEmpty) {
                  return _buildEmptyState();
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: alarms.length,
                  itemBuilder: (context, index) {
                    final alarm = alarms[index];
                    return AlarmListItem(
                      alarm: alarm,
                      onToggle: (value) {
                        alarmService.toggleAlarm(alarm.id, value);
                      },
                      onTap: () {
                        _editAlarm(context, alarm);
                      },
                      onDelete: () {
                        _deleteAlarm(context, alarm.id);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          _addNewAlarm(context);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.alarm_off, size: 80, color: Colors.grey[700]),
          const SizedBox(height: 16),
          Text(
            '알람이 없습니다',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            '새 알람을 추가해보세요',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _addNewAlarm(BuildContext context) async {
    final alarmService = Provider.of<AlarmService>(context, listen: false);
    final newId = alarmService.generateNewId();

    // 현재 시간으로 기본 알람 생성
    final now = DateTime.now();
    final defaultTime = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      (now.minute + 5) % 60, // 5분 후
    );

    final newAlarm = Alarm(id: newId, title: '알람', time: defaultTime);

    final result = await Navigator.push<Alarm>(
      context,
      MaterialPageRoute(
        builder:
            (context) => AlarmEditScreen(alarm: newAlarm, isNewAlarm: true),
      ),
    );

    if (result != null) {
      try {
        await alarmService.addAlarm(result);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('알람이 추가되었습니다')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('알람 추가 중 오류가 발생했습니다: $e')));
      }
    }
  }

  void _editAlarm(BuildContext context, Alarm alarm) async {
    final alarmService = Provider.of<AlarmService>(context, listen: false);

    final result = await Navigator.push<Alarm>(
      context,
      MaterialPageRoute(
        builder: (context) => AlarmEditScreen(alarm: alarm, isNewAlarm: false),
      ),
    );

    if (result != null) {
      await alarmService.updateAlarm(result);
    }
  }

  void _deleteAlarm(BuildContext context, int id) {
    final alarmService = Provider.of<AlarmService>(context, listen: false);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('알람 삭제'),
            content: const Text('이 알람을 삭제하시겠습니까?'),
            actions: [
              TextButton(
                child: const Text('취소'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('삭제'),
                onPressed: () {
                  alarmService.deleteAlarm(id);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
    );
  }
}
