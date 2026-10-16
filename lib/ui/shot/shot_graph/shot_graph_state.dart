// lib/ui/shot/shot_graph/shot_graph_state.dart
part of 'shot_graph_cubit.dart';

sealed class ShotGraphState {}

final class ShotGraphInitial extends ShotGraphState {}

final class ShotGraphWaiting extends ShotGraphState {}

final class ShotGraphRun extends ShotGraphState with EquatableMixin {
  final ShotSnapshot snapshot;
  ShotGraphRun(this.snapshot);

  List<ShotGraphPoint> get pressureData => snapshot.pressureData;
  List<ShotGraphPoint> get weightData => snapshot.weightData;

  /// Live metrics: while pouring, and while the last drops drip.
  ShotMetrics get metrics => snapshot.metrics;

  @override
  List<Object?> get props => [pressureData, weightData, metrics];
}

final class ShotGraphUpdating extends ShotGraphRun {
  ShotGraphUpdating(super.snapshot);
}

final class ShotGraphStopped extends ShotGraphRun {
  ShotGraphStopped(super.snapshot);

  ShotSummary get summary => snapshot.summary;
}
