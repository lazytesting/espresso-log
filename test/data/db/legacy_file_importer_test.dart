import 'dart:convert';
import 'dart:io';

import 'package:espresso_log/data/bean/drift_bean_repository.dart';
import 'package:espresso_log/data/db/app_database.dart' show AppDatabase;
import 'package:espresso_log/data/db/legacy_file_importer.dart';
import 'package:espresso_log/data/grinder/drift_grinder_repository.dart';
import 'package:espresso_log/data/shot/drift_shot_repository.dart';
import 'package:espresso_log/domain/bean/bean.dart';
import 'package:espresso_log/domain/grinder/grind_setting.dart';
import 'package:espresso_log/domain/grinder/grinder.dart';
import 'package:espresso_log/domain/shot/recorded_shot.dart';
import 'package:espresso_log/domain/shot/shot_graph_point.dart';
import 'package:espresso_log/domain/shot/shot_metrics.dart';
import 'package:espresso_log/domain/shot/shot_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

ShotSnapshot _snapshot() => ShotSnapshot(
  weightData: [ShotGraphPoint(0, 0), ShotGraphPoint(1000, 36)],
  pressureData: [ShotGraphPoint(0, 1.5), ShotGraphPoint(1000, 9)],
  metrics: ShotMetrics(weight: 36, pressure: 9, elapsedMillis: 1000),
  summary: ShotSummary(finalWeight: 36, peakPressure: 9, durationMillis: 1000),
);

void main() {
  late AppDatabase db;
  late Directory documents;

  setUp(() async {
    db = AppDatabase.memory();
    documents = await Directory.systemTemp.createTemp('legacy_importer');
  });
  tearDown(() async {
    await db.close().catchError((_) {});
    await documents.delete(recursive: true);
  });

  Future<void> writeJson(String dir, String name, Object json) async {
    final d = Directory('${documents.path}/$dir');
    await d.create(recursive: true);
    await File('${d.path}/$name.json').writeAsString(jsonEncode(json));
  }

  Future<void> writeBean(Bean bean) =>
      writeJson('beans', bean.id, bean.toJson());
  Future<void> writeShot(RecordedShot shot) =>
      writeJson('shots', shot.id, shot.toJson());

  Directory dir(String name) => Directory('${documents.path}/$name');

  test('imports beans and shots (v1 and v2) and renames the folders', () async {
    final a = Bean.create(name: 'A', now: DateTime(2026, 1, 1));
    final b = Bean.create(name: 'B', now: DateTime(2026, 1, 2));
    await writeBean(a);
    await writeBean(b);
    await writeShot(
      RecordedShot.create(
        _snapshot(),
        beanId: a.id,
        doseGrams: 18,
        now: DateTime(2026, 2, 1),
      ),
    );
    final v1 = RecordedShot.create(_snapshot(), now: DateTime(2026, 2, 2));
    final v1Json = v1.toJson()
      ..['version'] = 1
      ..remove('beanId')
      ..remove('doseGrams');
    await writeJson('shots', v1.id, v1Json);

    await LegacyFileImporter(db, documents).run();

    expect((await DriftBeanRepository(db).list()).map((e) => e.name), [
      'A',
      'B',
    ]);
    final shots = await DriftShotRepository(db).list();
    expect(shots, hasLength(2));
    expect(shots.last.beanId, a.id);
    expect(shots.last.doseGrams, 18);
    expect(shots.first.beanId, isNull);
    expect(shots.first.doseGrams, isNull);
    expect(dir('beans').existsSync(), isFalse);
    expect(dir('shots').existsSync(), isFalse);
    expect(dir('beans.imported').existsSync(), isTrue);
    expect(dir('shots.imported').existsSync(), isTrue);
  });

  test('skips a corrupt file and imports the others', () async {
    final a = Bean.create(name: 'A', now: DateTime(2026, 1, 1));
    await writeBean(a);
    await File('${documents.path}/beans/broken.json').writeAsString('{nope');
    await writeShot(
      RecordedShot.create(_snapshot(), now: DateTime(2026, 2, 1)),
    );
    await File('${documents.path}/shots/bad.json').writeAsString('[]');

    await LegacyFileImporter(db, documents).run();

    expect(await DriftBeanRepository(db).list(), [a]);
    expect(await DriftShotRepository(db).list(), hasLength(1));
  });

  test('a shot whose bean was not imported gets a null beanId', () async {
    await writeShot(
      RecordedShot.create(
        _snapshot(),
        beanId: 'ghost',
        doseGrams: 18,
        now: DateTime(2026, 2, 1),
      ),
    );

    await LegacyFileImporter(db, documents).run();

    final shots = await DriftShotRepository(db).list();
    expect(shots.single.beanId, isNull);
    expect(shots.single.doseGrams, 18);
  });

  test('is a no-op when neither folder exists, and on a second run', () async {
    await LegacyFileImporter(db, documents).run();
    expect(await DriftBeanRepository(db).list(), isEmpty);

    await writeBean(Bean.create(name: 'A', now: DateTime(2026, 1, 1)));
    await LegacyFileImporter(db, documents).run();
    await LegacyFileImporter(db, documents).run();

    expect(await DriftBeanRepository(db).list(), hasLength(1));
    expect(dir('beans.imported').existsSync(), isTrue);
  });

  test('a failing transaction throws and renames nothing', () async {
    await writeBean(Bean.create(name: 'A', now: DateTime(2026, 1, 1)));
    await writeShot(
      RecordedShot.create(_snapshot(), now: DateTime(2026, 2, 1)),
    );
    // Breaks the shot insert after the beans were written.
    await db.customStatement('DROP TABLE shots');

    await expectLater(
      LegacyFileImporter(db, documents).run(),
      throwsA(anything),
    );

    expect(await DriftBeanRepository(db).list(), isEmpty);
    expect(dir('beans').existsSync(), isTrue);
    expect(dir('shots').existsSync(), isTrue);
    expect(dir('beans.imported').existsSync(), isFalse);
    expect(dir('shots.imported').existsSync(), isFalse);
  });

  test('skips the import when the database already has data', () async {
    await DriftBeanRepository(
      db,
    ).save(Bean.create(name: 'Existing', now: DateTime(2026, 1, 1)));
    final a = Bean.create(name: 'A', now: DateTime(2026, 1, 2));
    await writeBean(a);
    await writeShot(
      RecordedShot.create(_snapshot(), now: DateTime(2026, 2, 1)),
    );

    await LegacyFileImporter(db, documents).run();

    expect(await DriftBeanRepository(db).list(), hasLength(1));
    expect(await DriftShotRepository(db).list(), isEmpty);
    expect(dir('beans').existsSync(), isTrue);
    expect(dir('shots').existsSync(), isTrue);
    expect(dir('beans.imported').existsSync(), isFalse);
    expect(dir('shots.imported').existsSync(), isFalse);
  });

  test('skips the import when only shots exist in the database', () async {
    await DriftShotRepository(
      db,
    ).save(RecordedShot.create(_snapshot(), now: DateTime(2026, 2, 1)));
    await writeBean(Bean.create(name: 'A', now: DateTime(2026, 1, 2)));

    await LegacyFileImporter(db, documents).run();

    expect(await DriftBeanRepository(db).list(), isEmpty);
    expect(dir('beans').existsSync(), isTrue);
  });

  test('keeps grinder fields when dropping an unknown bean', () async {
    final shot = RecordedShot.create(
      _snapshot(),
      beanId: 'ghost',
      grinderId: 'g1',
      grindSetting: '3C',
      now: DateTime(2026, 2, 1),
    );
    await writeShot(shot);
    await DriftGrinderRepository(db).save(
      const Grinder(
        id: 'g1',
        name: 'Niche',
        brand: 'Niche',
        settingType: GrindSettingType.coarseFine,
        archived: false,
      ),
    );

    await LegacyFileImporter(db, documents).run();

    final shots = await DriftShotRepository(db).list();
    expect(shots.single.beanId, isNull);
    expect(shots.single.grinderId, 'g1');
    expect(shots.single.grindSetting, '3C');
  });
}
