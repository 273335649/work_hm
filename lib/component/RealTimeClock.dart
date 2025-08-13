import 'package:flutter/material.dart';

class RealTimeClock extends StatefulWidget {
  @override
  _RealTimeClockState createState() => _RealTimeClockState();
}

class _RealTimeClockState extends State<RealTimeClock> {
  late Stream<DateTime> _clockStream;

  @override
  void initState() {
    super.initState();
    _clockStream = Stream.periodic(Duration(seconds: 1), (_) => DateTime.now());
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DateTime>(
      stream: _clockStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Text(
            _formatDateTime(DateTime.now()),
            style: TextStyle(color: Color(0xFF3A6FCE)), // 设置字体颜色为白色
          );
        }
        return Text(
          _formatDateTime(snapshot.data!),
          style: TextStyle(color: Color(0xFF3A6FCE)), // 设置字体颜色为白色
        );
      },
    );
  }
}
