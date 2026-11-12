import 'package:espresso_log/domain/shot/brew_ratio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ratio is output divided by dose', () {
    expect(brewRatio(outputGrams: 37.8, doseGrams: 18.0), closeTo(2.1, 0.001));
  });

  test('ratio is null for missing or non-positive values', () {
    expect(brewRatio(outputGrams: null, doseGrams: 18.0), isNull);
    expect(brewRatio(outputGrams: 36.0, doseGrams: null), isNull);
    expect(brewRatio(outputGrams: 36.0, doseGrams: 0), isNull);
    expect(brewRatio(outputGrams: 0, doseGrams: 18.0), isNull);
  });

  test('formatBrewRatio', () {
    expect(formatBrewRatio(2.1), '1 : 2.1');
    expect(formatBrewRatio(null), '--');
    expect(formatBrewRatio(1.96), '1 : 2.0');
  });
}
