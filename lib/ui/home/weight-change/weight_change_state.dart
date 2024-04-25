part of 'weight_change_cubit.dart';

sealed class WeightChangeState {}

final class WeightChangeInitial extends WeightChangeState {}

final class WeightChangeError extends WeightChangeState {}

final class WeightChangeUpdated extends WeightChangeState {
  final double weightChangeRate;

  WeightChangeUpdated(this.weightChangeRate);
}
