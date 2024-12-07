import 'dart:async';

import 'package:espresso_log/services/timer/abstract_timer_service.dart';

class TimerService implements AbstractTimerService {
  @override
  final timerUpdates = StreamController<TimerEvent>.broadcast();
  Timer? _timer;
  DateTime? _startMoment;

  @override
  Future<void> start() async {
    _startMoment = DateTime.now();
    timerUpdates.add(TimerStartedEvent(_startMoment!, 0));

    _timer = Timer.periodic(
        const Duration(milliseconds: 100), (Timer t) => _emitTickEvent());
  }

  _emitTickEvent() {
    timerUpdates.add(TimerTickedEvent(DateTime.now(),
        DateTime.now().difference(_startMoment!).inMilliseconds));
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    DateTime stopMoment = DateTime.now();
    timerUpdates.add(TimerStoppedEvent(
        stopMoment, DateTime.now().difference(_startMoment!).inMilliseconds));
  }

  @override
  bool get isRunning => _timer?.isActive == true;
}
