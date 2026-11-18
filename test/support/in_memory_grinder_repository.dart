import 'package:espresso_log/domain/grinder/grinder.dart';
import 'package:espresso_log/domain/grinder/grinder_repository.dart';

class InMemoryGrinderRepository implements GrinderRepository {
  final Map<String, Grinder> grinders = {};

  @override
  Future<void> save(Grinder grinder) async {
    grinders[grinder.id] = grinder;
  }

  @override
  Future<List<Grinder>> list() async =>
      grinders.values.toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  @override
  Future<Grinder?> get(String id) async => grinders[id];
}
