import 'package:equatable/equatable.dart';
import 'package:espresso_log/main.dart';
import 'package:espresso_log/services/timer/abstract_timer_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'timer_state.dart';

class TimerCubit extends Cubit<TimerState> {
  final AbstractTimerService _timerService = getIt.get<AbstractTimerService>();

  TimerCubit() : super(TimerInitial()) {
    _timerService.stream.listen((event) {
      var seconds = (event.milliSeconds / 1000).floor();
      var deciSeconds = ((event.milliSeconds - 1000 * seconds) / 100).floor();
      if (event is TimerStartedEvent || event is TimerTickedEvent) {
        emit(TimerRunning(seconds, deciSeconds));
      }

      if (event is TimerStoppedEvent) {
        emit(TimerStopped(seconds, deciSeconds));
      }
    });
  }
}
