import 'package:espresso_log/data/db/app_database.dart' show AppDatabase;
import 'package:espresso_log/data/grinder/drift_grinder_repository.dart';
import 'package:espresso_log/data/shot/drift_shot_repository.dart';
import 'package:espresso_log/domain/grinder/grind_setting.dart';
import 'package:espresso_log/domain/grinder/grinder.dart';
import 'package:espresso_log/domain/shot/recorded_shot.dart';
import 'package:espresso_log/domain/shot/shot_graph_point.dart';
import 'package:espresso_log/domain/shot/shot_metrics.dart';
import 'package:espresso_log/domain/shot/shot_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

ShotSnapshot _snapshot({double finalWeight = 12.5, int duration = 1000}) =>
    ShotSnapshot(
      weightData: [ShotGraphPoint(0, 0), ShotGraphPoint(1000, finalWeight)],
      pressureData: [ShotGraphPoint(0, 1.5), ShotGraphPoint(1000, 9.1)],
      metrics: ShotMetrics(
        weight: finalWeight,
        pressure: 9.1,
        elapsedMillis: duration,
      ),
      summary: ShotSummary(
        finalWeight: finalWeight,
        peakPressure: 9.1,
        durationMillis: duration,
      ),
    );

void main() {
  late AppDatabase db;
  late DriftShotRepository repository;

  setUp(() {
    db = AppDatabase.memory();
    repository = DriftShotRepository(db);
  });
  tearDown(() => db.close());

  test('list is empty before any save', () async {
    expect(await repository.list(), isEmpty);
  });

  test('save then get returns an equal snapshot', () async {
    final shot = RecordedShot.create(
      _snapshot(),
      doseGrams: 18,
      now: DateTime(2026, 1, 1, 8, 30, 15, 123, 456),
    );
    await repository.save(shot);

    final loaded = (await repository.get(shot.id))!;

    expect(loaded.id, shot.id);
    expect(loaded.recordedAt, shot.recordedAt);
    expect(loaded.doseGrams, 18);
    expect(loaded.beanId, isNull);
    expect(loaded.snapshot.weightData.last.value, 12.5);
    expect(loaded.snapshot.pressureData.last.millisecond, 1000);
    expect(loaded.snapshot.summary, shot.snapshot.summary);
    expect(loaded.snapshot.metrics, shot.snapshot.metrics);
  });

  test(
    'grinder id and grind setting round trip through get and list',
    () async {
      final grinder = Grinder.create(
        name: 'Zero',
        brand: 'Brand',
        settingType: GrindSettingType.coarseFine,
      );
      await DriftGrinderRepository(db).save(grinder);
      final shot = RecordedShot.create(
        _snapshot(),
        grinderId: grinder.id,
        grindSetting: '3C',
      );
      await repository.save(shot);

      final loaded = (await repository.get(shot.id))!;
      final item = (await repository.list()).single;

      expect(loaded.grinderId, grinder.id);
      expect(loaded.grindSetting, '3C');
      expect(item.grinderId, grinder.id);
      expect(item.grindSetting, '3C');
    },
  );

  test('get returns null for an unknown id', () async {
    expect(await repository.get('nope'), isNull);
  });

  test('list is newest first with summary columns', () async {
    final older = RecordedShot.create(
      _snapshot(finalWeight: 30, duration: 25000),
      now: DateTime(2026, 1, 1),
    );
    final newer = RecordedShot.create(
      _snapshot(finalWeight: 36, duration: 28000),
      now: DateTime(2026, 1, 2),
    );
    await repository.save(older);
    await repository.save(newer);

    final items = await repository.list();

    expect(items.map((s) => s.id), [newer.id, older.id]);
    expect(items[0].finalWeight, 36);
    expect(items[0].durationMillis, 28000);
    expect(items[1].finalWeight, 30);
    expect(items[1].durationMillis, 25000);
  });

  test('shots within the same second sort by microseconds', () async {
    final first = RecordedShot.create(
      _snapshot(),
      now: DateTime(2026, 1, 1, 8, 0, 0, 100, 1),
    );
    final second = RecordedShot.create(
      _snapshot(),
      now: DateTime(2026, 1, 1, 8, 0, 0, 100, 2),
    );
    await repository.save(second);
    await repository.save(first);

    expect((await repository.list()).map((s) => s.id), [second.id, first.id]);
    expect(
      (await repository.list()).first.recordedAt.microsecondsSinceEpoch,
      second.recordedAt.microsecondsSinceEpoch,
    );
  });

  test('delete removes the row and ignores unknown ids', () async {
    final shot = RecordedShot.create(_snapshot());
    await repository.save(shot);

    await repository.delete('unknown');
    expect(await repository.list(), hasLength(1));

    await repository.delete(shot.id);
    expect(await repository.list(), isEmpty);
    expect(await repository.get(shot.id), isNull);
  });
}
