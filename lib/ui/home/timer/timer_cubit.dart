import 'dart:async';

import 'package:espresso_log/main.dart';
import 'package:espresso_log/services/timer/abstract_timer_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'timer_state.dart';

class TimerCubit extends Cubit<TimerState> {
  final AbstractTimerService _timerService = getIt.get<AbstractTimerService>();
  DateTime? _startmoment;
  late StreamSubscription<TimerEvent> _timerSubscription;

  TimerCubit() : super(TimerInitial());

  (int, int) _getDuration(DateTime currentMoment) {
    var start = _startmoment ?? currentMoment;
    var diff = currentMoment.difference(start).inMilliseconds;
    var seconds = diff ~/ 1000;
    var deciSeconds = ((diff / 1000 - seconds) * 10).toInt();
    return (seconds, deciSeconds);
  }

  void start() {
    _timerService.start();
    _timerSubscription = _timerService.timerUpdates.stream.listen((event) {
      if (event is TimerTickedEvent) {
        _startmoment ??= event.timeStamp;
        var (seconds, deciSeconds) = _getDuration(event.timeStamp);
        emit(TimerRunning(seconds, deciSeconds));
      }
    });
  }

  void stop() {
    _timerService.stop();
    _timerSubscription.cancel();
    var (seconds, deciSeconds) = _getDuration(DateTime.now());
    emit(TimerStopped(seconds, deciSeconds));
    _startmoment = null;
  }
}
