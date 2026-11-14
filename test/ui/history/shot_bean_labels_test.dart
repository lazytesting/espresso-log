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
  test('formatDose', () {
    expect(formatDose(null), '--');
    expect(formatDose(18.04), '18.0 g');
  });

  test('beanNameFor', () {
    expect(beanNameFor(_shot(), null), 'Unknown bean');
    expect(beanNameFor(_shot(beanId: 'b1'), _guji), 'Guji');
  });
}
