import 'package:espresso_log/domain/bean/bean.dart';
import 'package:espresso_log/domain/bean/bean_repository.dart';
import 'package:espresso_log/domain/shot/recorded_shot.dart';
import 'package:espresso_log/domain/shot/shot_metrics.dart';
import 'package:espresso_log/domain/shot/shot_repository.dart';
import 'package:espresso_log/domain/shot/shot_snapshot.dart';
import 'package:espresso_log/ui/history/saved_shot_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../support/in_memory_bean_repository.dart';
import '../../support/in_memory_shot_repository.dart';

RecordedShot _shot(String id, {String? beanId, double? dose}) => RecordedShot(
  id: id,
  recordedAt: DateTime(2026, 1, 1),
  snapshot: const ShotSnapshot(
    weightData: [],
    pressureData: [],
    summary: ShotSummary(finalWeight: 36.0, durationMillis: 25000),
  ),
  beanId: beanId,
  doseGrams: dose,
);

Future<void> _pump(
  WidgetTester tester,
  InMemoryShotRepository shots,
  InMemoryBeanRepository beans,
  String id,
) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<ShotRepository>.value(value: shots),
        Provider<BeanRepository>.value(value: beans),
      ],
      child: MaterialApp(home: SavedShotScreen(shotId: id)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows bean, dose and ratio', (tester) async {
    final shots = InMemoryShotRepository();
    final beans = InMemoryBeanRepository();
    await beans.save(
      const Bean(
        id: 'b1',
        name: 'Guji',
        roaster: 'Roastery',
        roastLevel: 2,
        archived: true,
        doseGrams: 18,
      ),
    );
    await shots.save(_shot('1', beanId: 'b1', dose: 18.0));

    await _pump(tester, shots, beans, '1');

    expect(find.text('Guji'), findsOneWidget);
    expect(find.text('Roastery · Medium-light'), findsOneWidget);
    expect(find.text('18.0 g'), findsOneWidget);
    expect(find.text('36.0 g'), findsOneWidget);
    expect(find.text('1 : 2.0'), findsOneWidget);
    expect(find.text('Seconds'), findsOneWidget);
  });

  testWidgets('old shot shows unknown bean and dashes', (tester) async {
    final shots = InMemoryShotRepository();
    await shots.save(_shot('1'));

    await _pump(tester, shots, InMemoryBeanRepository(), '1');

    expect(find.text('Unknown bean'), findsOneWidget);
    expect(find.text('--'), findsNWidgets(2));
    expect(find.text('36.0 g'), findsOneWidget);
  });
}
