import 'package:espresso_log/domain/bean/bean.dart';
import 'package:espresso_log/domain/shot/recorded_shot.dart';
import 'package:espresso_log/domain/shot/shot_graph_point.dart';
import 'package:espresso_log/domain/shot/shot_metrics.dart';
import 'package:espresso_log/domain/shot/shot_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

ShotSnapshot _snapshot() => ShotSnapshot(
  weightData: [ShotGraphPoint(0, 0), ShotGraphPoint(1000, 36.0)],
  pressureData: [ShotGraphPoint(0, 1.5), ShotGraphPoint(1000, 9.1)],
  metrics: const ShotMetrics(weight: 36.0, pressure: 9.1, elapsedMillis: 1000),
  summary: const ShotSummary(
    finalWeight: 36.0,
    peakPressure: 9.1,
    durationMillis: 1000,
  ),
);

void main() {
  test('format version is 2', () {
    expect(RecordedShot.formatVersion, 2);
  });

  test('round trip keeps bean and dose', () {
    final shot = RecordedShot.create(
      _snapshot(),
      beanId: 'b1',
      doseGrams: 18.0,
    );
    final copy = RecordedShot.fromJson(shot.toJson());

    expect(copy.beanId, 'b1');
    expect(copy.doseGrams, 18.0);
    expect(copy.ratio, 2.0);
  });

  test('round trip without bean and dose gives nulls', () {
    final copy = RecordedShot.fromJson(
      RecordedShot.create(_snapshot()).toJson(),
    );

    expect(copy.beanId, isNull);
    expect(copy.doseGrams, isNull);
    expect(copy.ratio, isNull);
  });

  test('version 1 files load with nulls', () {
    final json = RecordedShot.create(
      _snapshot(),
      beanId: 'b1',
      doseGrams: 18.0,
    ).toJson()
      ..['version'] = 1
      ..remove('beanId')
      ..remove('doseGrams');
    final copy = RecordedShot.fromJson(json);

    expect(copy.beanId, isNull);
    expect(copy.doseGrams, isNull);
  });

  test('export json embeds the bean, stored json does not', () {
    final bean = Bean.create(name: 'Ethiopia');
    final shot = RecordedShot.create(_snapshot(), beanId: bean.id);

    expect(shot.toExportJson(bean: bean)['bean'], bean.toJson());
    expect(shot.toExportJson()['bean'], isNull);
    expect(shot.toJson().containsKey('bean'), isFalse);
  });
}
