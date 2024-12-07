import 'dart:async';

abstract class AbstractTimerService {
  final timerUpdates = StreamController<TimerEvent>();

  bool get isRunning;
  Future<void> start() async {}

  Future<void> stop() async {}
}

abstract class TimerEvent {
  final DateTime timeStamp;
  final int milliSeconds;

  TimerEvent(this.timeStamp, this.milliSeconds);
}

class TimerStartedEvent extends TimerEvent {
  TimerStartedEvent(super.timeStamp, super.milliSeconds);
}

class TimerStoppedEvent extends TimerEvent {
  TimerStoppedEvent(super.timeStamp, super.milliSeconds);
}

class TimerTickedEvent extends TimerEvent {
  TimerTickedEvent(super.timeStamp, super.milliSeconds);
}
