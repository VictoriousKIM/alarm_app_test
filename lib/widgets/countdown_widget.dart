import 'package:flutter/material.dart';
import 'dart:async';

import '../utils/time_utils.dart';

class CountdownWidget extends StatefulWidget {
  final DateTime alarmTime;
  const CountdownWidget({Key? key, required this.alarmTime}) : super(key: key);

  @override
  _CountdownWidgetState createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<CountdownWidget> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      getRemainingTime(widget.alarmTime),
      style: const TextStyle(color: Colors.grey),
    );
  }
}
