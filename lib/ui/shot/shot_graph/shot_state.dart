part of 'shot_cubit.dart';

sealed class ShotState {}

final class ShotStateInitial extends ShotState {}

final class ShotStateUpdating extends ShotState with EquatableMixin {
  final List<ShotGraphData> pressureData;
  final List<ShotGraphData> weightData;
  final int maxWeightAxis;
  final int maxPressureAxis;
  final double timer;
  final double pressure;
  final double weight;
  final double? weightChange;
  final bool isFinished;
  ShotStateUpdating(
    this.pressureData,
    this.weightData,
    this.maxWeightAxis,
    this.maxPressureAxis,
    this.timer,
    this.pressure,
    this.weight,
    this.weightChange,
    this.isFinished,
  );

  @override
  List<Object?> get props => [
    pressureData,
    weightData,
    maxWeightAxis,
    maxPressureAxis,
    timer,
    pressure,
    weight,
    weightChange,
    isFinished,
  ];
}

class ShotGraphData {
  final int millisecond;
  final double value;
  ShotGraphData(this.millisecond, this.value);
}
