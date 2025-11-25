import 'dart:async';

import 'package:espresso_log/devices/timer/abstract_timer_service.dart';
import 'package:espresso_log/devices/timer/models/timer_notification.dart';
import 'package:rxdart/rxdart.dart';

class TimerService implements AbstractTimerService {
  final _streamController = BehaviorSubject<TimerNotification>();
  @override
  Stream<TimerNotification> stream = const Stream.empty();

  Timer? _timer;
  DateTime? _startMoment;

  TimerService() {
    stream = _streamController.stream.asBroadcastStream();
  }
  @override
  Future<void> start() async {
    _startMoment = DateTime.now();
    _streamController.add(TimerStartedNotification(_startMoment!, 0));

    _timer = Timer.periodic(
      const Duration(milliseconds: 100),
      (Timer t) => _emitTickEvent(),
    );
  }

  void _emitTickEvent() {
    _streamController.add(
      TimerTickedNotification(
        DateTime.now(),
        DateTime.now().difference(_startMoment!).inMilliseconds,
      ),
    );
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    DateTime stopMoment = DateTime.now();
    _streamController.add(
      TimerStoppedNotification(
        stopMoment,
        DateTime.now().difference(_startMoment!).inMilliseconds,
      ),
    );
  }

  @override
  bool get isRunning => _timer?.isActive == true;
}
