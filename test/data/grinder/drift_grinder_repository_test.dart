import 'package:espresso_log/data/db/app_database.dart' show AppDatabase;
import 'package:espresso_log/data/grinder/drift_grinder_repository.dart';
import 'package:espresso_log/domain/grinder/grind_setting.dart';
import 'package:espresso_log/domain/grinder/grinder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftGrinderRepository repository;

  setUp(() {
    db = AppDatabase.memory();
    repository = DriftGrinderRepository(db);
  });
  tearDown(() => db.close());

  Grinder grinder(String name, int day, [GrindSettingType? t]) =>
      Grinder.create(
        name: name,
        brand: 'Brand',
        settingType: t ?? GrindSettingType.numeric,
        now: DateTime(2026, 1, day),
      );

  test('round trip incl. setting type', () async {
    final g = grinder('Zero', 1, GrindSettingType.coarseFine);
    await repository.save(g);
    expect(await repository.get(g.id), g);
    expect(await repository.get('nope'), isNull);
  });

  test('list includes archived, sorted case-insensitively', () async {
    await repository.save(grinder('beta', 1));
    await repository.save(grinder('Alpha', 2).copyWith(archived: true));
    await repository.save(grinder('Charlie', 3));
    final names = (await repository.list()).map((g) => g.name).toList();
    expect(names, ['Alpha', 'beta', 'Charlie']);
    expect((await repository.list()).first.archived, isTrue);
  });
}
