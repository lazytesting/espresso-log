import 'package:espresso_log/ui/beans/beans_cubit.dart';
import 'package:espresso_log/ui/home/dose_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_settings.dart';
import '../../support/in_memory_bean_repository.dart';

void main() {
  late BeansCubit cubit;

  setUp(() {
    cubit = BeansCubit(InMemoryBeanRepository(), FakeSettings());
  });

  tearDown(() => cubit.close());

  Future<void> pump(WidgetTester tester) async {
    await cubit.load();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(value: cubit, child: const DoseSelector()),
        ),
      ),
    );
  }

  Future<void> enterDose(
    WidgetTester tester,
    String text,
    String button,
  ) async {
    await tester.tap(find.byKey(const Key('dose-text')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), text);
    await tester.tap(find.text(button));
    await tester.pumpAndSettle();
  }

  testWidgets('shows dose with one decimal', (tester) async {
    await pump(tester);
    expect(find.text('Dose'), findsOneWidget);
    expect(find.text('18.0 g'), findsOneWidget);
  });

  testWidgets('plus and minus step by 0.1', (tester) async {
    await pump(tester);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('18.1 g'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();
    expect(find.text('17.9 g'), findsOneWidget);
  });

  testWidgets('plus at maximum keeps 30.0 g', (tester) async {
    await pump(tester);
    await cubit.setDose(30.0);
    await tester.pump();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('30.0 g'), findsOneWidget);
  });

  testWidgets('dialog accepts decimal comma', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('dose-text')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '18.0',
    );
    await tester.enterText(find.byType(TextField), '18,5');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('18.5 g'), findsOneWidget);
  });

  testWidgets('invalid text leaves dose unchanged', (tester) async {
    await pump(tester);
    await enterDose(tester, 'abc', 'OK');
    expect(find.text('18.0 g'), findsOneWidget);
  });

  testWidgets('out of range is clamped', (tester) async {
    await pump(tester);
    await enterDose(tester, '99', 'OK');
    expect(find.text('30.0 g'), findsOneWidget);
  });

  testWidgets('cancel leaves dose unchanged', (tester) async {
    await pump(tester);
    await enterDose(tester, '20', 'Cancel');
    expect(find.text('18.0 g'), findsOneWidget);
  });
}
