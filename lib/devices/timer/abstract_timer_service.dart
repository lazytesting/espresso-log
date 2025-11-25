import 'dart:async';

import 'package:espresso_log/devices/timer/models/timer_notification.dart';

abstract class AbstractTimerService {
  Stream<TimerNotification> stream = const Stream.empty();
  bool get isRunning;
  Future<void> start() async {}

  Future<void> stop() async {}
}
