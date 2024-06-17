import 'dart:async';

import 'package:espresso_log/main.dart';
import 'package:espresso_log/services/timer/abstract_timer_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

part 'timer_state.dart';

class TimerCubit extends Cubit<TimerState> {
  final AbstractTimerService _timerService = getIt.get<AbstractTimerService>();
  DateTime? _startmoment;
  late StreamSubscription<TimerEvent> _timerSubscription;

  int _getDuration(DateTime currentMoment) {
    var start = _startmoment ?? currentMoment;
    return currentMoment.difference(start).inSeconds;
  }

  TimerCubit() : super(TimerInitial()) {
    _timerService.timerUpdates.stream
        .whereType<TimerTickedEvent>()
        .listen((event) => emit(TimerRunning(_getDuration(event.timeStamp))));
  }

  void start() {
    _timerService.start();
    _timerSubscription = _timerService.timerUpdates.stream.listen((event) {
      if (event is TimerTickedEvent) {
        _startmoment ??= event.timeStamp;
        emit(TimerRunning(_getDuration(event.timeStamp)));
      }
    });
  }

  void stop() {
    _timerService.stop();
    _timerSubscription.cancel();
    emit(TimerStopped(_getDuration(DateTime.now())));
    _startmoment = null;
  }
}
