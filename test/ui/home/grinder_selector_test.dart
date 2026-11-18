import 'package:espresso_log/domain/grinder/grind_setting.dart';
import 'package:espresso_log/domain/grinder/grinder.dart';
import 'package:espresso_log/ui/beans/beans_cubit.dart';
import 'package:espresso_log/ui/grinders/grinders_cubit.dart';
import 'package:espresso_log/ui/home/grinder_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/fake_settings.dart';
import '../../support/in_memory_bean_repository.dart';
import '../../support/in_memory_grind_memory_repository.dart';
import '../../support/in_memory_grinder_repository.dart';

void main() {
  late InMemoryGrinderRepository repo;
  late FakeSettings settings;
  late BeansCubit beans;
  late GrindersCubit cubit;

  Grinder grinder(String id, String name, {bool archived = false}) => Grinder(
    id: id,
    name: name,
    brand: 'Brand $id',
    settingType: GrindSettingType.numeric,
    archived: archived,
  );

  setUp(() {
    repo = InMemoryGrinderRepository();
    settings = FakeSettings();
    beans = BeansCubit(InMemoryBeanRepository(), settings);
    cubit = GrindersCubit(
      repo,
      InMemoryGrindMemoryRepository(repo),
      settings,
      beans,
    );
    repo.grinders['a'] = grinder('a', 'Niche');
    repo.grinders['b'] = grinder('b', 'Eureka');
    repo.grinders['c'] = grinder('c', 'Gone', archived: true);
  });

  tearDown(() async {
    await cubit.close();
    await beans.close();
  });

  Future<GoRouter> pump(WidgetTester tester) async {
    await beans.load();
    await cubit.load();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: BlocProvider.value(
              value: cubit,
              child: const GrinderSelector(),
            ),
          ),
        ),
        GoRoute(
          path: '/settings/grinders/new',
          builder: (_, _) => const Scaffold(body: Text('new grinder page')),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    return router;
  }

  Finder inSheet(String text) =>
      find.descendant(of: find.byType(BottomSheet), matching: find.text(text));

  testWidgets('shows Unknown grinder when none selected', (tester) async {
    await pump(tester);
    expect(find.text('Grinder'), findsOneWidget);
    expect(find.text('Unknown grinder'), findsOneWidget);
  });

  testWidgets('shows selected grinder name and brand', (tester) async {
    settings.selectedGrinderId = 'a';
    await pump(tester);
    expect(find.text('Niche'), findsOneWidget);
    expect(find.text('Brand a'), findsOneWidget);
  });

  testWidgets('sheet lists active grinders, Unknown and Add grinder', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byType(GrinderSelector));
    await tester.pumpAndSettle();
    expect(inSheet('Niche'), findsOneWidget);
    expect(inSheet('Eureka'), findsOneWidget);
    expect(inSheet('Gone'), findsNothing);
    expect(inSheet('Unknown grinder'), findsOneWidget);
    expect(inSheet('Add grinder'), findsOneWidget);
  });

  testWidgets('picking a grinder selects it and shows its name', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byType(GrinderSelector));
    await tester.pumpAndSettle();
    await tester.tap(inSheet('Niche'));
    await tester.pumpAndSettle();
    expect(cubit.state.selectedGrinderId, 'a');
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Niche'), findsOneWidget);
    expect(find.text('Unknown grinder'), findsNothing);
  });

  testWidgets('picking Unknown grinder selects null', (tester) async {
    settings.selectedGrinderId = 'a';
    await pump(tester);
    await tester.tap(find.byType(GrinderSelector));
    await tester.pumpAndSettle();
    await tester.tap(inSheet('Unknown grinder'));
    await tester.pumpAndSettle();
    expect(cubit.state.selectedGrinderId, isNull);
    expect(find.text('Unknown grinder'), findsOneWidget);
  });

  testWidgets('Add grinder opens the new grinder route', (tester) async {
    await pump(tester);
    await tester.tap(find.byType(GrinderSelector));
    await tester.pumpAndSettle();
    await tester.tap(inSheet('Add grinder'));
    await tester.pumpAndSettle();
    expect(find.text('new grinder page'), findsOneWidget);
  });
}
