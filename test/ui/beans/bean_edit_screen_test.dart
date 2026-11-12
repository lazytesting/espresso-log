import 'package:espresso_log/domain/bean/bean.dart';
import 'package:espresso_log/ui/beans/bean_edit_screen.dart';
import 'package:espresso_log/ui/beans/beans_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_settings.dart';
import '../../support/in_memory_bean_repository.dart';

void main() {
  late InMemoryBeanRepository repo;
  late BeansCubit cubit;

  setUp(() {
    repo = InMemoryBeanRepository();
    cubit = BeansCubit(repo, FakeSettings());
  });

  tearDown(() => cubit.close());

  Future<void> pump(WidgetTester tester, {String? beanId}) async {
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
                    child: BeanEditScreen(beanId: beanId),
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

  Finder saveButton() => find.widgetWithText(TextButton, 'Save');

  testWidgets('Save disabled for empty and blank name, enabled for text', (
    tester,
  ) async {
    await pump(tester);
    expect(tester.widget<TextButton>(saveButton()).onPressed, isNull);
    await tester.enterText(find.byKey(const Key('bean-name')), '   ');
    await tester.pump();
    expect(tester.widget<TextButton>(saveButton()).onPressed, isNull);
    await tester.enterText(find.byKey(const Key('bean-name')), 'Guji');
    await tester.pump();
    expect(tester.widget<TextButton>(saveButton()).onPressed, isNotNull);
  });

  testWidgets('add mode saves trimmed text with default roast level 3', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(find.byKey(const Key('bean-name')), '  Guji ');
    await tester.enterText(find.byKey(const Key('bean-roaster')), ' Tim ');
    await tester.pump();
    await tester.tap(saveButton());
    await tester.pumpAndSettle();
    final bean = repo.beans.values.single;
    expect(bean.name, 'Guji');
    expect(bean.roaster, 'Tim');
    expect(bean.notes, isNull);
    expect(bean.roastLevel, 3);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('slider sets roast level to 5', (tester) async {
    await pump(tester);
    await tester.enterText(find.byKey(const Key('bean-name')), 'Guji');
    tester.widget<Slider>(find.byType(Slider)).onChanged!(5);
    await tester.pump();
    await tester.tap(saveButton());
    await tester.pumpAndSettle();
    expect(repo.beans.values.single.roastLevel, 5);
  });

  testWidgets('edit mode pre-fills and keeps dose', (tester) async {
    final bean = Bean.create(
      name: 'Old',
      roaster: 'R',
      roastLevel: 2,
      notes: 'n',
    ).copyWith(doseGrams: 17.5);
    await repo.save(bean);
    await pump(tester, beanId: bean.id);
    expect(find.text('Old'), findsOneWidget);
    expect(find.text('R'), findsOneWidget);
    expect(find.text('n'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('bean-name')), 'New');
    await tester.enterText(find.byKey(const Key('bean-roaster')), '');
    await tester.pump();
    await tester.tap(saveButton());
    await tester.pumpAndSettle();
    final saved = repo.beans[bean.id]!;
    expect(saved.name, 'New');
    expect(saved.roaster, isNull);
    expect(saved.notes, 'n');
    expect(saved.roastLevel, 2);
    expect(saved.doseGrams, 17.5);
  });

  testWidgets('edit save keeps a dose changed while the screen was open', (
    tester,
  ) async {
    final bean = Bean.create(name: 'Old').copyWith(doseGrams: 18.0);
    await repo.save(bean);
    await pump(tester, beanId: bean.id);
    await cubit.select(bean.id);
    await cubit.setDose(19.5);
    await tester.enterText(find.byKey(const Key('bean-name')), 'New');
    await tester.pump();
    await tester.tap(saveButton());
    await tester.pumpAndSettle();
    expect(repo.beans[bean.id]!.name, 'New');
    expect(repo.beans[bean.id]!.doseGrams, 19.5);
    expect(cubit.state.doseGrams, 19.5);
  });

  testWidgets('save after the bean was archived meanwhile does not re-add', (
    tester,
  ) async {
    final bean = Bean.create(name: 'Old');
    await repo.save(bean);
    await pump(tester, beanId: bean.id);
    await cubit.archiveBean(bean.id);
    await tester.enterText(find.byKey(const Key('bean-name')), 'New');
    await tester.pump();
    await tester.tap(saveButton());
    await tester.pumpAndSettle();
    expect(repo.beans[bean.id]!.archived, isTrue);
    expect(repo.beans[bean.id]!.name, 'Old');
    expect(cubit.state.beans, isEmpty);
    expect(find.byType(BeanEditScreen), findsNothing);
  });

  testWidgets('double tap on Save in add mode creates one bean', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(find.byKey(const Key('bean-name')), 'Guji');
    await tester.pump();
    final onPressed = tester.widget<TextButton>(saveButton()).onPressed!;
    onPressed();
    onPressed();
    await tester.pumpAndSettle();
    expect(repo.beans.length, 1);
    expect(cubit.state.beans.length, 1);
  });

  testWidgets('archive confirm archives, cancel does not', (tester) async {
    final bean = Bean.create(name: 'Old');
    await repo.save(bean);
    await pump(tester, beanId: bean.id);
    await tester.ensureVisible(find.text('Archive bean'));
    await tester.tap(find.text('Archive bean'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repo.beans[bean.id]!.archived, isFalse);
    expect(find.byType(BeanEditScreen), findsOneWidget);

    await tester.tap(find.text('Archive bean'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();
    expect(repo.beans[bean.id]!.archived, isTrue);
    expect(find.byType(BeanEditScreen), findsNothing);
  });

  testWidgets('unknown id shows Bean not found', (tester) async {
    await pump(tester, beanId: 'nope');
    expect(find.text('Bean not found'), findsOneWidget);
  });
}
