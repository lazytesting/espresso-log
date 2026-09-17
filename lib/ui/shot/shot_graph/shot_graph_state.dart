// lib/ui/shot/shot_graph/shot_graph_state.dart
part of 'shot_graph_cubit.dart';

sealed class ShotGraphState {}

final class ShotGraphInitial extends ShotGraphState {}

final class ShotGraphWaiting extends ShotGraphState {}

final class ShotGraphRun extends ShotGraphState with EquatableMixin {
  final List<ShotGraphPoint> pressureData;
  final List<ShotGraphPoint> weightData;
  ShotGraphRun(this.pressureData, this.weightData);

  @override
  List<Object?> get props => [pressureData, weightData];
}

final class ShotGraphUpdating extends ShotGraphRun {
  ShotGraphUpdating(super.pressureData, super.weightData);
}

final class ShotGraphStopped extends ShotGraphRun {
  ShotGraphStopped(super.pressureData, super.weightData);
}
