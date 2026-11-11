part of 'pressure_cubit.dart';

sealed class PressureState {}

final class PressureInitial extends PressureState {}

final class Pressure extends PressureState with Equatable {
  final double pressure;

  Pressure(this.pressure);

  @override
  List<Object?> get props => [pressure];
}
