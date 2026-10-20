import 'package:espresso_log/domain/shot/peak_filter.dart';
import 'package:espresso_log/domain/shot/shot_graph_point.dart';
import 'package:flutter_test/flutter_test.dart';

List<ShotGraphPoint> _points(List<double> values) => [
  for (final (i, v) in values.indexed) ShotGraphPoint(i * 100, v),
];

List<double> _values(List<ShotGraphPoint> points) =>
    points.map((p) => p.value).toList();

void main() {
  final filter = PeakFilter(
    minDuration: const Duration(milliseconds: 300),
    minHeight: 10,
  );

  test('returns an empty list for empty input', () {
    expect(filter.apply([]), isEmpty);
  });

  test('leaves data without peaks unchanged', () {
    final input = _points([0, 1, 2, 3, 4, 5]);

    expect(_values(filter.apply(input)), [0, 1, 2, 3, 4, 5]);
  });

  test('flattens an upward peak to a straight line', () {
    final input = _points([0, 0, 100, 100, 100, 0, 0]);

    expect(_values(filter.apply(input)), [0, 0, 0, 0, 0, 0, 0]);
  });

  test('interpolates between the values before and after the peak', () {
    final input = _points([2, 100, 100, 100, 100, 7]);

    expect(_values(filter.apply(input)), [2, 3, 4, 5, 6, 7]);
  });

  test('leaves a downward peak', () {
    final input = _points([50, 50, -40, -40, -40, 50, 50]);

    expect(_values(filter.apply(input)), [50, 50, -40, -40, -40, 50, 50]);
  });

  test('leaves peaks lower than minHeight', () {
    final input = _points([0, 0, 5, 5, 5, 0, 0]);

    expect(_values(filter.apply(input)), [0, 0, 5, 5, 5, 0, 0]);
  });

  test('leaves peaks shorter than minDuration', () {
    final input = _points([0, 0, 100, 0, 0]);

    expect(_values(filter.apply(input)), [0, 0, 100, 0, 0]);
  });

  test('leaves a step that does not come back down', () {
    final input = _points([0, 0, 40, 40, 40, 40]);

    expect(_values(filter.apply(input)), [0, 0, 40, 40, 40, 40]);
  });

  test('leaves a peak still going up at the end of the data', () {
    final input = _points([0, 0, 100, 100, 100]);

    expect(_values(filter.apply(input)), [0, 0, 100, 100, 100]);
  });

  test('leaves a peak at the start of the data', () {
    final input = _points([100, 100, 100, 0, 0]);

    expect(_values(filter.apply(input)), [100, 100, 100, 0, 0]);
  });

  test('flattens multiple separate peaks', () {
    final input = _points([0, 90, 90, 90, 0, 0, 90, 90, 90, 0]);

    expect(_values(filter.apply(input)), List.filled(10, 0.0));
  });

  test('uses timestamps, not indices, for interpolation', () {
    final input = [
      ShotGraphPoint(0, 0),
      ShotGraphPoint(100, 100),
      ShotGraphPoint(500, 100),
      ShotGraphPoint(1000, 5),
    ];

    expect(_values(filter.apply(input)), [0, 0.5, 2.5, 5]);
  });
}
