import 'package:espresso_log/domain/bean/bean.dart';
import 'package:espresso_log/domain/shot/brew_ratio.dart';
import 'package:espresso_log/domain/shot/shot_snapshot.dart';

/// A finished shot, as saved to the device and exported as JSON.
class RecordedShot {
  static const formatVersion = 2;

  final String id;
  final DateTime recordedAt;
  final ShotSnapshot snapshot;
  final String? beanId;
  final double? doseGrams;

  RecordedShot({
    required this.id,
    required this.recordedAt,
    required this.snapshot,
    this.beanId,
    this.doseGrams,
  });

  factory RecordedShot.create(
    ShotSnapshot snapshot, {
    String? beanId,
    double? doseGrams,
    DateTime? now,
  }) {
    final recordedAt = now ?? DateTime.now();
    return RecordedShot(
      id: recordedAt.microsecondsSinceEpoch.toString(),
      recordedAt: recordedAt,
      snapshot: snapshot,
      beanId: beanId,
      doseGrams: doseGrams,
    );
  }

  factory RecordedShot.fromJson(Map<String, dynamic> json) => RecordedShot(
    id: json['id'] as String,
    recordedAt: DateTime.parse(json['recordedAt'] as String),
    snapshot: ShotSnapshot.fromJson(json['snapshot'] as Map<String, dynamic>),
    beanId: json['beanId'] as String?,
    doseGrams: (json['doseGrams'] as num?)?.toDouble(),
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
    'snapshot': snapshot.toJson(),
  };

  Map<String, dynamic> toExportJson({Bean? bean}) => {
    ...toJson(),
    'bean': bean?.toJson(),
  };
}
