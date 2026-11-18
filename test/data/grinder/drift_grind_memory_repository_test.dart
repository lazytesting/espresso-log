import 'package:espresso_log/data/db/app_database.dart' show AppDatabase;
import 'package:espresso_log/data/grinder/drift_grind_memory_repository.dart';
import 'package:espresso_log/data/grinder/drift_grinder_repository.dart';
import 'package:espresso_log/domain/grinder/grind_setting.dart';
import 'package:espresso_log/domain/grinder/grinder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftGrindMemoryRepository memory;
  late Grinder numeric;
  late Grinder fine;

  setUp(() async {
    db = AppDatabase.memory();
    memory = DriftGrindMemoryRepository(db);
    final grinders = DriftGrinderRepository(db);
    numeric = Grinder.create(
      name: 'N',
      brand: 'B',
      settingType: GrindSettingType.numeric,
      now: DateTime(2026, 1, 1),
    );
    fine = Grinder.create(
      name: 'F',
      brand: 'B',
      settingType: GrindSettingType.coarseFine,
      now: DateTime(2026, 1, 2),
    );
    await grinders.save(numeric);
    await grinders.save(fine);
  });
  tearDown(() => db.close());

  test('unknown pair has no setting', () async {
    expect(await memory.settingFor(grinderId: numeric.id), isNull);
    expect(await memory.settingFor(grinderId: numeric.id, beanId: 'x'), isNull);
  });

  test(
    'remember twice for the unknown bean keeps one row, last wins',
    () async {
      await memory.remember(
        grinderId: numeric.id,
        setting: const GrindSetting.numeric(4),
        now: DateTime(2026, 1, 1, 10),
      );
      await memory.remember(
        grinderId: numeric.id,
        setting: const GrindSetting.numeric(6),
        now: DateTime(2026, 1, 1, 10),
      );
      final entries = await memory.entriesFor(numeric.id);
      expect(entries, hasLength(1));
      expect(entries.single.setting, const GrindSetting.numeric(6));
      expect(entries.single.beanId, isNull);
      expect(
        await memory.settingFor(grinderId: numeric.id),
        const GrindSetting.numeric(6),
      );
    },
  );

  test('entriesFor orders newest first with a microsecond gap', () async {
    final t = DateTime(2026, 1, 1, 10);
    await memory.remember(
      grinderId: numeric.id,
      beanId: 'a',
      setting: const GrindSetting.numeric(1),
      now: t,
    );
    await memory.remember(
      grinderId: numeric.id,
      beanId: 'b',
      setting: const GrindSetting.numeric(2),
      now: t.add(const Duration(microseconds: 5)),
    );
    final entries = await memory.entriesFor(numeric.id);
    expect(entries.map((e) => e.beanId), ['b', 'a']);
    expect(entries.first.lastUsedAt, t.add(const Duration(microseconds: 5)));
  });

  test('coarseFine round trips', () async {
    await memory.remember(
      grinderId: fine.id,
      beanId: 'a',
      setting: const GrindSetting.coarseFine(3, 'C'),
    );
    final s = await memory.settingFor(grinderId: fine.id, beanId: 'a');
    expect(s!.text, '3C');
    expect(s, const GrindSetting.coarseFine(3, 'C'));
  });
}
