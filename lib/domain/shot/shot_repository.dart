import 'package:espresso_log/domain/shot/recorded_shot.dart';

/// Driven port: persistent storage of finished shots.
abstract class ShotRepository {
  Future<void> save(RecordedShot shot);

  /// All saved shots, newest first.
  Future<List<RecordedShot>> list();

  Future<RecordedShot?> get(String id);

  /// Permanently removes the shot; does nothing when it does not exist.
  Future<void> delete(String id);
}
