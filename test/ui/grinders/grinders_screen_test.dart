import 'package:espresso_log/domain/grinder/grind_setting.dart';
import 'package:espresso_log/domain/grinder/grinder.dart';
import 'package:espresso_log/ui/beans/beans_cubit.dart';
import 'package:espresso_log/ui/grinders/grinders_cubit.dart';
import 'package:espresso_log/ui/grinders/grinders_screen.dart';
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

  Future<void> pump(WidgetTester tester) async {
    await beans.load();
    await cubit.load();
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: cubit, child: const GrindersScreen()),
      ),
    );
  }

  testWidgets('shows empty state', (tester) async {
    await pump(tester);
    expect(find.text('No grinders yet'), findsOneWidget);
    expect(find.byTooltip('Add grinder'), findsOneWidget);
  });

  testWidgets('lists grinders with brand, hides archived', (tester) async {
    await repo.save(
      Grinder.create(
        name: 'Zero',
        brand: 'Eureka',
        settingType: GrindSettingType.numeric,
      ),
    );
    await repo.save(
      Grinder.create(
        name: 'Gone',
        brand: 'X',
        settingType: GrindSettingType.numeric,
      ).copyWith(archived: true),
    );
    await pump(tester);
    expect(find.text('Zero'), findsOneWidget);
    expect(find.text('Eureka'), findsOneWidget);
    expect(find.text('Gone'), findsNothing);
    expect(find.text('No grinders yet'), findsNothing);
  });
}
