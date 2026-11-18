import 'grinder.dart';

abstract class GrinderRepository {
  Future<void> save(Grinder grinder);

  /// All grinders including archived ones, sorted by lowercase name.
  Future<List<Grinder>> list();

  Future<Grinder?> get(String id);
}
