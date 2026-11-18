import 'package:espresso_log/domain/grinder/grind_setting.dart';
import 'package:espresso_log/domain/grinder/grinder.dart';
import 'package:espresso_log/ui/beans/beans_cubit.dart';
import 'package:espresso_log/ui/grinders/grinder_edit_screen.dart';
import 'package:espresso_log/ui/grinders/grinders_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_settings.dart';
import '../../support/in_memory_bean_repository.dart';
import '../../support/in_memory_grind_memory_repository.dart';
import '../../support/in_memory_grinder_repository.dart';

void main() {
  late InMemoryGrinderRepository repo;
  late GrindersCubit cubit;
  late BeansCubit beans;

  setUp(() {
    repo = InMemoryGrinderRepository();
    final settings = FakeSettings();
    beans = BeansCubit(InMemoryBeanRepository(), settings);
    cubit = GrindersCubit(
      repo,
      InMemoryGrindMemoryRepository(repo),
      settings,
      beans,
    );
  });

  tearDown(() async {
    await cubit.close();
    await beans.close();
  });

  Future<void> pump(WidgetTester tester, {String? grinderId}) async {
    await beans.load();
    await cubit.load();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BlocProvider.value(
                    value: cubit,
                    child: GrinderEditScreen(grinderId: grinderId),
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Finder saveButton() => find.widgetWithText(FilledButton, 'Save');

  testWidgets('Save disabled while name or brand is blank', (tester) async {
    await pump(tester);
    bool enabled() =>
        tester.widget<FilledButton>(saveButton()).onPressed != null;
    expect(enabled(), isFalse);
    await tester.enterText(find.byKey(const Key('grinder-name')), 'Zero');
    await tester.pump();
    expect(enabled(), isFalse);
    await tester.enterText(find.byKey(const Key('grinder-brand')), '  ');
    await tester.pump();
    expect(enabled(), isFalse);
    await tester.enterText(find.byKey(const Key('grinder-brand')), 'Eureka');
    await tester.pump();
    expect(enabled(), isTrue);
    await tester.enterText(find.byKey(const Key('grinder-name')), ' ');
    await tester.pump();
    expect(enabled(), isFalse);
  });

  testWidgets('add creates a grinder with chosen type and returns', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(find.byKey(const Key('grinder-name')), ' Zero ');
    await tester.enterText(find.byKey(const Key('grinder-brand')), ' Eureka ');
    await tester.tap(find.text('Coarse + fine'));
    await tester.pump();
    await tester.tap(saveButton());
    await tester.pumpAndSettle();
    final grinder = repo.grinders.values.single;
    expect(grinder.name, 'Zero');
    expect(grinder.brand, 'Eureka');
    expect(grinder.settingType, GrindSettingType.coarseFine);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('add defaults to numeric', (tester) async {
    await pump(tester);
    await tester.enterText(find.byKey(const Key('grinder-name')), 'Zero');
    await tester.enterText(find.byKey(const Key('grinder-brand')), 'Eureka');
    await tester.pump();
    await tester.tap(saveButton());
    await tester.pumpAndSettle();
    expect(repo.grinders.values.single.settingType, GrindSettingType.numeric);
  });

  testWidgets('edit pre-fills, changes name/brand, type is disabled', (
    tester,
  ) async {
    final grinder = Grinder.create(
      name: 'Old',
      brand: 'B',
      settingType: GrindSettingType.coarseFine,
    );
    await repo.save(grinder);
    await pump(tester, grinderId: grinder.id);
    expect(find.text('Old'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    final control = tester.widget<SegmentedButton<GrindSettingType>>(
      find.byType(SegmentedButton<GrindSettingType>),
    );
    expect(control.onSelectionChanged, isNull);
    expect(control.selected, {GrindSettingType.coarseFine});
    await tester.enterText(find.byKey(const Key('grinder-name')), 'New');
    await tester.enterText(find.byKey(const Key('grinder-brand')), 'C');
    await tester.pump();
    await tester.tap(saveButton());
    await tester.pumpAndSettle();
    final saved = repo.grinders[grinder.id]!;
    expect(saved.name, 'New');
    expect(saved.brand, 'C');
    expect(saved.settingType, GrindSettingType.coarseFine);
  });

  testWidgets('archive confirm archives, cancel does not', (tester) async {
    final grinder = Grinder.create(
      name: 'Old',
      brand: 'B',
      settingType: GrindSettingType.numeric,
    );
    await repo.save(grinder);
    await pump(tester, grinderId: grinder.id);
    await tester.ensureVisible(find.text('Archive grinder'));
    await tester.tap(find.text('Archive grinder'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repo.grinders[grinder.id]!.archived, isFalse);
    expect(find.byType(GrinderEditScreen), findsOneWidget);

    await tester.tap(find.text('Archive grinder'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();
    expect(repo.grinders[grinder.id]!.archived, isTrue);
    expect(cubit.state.grinders, isEmpty);
    expect(find.byType(GrinderEditScreen), findsNothing);
  });

  testWidgets('unknown id shows Grinder not found', (tester) async {
    await pump(tester, grinderId: 'nope');
    expect(find.text('Grinder not found'), findsOneWidget);
  });
}
