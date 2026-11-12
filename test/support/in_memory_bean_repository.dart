import 'package:espresso_log/domain/bean/bean.dart';
import 'package:espresso_log/domain/bean/bean_repository.dart';

class InMemoryBeanRepository implements BeanRepository {
  final Map<String, Bean> beans = {};
  int saveCount = 0;

  @override
  Future<void> save(Bean bean) async {
    saveCount++;
    beans[bean.id] = bean;
  }

  @override
  Future<List<Bean>> list() async => beans.values.toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  @override
  Future<Bean?> get(String id) async => beans[id];
}
