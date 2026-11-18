import 'package:drift/drift.dart';
import 'package:espresso_log/data/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.memory());
  tearDown(() => db.close());

  test('inserting a shot with unknown beanId fails (foreign keys on)', () {
    expect(
      db
          .into(db.shots)
          .insert(
            ShotsCompanion.insert(
              id: 's1',
              recordedAt: DateTime(2026, 1, 1),
              beanId: const Value('missing'),
              durationMillis: 1000,
              snapshotJson: '{}',
            ),
          ),
      throwsA(isA<Exception>()),
    );
  });

  test(
    'inserting grind memory twice with same (grinderId, beanKey) violates the primary key',
    () async {
      await db
          .into(db.grinders)
          .insert(
            GrindersCompanion.insert(
              id: 'g1',
              name: 'Niche',
              brand: 'Niche',
              settingType: 'number',
            ),
          );
      GrindMemoryCompanion row() => GrindMemoryCompanion.insert(
        grinderId: 'g1',
        beanKey: '',
        setting: '12',
        lastUsedAt: 1,
      );
      await db.into(db.grindMemory).insert(row());
      await expectLater(
        db.into(db.grindMemory).insert(row()),
        throwsA(isA<Exception>()),
      );
    },
  );
}
