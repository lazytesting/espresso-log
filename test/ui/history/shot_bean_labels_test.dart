import 'package:espresso_log/domain/bean/bean.dart';
import 'package:espresso_log/domain/shot/recorded_shot.dart';
import 'package:espresso_log/domain/shot/shot_snapshot.dart';
import 'package:espresso_log/ui/history/shot_bean_labels.dart';
import 'package:flutter_test/flutter_test.dart';

RecordedShot _shot({String? beanId, double? dose}) => RecordedShot(
  id: '1',
  recordedAt: DateTime(2026, 1, 1),
  snapshot: ShotSnapshot.empty,
  beanId: beanId,
  doseGrams: dose,
);

const _guji = Bean(
  id: 'b1',
  name: 'Guji',
  roastLevel: 2,
  archived: false,
  doseGrams: 18,
);

void main() {
  test('subtitle with resolved bean and dose', () {
    expect(
      historySubtitle(_shot(beanId: 'b1', dose: 18.0), _guji),
      'Guji · 18.0 g',
    );
  });

  test('subtitle with missing bean', () {
    expect(
      historySubtitle(_shot(beanId: 'b1', dose: 18.0), null),
      'Unknown bean · 18.0 g',
    );
  });

  test('subtitle without bean id but with dose', () {
    expect(historySubtitle(_shot(dose: 18.0), null), 'Unknown bean · 18.0 g');
  });

  test('subtitle omits dose when null', () {
    expect(historySubtitle(_shot(beanId: 'b1'), _guji), 'Guji');
  });

  test('old shot has no subtitle', () {
    expect(historySubtitle(_shot(), null), isNull);
  });

  test('formatDose', () {
    expect(formatDose(null), '--');
    expect(formatDose(18.04), '18.0 g');
  });

  test('beanNameFor', () {
    expect(beanNameFor(_shot(), null), 'Unknown bean');
    expect(beanNameFor(_shot(beanId: 'b1'), _guji), 'Guji');
  });
}
