import 'package:espresso_log/domain/bean/bean.dart';
import 'package:espresso_log/ui/beans/beans_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_settings.dart';
import '../../support/in_memory_bean_repository.dart';

void main() {
  late InMemoryBeanRepository repo;
  late FakeSettings settings;
  late BeansCubit cubit;

  Bean bean(
    String id,
    String name, {
    double dose = 18.0,
    bool archived = false,
  }) => Bean(
    id: id,
    name: name,
    roastLevel: 3,
    archived: archived,
    doseGrams: dose,
  );

  setUp(() {
    repo = InMemoryBeanRepository();
    settings = FakeSettings();
    cubit = BeansCubit(repo, settings);
  });

  tearDown(() => cubit.close());

  test('initial state is not loaded', () {
    expect(cubit.state.loaded, false);
  });

  test('load with no beans', () async {
    await cubit.load();
    expect(cubit.state.loaded, true);
    expect(cubit.state.selectedBeanId, isNull);
    expect(cubit.state.doseGrams, 18.0);
    expect(cubit.state.selectedBean, isNull);
  });

  test('load restores stored selection, dose; hides archived', () async {
    repo.beans['a'] = bean('a', 'A', dose: 17.0);
    repo.beans['z'] = bean('z', 'Z', archived: true);
    settings.selectedBeanId = 'a';
    await cubit.load();
    expect(cubit.state.selectedBeanId, 'a');
    expect(cubit.state.doseGrams, 17.0);
    expect(cubit.state.selectedBean?.id, 'a');
    expect(cubit.state.beans.map((b) => b.id), ['a']);
  });

  test(
    'load with missing or archived selection falls back to unknown',
    () async {
      settings.unknownBeanDoseGrams = 16.5;
      settings.selectedBeanId = 'missing';
      await cubit.load();
      expect(cubit.state.selectedBeanId, isNull);
      expect(cubit.state.doseGrams, 16.5);

      repo.beans['z'] = bean('z', 'Z', dose: 20.0, archived: true);
      settings.selectedBeanId = 'z';
      final c2 = BeansCubit(repo, settings);
      await c2.load();
      expect(c2.state.selectedBeanId, isNull);
      expect(c2.state.doseGrams, 16.5);
      await c2.close();
    },
  );

  test('per-bean dose recall', () async {
    repo.beans['a'] = bean('a', 'A');
    repo.beans['b'] = bean('b', 'B');
    await cubit.load();
    await cubit.select('a');
    await cubit.setDose(17.5);
    await cubit.select('b');
    expect(cubit.state.doseGrams, 18.0);
    await cubit.setDose(19.0);
    await cubit.select('a');
    expect(cubit.state.doseGrams, 17.5);
    expect(repo.beans['a']!.doseGrams, 17.5);
    expect(cubit.state.beans.firstWhere((b) => b.id == 'a').doseGrams, 17.5);
  });

  test('unknown bean has own dose', () async {
    repo.beans['a'] = bean('a', 'A');
    await cubit.load();
    await cubit.select(null);
    await cubit.setDose(16.0);
    expect(settings.unknownBeanDoseGrams, 16.0);
    await cubit.select('a');
    expect(cubit.state.doseGrams, 18.0);
    await cubit.select(null);
    expect(cubit.state.doseGrams, 16.0);
  });

  test('setDose clamps', () async {
    await cubit.load();
    await cubit.setDose(100);
    expect(cubit.state.doseGrams, 30.0);
    expect(settings.unknownBeanDoseGrams, 30.0);
    await cubit.setDose(1);
    expect(cubit.state.doseGrams, 5.0);
  });

  test('select persists and ignores unknown ids', () async {
    repo.beans['a'] = bean('a', 'A');
    await cubit.load();
    await cubit.select('a');
    expect(settings.selectedBeanId, 'a');
    await cubit.select('nonexistent');
    expect(cubit.state.selectedBeanId, isNull);
    expect(settings.selectedBeanId, isNull);
  });

  test('addBean', () async {
    await cubit.load();
    final added = await cubit.addBean(name: ' Guji ', roastLevel: 2);
    expect(added.name, 'Guji');
    expect(cubit.state.beans.map((b) => b.id), contains(added.id));
    expect(repo.beans[added.id], added);
    expect(cubit.state.selectedBeanId, isNull);
  });

  test('updateBean', () async {
    repo.beans['a'] = bean('a', 'A');
    await cubit.load();
    await cubit.updateBean(repo.beans['a']!.copyWith(name: 'New'));
    expect(cubit.state.beans.single.name, 'New');
    expect(repo.beans['a']!.name, 'New');
  });

  test('updateBean re-sorts the list after a rename', () async {
    repo.beans['a'] = bean('a', 'Alpha');
    repo.beans['b'] = bean('b', 'Bravo');
    await cubit.load();
    await cubit.updateBean(repo.beans['a']!.copyWith(name: 'Zulu'));
    expect(cubit.state.beans.map((b) => b.name), ['Bravo', 'Zulu']);
  });

  test('updateBean of selected bean makes dose follow', () async {
    repo.beans['a'] = bean('a', 'A');
    settings.selectedBeanId = 'a';
    await cubit.load();
    await cubit.updateBean(repo.beans['a']!.copyWith(doseGrams: 19.5));
    expect(cubit.state.doseGrams, 19.5);
  });

  test('archive non-selected bean', () async {
    repo.beans['a'] = bean('a', 'A');
    repo.beans['b'] = bean('b', 'B');
    settings.selectedBeanId = 'a';
    await cubit.load();
    await cubit.archiveBean('b');
    expect(cubit.state.beans.map((b) => b.id), ['a']);
    expect((await repo.get('b'))!.archived, true);
    expect(cubit.state.selectedBeanId, 'a');
  });

  test('archive selected bean', () async {
    repo.beans['a'] = bean('a', 'A', dose: 17.0);
    settings.selectedBeanId = 'a';
    settings.unknownBeanDoseGrams = 16.0;
    await cubit.load();
    await cubit.archiveBean('a');
    expect(cubit.state.selectedBeanId, isNull);
    expect(settings.selectedBeanId, isNull);
    expect(cubit.state.doseGrams, 16.0);
    expect(cubit.state.beans, isEmpty);
  });
}
