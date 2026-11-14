import 'package:espresso_log/domain/shot/recorded_shot.dart';
import 'package:espresso_log/domain/shot/shot_repository.dart';
import 'package:espresso_log/domain/shot/shot_snapshot.dart';
import 'package:espresso_log/ui/beans/beans_cubit.dart';
import 'package:espresso_log/ui/shot/shot_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../support/fake_settings.dart';
import '../../support/in_memory_bean_repository.dart';

class _RecordingShotRepository implements ShotRepository {
  final List<RecordedShot> saved = [];

  @override
  Future<void> save(RecordedShot shot) async => saved.add(shot);

  @override
  Future<List<RecordedShot>> list() async => saved;

  @override
  Future<RecordedShot?> get(String id) async => null;
}

void main() {
  late _RecordingShotRepository shots;
  late BeansCubit cubit;

  setUp(() {
    shots = _RecordingShotRepository();
    cubit = BeansCubit(InMemoryBeanRepository(), FakeSettings());
  });

  tearDown(() => cubit.close());

  Future<void> pumpButton(
    WidgetTester tester, [
    ShotSnapshot snapshot = ShotSnapshot.empty,
  ]) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ShotRepository>.value(value: shots),
          BlocProvider<BeansCubit>.value(value: cubit),
        ],
        child: MaterialApp(home: Scaffold(body: SaveShotButton(snapshot))),
      ),
    );
  }

  testWidgets('saves selected bean and dose', (tester) async {
    await cubit.load();
    final guji = await cubit.addBean(name: 'Guji', roastLevel: 3);
    await cubit.select(guji.id);
    await cubit.setDose(17.5);
    await pumpButton(tester);

    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(shots.saved, hasLength(1));
    expect(shots.saved.single.beanId, guji.id);
    expect(shots.saved.single.doseGrams, 17.5);
    expect(find.text('Shot saved'), findsOneWidget);
  });

  testWidgets('saves null bean for Unknown bean with its dose', (tester) async {
    await cubit.load();
    await cubit.select(null);
    await cubit.setDose(16.0);
    await pumpButton(tester);

    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(shots.saved.single.beanId, isNull);
    expect(shots.saved.single.doseGrams, 16.0);
  });

  testWidgets('shows a check and disables after saving', (tester) async {
    await cubit.load();
    await pumpButton(tester);

    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.text('Save'), findsNothing);
    await tester.tap(find.byIcon(Icons.check));
    await tester.pump();
    expect(shots.saved, hasLength(1));
  });

  testWidgets('resets to Save for a new shot after restart', (tester) async {
    await cubit.load();
    await pumpButton(tester);
    await tester.tap(find.text('Save'));
    await tester.pump();

    await pumpButton(
      tester,
      // A different (non-identical) snapshot, as after a restart.
      ShotSnapshot(weightData: List.empty(), pressureData: List.empty()),
    );

    expect(find.text('Save'), findsOneWidget);
  });
}
