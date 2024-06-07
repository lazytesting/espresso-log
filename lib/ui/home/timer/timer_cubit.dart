import 'package:espresso_log/main.dart';
import 'package:espresso_log/services/timer/abstract_timer_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'timer_state.dart';

class TimerCubit extends Cubit<TimerState> {
  final AbstractTimerService _timerService = getIt.get<AbstractTimerService>();

  TimerCubit() : super(TimerInitial()) {
    _timerService.timerUpdates.listen((event) {
      if (event is TimerStoppedEvent) {
        emit(TimerStopped((event.milliseconds / 1000).round()));
      } else {
        emit(TimerRunning((event.milliseconds / 1000).round()));
      }
    });
  }

  void start() {
    _timerService.start();
  }

  void stop() {
    _timerService.stop();
  }
}
