import 'dart:convert';
import 'dart:io';

import 'package:espresso_log/domain/shot/recorded_shot.dart';
import 'package:espresso_log/domain/shot/shot_repository.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Stores every shot as `<id>.json` in [directory].
class FileShotRepository implements ShotRepository {
  final Directory directory;
  final Talker? _talker;

  FileShotRepository(this.directory, {Talker? talker}) : _talker = talker;

  File _file(String id) => File('${directory.path}/$id.json');

  @override
  Future<void> save(RecordedShot shot) async {
    await directory.create(recursive: true);
    await _file(shot.id).writeAsString(jsonEncode(shot.toJson()));
    _talker?.info('Saved shot ${shot.id}');
  }

  @override
  Future<List<RecordedShot>> list() async {
    if (!await directory.exists()) return [];
    final shots = <RecordedShot>[];
    await for (final entity in directory.list()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      final shot = await _read(entity);
      if (shot != null) shots.add(shot);
    }
    shots.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return shots;
  }

  @override
  Future<RecordedShot?> get(String id) async {
    final file = _file(id);
    if (!await file.exists()) return null;
    return _read(file);
  }

  Future<RecordedShot?> _read(File file) async {
    try {
      final json = jsonDecode(await file.readAsString());
      return RecordedShot.fromJson(json as Map<String, dynamic>);
    } catch (error, stackTrace) {
      _talker?.handle(error, stackTrace, 'Could not read shot ${file.path}');
      return null;
    }
  }
}
