import 'package:espresso_log/domain/bean/bean.dart';
import 'package:espresso_log/domain/bean/bean_repository.dart';
import 'package:espresso_log/domain/shot/shot_metrics.dart';
import 'package:espresso_log/domain/shot/recorded_shot.dart';
import 'package:espresso_log/domain/shot/shot_repository.dart';
import 'package:espresso_log/domain/shot/shot_snapshot.dart';
import 'package:espresso_log/ui/history/history.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../support/in_memory_bean_repository.dart';
import '../../support/in_memory_shot_repository.dart';

void main() {
  testWidgets('reloads when the tab becomes active again after a save', (
    tester,
  ) async {
    final shots = InMemoryShotRepository();
    Widget app({required bool active}) => MultiProvider(
      providers: [
        Provider<ShotRepository>.value(value: shots),
        Provider<BeanRepository>.value(value: InMemoryBeanRepository()),
      ],
      child: MaterialApp(
        home: TickerMode(enabled: active, child: const HistoryScreen()),
      ),
    );

    await tester.pumpWidget(app(active: true));
    await tester.pumpAndSettle();
    expect(find.text('No saved shots yet'), findsOneWidget);

    // The user leaves the tab (it stays alive but inactive) and saves a shot.
    await tester.pumpWidget(app(active: false));
    await shots.save(
      RecordedShot.create(
        ShotSnapshot.empty,
        now: DateTime(2026, 11, 12, 8, 14),
      ),
    );

    await tester.pumpWidget(app(active: true));
    await tester.pumpAndSettle();
    expect(find.text('08:14'), findsOneWidget);
  });

  Future<void> pumpHistory(
    WidgetTester tester,
    InMemoryShotRepository shots,
    InMemoryBeanRepository beans,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ShotRepository>.value(value: shots),
          Provider<BeanRepository>.value(value: beans),
        ],
        child: MaterialApp(
          home: HistoryScreen(now: () => DateTime(2026, 11, 14, 9)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  RecordedShot shotAt(DateTime at, {String? beanId, double? dose}) =>
      RecordedShot(
        id: at.microsecondsSinceEpoch.toString(),
        recordedAt: at,
        snapshot: const ShotSnapshot(
          weightData: [],
          pressureData: [],
          summary: ShotSummary(finalWeight: 36.0, durationMillis: 28400),
        ),
        beanId: beanId,
        doseGrams: dose,
      );

  testWidgets('groups shots under day headers with roaster and shot time', (
    tester,
  ) async {
    final shots = InMemoryShotRepository();
    final beans = InMemoryBeanRepository();
    await beans.save(
      const Bean(
        id: 'b1',
        name: 'Guji',
        roaster: 'Friedhats',
        roastLevel: 1,
        archived: false,
        doseGrams: 18,
      ),
    );
    await shots.save(
      shotAt(DateTime(2026, 11, 14, 8, 42), beanId: 'b1', dose: 18.0),
    );
    await shots.save(shotAt(DateTime(2026, 11, 12, 7, 5)));

    await pumpHistory(tester, shots, beans);

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Thu 12 Nov'), findsOneWidget);
    expect(find.text('08:42'), findsOneWidget);
    expect(find.text('Guji'), findsOneWidget);
    expect(find.text('Friedhats'), findsOneWidget);
    expect(find.text('18.0 → 36.0 g'), findsOneWidget);
    expect(find.text('28.4 s'), findsNWidgets(2));
    expect(find.text('Unknown bean'), findsOneWidget);
    expect(find.text('-- → 36.0 g'), findsOneWidget);
  });

  testWidgets('long bean name does not overflow at phone width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final shots = InMemoryShotRepository();
    final beans = InMemoryBeanRepository();
    await beans.save(
      Bean(
        id: 'b1',
        name: 'A' * 60,
        roaster: 'B' * 60,
        roastLevel: 1,
        archived: false,
        doseGrams: 18,
      ),
    );
    await shots.save(
      shotAt(DateTime(2026, 11, 14, 8, 42), beanId: 'b1', dose: 18.0),
    );

    await pumpHistory(tester, shots, beans);

    expect(tester.takeException(), isNull);
  });
}
