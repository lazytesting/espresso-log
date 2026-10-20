import 'package:espresso_log/domain/shot/shot_graph_point.dart';

/// Removes large temporary upward peaks (up and back down) from a series of
/// points,
/// e.g. the weight of a cup that is placed on the scale just before it is
/// tared. This does not happen during a real shot.
///
/// A peak is a run of points that all lie at least [minHeight] above the
/// average of the points just before and just after the run, and lasts at least
/// [minDuration]. Downward peaks are not detected. Its points are replaced by
/// a straight line between those two surrounding points.
///
/// A run that has not come back down yet (at the end of the data) is not a
/// peak, nor is a step that stays up. Shorter or lower fluctuations are left
/// to other filters, e.g. [MedianFilter].
class PeakFilter {
  PeakFilter({required this.minDuration, required this.minHeight});

  final Duration minDuration;
  final double minHeight;

  List<ShotGraphPoint> apply(List<ShotGraphPoint> points) {
    final result = List.of(points);

    // Scans [result], so a flattened peak counts as flat for the next one.
    var start = 1;
    while (start < result.length - 1) {
      final end = _peakEnd(result, start);
      if (end == null) {
        start++;
        continue;
      }
      final before = result[start - 1];
      final after = result[end + 1];
      final span = after.millisecond - before.millisecond;
      for (var i = start; i <= end; i++) {
        final fraction = span == 0
            ? 0
            : (result[i].millisecond - before.millisecond) / span;
        result[i] = ShotGraphPoint(
          result[i].millisecond,
          before.value + (after.value - before.value) * fraction,
        );
      }
      start = end + 1;
    }

    return result;
  }

  /// The index of the last point of the peak that starts at [start], or null
  /// if no peak starts there.
  int? _peakEnd(List<ShotGraphPoint> points, int start) {
    final before = points[start - 1].value;
    if (points[start].value - before < minHeight) return null;

    // Find the first point after the run that is back near the start level.
    var after = start + 1;
    while (after < points.length && points[after].value - before >= minHeight) {
      after++;
    }
    if (after >= points.length) return null;

    final reference = (before + points[after].value) / 2;
    final end = after - 1;
    for (var i = start; i <= end; i++) {
      if (points[i].value - reference < minHeight) return null;
    }

    // The peak lasts from the last point before it to the first point after it.
    final duration = points[after].millisecond - points[start - 1].millisecond;
    if (duration < minDuration.inMilliseconds) return null;

    return end;
  }
}
