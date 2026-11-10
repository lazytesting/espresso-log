import 'dart:io';

import 'package:espresso_log/data/shot/file_shot_repository.dart';
import 'package:espresso_log/domain/shot/recorded_shot.dart';
import 'package:espresso_log/domain/shot/shot_graph_point.dart';
import 'package:espresso_log/domain/shot/shot_metrics.dart';
import 'package:espresso_log/domain/shot/shot_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

ShotSnapshot _snapshot() => ShotSnapshot(
  weightData: [ShotGraphPoint(0, 0), ShotGraphPoint(1000, 12.5)],
  pressureData: [ShotGraphPoint(0, 1.5), ShotGraphPoint(1000, 9.1)],
  metrics: const ShotMetrics(weight: 12.5, pressure: 9.1, elapsedMillis: 1000),
  summary: const ShotSummary(
    finalWeight: 12.5,
    peakPressure: 9.1,
    durationMillis: 1000,
  ),
);

void main() {
  late Directory dir;
  late FileShotRepository repository;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('shots');
    repository = FileShotRepository(Directory('${dir.path}/shots'));
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('json round trip keeps the snapshot', () {
    final shot = RecordedShot.create(_snapshot());
    final copy = RecordedShot.fromJson(shot.toJson());

    expect(copy.id, shot.id);
    expect(copy.recordedAt, shot.recordedAt);
    expect(copy.snapshot.weightData.last.value, 12.5);
    expect(copy.snapshot.pressureData.last.millisecond, 1000);
    expect(copy.snapshot.summary, shot.snapshot.summary);
    expect(copy.snapshot.metrics, shot.snapshot.metrics);
  });

  test('list is empty before any save', () async {
    expect(await repository.list(), isEmpty);
  });

  test('saved shots are listed newest first and can be fetched', () async {
    final older = RecordedShot.create(_snapshot(), now: DateTime(2026, 1, 1));
    final newer = RecordedShot.create(_snapshot(), now: DateTime(2026, 2, 1));
    await repository.save(older);
    await repository.save(newer);

    expect((await repository.list()).map((s) => s.id), [newer.id, older.id]);
    expect((await repository.get(older.id))?.recordedAt, older.recordedAt);
    expect(await repository.get('missing'), isNull);
  });

  test('corrupt files are skipped', () async {
    await repository.save(RecordedShot.create(_snapshot()));
    File('${dir.path}/shots/bad.json').writeAsStringSync('not json');

    expect(await repository.list(), hasLength(1));
  });
}
