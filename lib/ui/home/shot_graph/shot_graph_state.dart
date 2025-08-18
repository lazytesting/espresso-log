part of 'shot_graph_cubit.dart';

sealed class ShotGraphState {}

final class ShotGraphInitial extends ShotGraphState {}

final class ShotGraphWaiting extends ShotGraphState {}

final class ShotGraphRun extends ShotGraphState with EquatableMixin {
  final List<ShotGraphData> pressureData;
  final List<ShotGraphData> weightData;
  ShotGraphRun(this.pressureData, this.weightData);

  @override
  List<Object?> get props => [pressureData, weightData];
}

final class ShotGraphUpdating extends ShotGraphRun {
  ShotGraphUpdating(super.pressureData, super.weightDat);
}

final class ShotGraphStopped extends ShotGraphRun {
  ShotGraphStopped(super.pressureData, super.weightData);
}

class ShotGraphData {
  final int millisecond;
  final double value;
  ShotGraphData(this.millisecond, this.value);
}
