import 'package:espresso_log/screen_container.dart';
import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScreenContainer(
      title: 'History',
      child: Text('History screen'),
    );
  }
}
