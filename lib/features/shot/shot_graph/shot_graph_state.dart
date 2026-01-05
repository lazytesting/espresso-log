part of 'shot_graph_cubit.dart';

sealed class ShotGraphState {}

final class ShotGraphInitial extends ShotGraphState {}

final class ShotGraphWaiting extends ShotGraphState {}

final class ShotGraphRun extends ShotGraphState with EquatableMixin {
  final List<ShotGraphData> pressureData;
  final List<ShotGraphData> weightData;
  final double timer;
  final double currentWeight;
  final double weightChangeRate;
  ShotGraphRun({required this.pressureData, required this.weightData, required this.timer, required this.currentWeight, required this.weightChangeRate});

  @override
  List<Object?> get props => [pressureData, weightData];
}

final class ShotGraphUpdating extends ShotGraphRun {
  ShotGraphUpdating({required super.pressureData, required super.weightData, required super.timer, required super.currentWeight, required super.weightChangeRate});
}

final class ShotGraphStopped extends ShotGraphRun {
  ShotGraphStopped({required super.pressureData, required super.weightData, required super.timer, required super.currentWeight, required super.weightChangeRate});
}

class ShotGraphData {
  final int millisecond;
  final double value;
  ShotGraphData(this.millisecond, this.value);
}
