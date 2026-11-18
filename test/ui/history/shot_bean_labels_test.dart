import 'package:espresso_log/domain/bean/bean.dart';
import 'package:espresso_log/ui/history/shot_bean_labels.dart';
import 'package:flutter_test/flutter_test.dart';

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
    expect(beanNameFor(null), 'Unknown bean');
    expect(beanNameFor(_guji), 'Guji');
  });
}
