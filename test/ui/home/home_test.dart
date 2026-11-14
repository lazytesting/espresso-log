import 'package:espresso_log/domain/bean/bean.dart';
import 'package:espresso_log/ui/beans/beans_cubit.dart';
import 'package:espresso_log/ui/components/current-weight/current_weight_widget.dart';
import 'package:espresso_log/ui/components/pressure/pressure_widget.dart';
import 'package:espresso_log/ui/components/weight-change/weight_change_widget.dart';
import 'package:espresso_log/ui/home/home.dart';
import 'package:espresso_log/ui/home/setup_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_settings.dart';
import '../../support/in_memory_bean_repository.dart';

void main() {
  late BeansCubit cubit;

  setUp(() async {
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
    cubit = BeansCubit(beans, FakeSettings()..selectedBeanId = 'b1');
    await cubit.load();
  });

  tearDown(() => cubit.close());

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: BlocProvider.value(value: cubit, child: const HomeScreen()),
      ),
    ),
  );

  testWidgets('one card with bean and dose and a start button only', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Bean'), findsOneWidget);
    expect(find.text('Dose'), findsOneWidget);
    expect(find.text('START SHOT'), findsOneWidget);
    expect(find.byType(Card), findsOneWidget);
    expect(find.byType(CurrentWeightWidget), findsNothing);
    expect(find.byType(WeightChangeWidget), findsNothing);
    expect(find.byType(PressureWidget), findsNothing);
    expect(find.byType(AppBar), findsNothing);
  });

  testWidgets('bean and dose labels have the same size', (tester) async {
    await pump(tester);

    expect(find.byType(SetupLabel), findsNWidgets(2));
    expect(
      tester.getSize(find.text('Bean')).height,
      tester.getSize(find.text('Dose')).height,
    );
    expect(
      tester.getSize(find.widgetWithText(SetupLabel, 'Bean')),
      tester.getSize(find.widgetWithText(SetupLabel, 'Dose')),
    );
  });

  testWidgets('bean name and roaster are right-aligned by the dropdown', (
    tester,
  ) async {
    await pump(tester);

    final iconLeft = tester.getTopLeft(find.byIcon(Icons.arrow_drop_down)).dx;
    expect(tester.getTopRight(find.text('Guji')).dx, closeTo(iconLeft, 16));
    expect(
      tester.getTopRight(find.text('Friedhats · Light')).dx,
      closeTo(iconLeft, 16),
    );
  });
}
