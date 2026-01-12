part of 'shot_cubit.dart';

sealed class ShotState {}

final class ShotInitial extends ShotState {}

final class ShotWaiting extends ShotState {}

final class ShotRun extends ShotState with EquatableMixin {
  final List<ShotGraphData> pressureData;
  final List<ShotGraphData> weightData;
  ShotRun(this.pressureData, this.weightData);

  @override
  List<Object?> get props => [pressureData, weightData];
}

final class ShotUpdating extends ShotRun {
  ShotUpdating(super.pressureData, super.weightDat);
}

final class ShotStopped extends ShotRun {
  ShotStopped(super.pressureData, super.weightData);
}

class ShotGraphData {
  final int millisecond;
  final double value;
  ShotGraphData(this.millisecond, this.value);
}
