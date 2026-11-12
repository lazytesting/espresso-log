import 'package:espresso_log/domain/bean/dose.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizeDose rounds and clamps', () {
    expect(normalizeDose(18.04), 18.0);
    expect(normalizeDose(31), 30.0);
    expect(normalizeDose(4), 5.0);
    expect(normalizeDose(18.0 + doseStepGrams), 18.1);
  });

  test('parseDose', () {
    expect(parseDose('18,5'), 18.5);
    expect(parseDose(' 17.25 '), closeTo(17.3, 0.051));
    expect(parseDose('abc'), isNull);
    expect(parseDose(''), isNull);
    expect(parseDose('NaN'), isNull);
    expect(parseDose('Infinity'), isNull);
    expect(parseDose('99'), 30.0);
  });
}
