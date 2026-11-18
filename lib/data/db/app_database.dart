import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

@DataClassName('BeanRow')
class Beans extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get roaster => text().nullable()();
  IntColumn get roastLevel => integer()();
  TextColumn get notes => text().nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  RealColumn get doseGrams => real()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('GrinderRow')
class Grinders extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get brand => text()();
  TextColumn get settingType => text()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class _MicrosDateTime extends TypeConverter<DateTime, int> {
  const _MicrosDateTime();

  @override
  DateTime fromSql(int fromDb) => DateTime.fromMicrosecondsSinceEpoch(fromDb);

  @override
  int toSql(DateTime value) => value.microsecondsSinceEpoch;
}

/// Last grind setting used per grinder and bean. [beanKey] is the bean id, or
/// '' for the unknown bean (deliberately no foreign key).
class GrindMemory extends Table {
  TextColumn get grinderId => text().references(Grinders, #id)();
  TextColumn get beanKey => text()();
  TextColumn get setting => text()();
  IntColumn get lastUsedAt => integer()();

  @override
  Set<Column> get primaryKey => {grinderId, beanKey};
}

@DataClassName('ShotRow')
class Shots extends Table {
  TextColumn get id => text()();

  /// Microseconds since epoch: drift's default (seconds) would truncate the
  /// precision that shot ids and newest-first ordering rely on.
  IntColumn get recordedAt => integer().map(const _MicrosDateTime())();
  TextColumn get beanId => text().nullable().references(Beans, #id)();
  TextColumn get grinderId => text().nullable().references(Grinders, #id)();
  TextColumn get grindSetting => text().nullable()();
  RealColumn get doseGrams => real().nullable()();
  RealColumn get finalWeight => real().nullable()();
  IntColumn get durationMillis => integer()();
  TextColumn get snapshotJson => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Beans, Grinders, GrindMemory, Shots])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  AppDatabase.memory() : super(NativeDatabase.memory());

  /// The on-disk database used by the app.
  factory AppDatabase.open() =>
      AppDatabase(driftDatabase(name: 'espresso_log'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
