import 'package:espresso_log/domain/shot/shot_snapshot.dart';

/// A finished shot, as saved to the device and exported as JSON.
class RecordedShot {
  static const formatVersion = 1;

  final String id;
  final DateTime recordedAt;
  final ShotSnapshot snapshot;

  RecordedShot({
    required this.id,
    required this.recordedAt,
    required this.snapshot,
  });

  factory RecordedShot.create(ShotSnapshot snapshot, {DateTime? now}) {
    final recordedAt = now ?? DateTime.now();
    return RecordedShot(
      id: recordedAt.microsecondsSinceEpoch.toString(),
      recordedAt: recordedAt,
      snapshot: snapshot,
    );
  }

  factory RecordedShot.fromJson(Map<String, dynamic> json) => RecordedShot(
    id: json['id'] as String,
    recordedAt: DateTime.parse(json['recordedAt'] as String),
    snapshot: ShotSnapshot.fromJson(json['snapshot'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {
    'version': formatVersion,
    'id': id,
    'recordedAt': recordedAt.toIso8601String(),
    'snapshot': snapshot.toJson(),
  };
}
