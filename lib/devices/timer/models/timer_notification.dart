import 'package:espresso_log/devices/models/notification.dart';
import 'package:json_annotation/json_annotation.dart';
part 'timer_notification.g.dart';

abstract class TimerNotification implements Notification {
  @override
  final DateTime timeStamp;
  final int milliSeconds;

  TimerNotification(this.timeStamp, this.milliSeconds);
}

@JsonSerializable()
class TimerStartedNotification extends TimerNotification {
  TimerStartedNotification(super.timeStamp, super.milliSeconds);
  @override
  Map<String, dynamic> toJson() => _$TimerStartedNotificationToJson(this);
}

@JsonSerializable()
class TimerStoppedNotification extends TimerNotification {
  TimerStoppedNotification(super.timeStamp, super.milliSeconds);
  @override
  Map<String, dynamic> toJson() => _$TimerStoppedNotificationToJson(this);
}

@JsonSerializable()
class TimerTickedNotification extends TimerNotification {
  TimerTickedNotification(super.timeStamp, super.milliSeconds);
  @override
  Map<String, dynamic> toJson() => _$TimerTickedNotificationToJson(this);
}
