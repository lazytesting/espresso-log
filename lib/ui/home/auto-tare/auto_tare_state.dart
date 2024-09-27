part of 'auto_tare_cubit.dart';

@immutable
sealed class AutoTareState {}

final class AutoTareEnabledState extends AutoTareState with EquatableMixin {
  @override
  List<Object?> get props => [];
}

final class AutoTareDisabledState extends AutoTareState with EquatableMixin {
  @override
  List<Object?> get props => [];
}
