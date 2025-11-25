import 'package:espresso_log/devices/models/notification.dart';

abstract class TimerNotification implements Notification {
  @override
  final DateTime timeStamp;
  final int milliSeconds;

  TimerNotification(this.timeStamp, this.milliSeconds);
}

class TimerStartedNotification extends TimerNotification {
  TimerStartedNotification(super.timeStamp, super.milliSeconds);
  @override
  Map<String, dynamic> toJson() => {
    'type': 'TimerStartedNotification',
    'milliSeconds': milliSeconds,
    'timeStamp': timeStamp.toIso8601String(),
  };
}

class TimerStoppedNotification extends TimerNotification {
  TimerStoppedNotification(super.timeStamp, super.milliSeconds);
  @override
  Map<String, dynamic> toJson() => {
    'type': 'TimerStoppedNotification',
    'milliSeconds': milliSeconds,
    'timeStamp': timeStamp.toIso8601String(),
  };
}

class TimerTickedNotification extends TimerNotification {
  TimerTickedNotification(super.timeStamp, super.milliSeconds);
  @override
  Map<String, dynamic> toJson() => {
    'type': 'TimerTickedNotification',
    'milliSeconds': milliSeconds,
    'timeStamp': timeStamp.toIso8601String(),
  };
}
