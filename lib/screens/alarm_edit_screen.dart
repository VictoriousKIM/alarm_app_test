import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import '../models/alarm.dart';
import '../utils/time_utils.dart';
import '../services/sound_service.dart';

class AlarmEditScreen extends StatefulWidget {
  final Alarm alarm;
  final bool isNewAlarm;

  const AlarmEditScreen({
    super.key,
    required this.alarm,
    required this.isNewAlarm,
  });

  @override
  State<AlarmEditScreen> createState() => _AlarmEditScreenState();
}

class _AlarmEditScreenState extends State<AlarmEditScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedTime;
  late List<bool> _repeatDays;
  late bool _vibrate;
  late bool _snoozeEnabled;
  late int _snoozeMinutes;
  late String _soundPath;

  // 소리 파일 목록
  List<String> _soundFiles = [];
  bool _isLoadingSounds = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.alarm.title);
    _descriptionController = TextEditingController(
      text: widget.alarm.description,
    );
    _selectedTime = widget.alarm.time;
    _repeatDays = List.from(widget.alarm.repeatDays);
    _vibrate = widget.alarm.vibrate;
    _snoozeEnabled = widget.alarm.snoozeEnabled;
    _snoozeMinutes = widget.alarm.snoozeMinutes;
    _soundPath = widget.alarm.soundPath;

    // 소리 파일 목록 로드
    _loadSoundFiles();
  }

  // 소리 파일 목록 로드
  Future<void> _loadSoundFiles() async {
    setState(() {
      _isLoadingSounds = true;
    });

    try {
      final files = await SoundService.getRawSoundFiles();
      setState(() {
        _soundFiles = files;
        _isLoadingSounds = false;
      });
    } catch (e) {
      print('소리 파일 로드 오류: $e');
      setState(() {
        _isLoadingSounds = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          widget.isNewAlarm ? '알람 추가' : '알람 편집',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saveAlarm,
            child: const Text(
              '저장',
              style: TextStyle(
                color: Colors.indigo,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimeSelector(),
            const SizedBox(height: 24),
            _buildTitleInput(),
            const SizedBox(height: 16),
            _buildDescriptionInput(),
            const SizedBox(height: 24),
            _buildRepeatDaysSelector(),
            const Divider(color: Colors.grey),
            _buildSoundSelector(),
            const Divider(color: Colors.grey),
            _buildVibrateToggle(),
            const Divider(color: Colors.grey),
            _buildSnoozeToggle(),
            if (_snoozeEnabled) _buildSnoozeMinutesSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return GestureDetector(
      onTap: _selectTime,
      child: Center(
        child: Text(
          formatTime24Hour(_selectedTime),
          style: const TextStyle(
            fontSize: 60,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTitleInput() {
    return TextField(
      controller: _titleController,
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(
        labelText: '알람 이름',
        labelStyle: TextStyle(color: Colors.grey),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.indigo),
        ),
      ),
    );
  }

  Widget _buildDescriptionInput() {
    return TextField(
      controller: _descriptionController,
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(
        labelText: '설명 (선택사항)',
        labelStyle: TextStyle(color: Colors.grey),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.indigo),
        ),
      ),
    );
  }

  Widget _buildRepeatDaysSelector() {
    final weekdayShortNames = getWeekdayShortNames();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('반복', style: TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(7, (index) {
            return _buildDayToggle(index, weekdayShortNames[index]);
          }),
        ),
      ],
    );
  }

  Widget _buildDayToggle(int dayIndex, String dayName) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _repeatDays[dayIndex] = !_repeatDays[dayIndex];
        });
      },
      child: CircleAvatar(
        radius: 20,
        backgroundColor:
            _repeatDays[dayIndex] ? Colors.indigo : Colors.grey[800],
        child: Text(
          dayName,
          style: TextStyle(
            color: _repeatDays[dayIndex] ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSoundSelector() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('알람 소리', style: TextStyle(color: Colors.white)),
      subtitle: Text(
        SoundService.getSoundDisplayName(_soundPath),
        style: TextStyle(color: Colors.grey[400]),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: _selectSound,
    );
  }

  Widget _buildVibrateToggle() {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('진동', style: TextStyle(color: Colors.white)),
      value: _vibrate,
      activeColor: Colors.indigo,
      onChanged: (value) {
        setState(() {
          _vibrate = value;
        });
      },
    );
  }

  Widget _buildSnoozeToggle() {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('다시 울림', style: TextStyle(color: Colors.white)),
      value: _snoozeEnabled,
      activeColor: Colors.indigo,
      onChanged: (value) {
        setState(() {
          _snoozeEnabled = value;
        });
      },
    );
  }

  Widget _buildSnoozeMinutesSelector() {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Row(
        children: [
          const Text('다시 울림 간격', style: TextStyle(color: Colors.grey)),
          const Spacer(),
          DropdownButton<int>(
            value: _snoozeMinutes,
            dropdownColor: Colors.grey[900],
            style: const TextStyle(color: Colors.white),
            underline: Container(height: 1, color: Colors.grey),
            onChanged: (int? value) {
              if (value != null) {
                setState(() {
                  _snoozeMinutes = value;
                });
              }
            },
            items:
                [5, 10, 15, 20, 30].map<DropdownMenuItem<int>>((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text('$value분'),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  void _selectTime() async {
    final TimeOfDay currentTime = TimeOfDay(
      hour: _selectedTime.hour,
      minute: _selectedTime.minute,
    );

    final TimeOfDay? pickedTime = await showTimePickerDialog(
      context,
      currentTime,
    );

    if (pickedTime != null) {
      setState(() {
        _selectedTime = DateTime(
          _selectedTime.year,
          _selectedTime.month,
          _selectedTime.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }

  void _selectSound() async {
    String? currentlyPlayingSound;

    // 현재 재생 중인 소리 중지
    await SoundService.stopSound();

    // 상태 업데이트를 위한 타이머
    Timer? statusTimer;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // 타이머 시작
            statusTimer ??= Timer.periodic(Duration(milliseconds: 300), (_) {
              final playing = SoundService.getCurrentlyPlayingSound();
              if (playing != currentlyPlayingSound) {
                setState(() {
                  currentlyPlayingSound = playing;
                  print('상태 업데이트: 현재 재생 중인 소리 = $currentlyPlayingSound');
                });
              }
            });

            return AlertDialog(
              title: Text('알람 소리 선택'),
              content:
                  _isLoadingSounds
                      ? Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 기본 알람 옵션
                            ListTile(
                              title: Text('기본 알람'),
                              selected: _soundPath == 'default',
                              onTap: () {
                                setState(() {
                                  _soundPath = 'default';
                                });
                                Navigator.pop(context);
                              },
                              trailing: IconButton(
                                icon: Icon(
                                  currentlyPlayingSound == 'default'
                                      ? Icons.stop
                                      : Icons.play_arrow,
                                ),
                                onPressed: () async {
                                  print(
                                    '버튼 클릭: default, 현재 재생 중: $currentlyPlayingSound',
                                  );
                                  if (currentlyPlayingSound == 'default') {
                                    await SoundService.stopSound();
                                  } else {
                                    await SoundService.stopSound();
                                    await SoundService.playSound('default');
                                  }
                                },
                              ),
                            ),

                            // 동적으로 로드된 소리 파일들
                            ..._soundFiles.map(
                              (soundFile) => ListTile(
                                title: Text(
                                  SoundService.getSoundDisplayName(soundFile),
                                ),
                                selected: _soundPath == soundFile,
                                onTap: () {
                                  setState(() {
                                    _soundPath = soundFile;
                                  });
                                  Navigator.pop(context);
                                },
                                trailing: IconButton(
                                  icon: Icon(
                                    currentlyPlayingSound == soundFile
                                        ? Icons.stop
                                        : Icons.play_arrow,
                                  ),
                                  onPressed: () async {
                                    print(
                                      '버튼 클릭: $soundFile, 현재 재생 중: $currentlyPlayingSound',
                                    );
                                    if (currentlyPlayingSound == soundFile) {
                                      await SoundService.stopSound();
                                    } else {
                                      await SoundService.stopSound();
                                      await SoundService.playSound(soundFile);
                                    }
                                  },
                                ),
                              ),
                            ),

                            // 소리 없음 옵션
                            ListTile(
                              title: Text('소리 없음'),
                              selected: _soundPath == 'none',
                              onTap: () {
                                setState(() {
                                  _soundPath = 'none';
                                });
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
              actions: [
                TextButton(
                  onPressed: () {
                    SoundService.stopSound();
                    Navigator.pop(context);
                  },
                  child: Text('취소'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      // 대화상자가 닫힐 때 소리 중지 및 타이머 취소
      SoundService.stopSound();
      statusTimer?.cancel();
    });
  }

  void _saveAlarm() {
    // 입력 검증
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('알람 이름을 입력해주세요')));
      return;
    }

    // 알람 객체 생성
    final updatedAlarm = widget.alarm.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      time: _selectedTime,
      repeatDays: _repeatDays,
      vibrate: _vibrate,
      snoozeEnabled: _snoozeEnabled,
      snoozeMinutes: _snoozeMinutes,
      soundPath: _soundPath,
    );

    // 결과 반환 및 화면 닫기
    Navigator.pop(context, updatedAlarm);
  }
}
