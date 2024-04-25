import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

part 'timer_state.dart';

class TimerCubit extends Cubit<TimerState> {
  final _stopwatch = Stopwatch();
  bool _isRunning = false;

  TimerCubit() : super(TimerInitial());

  void start() {
    _stopwatch.reset();
    _stopwatch.start();
    _isRunning = true;
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!_isRunning) {
        timer.cancel();
        emit(TimerStopped((_stopwatch.elapsedMilliseconds / 1000).round()));
      } else {
        emit(TimerRunning((_stopwatch.elapsedMilliseconds / 1000).round()));
      }
    });
  }

  void stop() {
    _isRunning = false;
  }
}
