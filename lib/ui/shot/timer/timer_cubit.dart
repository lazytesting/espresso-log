import 'package:equatable/equatable.dart';
import 'package:espresso_log/devices/timer/abstract_timer_service.dart';
import 'package:espresso_log/devices/timer/models/timer_notification.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'timer_state.dart';

class TimerCubit extends Cubit<TimerState> {
  final AbstractTimerService _timerService;

  TimerCubit(this._timerService) : super(TimerInitial()) {
    _timerService.stream.listen((event) {
      var seconds = (event.milliSeconds / 1000).floor();
      var deciSeconds = ((event.milliSeconds - 1000 * seconds) / 100).floor();
      if (event is TimerStartedNotification ||
          event is TimerTickedNotification) {
        emit(TimerRunning(seconds, deciSeconds));
      }

      if (event is TimerStoppedNotification) {
        emit(TimerStopped(seconds, deciSeconds));
      }
    });
  }
}
