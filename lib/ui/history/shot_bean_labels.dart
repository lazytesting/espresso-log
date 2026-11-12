import 'package:espresso_log/domain/bean/bean.dart';
import 'package:espresso_log/domain/shot/recorded_shot.dart';

const unknownBeanLabel = 'Unknown bean';

String beanNameFor(RecordedShot shot, Bean? bean) =>
    bean?.name ?? unknownBeanLabel;

String formatDose(double? grams) =>
    grams == null ? '--' : '${grams.toStringAsFixed(1)} g';

/// Second line of a history row; null for shots saved before beans existed.
String? historySubtitle(RecordedShot shot, Bean? bean) {
  if (shot.beanId == null && shot.doseGrams == null) return null;
  final name = beanNameFor(shot, bean);
  return shot.doseGrams == null
      ? name
      : '$name · ${formatDose(shot.doseGrams)}';
}
