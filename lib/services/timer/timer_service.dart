import 'dart:async';

import 'package:espresso_log/services/timer/abstract_timer_service.dart';

class TimerService implements AbstractTimerService {
  @override
  final timerUpdates = StreamController<TimerEvent>.broadcast();
  Timer? _timer;

  @override
  Future<void> start() async {
    DateTime startMoment = DateTime.now();
    timerUpdates.add(TimerStartedEvent(startMoment));

    _timer = Timer.periodic(
        const Duration(milliseconds: 100), (Timer t) => _emitTickEvent());
  }

  _emitTickEvent() {
    timerUpdates.add(TimerTickedEvent(DateTime.now()));
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    DateTime stopMoment = DateTime.now();
    timerUpdates.add(TimerStoppedEvent(stopMoment));
  }
}
