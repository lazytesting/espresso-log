/// Smooths a series of readings by replacing each value with the median of
/// a window of neighbours centered on it.
///
/// Unlike a moving average, a spike from a single bad reading (e.g. bumping
/// the scale while pressing tare) is discarded rather than blended into
/// nearby values, since it never becomes the median of its window.
class MedianFilter {
  MedianFilter({required this.windowSize})
    : assert(windowSize > 0 && windowSize.isOdd);

  final int windowSize;

  List<double> apply(List<double> values) {
    final half = windowSize ~/ 2;

    return List.generate(values.length, (i) {
      final start = (i - half).clamp(0, values.length);
      final end = (i + half + 1).clamp(0, values.length);
      final window = values.sublist(start, end).toList()..sort();
      return window[window.length ~/ 2];
    });
  }
}
