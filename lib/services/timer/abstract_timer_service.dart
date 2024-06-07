import 'package:rxdart/rxdart.dart';

abstract class AbstractTimerService {
  final timerUpdates = BehaviorSubject<TimerEvent>();

  Future<void> start() async {}

  Future<void> stop() async {}
}

abstract class TimerEvent {
  final int milliseconds;

  TimerEvent(this.milliseconds);
}

class TimerStartedEvent extends TimerEvent {
  TimerStartedEvent(super.milliseconds);
}

class TimerTickedEvent extends TimerEvent {
  TimerTickedEvent(super.milliseconds);
}

class TimerStoppedEvent extends TimerEvent {
  TimerStoppedEvent(super.milliseconds);
}
