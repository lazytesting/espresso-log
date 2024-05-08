import 'dart:async';

import 'package:espresso_log/services/timer/abstract_timer_service.dart';
import 'package:espresso_log/ui/home/timer/timer_cubit.dart';
import 'package:rxdart/rxdart.dart';

class TimerService implements AbstractTimerService {
  @override
  final timerUpdates = BehaviorSubject<TimerEvent>();
  final _stopwatch = Stopwatch();
  bool _isRunning = false;

  @override
  Future<void> start() async {
    timerUpdates.add(TimerStartedEvent(0));
    _stopwatch.reset();
    _stopwatch.start();
    _isRunning = true;
    // TODO change timing
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!_isRunning) {
        timer.cancel();
        timerUpdates.add(TimerStoppedEvent(_stopwatch.elapsedMilliseconds));
      } else {
        timerUpdates.add(TimerTickedEvent(_stopwatch.elapsedMilliseconds));
      }
    });
  }

  @override
  Future<void> stop() async {
    _isRunning = false;
  }
}
