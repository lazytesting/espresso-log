part of 'current_weight_cubit.dart';

@immutable
sealed class CurrentWeightState {}

final class CurrentWeightInitial extends CurrentWeightState
    with EquatableMixin {
  @override
  List<Object?> get props => throw UnimplementedError();
}

final class CurrentWeightError extends CurrentWeightState with EquatableMixin {
  @override
  List<Object?> get props => [];
}

final class CurrentWeightMeasured extends CurrentWeightState
    with EquatableMixin {
  final double weight;

  CurrentWeightMeasured(this.weight);

  @override
  List<Object?> get props => [weight];
}
