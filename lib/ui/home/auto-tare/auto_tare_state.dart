part of 'auto_tare_cubit.dart';

@immutable
sealed class AutoTareState {}

final class AutoTareEnabledState extends AutoTareState {}

final class AutoTareDisabledState extends AutoTareState {}
