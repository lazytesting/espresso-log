import 'package:espresso_log/domain/shot/timer_event.dart';

abstract class AbstractShotClock {
  Stream<TimerEvent> stream = const Stream.empty();
  bool get isRunning;

  Future<void> start() async {}

  Future<void> stop() async {}
}
