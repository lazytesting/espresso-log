import 'package:espresso_log/domain/grinder/grind_setting.dart';
import 'package:espresso_log/domain/grinder/grinder.dart';
import 'package:espresso_log/domain/shot/recorded_shot.dart';
import 'package:espresso_log/domain/shot/shot_list_item.dart';
import 'package:espresso_log/domain/shot/shot_repository.dart';
import 'package:espresso_log/domain/shot/shot_snapshot.dart';
import 'package:espresso_log/ui/beans/beans_cubit.dart';
import 'package:espresso_log/ui/grinders/grinders_cubit.dart';
import 'package:espresso_log/ui/shot/shot_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../support/fake_settings.dart';
import '../../support/in_memory_bean_repository.dart';
import '../../support/in_memory_grind_memory_repository.dart';
import '../../support/in_memory_grinder_repository.dart';

class _RecordingShotRepository implements ShotRepository {
  final List<RecordedShot> saved = [];

  @override
  Future<void> save(RecordedShot shot) async => saved.add(shot);

  @override
  Future<List<ShotListItem>> list() async =>
      saved.map(ShotListItem.fromShot).toList();

  @override
  Future<RecordedShot?> get(String id) async => null;

  @override
  Future<void> delete(String id) async {}
}

void main() {
  late _RecordingShotRepository shots;
  late BeansCubit cubit;
  late InMemoryGrinderRepository grinderRepo;
  late FakeSettings settings;
  late GrindersCubit grinders;

  setUp(() {
    shots = _RecordingShotRepository();
    settings = FakeSettings();
    cubit = BeansCubit(InMemoryBeanRepository(), settings);
    grinderRepo = InMemoryGrinderRepository();
    grinders = GrindersCubit(
      grinderRepo,
      InMemoryGrindMemoryRepository(grinderRepo),
      settings,
      cubit,
    );
  });

  tearDown(() async {
    await grinders.close();
    await cubit.close();
  });

  Future<void> pumpButton(
    WidgetTester tester, [
    ShotSnapshot snapshot = ShotSnapshot.empty,
  ]) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ShotRepository>.value(value: shots),
          BlocProvider<BeansCubit>.value(value: cubit),
          BlocProvider<GrindersCubit>.value(value: grinders),
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

  testWidgets('saves selected grinder and grind setting', (tester) async {
    grinderRepo.grinders['g1'] = const Grinder(
      id: 'g1',
      name: 'Niche',
      brand: 'Niche',
      settingType: GrindSettingType.coarseFine,
      archived: false,
    );
    await cubit.load();
    await grinders.load();
    await grinders.select('g1');
    await grinders.setSetting(const GrindSetting.coarseFine(3, 'C'));
    await pumpButton(tester);

    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(shots.saved.single.grinderId, 'g1');
    expect(shots.saved.single.grindSetting, '3C');
  });

  testWidgets('saves null grinder and setting when none selected', (
    tester,
  ) async {
    await cubit.load();
    await grinders.load();
    await pumpButton(tester);

    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(shots.saved.single.grinderId, isNull);
    expect(shots.saved.single.grindSetting, isNull);
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
