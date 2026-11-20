import 'package:espresso_log/domain/grinder/grind_setting.dart';
import 'package:espresso_log/domain/grinder/grinder.dart';
import 'package:espresso_log/ui/beans/beans_cubit.dart';
import 'package:espresso_log/ui/grinders/grinders_cubit.dart';
import 'package:espresso_log/ui/home/grind_size_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_settings.dart';
import '../../support/in_memory_bean_repository.dart';
import '../../support/in_memory_grind_memory_repository.dart';
import '../../support/in_memory_grinder_repository.dart';

void main() {
  late InMemoryGrinderRepository repo;
  late InMemoryGrindMemoryRepository memory;
  late FakeSettings settings;
  late BeansCubit beans;
  late GrindersCubit cubit;

  setUp(() {
    repo = InMemoryGrinderRepository();
    memory = InMemoryGrindMemoryRepository(repo);
    settings = FakeSettings();
    beans = BeansCubit(InMemoryBeanRepository(), settings);
    cubit = GrindersCubit(repo, memory, settings, beans);
    repo.grinders['n'] = const Grinder(
      id: 'n',
      name: 'Num',
      brand: 'B',
      settingType: GrindSettingType.numeric,
      archived: false,
    );
    repo.grinders['c'] = const Grinder(
      id: 'c',
      name: 'CF',
      brand: 'B',
      settingType: GrindSettingType.coarseFine,
      archived: false,
    );
  });

  tearDown(() async {
    await cubit.close();
    await beans.close();
  });

  Future<void> pump(
    WidgetTester tester, {
    String? grinderId,
    GrindSetting? setting,
  }) async {
    if (grinderId != null) {
      settings.selectedGrinderId = grinderId;
      if (setting != null) {
        await memory.remember(
          grinderId: grinderId,
          beanId: null,
          setting: setting,
          now: DateTime(2026, 1, 1),
        );
      }
    }
    await beans.load();
    await cubit.load();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(
            value: cubit,
            child: const GrindSizeSelector(),
          ),
        ),
      ),
    );
  }

  testWidgets('hidden when no grinder is selected', (tester) async {
    await pump(tester);
    expect(find.text('Grind size'), findsNothing);
    expect(find.byKey(const Key('grind-text')), findsNothing);
  });

  testWidgets('plus on numeric 5 shows 6', (tester) async {
    await pump(tester, grinderId: 'n', setting: const GrindSetting.numeric(5));
    expect(find.text('Grind size'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('6'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pumpAndSettle();
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('plus on 3Z shows 4A', (tester) async {
    await pump(
      tester,
      grinderId: 'c',
      setting: const GrindSetting.coarseFine(3, 'Z'),
    );
    expect(find.text('3Z'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('4A'), findsOneWidget);
  });

  testWidgets('picker sets a numeric value directly', (tester) async {
    await pump(tester, grinderId: 'n', setting: const GrindSetting.numeric(5));
    await tester.tap(find.byKey(const Key('grind-text')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('grind-coarse')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('9').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('9'), findsOneWidget);
    expect(cubit.state.setting, const GrindSetting.numeric(9));
  });

  testWidgets('picker sets coarse and fine', (tester) async {
    await pump(
      tester,
      grinderId: 'c',
      setting: const GrindSetting.coarseFine(3, 'F'),
    );
    await tester.tap(find.byKey(const Key('grind-text')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('grind-coarse')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('7').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('grind-fine')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('C').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('7C'), findsOneWidget);
    expect(cubit.state.setting, const GrindSetting.coarseFine(7, 'C'));
  });

  testWidgets('cancel leaves the setting unchanged', (tester) async {
    await pump(tester, grinderId: 'n', setting: const GrindSetting.numeric(5));
    await tester.tap(find.byKey(const Key('grind-text')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('5'), findsOneWidget);
  });
}
