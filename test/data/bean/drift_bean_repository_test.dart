import 'package:espresso_log/data/bean/drift_bean_repository.dart';
import 'package:espresso_log/data/db/app_database.dart' show AppDatabase;
import 'package:espresso_log/domain/bean/bean.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftBeanRepository repository;

  setUp(() {
    db = AppDatabase.memory();
    repository = DriftBeanRepository(db);
  });
  tearDown(() => db.close());

  test('list is empty before any save', () async {
    expect(await repository.list(), isEmpty);
  });

  test('saved beans are listed by name and can be fetched', () async {
    final ethiopia = Bean.create(name: 'Ethiopia', now: DateTime(2026, 1, 1));
    final brazil = Bean.create(name: 'brazil', now: DateTime(2026, 1, 2));
    await repository.save(ethiopia);
    await repository.save(brazil);

    expect((await repository.list()).map((b) => b.name), [
      'brazil',
      'Ethiopia',
    ]);
    expect(await repository.get(brazil.id), brazil);
    expect(await repository.get('missing'), isNull);
  });

  test('save and get round trip keeps all fields', () async {
    final bean = Bean.create(
      name: 'Kenya',
      roaster: 'Roastery',
      roastLevel: 2,
      notes: 'fruity',
    ).copyWith(doseGrams: 17.5);
    await repository.save(bean);

    expect(await repository.get(bean.id), bean);
  });

  test('list sorts names case-insensitively', () async {
    await repository.save(Bean.create(name: 'b', now: DateTime(2026, 1, 1)));
    await repository.save(Bean.create(name: 'A', now: DateTime(2026, 1, 2)));

    expect((await repository.list()).map((b) => b.name), ['A', 'b']);
  });

  test(
    'saving again replaces the bean and archived beans are listed',
    () async {
      final bean = Bean.create(name: 'brazil');
      await repository.save(bean);
      await repository.save(bean.copyWith(archived: true));

      final beans = await repository.list();
      expect(beans, hasLength(1));
      expect(beans.single.archived, isTrue);
    },
  );
}
