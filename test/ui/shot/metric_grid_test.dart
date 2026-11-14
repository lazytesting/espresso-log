import 'package:espresso_log/ui/shot/metric_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('MetricGrid lays cells out in rows of `columns` in one card', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const MetricGrid(
          columns: 3,
          cells: [
            MetricCell(value: '1'),
            MetricCell(value: '2'),
            MetricCell(value: '3'),
            MetricCell(value: '4'),
          ],
        ),
      ),
    );

    expect(find.byType(Card), findsOneWidget);
    expect(
      find.descendant(of: find.byType(MetricGrid), matching: find.byType(Row)),
      findsNWidgets(2),
    );
  });

  testWidgets('MetricCell shows value, unit and label', (tester) async {
    await tester.pumpWidget(
      _wrap(const MetricCell(value: '18.0', unit: 'g', label: 'Dose')),
    );

    expect(find.text('Dose'), findsOneWidget);
    expect(find.textContaining('18.0', findRichText: true), findsOneWidget);
    expect(find.textContaining(' g', findRichText: true), findsOneWidget);
  });

  testWidgets('MetricCell hides the unit when the value is unknown', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const MetricCell(value: '--', unit: 'g')));

    expect(find.text('--', findRichText: true), findsOneWidget);
  });

  test('formatMetric', () {
    expect(formatMetric(null), '--');
    expect(formatMetric(9.24), '9.2');
  });
}
