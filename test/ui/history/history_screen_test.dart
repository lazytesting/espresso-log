import 'package:espresso_log/domain/bean/bean_repository.dart';
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
    expect(find.text('2026-11-12 08:14'), findsOneWidget);
  });
}
