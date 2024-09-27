part of 'weight_graph_cubit.dart';

sealed class WeightGraphState {}

final class WeightGraphInitial extends WeightGraphState {}

final class WeightGraphUpdating extends WeightGraphState with EquatableMixin {
  final List<GraphData> data;
  WeightGraphUpdating(this.data);

  @override
  List<Object?> get props => [data];
}

final class WeightGraphStopped extends WeightGraphState with EquatableMixin {
  final List<GraphData> data;
  WeightGraphStopped(this.data);

  @override
  List<Object?> get props => [data];
}

class GraphData {
  final int millisecond;
  final double weight;

  GraphData(this.millisecond, this.weight);
}
