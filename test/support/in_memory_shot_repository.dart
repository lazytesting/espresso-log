import 'package:espresso_log/domain/shot/recorded_shot.dart';
import 'package:espresso_log/domain/shot/shot_list_item.dart';
import 'package:espresso_log/domain/shot/shot_repository.dart';

class InMemoryShotRepository implements ShotRepository {
  final Map<String, RecordedShot> shots = {};

  @override
  Future<void> save(RecordedShot shot) async => shots[shot.id] = shot;

  @override
  Future<List<ShotListItem>> list() async =>
      (shots.values.toList()
            ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt)))
          .map(ShotListItem.fromShot)
          .toList();

  @override
  Future<RecordedShot?> get(String id) async => shots[id];

  @override
  Future<void> delete(String id) async => shots.remove(id);
}
