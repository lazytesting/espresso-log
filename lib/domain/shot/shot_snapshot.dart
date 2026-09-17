import 'package:espresso_log/domain/shot/shot_graph_point.dart';

class ShotSnapshot {
  final List<ShotGraphPoint> weightData;
  final List<ShotGraphPoint> pressureData;

  const ShotSnapshot({required this.weightData, required this.pressureData});

  static const empty = ShotSnapshot(weightData: [], pressureData: []);
}
