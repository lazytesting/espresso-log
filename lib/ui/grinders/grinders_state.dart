part of 'grinders_cubit.dart';

class GrindersState extends Equatable {
  const GrindersState({
    this.loaded = false,
    this.grinders = const [],
    this.selectedGrinderId,
    this.setting,
  });

  final bool loaded;

  /// Non-archived grinders in name order.
  final List<Grinder> grinders;
  final String? selectedGrinderId;

  /// Grind setting for the selected grinder and current bean; null when no
  /// grinder is selected.
  final GrindSetting? setting;

  Grinder? get selectedGrinder {
    for (final grinder in grinders) {
      if (grinder.id == selectedGrinderId) return grinder;
    }
    return null;
  }

  @override
  List<Object?> get props => [loaded, grinders, selectedGrinderId, setting];
}
