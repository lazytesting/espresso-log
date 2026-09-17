import 'package:espresso_log/domain/shot/median_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns an empty list for empty input', () {
    final filter = MedianFilter(windowSize: 3);

    expect(filter.apply([]), isEmpty);
  });

  test('leaves flat data unchanged', () {
    final filter = MedianFilter(windowSize: 3);

    expect(filter.apply([5, 5, 5, 5, 5]), [5, 5, 5, 5, 5]);
  });

  test('removes an isolated single-sample spike', () {
    final filter = MedianFilter(windowSize: 3);

    // A single reading jumps from 18 to 40 and immediately back to 18, as
    // could happen from touching the scale while pressing tare.
    expect(filter.apply([18, 18, 40, 18, 18]), [18, 18, 18, 18, 18]);
  });

  test('uses a shrunk window at the edges instead of padding', () {
    final filter = MedianFilter(windowSize: 5);

    // With windowSize 5 the first element only has itself and its two
    // right neighbours available (no padding), so the median is of [1, 2, 3].
    expect(filter.apply([1, 2, 3, 100, 100]).first, 2);
  });
}
