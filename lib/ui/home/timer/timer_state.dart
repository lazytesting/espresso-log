part of 'timer_cubit.dart';

sealed class TimerState {}

final class TimerInitial extends TimerState {}

final class TimerRunning extends TimerState {
  final int seconds;

  TimerRunning(this.seconds);
}

final class TimerStopped extends TimerState {
  final int seconds;

  TimerStopped(this.seconds);
}
