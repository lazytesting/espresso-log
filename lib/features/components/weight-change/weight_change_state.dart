part of 'weight_change_cubit.dart';

sealed class WeightChangeState {}

final class WeightChangeInitial extends WeightChangeState with EquatableMixin {
  @override
  List<Object?> get props => [];
}

final class WeightChangeError extends WeightChangeState with EquatableMixin {
  @override
  List<Object?> get props => [];
}

final class WeightChangeUpdated extends WeightChangeState with EquatableMixin {
  final double weightChangeRate;

  WeightChangeUpdated(this.weightChangeRate);
  @override
  List<Object?> get props => [weightChangeRate];
}
