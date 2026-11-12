import 'package:espresso_log/domain/bean/bean.dart';
import 'package:espresso_log/domain/shot/recorded_shot.dart';
import 'package:espresso_log/domain/shot/shot_snapshot.dart';
import 'package:espresso_log/ui/history/history_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/in_memory_bean_repository.dart';
import '../../support/in_memory_shot_repository.dart';

RecordedShot _shot(String id, {String? beanId, double? dose}) => RecordedShot(
  id: id,
  recordedAt: DateTime(2026, 1, int.parse(id)),
  snapshot: ShotSnapshot.empty,
  beanId: beanId,
  doseGrams: dose,
);

void main() {
  late InMemoryShotRepository shots;
  late InMemoryBeanRepository beans;
  late HistoryCubit cubit;

  const archived = Bean(
    id: 'old',
    name: 'Old Bean',
    roastLevel: 3,
    archived: true,
    doseGrams: 18,
  );

  setUp(() {
    shots = InMemoryShotRepository();
    beans = InMemoryBeanRepository()..beans['old'] = archived;
    cubit = HistoryCubit(shots, beans);
  });

  test('starts as null before loading', () {
    expect(cubit.state, isNull);
  });

  test('pairs shots with beans, archived included, null otherwise', () async {
    await shots.save(_shot('1', beanId: 'old', dose: 18));
    await shots.save(_shot('2', beanId: 'missing', dose: 18));
    await shots.save(_shot('3', dose: 18));
    await shots.save(_shot('4'));

    await cubit.load();

    final entries = cubit.state!;
    expect(entries.map((e) => e.shot.id), ['4', '3', '2', '1']);
    expect(entries[3].bean, archived);
    expect(entries[2].bean, isNull);
    expect(entries[1].bean, isNull);
    expect(entries[0].bean, isNull);
    expect(entries[0].shot.beanId, isNull);
    expect(entries[0].shot.doseGrams, isNull);
  });
}
