part of 'shot_cubit.dart';

sealed class ShotState {}

final class ShotInitial extends ShotState {}

final class ShotWaiting extends ShotState {}

final class ShotRun extends ShotState with EquatableMixin {
  final List<ShotGraphData> pressureData;
  final List<ShotGraphData> weightData;
  final double timer;
  final double weight;
  final double weightChange;
  final double pressure;

  ShotRun({
    required this.pressureData,
    required this.weightData,
    required this.timer,
    required this.weight,
    required this.weightChange,
    required this.pressure,
  });

  @override
  List<Object?> get props => [pressureData, weightData];
}

final class ShotUpdating extends ShotRun {
  ShotUpdating({
    required super.pressureData,
    required super.weightData,
    required super.timer,
    required super.weight,
    required super.weightChange,
    required super.pressure,
  });
}

final class ShotStopped extends ShotRun {
  ShotStopped({
    required super.pressureData,
    required super.weightData,
    required super.timer,
    required super.weight,
    required super.weightChange,
    required super.pressure,
  });
}

class ShotGraphData {
  final int millisecond;
  final double value;
  ShotGraphData(this.millisecond, this.value);
}
