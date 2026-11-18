import 'package:drift/drift.dart';

import '../../domain/grinder/grind_setting.dart';
import '../../domain/grinder/grinder.dart';
import '../../domain/grinder/grinder_repository.dart';
import '../db/app_database.dart';

class DriftGrinderRepository implements GrinderRepository {
  final AppDatabase _db;

  DriftGrinderRepository(this._db);

  @override
  Future<void> save(Grinder grinder) async {
    await _db
        .into(_db.grinders)
        .insertOnConflictUpdate(
          GrindersCompanion.insert(
            id: grinder.id,
            name: grinder.name,
            brand: grinder.brand,
            settingType: grinder.settingType.name,
            archived: Value(grinder.archived),
          ),
        );
  }

  @override
  Future<List<Grinder>> list() async {
    final rows = await _db.select(_db.grinders).get();
    return rows.map(_toGrinder).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  @override
  Future<Grinder?> get(String id) async {
    final row = await (_db.select(
      _db.grinders,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toGrinder(row);
  }

  Grinder _toGrinder(GrinderRow row) => Grinder(
    id: row.id,
    name: row.name,
    brand: row.brand,
    settingType: GrindSettingType.values.byName(row.settingType),
    archived: row.archived,
  );
}
