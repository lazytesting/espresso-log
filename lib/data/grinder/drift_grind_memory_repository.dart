import 'package:drift/drift.dart';

import '../../domain/grinder/grind_memory_repository.dart';
import '../../domain/grinder/grind_setting.dart';
import '../db/app_database.dart';

class DriftGrindMemoryRepository implements GrindMemoryRepository {
  final AppDatabase _db;

  DriftGrindMemoryRepository(this._db);

  Future<GrindSettingType?> _typeOf(String grinderId) async {
    final row = await (_db.select(
      _db.grinders,
    )..where((t) => t.id.equals(grinderId))).getSingleOrNull();
    return row == null ? null : GrindSettingType.values.byName(row.settingType);
  }

  @override
  Future<GrindSetting?> settingFor({
    required String grinderId,
    String? beanId,
  }) async {
    final type = await _typeOf(grinderId);
    if (type == null) return null;
    final row =
        await (_db.select(_db.grindMemory)..where(
              (t) =>
                  t.grinderId.equals(grinderId) &
                  t.beanKey.equals(beanId ?? ''),
            ))
            .getSingleOrNull();
    return row == null ? null : GrindSetting.parse(type, row.setting);
  }

  @override
  Future<void> remember({
    required String grinderId,
    String? beanId,
    required GrindSetting setting,
    DateTime? now,
  }) async {
    await _db
        .into(_db.grindMemory)
        .insertOnConflictUpdate(
          GrindMemoryCompanion.insert(
            grinderId: grinderId,
            beanKey: beanId ?? '',
            setting: setting.text,
            lastUsedAt: (now ?? DateTime.now()).microsecondsSinceEpoch,
          ),
        );
  }

  @override
  Future<List<GrindMemoryEntry>> entriesFor(String grinderId) async {
    final type = await _typeOf(grinderId);
    if (type == null) return [];
    final rows =
        await (_db.select(_db.grindMemory)
              ..where((t) => t.grinderId.equals(grinderId))
              ..orderBy([
                (t) => OrderingTerm.desc(t.lastUsedAt),
                (t) => OrderingTerm.asc(t.beanKey),
              ]))
            .get();
    final entries = <GrindMemoryEntry>[];
    for (final row in rows) {
      final setting = GrindSetting.parse(type, row.setting);
      if (setting == null) continue;
      entries.add(
        GrindMemoryEntry(
          grinderId: row.grinderId,
          beanId: row.beanKey.isEmpty ? null : row.beanKey,
          setting: setting,
          lastUsedAt: DateTime.fromMicrosecondsSinceEpoch(row.lastUsedAt),
        ),
      );
    }
    return entries;
  }
}
