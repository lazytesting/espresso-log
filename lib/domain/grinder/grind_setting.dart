import 'package:equatable/equatable.dart';

enum GrindSettingType { numeric, coarseFine }

class GrindSetting extends Equatable {
  static const int minCoarse = 1;
  static const int maxCoarse = 10;
  static const List<String> fineSteps = ['A', 'B', 'C', 'D', 'E', 'F'];

  final GrindSettingType type;
  final int coarse;
  final String? fine;

  const GrindSetting.numeric(int value)
    : assert(value >= minCoarse && value <= maxCoarse),
      type = GrindSettingType.numeric,
      coarse = value,
      fine = null;

  const GrindSetting.coarseFine(this.coarse, this.fine)
    : assert(coarse >= minCoarse && coarse <= maxCoarse),
      type = GrindSettingType.coarseFine;

  static GrindSetting defaultFor(GrindSettingType type) => switch (type) {
    GrindSettingType.numeric => const GrindSetting.numeric(5),
    GrindSettingType.coarseFine => const GrindSetting.coarseFine(5, 'A'),
  };

  static GrindSetting? parse(GrindSettingType type, String text) {
    final trimmed = text.trim().toUpperCase();
    switch (type) {
      case GrindSettingType.numeric:
        final value = int.tryParse(trimmed);
        if (value == null || value < minCoarse || value > maxCoarse) {
          return null;
        }
        return GrindSetting.numeric(value);
      case GrindSettingType.coarseFine:
        final match = RegExp(r'^(\d{1,2})([A-F])$').firstMatch(trimmed);
        if (match == null) return null;
        final coarse = int.parse(match.group(1)!);
        if (coarse < minCoarse || coarse > maxCoarse) return null;
        return GrindSetting.coarseFine(coarse, match.group(2)!);
    }
  }

  String get text =>
      type == GrindSettingType.numeric ? '$coarse' : '$coarse$fine';

  GrindSetting stepped(int delta) {
    if (type == GrindSettingType.numeric) {
      return GrindSetting.numeric((coarse + delta).clamp(minCoarse, maxCoarse));
    }
    final index =
        (coarse - minCoarse) * fineSteps.length +
        fineSteps.indexOf(fine!) +
        delta;
    final max = maxCoarse * fineSteps.length - 1;
    final clamped = index.clamp(0, max);
    return GrindSetting.coarseFine(
      clamped ~/ fineSteps.length + minCoarse,
      fineSteps[clamped % fineSteps.length],
    );
  }

  @override
  List<Object?> get props => [type, coarse, fine];
}
