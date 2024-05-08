part of 'weight_graph_cubit.dart';

sealed class WeightGraphState {}

final class WeightGraphInitial extends WeightGraphState {}

final class WeightGraphUpdating extends WeightGraphState {
  final List<GraphData> data;
  WeightGraphUpdating(this.data);
}

final class WeightGraphStopped extends WeightGraphState {
  final List<GraphData> data;
  WeightGraphStopped(this.data);
}

class GraphData {
  final int millisecond;
  final double weight;

  GraphData(this.millisecond, this.weight);
}
