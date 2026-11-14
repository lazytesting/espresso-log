import 'package:espresso_log/domain/bean/bean.dart';
import 'package:espresso_log/domain/shot/shot_metrics.dart';
import 'package:espresso_log/domain/shot/shot_snapshot.dart';
import 'package:espresso_log/ui/shot/shot_result_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _guji = Bean(
  id: 'b1',
  name: 'Guji',
  roaster: 'Friedhats',
  roastLevel: 1,
  archived: false,
  doseGrams: 18,
);

const _fullShot = ShotSnapshot(
  weightData: [],
  pressureData: [],
  summary: ShotSummary(
    finalWeight: 36.0,
    peakWeightChangeRate: 2.4,
    peakPressure: 9.2,
    durationMillis: 28400,
  ),
);

Future<void> _pump(
  WidgetTester tester, {
  required ShotSnapshot snapshot,
  Bean? bean,
  double? dose,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: ShotResultView(snapshot: snapshot, bean: bean, doseGrams: dose),
    ),
  ),
);

void main() {
  testWidgets('shows bean header and every metric with its label', (
    tester,
  ) async {
    await _pump(tester, snapshot: _fullShot, bean: _guji, dose: 18.0);

    expect(find.text('Guji'), findsOneWidget);
    expect(find.text('Friedhats · Light'), findsOneWidget);
    for (final label in [
      'Dose',
      'Yield',
      'Ratio',
      'Time',
      'Peak pressure',
      'Peak flow',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text('1 : 2.0', findRichText: true), findsOneWidget);
    expect(find.textContaining('28.4', findRichText: true), findsOneWidget);
    expect(find.textContaining('9.2', findRichText: true), findsOneWidget);
    expect(find.textContaining('2.4', findRichText: true), findsOneWidget);
  });

  testWidgets('empty shot without bean or dose shows dashes', (tester) async {
    await _pump(tester, snapshot: ShotSnapshot.empty);

    expect(find.text('Unknown bean'), findsOneWidget);
    expect(find.text('--', findRichText: true), findsNWidgets(5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('long bean name does not overflow at phone width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _pump(
      tester,
      snapshot: _fullShot,
      bean: _guji.copyWith(name: 'A' * 60, roaster: () => 'B' * 60),
      dose: 18.0,
    );

    expect(tester.takeException(), isNull);
  });
}
