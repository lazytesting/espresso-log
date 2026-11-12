import 'package:espresso_log/domain/bean/bean.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('create trims and applies defaults', () {
    final bean = Bean.create(name: '  Guji ', roaster: '   ');
    expect(bean.name, 'Guji');
    expect(bean.roaster, isNull);
    expect(bean.roastLevel, 3);
    expect(bean.doseGrams, 18.0);
    expect(bean.archived, false);
    expect(bean.id, isNotEmpty);
  });

  test('now fixes the id', () {
    final now = DateTime(2026, 11, 12, 8, 30);
    expect(
      Bean.create(name: 'A', now: now).id,
      now.microsecondsSinceEpoch.toString(),
    );
  });

  test('json round trip', () {
    const bean = Bean(
      id: '1',
      name: 'Guji',
      roaster: 'Roastery',
      roastLevel: 2,
      notes: 'fruity',
      archived: true,
      doseGrams: 17.5,
    );
    expect(Bean.fromJson(bean.toJson()), bean);
  });

  test('fromJson clamps roast level and defaults archived', () {
    final bean = Bean.fromJson({
      'id': '1',
      'name': 'A',
      'roastLevel': 9,
      'doseGrams': 18.0,
    });
    expect(bean.roastLevel, 5);
    expect(bean.archived, false);
  });

  test('copyWith can clear roaster', () {
    final bean = Bean.create(name: 'A', roaster: 'R');
    expect(bean.copyWith(roaster: () => null).roaster, isNull);
  });

  test('roastLabel', () {
    expect(Bean.roastLabel(1), 'Light');
    expect(Bean.roastLabel(2), 'Medium-light');
    expect(Bean.roastLabel(3), 'Medium');
    expect(Bean.roastLabel(4), 'Medium-dark');
    expect(Bean.roastLabel(5), 'Dark');
  });
}
