import 'package:espresso_log/devices/models/notification.dart';

class WeightNotification implements Notification {
  final double weight;
  @override
  final DateTime timeStamp;

  WeightNotification({required this.weight, required this.timeStamp});

  @override
  Map<String, dynamic> toJson() => {
    'type': 'WeightNotification',
    'weight': weight,
    'timeStamp': timeStamp.toIso8601String(),
  };
}

class TareNotification implements Notification {
  @override
  final DateTime timeStamp;
  TareNotification({required this.timeStamp});
  @override
  Map<String, dynamic> toJson() => {
    'type': 'TareNotification',
    'timeStamp': timeStamp.toIso8601String(),
  };
}
