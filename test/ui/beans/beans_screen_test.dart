import 'package:espresso_log/domain/bean/bean.dart';
import 'package:espresso_log/ui/beans/beans_cubit.dart';
import 'package:espresso_log/ui/beans/beans_screen.dart';
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

  Future<void> pump(WidgetTester tester) async {
    await cubit.load();
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: cubit, child: const BeansScreen()),
      ),
    );
  }

  testWidgets('shows empty state', (tester) async {
    await pump(tester);
    expect(find.text('No beans yet'), findsOneWidget);
    expect(find.text('Add bean'), findsOneWidget);
  });

  testWidgets('lists beans with subtitle, hides archived', (tester) async {
    await repo.save(Bean.create(name: 'Guji', roaster: 'Tim', roastLevel: 1));
    await repo.save(Bean.create(name: 'Plain', roastLevel: 5));
    await repo.save(Bean.create(name: 'Gone').copyWith(archived: true));
    await pump(tester);
    expect(find.text('Guji'), findsOneWidget);
    expect(find.text('Tim · Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('Gone'), findsNothing);
    expect(find.text('No beans yet'), findsNothing);
  });
}
