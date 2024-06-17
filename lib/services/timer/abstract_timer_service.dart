import 'dart:async';

abstract class AbstractTimerService {
  final timerUpdates = StreamController<TimerEvent>();

  Future<void> start() async {}

  Future<void> stop() async {}
}

abstract class TimerEvent {
  final DateTime timeStamp;

  TimerEvent(this.timeStamp);
}

class TimerStartedEvent extends TimerEvent {
  TimerStartedEvent(super.timeStamp);
}

class TimerStoppedEvent extends TimerEvent {
  TimerStoppedEvent(super.timeStamp);
}

class TimerTickedEvent extends TimerEvent {
  TimerTickedEvent(super.timeStamp);
}
