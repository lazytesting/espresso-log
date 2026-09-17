import 'package:equatable/equatable.dart';
import 'package:espresso_log/domain/shot/abstract_shot_clock.dart';
import 'package:espresso_log/domain/shot/timer_event.dart' as timer_events;
import 'package:flutter_bloc/flutter_bloc.dart';

part 'timer_state.dart';

class TimerCubit extends Cubit<TimerState> {
  final AbstractShotClock _shotClock;

  TimerCubit(this._shotClock) : super(TimerInitial()) {
    _shotClock.stream.listen((event) {
      var seconds = (event.milliSeconds / 1000).floor();
      var deciSeconds = ((event.milliSeconds - 1000 * seconds) / 100).floor();
      if (event is timer_events.TimerStarted ||
          event is timer_events.TimerTicked) {
        emit(TimerRunning(seconds, deciSeconds));
      }

      if (event is timer_events.TimerStopped) {
        emit(TimerStopped(seconds, deciSeconds));
      }
    });
  }
}
