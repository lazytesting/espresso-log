import 'dart:async';

import 'package:espresso_log/services/notification.dart';
import 'package:json_annotation/json_annotation.dart';

part 'abstract_timer_service.g.dart';

abstract class AbstractTimerService {
  Stream<TimerEvent> stream = const Stream.empty();
  bool get isRunning;
  Future<void> start() async {}

  Future<void> stop() async {}
}

abstract class TimerEvent implements Notification {
  @override
  final DateTime timeStamp;
  final int milliSeconds;

  TimerEvent(this.timeStamp, this.milliSeconds);
}

@JsonSerializable()
class TimerStartedEvent extends TimerEvent {
  TimerStartedEvent(super.timeStamp, super.milliSeconds);
  Map<String, dynamic> toJson() => _$TimerStartedEventToJson(this);
}

@JsonSerializable()
class TimerStoppedEvent extends TimerEvent {
  TimerStoppedEvent(super.timeStamp, super.milliSeconds);
  Map<String, dynamic> toJson() => _$TimerStoppedEventToJson(this);
}

@JsonSerializable()
class TimerTickedEvent extends TimerEvent {
  TimerTickedEvent(super.timeStamp, super.milliSeconds);
  Map<String, dynamic> toJson() => _$TimerTickedEventToJson(this);
}
