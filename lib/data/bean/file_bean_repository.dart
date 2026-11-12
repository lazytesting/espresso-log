import 'dart:convert';
import 'dart:io';

import 'package:espresso_log/domain/bean/bean.dart';
import 'package:espresso_log/domain/bean/bean_repository.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Stores every bean as `<id>.json` in [directory].
class FileBeanRepository implements BeanRepository {
  final Directory directory;
  final Talker? _talker;

  FileBeanRepository(this.directory, {Talker? talker}) : _talker = talker;

  File _file(String id) => File('${directory.path}/$id.json');

  @override
  Future<void> save(Bean bean) async {
    await directory.create(recursive: true);
    await _file(bean.id).writeAsString(jsonEncode(bean.toJson()));
    _talker?.info('Saved bean ${bean.id}');
  }

  @override
  Future<List<Bean>> list() async {
    if (!await directory.exists()) return [];
    final beans = <Bean>[];
    await for (final entity in directory.list()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      final bean = await _read(entity);
      if (bean != null) beans.add(bean);
    }
    beans.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return beans;
  }

  @override
  Future<Bean?> get(String id) async {
    final file = _file(id);
    if (!await file.exists()) return null;
    return _read(file);
  }

  Future<Bean?> _read(File file) async {
    try {
      final json = jsonDecode(await file.readAsString());
      return Bean.fromJson(json as Map<String, dynamic>);
    } catch (error, stackTrace) {
      _talker?.handle(error, stackTrace, 'Could not read bean ${file.path}');
      return null;
    }
  }
}
