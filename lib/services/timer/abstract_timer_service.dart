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
  TimerStartedEvent(int milliseconds) : super(milliseconds);
}

class TimerTickedEvent extends TimerEvent {
  TimerTickedEvent(int milliseconds) : super(milliseconds);
}

class TimerStoppedEvent extends TimerEvent {
  TimerStoppedEvent(int milliseconds) : super(milliseconds);
}
