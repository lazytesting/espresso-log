import 'package:espresso_log/domain/grinder/grind_setting.dart';
import 'package:espresso_log/domain/grinder/grinder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('create trims name and brand', () {
    final g = Grinder.create(
      name: '  Zero  ',
      brand: ' Niche ',
      settingType: GrindSettingType.numeric,
      now: DateTime(2026, 1, 1),
    );
    expect(g.name, 'Zero');
    expect(g.brand, 'Niche');
    expect(g.archived, isFalse);
    expect(g.id, DateTime(2026, 1, 1).microsecondsSinceEpoch.toString());
  });

  test('json round trip', () {
    final g = Grinder.create(
      name: 'Zero',
      brand: 'Niche',
      settingType: GrindSettingType.coarseFine,
      now: DateTime(2026, 1, 1),
    ).copyWith(archived: true);
    expect(Grinder.fromJson(g.toJson()), g);
  });
}
