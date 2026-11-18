import 'package:espresso_log/domain/bean/bean.dart';
import 'package:espresso_log/domain/grinder/grind_setting.dart';
import 'package:espresso_log/domain/grinder/grinder.dart';
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

const _niche = Grinder(
  id: 'g1',
  name: 'Niche',
  brand: 'Niche',
  settingType: GrindSettingType.numeric,
  archived: false,
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
  Grinder? grinder,
  String? grindSetting,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: ShotResultView(
        snapshot: snapshot,
        bean: bean,
        doseGrams: dose,
        grinder: grinder,
        grindSetting: grindSetting,
      ),
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
    expect(find.text('1:2.0', findRichText: true), findsOneWidget);
    expect(find.textContaining('28.4', findRichText: true), findsOneWidget);
    expect(find.textContaining('9.2', findRichText: true), findsOneWidget);
    expect(find.textContaining('2.4', findRichText: true), findsOneWidget);
  });

  testWidgets('empty shot without bean or dose shows dashes', (tester) async {
    await _pump(tester, snapshot: ShotSnapshot.empty);

    expect(find.text('Unknown bean'), findsOneWidget);
    expect(find.text('--', findRichText: true), findsNWidgets(6));
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

  testWidgets('ratio uses the same text colour as the other values', (
    tester,
  ) async {
    await _pump(tester, snapshot: _fullShot, bean: _guji, dose: 18.0);

    Color? colorOf(String text) => tester
        .widget<RichText>(find.textContaining(text, findRichText: true))
        .text
        .style
        ?.color;
    expect(colorOf('1:2.0'), colorOf('28.4'));
  });

  testWidgets('shows grinder name and grind setting', (tester) async {
    await _pump(
      tester,
      snapshot: _fullShot,
      bean: _guji,
      dose: 18.0,
      grinder: _niche,
      grindSetting: '3C',
    );

    expect(find.text('Niche'), findsOneWidget);
    expect(find.text('Grind'), findsOneWidget);
    expect(find.text('3C', findRichText: true), findsOneWidget);
  });

  testWidgets('without a grinder shows Unknown grinder and no Grind', (
    tester,
  ) async {
    await _pump(tester, snapshot: _fullShot, bean: _guji, dose: 18.0);

    expect(find.text('Unknown grinder'), findsOneWidget);
    expect(find.text('Grind'), findsNothing);
  });
}
