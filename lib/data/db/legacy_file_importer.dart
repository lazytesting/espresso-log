import 'dart:convert';
import 'dart:io';

import 'package:talker_flutter/talker_flutter.dart';

import '../../domain/bean/bean.dart';
import '../../domain/shot/recorded_shot.dart';
import '../bean/drift_bean_repository.dart';
import '../shot/drift_shot_repository.dart';
import 'app_database.dart';

/// One-time import of the old per-file JSON beans and shots into the database.
///
/// Everything is inserted in a single transaction; the source folders are
/// renamed to `*.imported` only after it succeeds, so a failure loses nothing
/// and a later run imports again.
class LegacyFileImporter {
  final AppDatabase _db;
  final Directory _documents;
  final Talker? _talker;

  LegacyFileImporter(this._db, this._documents, {Talker? talker})
    : _talker = talker;

  Directory get _beansDir => Directory('${_documents.path}/beans');
  Directory get _shotsDir => Directory('${_documents.path}/shots');

  Future<void> run() async {
    final hasBeans = await _beansDir.exists();
    final hasShots = await _shotsDir.exists();
    if (!hasBeans && !hasShots) return;

    // Only import into an empty database, so a failed folder rename after a
    // committed import cannot resurrect shots the user deleted since.
    final existingBeans = await _db.select(_db.beans).get();
    final existingShots = await _db.select(_db.shots).get();
    if (existingBeans.isNotEmpty || existingShots.isNotEmpty) {
      _talker?.info('Skipped legacy import: database already has data');
      return;
    }

    final beans = hasBeans
        ? await _readAll(_beansDir, Bean.fromJson)
        : <Bean>[];
    final shots = hasShots
        ? await _readAll(_shotsDir, RecordedShot.fromJson)
        : <RecordedShot>[];
    final beanIds = {for (final bean in beans) bean.id};

    final beanRepository = DriftBeanRepository(_db);
    final shotRepository = DriftShotRepository(_db);
    await _db.transaction(() async {
      for (final bean in beans) {
        await beanRepository.insertIfAbsent(bean);
      }
      for (final shot in shots) {
        await shotRepository.insertIfAbsent(_withKnownBean(shot, beanIds));
      }
    });

    if (hasBeans) await _beansDir.rename('${_beansDir.path}.imported');
    if (hasShots) await _shotsDir.rename('${_shotsDir.path}.imported');
    _talker?.info(
      'Imported ${beans.length} legacy beans and ${shots.length} shots',
    );
  }

  RecordedShot _withKnownBean(RecordedShot shot, Set<String> beanIds) {
    if (shot.beanId == null || beanIds.contains(shot.beanId)) return shot;
    return RecordedShot(
      id: shot.id,
      recordedAt: shot.recordedAt,
      snapshot: shot.snapshot,
      doseGrams: shot.doseGrams,
      grinderId: shot.grinderId,
      grindSetting: shot.grindSetting,
    );
  }

  Future<List<T>> _readAll<T>(
    Directory directory,
    T Function(Map<String, dynamic>) parse,
  ) async {
    final items = <T>[];
    await for (final entity in directory.list()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      try {
        final json = jsonDecode(await entity.readAsString());
        items.add(parse(json as Map<String, dynamic>));
      } catch (error, stackTrace) {
        _talker?.handle(
          error,
          stackTrace,
          'Skipped legacy file ${entity.path}',
        );
      }
    }
    return items;
  }
}
