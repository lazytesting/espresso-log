import 'package:espresso_log/domain/bean/bean.dart';
import 'package:espresso_log/domain/grinder/grind_setting.dart';
import 'package:espresso_log/domain/grinder/grinder.dart';
import 'package:espresso_log/ui/beans/beans_cubit.dart';
import 'package:espresso_log/ui/grinders/grinders_cubit.dart';
import 'package:espresso_log/ui/components/current-weight/current_weight_widget.dart';
import 'package:espresso_log/ui/components/pressure/pressure_widget.dart';
import 'package:espresso_log/ui/components/weight-change/weight_change_widget.dart';
import 'package:espresso_log/ui/home/bean_selector.dart';
import 'package:espresso_log/ui/home/home.dart';
import 'package:espresso_log/ui/home/setup_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_settings.dart';
import '../../support/in_memory_bean_repository.dart';
import '../../support/in_memory_grind_memory_repository.dart';
import '../../support/in_memory_grinder_repository.dart';

void main() {
  late BeansCubit cubit;
  late GrindersCubit grinders;

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
    final settings = FakeSettings()
      ..selectedBeanId = 'b1'
      ..selectedGrinderId = 'g1';
    cubit = BeansCubit(beans, settings);
    await cubit.load();
    final grinderRepo = InMemoryGrinderRepository();
    grinderRepo.grinders['g1'] = const Grinder(
      id: 'g1',
      name: 'Niche',
      brand: 'Niche Coffee',
      settingType: GrindSettingType.numeric,
      archived: false,
    );
    grinders = GrindersCubit(
      grinderRepo,
      InMemoryGrindMemoryRepository(grinderRepo),
      settings,
      cubit,
    );
    await grinders.load();
  });

  tearDown(() async {
    await grinders.close();
    await cubit.close();
  });

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: cubit),
            BlocProvider.value(value: grinders),
          ],
          child: const HomeScreen(),
        ),
      ),
    ),
  );

  testWidgets('one card with setup rows and a start button only', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Grinder'), findsOneWidget);
    expect(find.text('Grind size'), findsOneWidget);
    expect(find.text('Bean'), findsOneWidget);
    expect(find.text('Dose'), findsOneWidget);
    expect(find.text('Start shot'), findsOneWidget);
    expect(find.byType(Card), findsOneWidget);
    expect(find.byType(CurrentWeightWidget), findsNothing);
    expect(find.byType(WeightChangeWidget), findsNothing);
    expect(find.byType(PressureWidget), findsNothing);
    expect(find.byType(AppBar), findsNothing);
  });

  testWidgets('rows are ordered Grinder, Grind, Bean, Dose', (tester) async {
    await pump(tester);

    final ys = [
      for (final label in ['Grinder', 'Grind size', 'Bean', 'Dose'])
        tester.getTopLeft(find.text(label)).dy,
    ];
    expect(ys, [...ys]..sort());
    expect(ys.toSet().length, 4);
  });

  testWidgets('setup labels have the same size', (tester) async {
    await pump(tester);

    expect(find.byType(SetupLabel), findsNWidgets(4));
    expect(
      tester.getSize(find.widgetWithText(SetupLabel, 'Bean')),
      tester.getSize(find.widgetWithText(SetupLabel, 'Dose')),
    );
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

    final iconLeft = tester
        .getTopLeft(
          find.descendant(
            of: find.byType(BeanSelector),
            matching: find.byIcon(Icons.arrow_drop_down),
          ),
        )
        .dx;
    expect(tester.getTopRight(find.text('Guji')).dx, closeTo(iconLeft, 16));
    expect(
      tester.getTopRight(find.text('Friedhats · Light')).dx,
      closeTo(iconLeft, 16),
    );
  });
}
