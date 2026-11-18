import 'package:espresso_log/domain/bean/bean.dart';
import 'package:espresso_log/domain/grinder/grinder.dart';
import 'package:espresso_log/domain/shot/brew_ratio.dart';
import 'package:espresso_log/domain/shot/shot_snapshot.dart';

/// A finished shot, as saved to the device and exported as JSON.
class RecordedShot {
  static const formatVersion = 3;

  final String id;
  final DateTime recordedAt;
  final ShotSnapshot snapshot;
  final String? beanId;
  final double? doseGrams;
  final String? grinderId;

  /// Display text of the grind setting, such as `3C`.
  final String? grindSetting;

  RecordedShot({
    required this.id,
    required this.recordedAt,
    required this.snapshot,
    this.beanId,
    this.doseGrams,
    this.grinderId,
    this.grindSetting,
  });

  factory RecordedShot.create(
    ShotSnapshot snapshot, {
    String? beanId,
    double? doseGrams,
    String? grinderId,
    String? grindSetting,
    DateTime? now,
  }) {
    final recordedAt = now ?? DateTime.now();
    return RecordedShot(
      id: recordedAt.microsecondsSinceEpoch.toString(),
      recordedAt: recordedAt,
      snapshot: snapshot,
      beanId: beanId,
      doseGrams: doseGrams,
      grinderId: grinderId,
      grindSetting: grindSetting,
    );
  }

  factory RecordedShot.fromJson(Map<String, dynamic> json) => RecordedShot(
    id: json['id'] as String,
    recordedAt: DateTime.parse(json['recordedAt'] as String),
    snapshot: ShotSnapshot.fromJson(json['snapshot'] as Map<String, dynamic>),
    beanId: json['beanId'] as String?,
    doseGrams: (json['doseGrams'] as num?)?.toDouble(),
    grinderId: json['grinderId'] as String?,
    grindSetting: json['grindSetting'] as String?,
  );

  double? get ratio => brewRatio(
    outputGrams: snapshot.summary.finalWeight,
    doseGrams: doseGrams,
  );

  Map<String, dynamic> toJson() => {
    'version': formatVersion,
    'id': id,
    'recordedAt': recordedAt.toIso8601String(),
    'beanId': beanId,
    'doseGrams': doseGrams,
    'grinderId': grinderId,
    'grindSetting': grindSetting,
    'snapshot': snapshot.toJson(),
  };

  Map<String, dynamic> toExportJson({Bean? bean, Grinder? grinder}) => {
    ...toJson(),
    'bean': bean?.toJson(),
    'grinder': grinder?.toJson(),
  };
}
