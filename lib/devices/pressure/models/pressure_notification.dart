import 'package:espresso_log/devices/models/notification.dart';

class PressureNotification implements Notification {
  @override
  final DateTime timeStamp;
  final double pressure;

  PressureNotification(this.pressure, this.timeStamp);
  @override
  Map<String, dynamic> toJson() => {
    'type': 'PressureNotification',
    'pressure': pressure,
    'timeStamp': timeStamp.toIso8601String(),
  };
}
