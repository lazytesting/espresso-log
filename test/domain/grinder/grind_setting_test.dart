import 'package:espresso_log/domain/grinder/grind_setting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parse numeric and coarseFine', () {
    expect(GrindSetting.parse(GrindSettingType.numeric, '5')!.text, '5');
    expect(GrindSetting.parse(GrindSettingType.coarseFine, '3C')!.text, '3C');
  });

  test('parse is case-insensitive', () {
    expect(
      GrindSetting.parse(GrindSettingType.coarseFine, '3c'),
      const GrindSetting.coarseFine(3, 'C'),
    );
  });

  test('parse trims whitespace', () {
    expect(
      GrindSetting.parse(GrindSettingType.coarseFine, ' 3c '),
      const GrindSetting.coarseFine(3, 'C'),
    );
  });

  test('parse accepts the whole micro range A-Z', () {
    expect(GrindSetting.parse(GrindSettingType.coarseFine, '3G')!.text, '3G');
    expect(GrindSetting.parse(GrindSettingType.coarseFine, '10Z')!.text, '10Z');
  });

  test('parse returns null for invalid text', () {
    expect(GrindSetting.parse(GrindSettingType.numeric, '11'), isNull);
    expect(GrindSetting.parse(GrindSettingType.numeric, '0'), isNull);
    expect(GrindSetting.parse(GrindSettingType.numeric, ''), isNull);
    expect(GrindSetting.parse(GrindSettingType.numeric, '3C'), isNull);
    expect(GrindSetting.parse(GrindSettingType.coarseFine, '3?'), isNull);
    expect(GrindSetting.parse(GrindSettingType.coarseFine, '3AA'), isNull);
    expect(GrindSetting.parse(GrindSettingType.coarseFine, ''), isNull);
    expect(GrindSetting.parse(GrindSettingType.coarseFine, '11A'), isNull);
  });

  test('stepped rolls fine over into the next coarse step', () {
    expect(
      const GrindSetting.coarseFine(3, 'Z').stepped(1),
      const GrindSetting.coarseFine(4, 'A'),
    );
    expect(
      const GrindSetting.coarseFine(4, 'A').stepped(-1),
      const GrindSetting.coarseFine(3, 'Z'),
    );
    expect(
      const GrindSetting.coarseFine(3, 'B').stepped(1),
      const GrindSetting.coarseFine(3, 'C'),
    );
  });

  test('stepped is clamped at the ends', () {
    expect(
      const GrindSetting.numeric(10).stepped(1),
      const GrindSetting.numeric(10),
    );
    expect(
      const GrindSetting.coarseFine(1, 'A').stepped(-1),
      const GrindSetting.coarseFine(1, 'A'),
    );
    expect(
      const GrindSetting.coarseFine(10, 'Z').stepped(1),
      const GrindSetting.coarseFine(10, 'Z'),
    );
  });

  test('defaultFor', () {
    expect(
      GrindSetting.defaultFor(GrindSettingType.numeric),
      const GrindSetting.numeric(5),
    );
    expect(
      GrindSetting.defaultFor(GrindSettingType.coarseFine),
      const GrindSetting.coarseFine(5, 'A'),
    );
  });
}
