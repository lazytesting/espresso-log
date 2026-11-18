import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/shot/recorded_shot.dart';
import '../../domain/shot/shot_list_item.dart';
import '../../domain/shot/shot_repository.dart';
import '../../domain/shot/shot_snapshot.dart';
import '../db/app_database.dart';

class DriftShotRepository implements ShotRepository {
  final AppDatabase _db;

  DriftShotRepository(this._db);

  @override
  Future<void> save(RecordedShot shot) async {
    await _db.into(_db.shots).insertOnConflictUpdate(_toCompanion(shot));
  }

  /// Inserts [shot] unless a shot with the same id already exists.
  Future<void> insertIfAbsent(RecordedShot shot) async {
    await _db
        .into(_db.shots)
        .insert(_toCompanion(shot), mode: InsertMode.insertOrIgnore);
  }

  ShotsCompanion _toCompanion(RecordedShot shot) {
    final summary = shot.snapshot.summary;
    return ShotsCompanion.insert(
      id: shot.id,
      recordedAt: shot.recordedAt,
      beanId: Value(shot.beanId),
      grinderId: Value(shot.grinderId),
      grindSetting: Value(shot.grindSetting),
      doseGrams: Value(shot.doseGrams),
      finalWeight: Value(summary.finalWeight),
      durationMillis: summary.durationMillis,
      snapshotJson: jsonEncode(shot.snapshot.toJson()),
    );
  }

  @override
  Future<List<ShotListItem>> list() async {
    final t = _db.shots;
    final query = _db.selectOnly(t)
      ..addColumns([
        t.id,
        t.recordedAt,
        t.beanId,
        t.grinderId,
        t.grindSetting,
        t.doseGrams,
        t.finalWeight,
        t.durationMillis,
      ])
      ..orderBy([OrderingTerm.desc(t.recordedAt)]);
    final rows = await query.get();
    return [
      for (final row in rows)
        ShotListItem(
          id: row.read(t.id)!,
          recordedAt: row.readWithConverter(t.recordedAt)!,
          beanId: row.read(t.beanId),
          grinderId: row.read(t.grinderId),
          grindSetting: row.read(t.grindSetting),
          doseGrams: row.read(t.doseGrams),
          finalWeight: row.read(t.finalWeight),
          durationMillis: row.read(t.durationMillis)!,
        ),
    ];
  }

  @override
  Future<RecordedShot?> get(String id) async {
    final row = await (_db.select(
      _db.shots,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return RecordedShot(
      id: row.id,
      recordedAt: row.recordedAt,
      beanId: row.beanId,
      grinderId: row.grinderId,
      grindSetting: row.grindSetting,
      doseGrams: row.doseGrams,
      snapshot: ShotSnapshot.fromJson(
        jsonDecode(row.snapshotJson) as Map<String, dynamic>,
      ),
    );
  }

  @override
  Future<void> delete(String id) async {
    await (_db.delete(_db.shots)..where((t) => t.id.equals(id))).go();
  }
}
