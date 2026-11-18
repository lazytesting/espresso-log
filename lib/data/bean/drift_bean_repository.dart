import 'package:drift/drift.dart';

import '../../domain/bean/bean.dart';
import '../../domain/bean/bean_repository.dart';
import '../db/app_database.dart';

class DriftBeanRepository implements BeanRepository {
  final AppDatabase _db;

  DriftBeanRepository(this._db);

  @override
  Future<void> save(Bean bean) async {
    await _db
        .into(_db.beans)
        .insertOnConflictUpdate(
          BeansCompanion.insert(
            id: bean.id,
            name: bean.name,
            roaster: Value(bean.roaster),
            roastLevel: bean.roastLevel,
            notes: Value(bean.notes),
            archived: Value(bean.archived),
            doseGrams: bean.doseGrams,
          ),
        );
  }

  @override
  Future<List<Bean>> list() async {
    final rows = await _db.select(_db.beans).get();
    final beans = rows.map(_toBean).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return beans;
  }

  @override
  Future<Bean?> get(String id) async {
    final row = await (_db.select(
      _db.beans,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toBean(row);
  }

  Bean _toBean(BeanRow row) => Bean(
    id: row.id,
    name: row.name,
    roaster: row.roaster,
    roastLevel: row.roastLevel,
    notes: row.notes,
    archived: row.archived,
    doseGrams: row.doseGrams,
  );
}
