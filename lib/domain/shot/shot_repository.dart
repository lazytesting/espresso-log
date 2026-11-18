import 'package:espresso_log/domain/shot/recorded_shot.dart';
import 'package:espresso_log/domain/shot/shot_list_item.dart';

/// Driven port: persistent storage of finished shots.
abstract class ShotRepository {
  Future<void> save(RecordedShot shot);

  /// All saved shots, newest first, without their graph snapshots.
  Future<List<ShotListItem>> list();

  Future<RecordedShot?> get(String id);

  /// Permanently removes the shot; does nothing when it does not exist.
  Future<void> delete(String id);
}
