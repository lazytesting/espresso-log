import 'package:espresso_log/domain/bean/bean.dart';
import 'package:espresso_log/domain/grinder/grind_setting.dart';
import 'package:espresso_log/domain/grinder/grinder.dart';
import 'package:espresso_log/ui/beans/beans_cubit.dart';
import 'package:espresso_log/ui/grinders/grinders_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_settings.dart';
import '../../support/in_memory_bean_repository.dart';
import '../../support/in_memory_grind_memory_repository.dart';
import '../../support/in_memory_grinder_repository.dart';

void main() {
  late InMemoryBeanRepository beanRepo;
  late InMemoryGrinderRepository grinderRepo;
  late InMemoryGrindMemoryRepository memory;
  late FakeSettings settings;
  late BeansCubit beans;
  late GrindersCubit cubit;

  Bean bean(String id, {bool archived = false}) => Bean(
    id: id,
    name: id,
    roastLevel: 3,
    archived: archived,
    doseGrams: 18.0,
  );

  Grinder grinder(
    String id, {
    GrindSettingType type = GrindSettingType.numeric,
    bool archived = false,
  }) => Grinder(
    id: id,
    name: id,
    brand: 'B',
    settingType: type,
    archived: archived,
  );

  Future<void> remember(
    String grinderId,
    String? beanId,
    GrindSetting setting,
    int minute,
  ) => memory.remember(
    grinderId: grinderId,
    beanId: beanId,
    setting: setting,
    now: DateTime(2026, 1, 1, 0, minute),
  );

  Future<void> loadAll() async {
    await beans.load();
    await cubit.load();
  }

  setUp(() {
    beanRepo = InMemoryBeanRepository();
    grinderRepo = InMemoryGrinderRepository();
    memory = InMemoryGrindMemoryRepository(grinderRepo);
    settings = FakeSettings();
    beans = BeansCubit(beanRepo, settings);
    cubit = GrindersCubit(grinderRepo, memory, settings, beans);
    beanRepo.beans['a'] = bean('a');
    beanRepo.beans['b'] = bean('b');
    beanRepo.beans['x'] = bean('x');
    grinderRepo.grinders['g'] = grinder('g');
  });

  tearDown(() async {
    await cubit.close();
    await beans.close();
  });

  test('load restores selected grinder', () async {
    await remember('g', null, const GrindSetting.numeric(7), 1);
    settings.selectedGrinderId = 'g';
    await loadAll();
    expect(cubit.state.loaded, true);
    expect(cubit.state.selectedGrinderId, 'g');
    expect(cubit.state.selectedGrinder?.id, 'g');
    expect(cubit.state.setting, const GrindSetting.numeric(7));
  });

  test('load ignores archived selected grinder', () async {
    grinderRepo.grinders['g'] = grinder('g', archived: true);
    settings.selectedGrinderId = 'g';
    await loadAll();
    expect(cubit.state.selectedGrinderId, isNull);
    expect(cubit.state.setting, isNull);
    expect(cubit.state.grinders, isEmpty);
  });

  test('select picks last used bean and its remembered grind size', () async {
    await loadAll();
    await remember('g', 'a', const GrindSetting.numeric(3), 1);
    await remember('g', 'b', const GrindSetting.numeric(8), 2);
    await cubit.select('g');
    await pumpEventQueue();
    expect(beans.state.selectedBeanId, 'b');
    expect(cubit.state.selectedGrinderId, 'g');
    expect(cubit.state.setting, const GrindSetting.numeric(8));
    expect(settings.selectedGrinderId, 'g');
  });

  test('select with newest row unknown bean selects unknown bean', () async {
    await loadAll();
    await beans.select('a');
    await remember('g', 'a', const GrindSetting.numeric(3), 1);
    await remember('g', null, const GrindSetting.numeric(6), 2);
    await cubit.select('g');
    await pumpEventQueue();
    expect(beans.state.selectedBeanId, isNull);
    expect(cubit.state.setting, const GrindSetting.numeric(6));
  });

  test('select skips archived bean for next newest row', () async {
    beanRepo.beans['x'] = bean('x', archived: true);
    await loadAll();
    await remember('g', 'a', const GrindSetting.numeric(3), 1);
    await remember('g', 'x', const GrindSetting.numeric(9), 2);
    await cubit.select('g');
    await pumpEventQueue();
    expect(beans.state.selectedBeanId, 'a');
    expect(cubit.state.setting, const GrindSetting.numeric(3));
  });

  test('select with no history keeps bean and uses default setting', () async {
    await loadAll();
    await beans.select('a');
    await cubit.select('g');
    await pumpEventQueue();
    expect(beans.state.selectedBeanId, 'a');
    expect(cubit.state.setting, const GrindSetting.numeric(5));
  });

  test('bean change loads that pair\'s size', () async {
    await loadAll();
    await remember('g', 'a', const GrindSetting.numeric(3), 1);
    await remember('g', 'b', const GrindSetting.numeric(8), 2);
    await cubit.select('g');
    await beans.select('a');
    await pumpEventQueue();
    expect(cubit.state.setting, const GrindSetting.numeric(3));
  });

  test('bean change creates default row for new pair', () async {
    grinderRepo.grinders['g'] = grinder('g', type: GrindSettingType.coarseFine);
    await loadAll();
    await cubit.select('g');
    await beans.select('b');
    await pumpEventQueue();
    expect(cubit.state.setting, const GrindSetting.coarseFine(5, 'A'));
    expect(
      await memory.settingFor(grinderId: 'g', beanId: 'b'),
      const GrindSetting.coarseFine(5, 'A'),
    );
    expect(memory.entries[('g', 'b')]?.lastUsedAt, isNotNull);
  });

  test('setSetting with unknown bean stores one row per grinder', () async {
    grinderRepo.grinders['h'] = grinder('h');
    await loadAll();
    await cubit.select('g');
    await cubit.setSetting(const GrindSetting.numeric(2));
    await cubit.setSetting(const GrindSetting.numeric(4));
    expect(cubit.state.setting, const GrindSetting.numeric(4));
    expect(memory.entries.keys.where((k) => k.$1 == 'g'), [('g', '')]);
    expect(
      await memory.settingFor(grinderId: 'g'),
      const GrindSetting.numeric(4),
    );
  });

  test(
    'no grinder selected leaves setting null and setSetting does nothing',
    () async {
      await loadAll();
      await beans.select('a');
      await pumpEventQueue();
      expect(cubit.state.setting, isNull);
      await cubit.setSetting(const GrindSetting.numeric(2));
      expect(cubit.state.setting, isNull);
      expect(memory.entries, isEmpty);
    },
  );

  test('archive selected grinder clears selection', () async {
    await loadAll();
    await cubit.select('g');
    await cubit.archiveGrinder('g');
    expect(cubit.state.selectedGrinderId, isNull);
    expect(cubit.state.setting, isNull);
    expect(cubit.state.grinders, isEmpty);
    expect(settings.selectedGrinderId, isNull);
    expect(grinderRepo.grinders['g']!.archived, true);
  });

  test('addGrinder appears sorted', () async {
    await loadAll();
    await cubit.select('g');
    final added = await cubit.addGrinder(
      name: 'A first',
      brand: 'X',
      settingType: GrindSettingType.numeric,
    );
    expect(cubit.state.grinders.map((g) => g.name), ['A first', 'g']);
    expect(grinderRepo.grinders[added.id], added);
    expect(cubit.state.selectedGrinderId, 'g');
  });

  test('select second grinder does not write rows for the first', () async {
    grinderRepo.grinders['h'] = grinder('h');
    await loadAll();
    await beans.select('a');
    await remember('g', 'a', const GrindSetting.numeric(3), 1);
    await remember('h', 'b', const GrindSetting.numeric(8), 2);
    await cubit.select('g');
    await pumpEventQueue();
    final before = (await memory.entriesFor('g')).length;
    final emitted = <GrindersState>[];
    final sub = cubit.stream.listen(emitted.add);
    await cubit.select('h');
    await pumpEventQueue();
    await sub.cancel();
    expect(beans.state.selectedBeanId, 'b');
    expect((await memory.entriesFor('g')).length, before);
    expect(memory.entries.containsKey(('g', 'b')), false);
    expect(cubit.state.selectedGrinderId, 'h');
    expect(cubit.state.setting, const GrindSetting.numeric(8));
    expect(
      emitted.where(
        (s) => s.selectedGrinderId == 'g' && s.setting == emitted.last.setting,
      ),
      isEmpty,
    );
    expect(emitted.every((s) => s.selectedGrinderId == 'h'), true);
  });

  test('rapid bean changes end with the last bean\'s setting', () async {
    await loadAll();
    await remember('g', 'a', const GrindSetting.numeric(3), 1);
    await remember('g', 'b', const GrindSetting.numeric(8), 2);
    await cubit.select('g');
    await pumpEventQueue();
    final f1 = beans.select('a');
    final f2 = beans.select('b');
    await Future.wait([f1, f2]);
    await pumpEventQueue();
    expect(beans.state.selectedBeanId, 'b');
    expect(cubit.state.setting, const GrindSetting.numeric(8));
  });
}
