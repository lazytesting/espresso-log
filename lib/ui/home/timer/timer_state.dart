part of 'timer_cubit.dart';

sealed class TimerState {}

final class TimerInitial extends TimerState {}

final class TimerRunning extends TimerState {
  final int seconds;
  final int deciSeconds;

  TimerRunning(this.seconds, this.deciSeconds);
}

final class TimerStopped extends TimerState {
  final int seconds;
  final int deciSeconds;

  TimerStopped(this.seconds, this.deciSeconds);
}
