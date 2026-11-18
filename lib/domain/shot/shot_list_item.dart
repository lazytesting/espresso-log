import 'package:espresso_log/domain/shot/recorded_shot.dart';

/// A saved shot as listed in History: the columns needed for a row, without
/// the (large) graph snapshot.
class ShotListItem {
  final String id;
  final DateTime recordedAt;
  final String? beanId;
  final String? grinderId;
  final String? grindSetting;
  final double? doseGrams;
  final double? finalWeight;
  final int durationMillis;

  const ShotListItem({
    required this.id,
    required this.recordedAt,
    required this.durationMillis,
    this.beanId,
    this.grinderId,
    this.grindSetting,
    this.doseGrams,
    this.finalWeight,
  });

  factory ShotListItem.fromShot(RecordedShot shot) => ShotListItem(
    id: shot.id,
    recordedAt: shot.recordedAt,
    beanId: shot.beanId,
    grinderId: shot.grinderId,
    grindSetting: shot.grindSetting,
    doseGrams: shot.doseGrams,
    finalWeight: shot.snapshot.summary.finalWeight,
    durationMillis: shot.snapshot.summary.durationMillis,
  );
}
