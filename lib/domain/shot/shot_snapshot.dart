import 'package:espresso_log/domain/shot/shot_graph_point.dart';
import 'package:espresso_log/domain/shot/shot_metrics.dart';

class ShotSnapshot {
  final List<ShotGraphPoint> weightData;
  final List<ShotGraphPoint> pressureData;
  final ShotMetrics metrics;
  final ShotSummary summary;

  const ShotSnapshot({
    required this.weightData,
    required this.pressureData,
    this.metrics = ShotMetrics.empty,
    this.summary = ShotSummary.empty,
  });

  static const empty = ShotSnapshot(weightData: [], pressureData: []);

  factory ShotSnapshot.fromJson(Map<String, dynamic> json) => ShotSnapshot(
    weightData: _points(json['weightData']),
    pressureData: _points(json['pressureData']),
    metrics: ShotMetrics.fromJson(json['metrics'] as Map<String, dynamic>),
    summary: ShotSummary.fromJson(json['summary'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {
    'weightData': weightData.map((p) => p.toJson()).toList(),
    'pressureData': pressureData.map((p) => p.toJson()).toList(),
    'metrics': metrics.toJson(),
    'summary': summary.toJson(),
  };

  static List<ShotGraphPoint> _points(Object? json) => [
    for (final p in json as List)
      ShotGraphPoint.fromJson(p as Map<String, dynamic>),
  ];
}
