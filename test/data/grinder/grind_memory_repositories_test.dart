import 'package:espresso_log/data/db/app_database.dart' show AppDatabase;
import 'package:espresso_log/data/grinder/drift_grind_memory_repository.dart';
import 'package:espresso_log/data/grinder/drift_grinder_repository.dart';
import 'package:espresso_log/domain/grinder/grind_memory_repository.dart';
import 'package:espresso_log/domain/grinder/grind_setting.dart';
import 'package:espresso_log/domain/grinder/grinder.dart';
import 'package:espresso_log/domain/grinder/grinder_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/in_memory_grind_memory_repository.dart';
import '../../support/in_memory_grinder_repository.dart';

/// Runs the same contract against the Drift and in-memory implementations.
void main() {
  final grinder = Grinder.create(
    name: 'N',
    brand: 'B',
    settingType: GrindSettingType.numeric,
    now: DateTime(2026, 1, 1),
  );

  void contract(
    String name,
    Future<(GrinderRepository, GrindMemoryRepository, Future<void> Function())>
    Function()
    create,
  ) {
    group(name, () {
      late GrinderRepository grinders;
      late GrindMemoryRepository memory;
      late Future<void> Function() dispose;

      setUp(() async {
        (grinders, memory, dispose) = await create();
        await grinders.save(grinder);
      });
      tearDown(() => dispose());

      test('unknown grinder yields null and empty', () async {
        await memory.remember(
          grinderId: grinder.id,
          setting: const GrindSetting.numeric(3),
        );
        expect(await memory.settingFor(grinderId: 'ghost'), isNull);
        expect(await memory.entriesFor('ghost'), isEmpty);
      });

      test(
        'ties in lastUsedAt order by bean key, unknown bean first',
        () async {
          final t = DateTime(2026, 1, 1, 10);
          for (final bean in ['b', 'a', null]) {
            await memory.remember(
              grinderId: grinder.id,
              beanId: bean,
              setting: const GrindSetting.numeric(4),
              now: t,
            );
          }
          final order = (await memory.entriesFor(
            grinder.id,
          )).map((e) => e.beanId).toList();
          expect(order, [null, 'a', 'b']);
        },
      );
    });
  }

  contract('drift', () async {
    final db = AppDatabase.memory();
    return (
      DriftGrinderRepository(db) as GrinderRepository,
      DriftGrindMemoryRepository(db) as GrindMemoryRepository,
      () => db.close(),
    );
  });

  contract('in-memory', () async {
    final grinders = InMemoryGrinderRepository();
    return (
      grinders as GrinderRepository,
      InMemoryGrindMemoryRepository(grinders) as GrindMemoryRepository,
      () async {},
    );
  });
}
