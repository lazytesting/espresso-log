part of 'shot_cubit.dart';

sealed class ShotState {}

final class ShotInitial extends ShotState {}

final class ShotWaiting extends ShotState {}

final class ShotUpdating extends ShotState with EquatableMixin {
  final List<ShotGraphData> pressureData;
  final List<ShotGraphData> weightData;
  final double timer;
  final double weight;
  final double weightChange;
  final double pressure;
  final bool isFinished;

  ShotUpdating({
    required this.pressureData,
    required this.weightData,
    required this.timer,
    required this.weight,
    required this.weightChange,
    required this.pressure,
    required this.isFinished,
  });

  @override
  List<Object?> get props => [
    pressureData,
    weightData,
    timer,
    weight,
    weightChange,
    pressure,
    isFinished,
  ];
}

class ShotGraphData {
  final int millisecond;
  final double value;
  ShotGraphData(this.millisecond, this.value);
}
