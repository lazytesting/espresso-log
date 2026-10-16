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
}
