import 'package:espresso_log/domain/bean/bean.dart';
import 'package:espresso_log/ui/beans/beans_cubit.dart';
import 'package:espresso_log/ui/home/bean_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_settings.dart';
import '../../support/in_memory_bean_repository.dart';

void main() {
  late InMemoryBeanRepository repo;
  late FakeSettings settings;
  late BeansCubit cubit;
  late Bean guji;
  late Bean santos;

  setUp(() {
    repo = InMemoryBeanRepository();
    settings = FakeSettings();
    cubit = BeansCubit(repo, settings);
    guji = Bean.create(
      name: 'Guji',
      roaster: 'Friedhats',
      roastLevel: 1,
      now: DateTime(2026, 1, 1),
    );
    santos = Bean.create(
      name: 'Santos',
      now: DateTime(2026, 1, 2),
    ).copyWith(doseGrams: 19.5);
  });

  tearDown(() => cubit.close());

  Future<void> pump(WidgetTester tester) async {
    await cubit.load();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(value: cubit, child: const BeanSelector()),
        ),
      ),
    );
  }

  Finder inSheet(String text) =>
      find.descendant(of: find.byType(BottomSheet), matching: find.text(text));

  testWidgets('shows Unknown bean when none selected', (tester) async {
    await pump(tester);
    expect(find.text('Bean'), findsOneWidget);
    expect(find.text('Unknown bean'), findsOneWidget);
  });

  testWidgets('shows selected bean name and roaster with roast', (
    tester,
  ) async {
    await repo.save(guji);
    await repo.save(santos);
    settings.selectedBeanId = guji.id;
    await pump(tester);
    expect(find.text('Guji'), findsOneWidget);
    expect(find.text('Friedhats · Light'), findsOneWidget);
  });

  testWidgets('sheet with no beans only lists Unknown bean', (tester) async {
    await pump(tester);
    await tester.tap(find.byType(BeanSelector));
    await tester.pumpAndSettle();
    expect(inSheet('Unknown bean'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(ListTile),
      ),
      findsOneWidget,
    );
  });

  testWidgets('sheet lists beans, marks selection, hides archived', (
    tester,
  ) async {
    await repo.save(guji);
    await repo.save(santos);
    await repo.save(
      Bean.create(
        name: 'Gone',
        now: DateTime(2026, 1, 3),
      ).copyWith(archived: true),
    );
    settings.selectedBeanId = guji.id;
    await pump(tester);
    await tester.tap(find.byType(BeanSelector));
    await tester.pumpAndSettle();
    expect(inSheet('Guji'), findsOneWidget);
    expect(inSheet('Santos'), findsOneWidget);
    expect(inSheet('Unknown bean'), findsOneWidget);
    expect(inSheet('Gone'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
    );
  });

  testWidgets('picking a bean selects it and closes the sheet', (tester) async {
    await repo.save(guji);
    await repo.save(santos);
    settings.selectedBeanId = guji.id;
    await pump(tester);
    await tester.tap(find.byType(BeanSelector));
    await tester.pumpAndSettle();
    await tester.tap(inSheet('Santos'));
    await tester.pumpAndSettle();
    expect(cubit.state.selectedBeanId, santos.id);
    expect(cubit.state.doseGrams, 19.5);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('picking Unknown bean selects null', (tester) async {
    await repo.save(guji);
    settings.selectedBeanId = guji.id;
    await pump(tester);
    await tester.tap(find.byType(BeanSelector));
    await tester.pumpAndSettle();
    await tester.tap(inSheet('Unknown bean'));
    await tester.pumpAndSettle();
    expect(cubit.state.selectedBeanId, isNull);
    expect(find.byType(BottomSheet), findsNothing);
  });
}
