import 'bean.dart';

abstract class BeanRepository {
  Future<void> save(Bean bean);

  /// All beans including archived, sorted by name case-insensitively.
  Future<List<Bean>> list();

  Future<Bean?> get(String id);
}
