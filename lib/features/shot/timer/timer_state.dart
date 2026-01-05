part of 'timer_cubit.dart';

sealed class TimerState {}

final class TimerInitial extends TimerState {}

final class TimerRunning extends TimerState with EquatableMixin {
  final int seconds;
  final int deciSeconds;

  TimerRunning(this.seconds, this.deciSeconds);

  @override
  List<Object?> get props => [seconds, deciSeconds];
}

final class TimerStopped extends TimerState with EquatableMixin {
  final int seconds;
  final int deciSeconds;

  TimerStopped(this.seconds, this.deciSeconds);

  @override
  List<Object?> get props => [seconds, deciSeconds];
}
