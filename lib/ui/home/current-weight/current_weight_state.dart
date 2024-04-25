part of 'current_weight_cubit.dart';

@immutable
sealed class CurrentWeightState {}

final class CurrentWeightInitial extends CurrentWeightState {}

final class CurrentWeightError extends CurrentWeightState {}

final class CurrentWeightMeasured extends CurrentWeightState {
  final double weight;

  CurrentWeightMeasured(this.weight);
}
