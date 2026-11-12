import 'dart:io';

import 'package:espresso_log/data/bean/file_bean_repository.dart';
import 'package:espresso_log/domain/bean/bean.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  late FileBeanRepository repository;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('beans');
    repository = FileBeanRepository(Directory('${dir.path}/beans'));
  });
  tearDown(() => dir.deleteSync(recursive: true));

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

  test('corrupt and non-json files are skipped', () async {
    await repository.save(Bean.create(name: 'brazil'));
    File('${dir.path}/beans/broken.json').writeAsStringSync('not json');
    File('${dir.path}/beans/partial.json').writeAsStringSync('{"id":"x"}');
    File('${dir.path}/beans/notes.txt').writeAsStringSync('hello');

    expect(await repository.list(), hasLength(1));
  });
}
