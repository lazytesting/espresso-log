import 'dart:async';

import 'package:espresso_log/domain/shot/abstract_shot_clock.dart';
import 'package:espresso_log/domain/shot/timer_event.dart';
import 'package:rxdart/rxdart.dart';
import 'package:talker_flutter/talker_flutter.dart';

class ShotClock implements AbstractShotClock {
  final _streamController = BehaviorSubject<TimerEvent>();
  @override
  Stream<TimerEvent> stream = const Stream.empty();

  Timer? _timer;
  DateTime? _startMoment;

  final Talker? _talker;

  ShotClock({Talker? talker}) : _talker = talker {
    stream = _streamController.stream.asBroadcastStream();
  }
  @override
  Future<void> start() async {
    _startMoment = DateTime.now();
    _talker?.info('Shot clock started');
    _streamController.add(TimerStarted(_startMoment!, 0));

    _timer = Timer.periodic(
      const Duration(milliseconds: 100),
      (Timer t) => _emitTickEvent(),
    );
  }

  void _emitTickEvent() {
    _streamController.add(
      TimerTicked(
        DateTime.now(),
        DateTime.now().difference(_startMoment!).inMilliseconds,
      ),
    );
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    DateTime stopMoment = DateTime.now();
    _talker?.info(
      'Shot clock stopped after '
      '${_startMoment == null ? '?' : stopMoment.difference(_startMoment!).inMilliseconds}ms',
    );
    _streamController.add(
      TimerStopped(
        stopMoment,
        DateTime.now().difference(_startMoment!).inMilliseconds,
      ),
    );
  }

  @override
  bool get isRunning => _timer?.isActive == true;
}
