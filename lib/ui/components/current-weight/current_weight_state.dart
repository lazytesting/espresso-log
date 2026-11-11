part of 'current_weight_cubit.dart';

@immutable
sealed class CurrentWeightState {}

final class CurrentWeightInitial extends CurrentWeightState
    with Equatable {
  @override
  List<Object?> get props => throw UnimplementedError();
}

final class CurrentWeightError extends CurrentWeightState with Equatable {
  @override
  List<Object?> get props => [];
}

final class CurrentWeightMeasured extends CurrentWeightState
    with Equatable {
  final double weight;

  CurrentWeightMeasured(this.weight);

  @override
  List<Object?> get props => [weight];
}
