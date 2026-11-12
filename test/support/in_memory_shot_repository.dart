import 'package:espresso_log/domain/shot/recorded_shot.dart';
import 'package:espresso_log/domain/shot/shot_repository.dart';

class InMemoryShotRepository implements ShotRepository {
  final Map<String, RecordedShot> shots = {};

  @override
  Future<void> save(RecordedShot shot) async => shots[shot.id] = shot;

  @override
  Future<List<RecordedShot>> list() async =>
      shots.values.toList()
        ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

  @override
  Future<RecordedShot?> get(String id) async => shots[id];
}
