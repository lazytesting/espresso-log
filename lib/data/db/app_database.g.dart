// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $BeansTable extends Beans with TableInfo<$BeansTable, Bean> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BeansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roasterMeta = const VerificationMeta(
    'roaster',
  );
  @override
  late final GeneratedColumn<String> roaster = GeneratedColumn<String>(
    'roaster',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roastLevelMeta = const VerificationMeta(
    'roastLevel',
  );
  @override
  late final GeneratedColumn<int> roastLevel = GeneratedColumn<int>(
    'roast_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _doseGramsMeta = const VerificationMeta(
    'doseGrams',
  );
  @override
  late final GeneratedColumn<double> doseGrams = GeneratedColumn<double>(
    'dose_grams',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    roaster,
    roastLevel,
    notes,
    archived,
    doseGrams,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'beans';
  @override
  VerificationContext validateIntegrity(
    Insertable<Bean> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('roaster')) {
      context.handle(
        _roasterMeta,
        roaster.isAcceptableOrUnknown(data['roaster']!, _roasterMeta),
      );
    }
    if (data.containsKey('roast_level')) {
      context.handle(
        _roastLevelMeta,
        roastLevel.isAcceptableOrUnknown(data['roast_level']!, _roastLevelMeta),
      );
    } else if (isInserting) {
      context.missing(_roastLevelMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('dose_grams')) {
      context.handle(
        _doseGramsMeta,
        doseGrams.isAcceptableOrUnknown(data['dose_grams']!, _doseGramsMeta),
      );
    } else if (isInserting) {
      context.missing(_doseGramsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Bean map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Bean(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      roaster: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}roaster'],
      ),
      roastLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}roast_level'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      doseGrams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}dose_grams'],
      )!,
    );
  }

  @override
  $BeansTable createAlias(String alias) {
    return $BeansTable(attachedDatabase, alias);
  }
}

class Bean extends DataClass implements Insertable<Bean> {
  final String id;
  final String name;
  final String? roaster;
  final int roastLevel;
  final String? notes;
  final bool archived;
  final double doseGrams;
  const Bean({
    required this.id,
    required this.name,
    this.roaster,
    required this.roastLevel,
    this.notes,
    required this.archived,
    required this.doseGrams,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || roaster != null) {
      map['roaster'] = Variable<String>(roaster);
    }
    map['roast_level'] = Variable<int>(roastLevel);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['archived'] = Variable<bool>(archived);
    map['dose_grams'] = Variable<double>(doseGrams);
    return map;
  }

  BeansCompanion toCompanion(bool nullToAbsent) {
    return BeansCompanion(
      id: Value(id),
      name: Value(name),
      roaster: roaster == null && nullToAbsent
          ? const Value.absent()
          : Value(roaster),
      roastLevel: Value(roastLevel),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      archived: Value(archived),
      doseGrams: Value(doseGrams),
    );
  }

  factory Bean.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Bean(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      roaster: serializer.fromJson<String?>(json['roaster']),
      roastLevel: serializer.fromJson<int>(json['roastLevel']),
      notes: serializer.fromJson<String?>(json['notes']),
      archived: serializer.fromJson<bool>(json['archived']),
      doseGrams: serializer.fromJson<double>(json['doseGrams']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'roaster': serializer.toJson<String?>(roaster),
      'roastLevel': serializer.toJson<int>(roastLevel),
      'notes': serializer.toJson<String?>(notes),
      'archived': serializer.toJson<bool>(archived),
      'doseGrams': serializer.toJson<double>(doseGrams),
    };
  }

  Bean copyWith({
    String? id,
    String? name,
    Value<String?> roaster = const Value.absent(),
    int? roastLevel,
    Value<String?> notes = const Value.absent(),
    bool? archived,
    double? doseGrams,
  }) => Bean(
    id: id ?? this.id,
    name: name ?? this.name,
    roaster: roaster.present ? roaster.value : this.roaster,
    roastLevel: roastLevel ?? this.roastLevel,
    notes: notes.present ? notes.value : this.notes,
    archived: archived ?? this.archived,
    doseGrams: doseGrams ?? this.doseGrams,
  );
  Bean copyWithCompanion(BeansCompanion data) {
    return Bean(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      roaster: data.roaster.present ? data.roaster.value : this.roaster,
      roastLevel: data.roastLevel.present
          ? data.roastLevel.value
          : this.roastLevel,
      notes: data.notes.present ? data.notes.value : this.notes,
      archived: data.archived.present ? data.archived.value : this.archived,
      doseGrams: data.doseGrams.present ? data.doseGrams.value : this.doseGrams,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Bean(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('roaster: $roaster, ')
          ..write('roastLevel: $roastLevel, ')
          ..write('notes: $notes, ')
          ..write('archived: $archived, ')
          ..write('doseGrams: $doseGrams')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, roaster, roastLevel, notes, archived, doseGrams);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Bean &&
          other.id == this.id &&
          other.name == this.name &&
          other.roaster == this.roaster &&
          other.roastLevel == this.roastLevel &&
          other.notes == this.notes &&
          other.archived == this.archived &&
          other.doseGrams == this.doseGrams);
}

class BeansCompanion extends UpdateCompanion<Bean> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> roaster;
  final Value<int> roastLevel;
  final Value<String?> notes;
  final Value<bool> archived;
  final Value<double> doseGrams;
  final Value<int> rowid;
  const BeansCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.roaster = const Value.absent(),
    this.roastLevel = const Value.absent(),
    this.notes = const Value.absent(),
    this.archived = const Value.absent(),
    this.doseGrams = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BeansCompanion.insert({
    required String id,
    required String name,
    this.roaster = const Value.absent(),
    required int roastLevel,
    this.notes = const Value.absent(),
    this.archived = const Value.absent(),
    required double doseGrams,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       roastLevel = Value(roastLevel),
       doseGrams = Value(doseGrams);
  static Insertable<Bean> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? roaster,
    Expression<int>? roastLevel,
    Expression<String>? notes,
    Expression<bool>? archived,
    Expression<double>? doseGrams,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (roaster != null) 'roaster': roaster,
      if (roastLevel != null) 'roast_level': roastLevel,
      if (notes != null) 'notes': notes,
      if (archived != null) 'archived': archived,
      if (doseGrams != null) 'dose_grams': doseGrams,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BeansCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? roaster,
    Value<int>? roastLevel,
    Value<String?>? notes,
    Value<bool>? archived,
    Value<double>? doseGrams,
    Value<int>? rowid,
  }) {
    return BeansCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      roaster: roaster ?? this.roaster,
      roastLevel: roastLevel ?? this.roastLevel,
      notes: notes ?? this.notes,
      archived: archived ?? this.archived,
      doseGrams: doseGrams ?? this.doseGrams,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (roaster.present) {
      map['roaster'] = Variable<String>(roaster.value);
    }
    if (roastLevel.present) {
      map['roast_level'] = Variable<int>(roastLevel.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (doseGrams.present) {
      map['dose_grams'] = Variable<double>(doseGrams.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BeansCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('roaster: $roaster, ')
          ..write('roastLevel: $roastLevel, ')
          ..write('notes: $notes, ')
          ..write('archived: $archived, ')
          ..write('doseGrams: $doseGrams, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GrindersTable extends Grinders with TableInfo<$GrindersTable, Grinder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GrindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _settingTypeMeta = const VerificationMeta(
    'settingType',
  );
  @override
  late final GeneratedColumn<String> settingType = GeneratedColumn<String>(
    'setting_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    brand,
    settingType,
    archived,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'grinders';
  @override
  VerificationContext validateIntegrity(
    Insertable<Grinder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    } else if (isInserting) {
      context.missing(_brandMeta);
    }
    if (data.containsKey('setting_type')) {
      context.handle(
        _settingTypeMeta,
        settingType.isAcceptableOrUnknown(
          data['setting_type']!,
          _settingTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_settingTypeMeta);
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Grinder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Grinder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      )!,
      settingType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}setting_type'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
    );
  }

  @override
  $GrindersTable createAlias(String alias) {
    return $GrindersTable(attachedDatabase, alias);
  }
}

class Grinder extends DataClass implements Insertable<Grinder> {
  final String id;
  final String name;
  final String brand;
  final String settingType;
  final bool archived;
  const Grinder({
    required this.id,
    required this.name,
    required this.brand,
    required this.settingType,
    required this.archived,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['brand'] = Variable<String>(brand);
    map['setting_type'] = Variable<String>(settingType);
    map['archived'] = Variable<bool>(archived);
    return map;
  }

  GrindersCompanion toCompanion(bool nullToAbsent) {
    return GrindersCompanion(
      id: Value(id),
      name: Value(name),
      brand: Value(brand),
      settingType: Value(settingType),
      archived: Value(archived),
    );
  }

  factory Grinder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Grinder(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      brand: serializer.fromJson<String>(json['brand']),
      settingType: serializer.fromJson<String>(json['settingType']),
      archived: serializer.fromJson<bool>(json['archived']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'brand': serializer.toJson<String>(brand),
      'settingType': serializer.toJson<String>(settingType),
      'archived': serializer.toJson<bool>(archived),
    };
  }

  Grinder copyWith({
    String? id,
    String? name,
    String? brand,
    String? settingType,
    bool? archived,
  }) => Grinder(
    id: id ?? this.id,
    name: name ?? this.name,
    brand: brand ?? this.brand,
    settingType: settingType ?? this.settingType,
    archived: archived ?? this.archived,
  );
  Grinder copyWithCompanion(GrindersCompanion data) {
    return Grinder(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      brand: data.brand.present ? data.brand.value : this.brand,
      settingType: data.settingType.present
          ? data.settingType.value
          : this.settingType,
      archived: data.archived.present ? data.archived.value : this.archived,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Grinder(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('brand: $brand, ')
          ..write('settingType: $settingType, ')
          ..write('archived: $archived')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, brand, settingType, archived);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Grinder &&
          other.id == this.id &&
          other.name == this.name &&
          other.brand == this.brand &&
          other.settingType == this.settingType &&
          other.archived == this.archived);
}

class GrindersCompanion extends UpdateCompanion<Grinder> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> brand;
  final Value<String> settingType;
  final Value<bool> archived;
  final Value<int> rowid;
  const GrindersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.brand = const Value.absent(),
    this.settingType = const Value.absent(),
    this.archived = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GrindersCompanion.insert({
    required String id,
    required String name,
    required String brand,
    required String settingType,
    this.archived = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       brand = Value(brand),
       settingType = Value(settingType);
  static Insertable<Grinder> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? brand,
    Expression<String>? settingType,
    Expression<bool>? archived,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (brand != null) 'brand': brand,
      if (settingType != null) 'setting_type': settingType,
      if (archived != null) 'archived': archived,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GrindersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? brand,
    Value<String>? settingType,
    Value<bool>? archived,
    Value<int>? rowid,
  }) {
    return GrindersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      settingType: settingType ?? this.settingType,
      archived: archived ?? this.archived,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (settingType.present) {
      map['setting_type'] = Variable<String>(settingType.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GrindersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('brand: $brand, ')
          ..write('settingType: $settingType, ')
          ..write('archived: $archived, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GrindMemoryTable extends GrindMemory
    with TableInfo<$GrindMemoryTable, GrindMemoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GrindMemoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _grinderIdMeta = const VerificationMeta(
    'grinderId',
  );
  @override
  late final GeneratedColumn<String> grinderId = GeneratedColumn<String>(
    'grinder_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES grinders (id)',
    ),
  );
  static const VerificationMeta _beanKeyMeta = const VerificationMeta(
    'beanKey',
  );
  @override
  late final GeneratedColumn<String> beanKey = GeneratedColumn<String>(
    'bean_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _settingMeta = const VerificationMeta(
    'setting',
  );
  @override
  late final GeneratedColumn<String> setting = GeneratedColumn<String>(
    'setting',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastUsedAtMeta = const VerificationMeta(
    'lastUsedAt',
  );
  @override
  late final GeneratedColumn<int> lastUsedAt = GeneratedColumn<int>(
    'last_used_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    grinderId,
    beanKey,
    setting,
    lastUsedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'grind_memory';
  @override
  VerificationContext validateIntegrity(
    Insertable<GrindMemoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('grinder_id')) {
      context.handle(
        _grinderIdMeta,
        grinderId.isAcceptableOrUnknown(data['grinder_id']!, _grinderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_grinderIdMeta);
    }
    if (data.containsKey('bean_key')) {
      context.handle(
        _beanKeyMeta,
        beanKey.isAcceptableOrUnknown(data['bean_key']!, _beanKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_beanKeyMeta);
    }
    if (data.containsKey('setting')) {
      context.handle(
        _settingMeta,
        setting.isAcceptableOrUnknown(data['setting']!, _settingMeta),
      );
    } else if (isInserting) {
      context.missing(_settingMeta);
    }
    if (data.containsKey('last_used_at')) {
      context.handle(
        _lastUsedAtMeta,
        lastUsedAt.isAcceptableOrUnknown(
          data['last_used_at']!,
          _lastUsedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastUsedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {grinderId, beanKey};
  @override
  GrindMemoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GrindMemoryData(
      grinderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grinder_id'],
      )!,
      beanKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bean_key'],
      )!,
      setting: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}setting'],
      )!,
      lastUsedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_used_at'],
      )!,
    );
  }

  @override
  $GrindMemoryTable createAlias(String alias) {
    return $GrindMemoryTable(attachedDatabase, alias);
  }
}

class GrindMemoryData extends DataClass implements Insertable<GrindMemoryData> {
  final String grinderId;
  final String beanKey;
  final String setting;
  final int lastUsedAt;
  const GrindMemoryData({
    required this.grinderId,
    required this.beanKey,
    required this.setting,
    required this.lastUsedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['grinder_id'] = Variable<String>(grinderId);
    map['bean_key'] = Variable<String>(beanKey);
    map['setting'] = Variable<String>(setting);
    map['last_used_at'] = Variable<int>(lastUsedAt);
    return map;
  }

  GrindMemoryCompanion toCompanion(bool nullToAbsent) {
    return GrindMemoryCompanion(
      grinderId: Value(grinderId),
      beanKey: Value(beanKey),
      setting: Value(setting),
      lastUsedAt: Value(lastUsedAt),
    );
  }

  factory GrindMemoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GrindMemoryData(
      grinderId: serializer.fromJson<String>(json['grinderId']),
      beanKey: serializer.fromJson<String>(json['beanKey']),
      setting: serializer.fromJson<String>(json['setting']),
      lastUsedAt: serializer.fromJson<int>(json['lastUsedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'grinderId': serializer.toJson<String>(grinderId),
      'beanKey': serializer.toJson<String>(beanKey),
      'setting': serializer.toJson<String>(setting),
      'lastUsedAt': serializer.toJson<int>(lastUsedAt),
    };
  }

  GrindMemoryData copyWith({
    String? grinderId,
    String? beanKey,
    String? setting,
    int? lastUsedAt,
  }) => GrindMemoryData(
    grinderId: grinderId ?? this.grinderId,
    beanKey: beanKey ?? this.beanKey,
    setting: setting ?? this.setting,
    lastUsedAt: lastUsedAt ?? this.lastUsedAt,
  );
  GrindMemoryData copyWithCompanion(GrindMemoryCompanion data) {
    return GrindMemoryData(
      grinderId: data.grinderId.present ? data.grinderId.value : this.grinderId,
      beanKey: data.beanKey.present ? data.beanKey.value : this.beanKey,
      setting: data.setting.present ? data.setting.value : this.setting,
      lastUsedAt: data.lastUsedAt.present
          ? data.lastUsedAt.value
          : this.lastUsedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GrindMemoryData(')
          ..write('grinderId: $grinderId, ')
          ..write('beanKey: $beanKey, ')
          ..write('setting: $setting, ')
          ..write('lastUsedAt: $lastUsedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(grinderId, beanKey, setting, lastUsedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GrindMemoryData &&
          other.grinderId == this.grinderId &&
          other.beanKey == this.beanKey &&
          other.setting == this.setting &&
          other.lastUsedAt == this.lastUsedAt);
}

class GrindMemoryCompanion extends UpdateCompanion<GrindMemoryData> {
  final Value<String> grinderId;
  final Value<String> beanKey;
  final Value<String> setting;
  final Value<int> lastUsedAt;
  final Value<int> rowid;
  const GrindMemoryCompanion({
    this.grinderId = const Value.absent(),
    this.beanKey = const Value.absent(),
    this.setting = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GrindMemoryCompanion.insert({
    required String grinderId,
    required String beanKey,
    required String setting,
    required int lastUsedAt,
    this.rowid = const Value.absent(),
  }) : grinderId = Value(grinderId),
       beanKey = Value(beanKey),
       setting = Value(setting),
       lastUsedAt = Value(lastUsedAt);
  static Insertable<GrindMemoryData> custom({
    Expression<String>? grinderId,
    Expression<String>? beanKey,
    Expression<String>? setting,
    Expression<int>? lastUsedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (grinderId != null) 'grinder_id': grinderId,
      if (beanKey != null) 'bean_key': beanKey,
      if (setting != null) 'setting': setting,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GrindMemoryCompanion copyWith({
    Value<String>? grinderId,
    Value<String>? beanKey,
    Value<String>? setting,
    Value<int>? lastUsedAt,
    Value<int>? rowid,
  }) {
    return GrindMemoryCompanion(
      grinderId: grinderId ?? this.grinderId,
      beanKey: beanKey ?? this.beanKey,
      setting: setting ?? this.setting,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (grinderId.present) {
      map['grinder_id'] = Variable<String>(grinderId.value);
    }
    if (beanKey.present) {
      map['bean_key'] = Variable<String>(beanKey.value);
    }
    if (setting.present) {
      map['setting'] = Variable<String>(setting.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<int>(lastUsedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GrindMemoryCompanion(')
          ..write('grinderId: $grinderId, ')
          ..write('beanKey: $beanKey, ')
          ..write('setting: $setting, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShotsTable extends Shots with TableInfo<$ShotsTable, Shot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _beanIdMeta = const VerificationMeta('beanId');
  @override
  late final GeneratedColumn<String> beanId = GeneratedColumn<String>(
    'bean_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES beans (id)',
    ),
  );
  static const VerificationMeta _grinderIdMeta = const VerificationMeta(
    'grinderId',
  );
  @override
  late final GeneratedColumn<String> grinderId = GeneratedColumn<String>(
    'grinder_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES grinders (id)',
    ),
  );
  static const VerificationMeta _grindSettingMeta = const VerificationMeta(
    'grindSetting',
  );
  @override
  late final GeneratedColumn<String> grindSetting = GeneratedColumn<String>(
    'grind_setting',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _doseGramsMeta = const VerificationMeta(
    'doseGrams',
  );
  @override
  late final GeneratedColumn<double> doseGrams = GeneratedColumn<double>(
    'dose_grams',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _finalWeightMeta = const VerificationMeta(
    'finalWeight',
  );
  @override
  late final GeneratedColumn<double> finalWeight = GeneratedColumn<double>(
    'final_weight',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMillisMeta = const VerificationMeta(
    'durationMillis',
  );
  @override
  late final GeneratedColumn<int> durationMillis = GeneratedColumn<int>(
    'duration_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _snapshotJsonMeta = const VerificationMeta(
    'snapshotJson',
  );
  @override
  late final GeneratedColumn<String> snapshotJson = GeneratedColumn<String>(
    'snapshot_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    recordedAt,
    beanId,
    grinderId,
    grindSetting,
    doseGrams,
    finalWeight,
    durationMillis,
    snapshotJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shots';
  @override
  VerificationContext validateIntegrity(
    Insertable<Shot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('bean_id')) {
      context.handle(
        _beanIdMeta,
        beanId.isAcceptableOrUnknown(data['bean_id']!, _beanIdMeta),
      );
    }
    if (data.containsKey('grinder_id')) {
      context.handle(
        _grinderIdMeta,
        grinderId.isAcceptableOrUnknown(data['grinder_id']!, _grinderIdMeta),
      );
    }
    if (data.containsKey('grind_setting')) {
      context.handle(
        _grindSettingMeta,
        grindSetting.isAcceptableOrUnknown(
          data['grind_setting']!,
          _grindSettingMeta,
        ),
      );
    }
    if (data.containsKey('dose_grams')) {
      context.handle(
        _doseGramsMeta,
        doseGrams.isAcceptableOrUnknown(data['dose_grams']!, _doseGramsMeta),
      );
    }
    if (data.containsKey('final_weight')) {
      context.handle(
        _finalWeightMeta,
        finalWeight.isAcceptableOrUnknown(
          data['final_weight']!,
          _finalWeightMeta,
        ),
      );
    }
    if (data.containsKey('duration_millis')) {
      context.handle(
        _durationMillisMeta,
        durationMillis.isAcceptableOrUnknown(
          data['duration_millis']!,
          _durationMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationMillisMeta);
    }
    if (data.containsKey('snapshot_json')) {
      context.handle(
        _snapshotJsonMeta,
        snapshotJson.isAcceptableOrUnknown(
          data['snapshot_json']!,
          _snapshotJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_snapshotJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Shot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Shot(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      beanId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bean_id'],
      ),
      grinderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grinder_id'],
      ),
      grindSetting: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grind_setting'],
      ),
      doseGrams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}dose_grams'],
      ),
      finalWeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}final_weight'],
      ),
      durationMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_millis'],
      )!,
      snapshotJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}snapshot_json'],
      )!,
    );
  }

  @override
  $ShotsTable createAlias(String alias) {
    return $ShotsTable(attachedDatabase, alias);
  }
}

class Shot extends DataClass implements Insertable<Shot> {
  final String id;
  final DateTime recordedAt;
  final String? beanId;
  final String? grinderId;
  final String? grindSetting;
  final double? doseGrams;
  final double? finalWeight;
  final int durationMillis;
  final String snapshotJson;
  const Shot({
    required this.id,
    required this.recordedAt,
    this.beanId,
    this.grinderId,
    this.grindSetting,
    this.doseGrams,
    this.finalWeight,
    required this.durationMillis,
    required this.snapshotJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    if (!nullToAbsent || beanId != null) {
      map['bean_id'] = Variable<String>(beanId);
    }
    if (!nullToAbsent || grinderId != null) {
      map['grinder_id'] = Variable<String>(grinderId);
    }
    if (!nullToAbsent || grindSetting != null) {
      map['grind_setting'] = Variable<String>(grindSetting);
    }
    if (!nullToAbsent || doseGrams != null) {
      map['dose_grams'] = Variable<double>(doseGrams);
    }
    if (!nullToAbsent || finalWeight != null) {
      map['final_weight'] = Variable<double>(finalWeight);
    }
    map['duration_millis'] = Variable<int>(durationMillis);
    map['snapshot_json'] = Variable<String>(snapshotJson);
    return map;
  }

  ShotsCompanion toCompanion(bool nullToAbsent) {
    return ShotsCompanion(
      id: Value(id),
      recordedAt: Value(recordedAt),
      beanId: beanId == null && nullToAbsent
          ? const Value.absent()
          : Value(beanId),
      grinderId: grinderId == null && nullToAbsent
          ? const Value.absent()
          : Value(grinderId),
      grindSetting: grindSetting == null && nullToAbsent
          ? const Value.absent()
          : Value(grindSetting),
      doseGrams: doseGrams == null && nullToAbsent
          ? const Value.absent()
          : Value(doseGrams),
      finalWeight: finalWeight == null && nullToAbsent
          ? const Value.absent()
          : Value(finalWeight),
      durationMillis: Value(durationMillis),
      snapshotJson: Value(snapshotJson),
    );
  }

  factory Shot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Shot(
      id: serializer.fromJson<String>(json['id']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      beanId: serializer.fromJson<String?>(json['beanId']),
      grinderId: serializer.fromJson<String?>(json['grinderId']),
      grindSetting: serializer.fromJson<String?>(json['grindSetting']),
      doseGrams: serializer.fromJson<double?>(json['doseGrams']),
      finalWeight: serializer.fromJson<double?>(json['finalWeight']),
      durationMillis: serializer.fromJson<int>(json['durationMillis']),
      snapshotJson: serializer.fromJson<String>(json['snapshotJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'beanId': serializer.toJson<String?>(beanId),
      'grinderId': serializer.toJson<String?>(grinderId),
      'grindSetting': serializer.toJson<String?>(grindSetting),
      'doseGrams': serializer.toJson<double?>(doseGrams),
      'finalWeight': serializer.toJson<double?>(finalWeight),
      'durationMillis': serializer.toJson<int>(durationMillis),
      'snapshotJson': serializer.toJson<String>(snapshotJson),
    };
  }

  Shot copyWith({
    String? id,
    DateTime? recordedAt,
    Value<String?> beanId = const Value.absent(),
    Value<String?> grinderId = const Value.absent(),
    Value<String?> grindSetting = const Value.absent(),
    Value<double?> doseGrams = const Value.absent(),
    Value<double?> finalWeight = const Value.absent(),
    int? durationMillis,
    String? snapshotJson,
  }) => Shot(
    id: id ?? this.id,
    recordedAt: recordedAt ?? this.recordedAt,
    beanId: beanId.present ? beanId.value : this.beanId,
    grinderId: grinderId.present ? grinderId.value : this.grinderId,
    grindSetting: grindSetting.present ? grindSetting.value : this.grindSetting,
    doseGrams: doseGrams.present ? doseGrams.value : this.doseGrams,
    finalWeight: finalWeight.present ? finalWeight.value : this.finalWeight,
    durationMillis: durationMillis ?? this.durationMillis,
    snapshotJson: snapshotJson ?? this.snapshotJson,
  );
  Shot copyWithCompanion(ShotsCompanion data) {
    return Shot(
      id: data.id.present ? data.id.value : this.id,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      beanId: data.beanId.present ? data.beanId.value : this.beanId,
      grinderId: data.grinderId.present ? data.grinderId.value : this.grinderId,
      grindSetting: data.grindSetting.present
          ? data.grindSetting.value
          : this.grindSetting,
      doseGrams: data.doseGrams.present ? data.doseGrams.value : this.doseGrams,
      finalWeight: data.finalWeight.present
          ? data.finalWeight.value
          : this.finalWeight,
      durationMillis: data.durationMillis.present
          ? data.durationMillis.value
          : this.durationMillis,
      snapshotJson: data.snapshotJson.present
          ? data.snapshotJson.value
          : this.snapshotJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Shot(')
          ..write('id: $id, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('beanId: $beanId, ')
          ..write('grinderId: $grinderId, ')
          ..write('grindSetting: $grindSetting, ')
          ..write('doseGrams: $doseGrams, ')
          ..write('finalWeight: $finalWeight, ')
          ..write('durationMillis: $durationMillis, ')
          ..write('snapshotJson: $snapshotJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    recordedAt,
    beanId,
    grinderId,
    grindSetting,
    doseGrams,
    finalWeight,
    durationMillis,
    snapshotJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Shot &&
          other.id == this.id &&
          other.recordedAt == this.recordedAt &&
          other.beanId == this.beanId &&
          other.grinderId == this.grinderId &&
          other.grindSetting == this.grindSetting &&
          other.doseGrams == this.doseGrams &&
          other.finalWeight == this.finalWeight &&
          other.durationMillis == this.durationMillis &&
          other.snapshotJson == this.snapshotJson);
}

class ShotsCompanion extends UpdateCompanion<Shot> {
  final Value<String> id;
  final Value<DateTime> recordedAt;
  final Value<String?> beanId;
  final Value<String?> grinderId;
  final Value<String?> grindSetting;
  final Value<double?> doseGrams;
  final Value<double?> finalWeight;
  final Value<int> durationMillis;
  final Value<String> snapshotJson;
  final Value<int> rowid;
  const ShotsCompanion({
    this.id = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.beanId = const Value.absent(),
    this.grinderId = const Value.absent(),
    this.grindSetting = const Value.absent(),
    this.doseGrams = const Value.absent(),
    this.finalWeight = const Value.absent(),
    this.durationMillis = const Value.absent(),
    this.snapshotJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShotsCompanion.insert({
    required String id,
    required DateTime recordedAt,
    this.beanId = const Value.absent(),
    this.grinderId = const Value.absent(),
    this.grindSetting = const Value.absent(),
    this.doseGrams = const Value.absent(),
    this.finalWeight = const Value.absent(),
    required int durationMillis,
    required String snapshotJson,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       recordedAt = Value(recordedAt),
       durationMillis = Value(durationMillis),
       snapshotJson = Value(snapshotJson);
  static Insertable<Shot> custom({
    Expression<String>? id,
    Expression<DateTime>? recordedAt,
    Expression<String>? beanId,
    Expression<String>? grinderId,
    Expression<String>? grindSetting,
    Expression<double>? doseGrams,
    Expression<double>? finalWeight,
    Expression<int>? durationMillis,
    Expression<String>? snapshotJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (beanId != null) 'bean_id': beanId,
      if (grinderId != null) 'grinder_id': grinderId,
      if (grindSetting != null) 'grind_setting': grindSetting,
      if (doseGrams != null) 'dose_grams': doseGrams,
      if (finalWeight != null) 'final_weight': finalWeight,
      if (durationMillis != null) 'duration_millis': durationMillis,
      if (snapshotJson != null) 'snapshot_json': snapshotJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShotsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? recordedAt,
    Value<String?>? beanId,
    Value<String?>? grinderId,
    Value<String?>? grindSetting,
    Value<double?>? doseGrams,
    Value<double?>? finalWeight,
    Value<int>? durationMillis,
    Value<String>? snapshotJson,
    Value<int>? rowid,
  }) {
    return ShotsCompanion(
      id: id ?? this.id,
      recordedAt: recordedAt ?? this.recordedAt,
      beanId: beanId ?? this.beanId,
      grinderId: grinderId ?? this.grinderId,
      grindSetting: grindSetting ?? this.grindSetting,
      doseGrams: doseGrams ?? this.doseGrams,
      finalWeight: finalWeight ?? this.finalWeight,
      durationMillis: durationMillis ?? this.durationMillis,
      snapshotJson: snapshotJson ?? this.snapshotJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (beanId.present) {
      map['bean_id'] = Variable<String>(beanId.value);
    }
    if (grinderId.present) {
      map['grinder_id'] = Variable<String>(grinderId.value);
    }
    if (grindSetting.present) {
      map['grind_setting'] = Variable<String>(grindSetting.value);
    }
    if (doseGrams.present) {
      map['dose_grams'] = Variable<double>(doseGrams.value);
    }
    if (finalWeight.present) {
      map['final_weight'] = Variable<double>(finalWeight.value);
    }
    if (durationMillis.present) {
      map['duration_millis'] = Variable<int>(durationMillis.value);
    }
    if (snapshotJson.present) {
      map['snapshot_json'] = Variable<String>(snapshotJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShotsCompanion(')
          ..write('id: $id, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('beanId: $beanId, ')
          ..write('grinderId: $grinderId, ')
          ..write('grindSetting: $grindSetting, ')
          ..write('doseGrams: $doseGrams, ')
          ..write('finalWeight: $finalWeight, ')
          ..write('durationMillis: $durationMillis, ')
          ..write('snapshotJson: $snapshotJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BeansTable beans = $BeansTable(this);
  late final $GrindersTable grinders = $GrindersTable(this);
  late final $GrindMemoryTable grindMemory = $GrindMemoryTable(this);
  late final $ShotsTable shots = $ShotsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    beans,
    grinders,
    grindMemory,
    shots,
  ];
}

typedef $$BeansTableCreateCompanionBuilder =
    BeansCompanion Function({
      required String id,
      required String name,
      Value<String?> roaster,
      required int roastLevel,
      Value<String?> notes,
      Value<bool> archived,
      required double doseGrams,
      Value<int> rowid,
    });
typedef $$BeansTableUpdateCompanionBuilder =
    BeansCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> roaster,
      Value<int> roastLevel,
      Value<String?> notes,
      Value<bool> archived,
      Value<double> doseGrams,
      Value<int> rowid,
    });

final class $$BeansTableReferences
    extends BaseReferences<_$AppDatabase, $BeansTable, Bean> {
  $$BeansTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ShotsTable, List<Shot>> _shotsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.shots,
    aliasName: 'beans__id__shots__bean_id',
  );

  $$ShotsTableProcessedTableManager get shotsRefs {
    final manager = $$ShotsTableTableManager(
      $_db,
      $_db.shots,
    ).filter((f) => f.beanId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_shotsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BeansTableFilterComposer extends Composer<_$AppDatabase, $BeansTable> {
  $$BeansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roaster => $composableBuilder(
    column: $table.roaster,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get roastLevel => $composableBuilder(
    column: $table.roastLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get doseGrams => $composableBuilder(
    column: $table.doseGrams,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> shotsRefs(
    Expression<bool> Function($$ShotsTableFilterComposer f) f,
  ) {
    final $$ShotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shots,
      getReferencedColumn: (t) => t.beanId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShotsTableFilterComposer(
            $db: $db,
            $table: $db.shots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BeansTableOrderingComposer
    extends Composer<_$AppDatabase, $BeansTable> {
  $$BeansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roaster => $composableBuilder(
    column: $table.roaster,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get roastLevel => $composableBuilder(
    column: $table.roastLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get doseGrams => $composableBuilder(
    column: $table.doseGrams,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BeansTableAnnotationComposer
    extends Composer<_$AppDatabase, $BeansTable> {
  $$BeansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get roaster =>
      $composableBuilder(column: $table.roaster, builder: (column) => column);

  GeneratedColumn<int> get roastLevel => $composableBuilder(
    column: $table.roastLevel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<double> get doseGrams =>
      $composableBuilder(column: $table.doseGrams, builder: (column) => column);

  Expression<T> shotsRefs<T extends Object>(
    Expression<T> Function($$ShotsTableAnnotationComposer a) f,
  ) {
    final $$ShotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shots,
      getReferencedColumn: (t) => t.beanId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShotsTableAnnotationComposer(
            $db: $db,
            $table: $db.shots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BeansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BeansTable,
          Bean,
          $$BeansTableFilterComposer,
          $$BeansTableOrderingComposer,
          $$BeansTableAnnotationComposer,
          $$BeansTableCreateCompanionBuilder,
          $$BeansTableUpdateCompanionBuilder,
          (Bean, $$BeansTableReferences),
          Bean,
          PrefetchHooks Function({bool shotsRefs})
        > {
  $$BeansTableTableManager(_$AppDatabase db, $BeansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BeansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BeansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BeansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> roaster = const Value.absent(),
                Value<int> roastLevel = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<double> doseGrams = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BeansCompanion(
                id: id,
                name: name,
                roaster: roaster,
                roastLevel: roastLevel,
                notes: notes,
                archived: archived,
                doseGrams: doseGrams,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> roaster = const Value.absent(),
                required int roastLevel,
                Value<String?> notes = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                required double doseGrams,
                Value<int> rowid = const Value.absent(),
              }) => BeansCompanion.insert(
                id: id,
                name: name,
                roaster: roaster,
                roastLevel: roastLevel,
                notes: notes,
                archived: archived,
                doseGrams: doseGrams,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BeansTable, Bean>(table),
                  $$BeansTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({shotsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (shotsRefs) db.shots],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (shotsRefs)
                    await $_getPrefetchedDataByColumns<
                      Bean,
                      $BeansTable,
                      Shot,
                      $ShotsTable
                    >(
                      currentTable: table,
                      referencedTable: $$BeansTableReferences._shotsRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$BeansTableReferences(db, table, p0).shotsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'bean_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$BeansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BeansTable,
      Bean,
      $$BeansTableFilterComposer,
      $$BeansTableOrderingComposer,
      $$BeansTableAnnotationComposer,
      $$BeansTableCreateCompanionBuilder,
      $$BeansTableUpdateCompanionBuilder,
      (Bean, $$BeansTableReferences),
      Bean,
      PrefetchHooks Function({bool shotsRefs})
    >;
typedef $$GrindersTableCreateCompanionBuilder =
    GrindersCompanion Function({
      required String id,
      required String name,
      required String brand,
      required String settingType,
      Value<bool> archived,
      Value<int> rowid,
    });
typedef $$GrindersTableUpdateCompanionBuilder =
    GrindersCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> brand,
      Value<String> settingType,
      Value<bool> archived,
      Value<int> rowid,
    });

final class $$GrindersTableReferences
    extends BaseReferences<_$AppDatabase, $GrindersTable, Grinder> {
  $$GrindersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$GrindMemoryTable, List<GrindMemoryData>>
  _grindMemoryRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.grindMemory,
    aliasName: 'grinders__id__grind_memory__grinder_id',
  );

  $$GrindMemoryTableProcessedTableManager get grindMemoryRefs {
    final manager = $$GrindMemoryTableTableManager(
      $_db,
      $_db.grindMemory,
    ).filter((f) => f.grinderId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_grindMemoryRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ShotsTable, List<Shot>> _shotsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.shots,
    aliasName: 'grinders__id__shots__grinder_id',
  );

  $$ShotsTableProcessedTableManager get shotsRefs {
    final manager = $$ShotsTableTableManager(
      $_db,
      $_db.shots,
    ).filter((f) => f.grinderId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_shotsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$GrindersTableFilterComposer
    extends Composer<_$AppDatabase, $GrindersTable> {
  $$GrindersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get settingType => $composableBuilder(
    column: $table.settingType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> grindMemoryRefs(
    Expression<bool> Function($$GrindMemoryTableFilterComposer f) f,
  ) {
    final $$GrindMemoryTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.grindMemory,
      getReferencedColumn: (t) => t.grinderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GrindMemoryTableFilterComposer(
            $db: $db,
            $table: $db.grindMemory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> shotsRefs(
    Expression<bool> Function($$ShotsTableFilterComposer f) f,
  ) {
    final $$ShotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shots,
      getReferencedColumn: (t) => t.grinderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShotsTableFilterComposer(
            $db: $db,
            $table: $db.shots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GrindersTableOrderingComposer
    extends Composer<_$AppDatabase, $GrindersTable> {
  $$GrindersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get settingType => $composableBuilder(
    column: $table.settingType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GrindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $GrindersTable> {
  $$GrindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<String> get settingType => $composableBuilder(
    column: $table.settingType,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  Expression<T> grindMemoryRefs<T extends Object>(
    Expression<T> Function($$GrindMemoryTableAnnotationComposer a) f,
  ) {
    final $$GrindMemoryTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.grindMemory,
      getReferencedColumn: (t) => t.grinderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GrindMemoryTableAnnotationComposer(
            $db: $db,
            $table: $db.grindMemory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> shotsRefs<T extends Object>(
    Expression<T> Function($$ShotsTableAnnotationComposer a) f,
  ) {
    final $$ShotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shots,
      getReferencedColumn: (t) => t.grinderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShotsTableAnnotationComposer(
            $db: $db,
            $table: $db.shots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GrindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GrindersTable,
          Grinder,
          $$GrindersTableFilterComposer,
          $$GrindersTableOrderingComposer,
          $$GrindersTableAnnotationComposer,
          $$GrindersTableCreateCompanionBuilder,
          $$GrindersTableUpdateCompanionBuilder,
          (Grinder, $$GrindersTableReferences),
          Grinder,
          PrefetchHooks Function({bool grindMemoryRefs, bool shotsRefs})
        > {
  $$GrindersTableTableManager(_$AppDatabase db, $GrindersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GrindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GrindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GrindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> brand = const Value.absent(),
                Value<String> settingType = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GrindersCompanion(
                id: id,
                name: name,
                brand: brand,
                settingType: settingType,
                archived: archived,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String brand,
                required String settingType,
                Value<bool> archived = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GrindersCompanion.insert(
                id: id,
                name: name,
                brand: brand,
                settingType: settingType,
                archived: archived,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GrindersTable, Grinder>(table),
                  $$GrindersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({grindMemoryRefs = false, shotsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (grindMemoryRefs) db.grindMemory,
                    if (shotsRefs) db.shots,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (grindMemoryRefs)
                        await $_getPrefetchedDataByColumns<
                          Grinder,
                          $GrindersTable,
                          GrindMemoryData,
                          $GrindMemoryTable
                        >(
                          currentTable: table,
                          referencedTable: $$GrindersTableReferences
                              ._grindMemoryRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GrindersTableReferences(
                                db,
                                table,
                                p0,
                              ).grindMemoryRefs,
                          currentColumn: 'id',
                          referencedColumn: 'grinder_id',
                          typedResults: items,
                        ),
                      if (shotsRefs)
                        await $_getPrefetchedDataByColumns<
                          Grinder,
                          $GrindersTable,
                          Shot,
                          $ShotsTable
                        >(
                          currentTable: table,
                          referencedTable: $$GrindersTableReferences
                              ._shotsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GrindersTableReferences(
                                db,
                                table,
                                p0,
                              ).shotsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'grinder_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$GrindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GrindersTable,
      Grinder,
      $$GrindersTableFilterComposer,
      $$GrindersTableOrderingComposer,
      $$GrindersTableAnnotationComposer,
      $$GrindersTableCreateCompanionBuilder,
      $$GrindersTableUpdateCompanionBuilder,
      (Grinder, $$GrindersTableReferences),
      Grinder,
      PrefetchHooks Function({bool grindMemoryRefs, bool shotsRefs})
    >;
typedef $$GrindMemoryTableCreateCompanionBuilder =
    GrindMemoryCompanion Function({
      required String grinderId,
      required String beanKey,
      required String setting,
      required int lastUsedAt,
      Value<int> rowid,
    });
typedef $$GrindMemoryTableUpdateCompanionBuilder =
    GrindMemoryCompanion Function({
      Value<String> grinderId,
      Value<String> beanKey,
      Value<String> setting,
      Value<int> lastUsedAt,
      Value<int> rowid,
    });

final class $$GrindMemoryTableReferences
    extends BaseReferences<_$AppDatabase, $GrindMemoryTable, GrindMemoryData> {
  $$GrindMemoryTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GrindersTable _grinderIdTable(_$AppDatabase db) =>
      db.grinders.createAlias('grind_memory__grinder_id__grinders__id');

  $$GrindersTableProcessedTableManager get grinderId {
    final $_column = $_itemColumn<String>('grinder_id')!;

    final manager = $$GrindersTableTableManager(
      $_db,
      $_db.grinders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_grinderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$GrindMemoryTableFilterComposer
    extends Composer<_$AppDatabase, $GrindMemoryTable> {
  $$GrindMemoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get beanKey => $composableBuilder(
    column: $table.beanKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get setting => $composableBuilder(
    column: $table.setting,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$GrindersTableFilterComposer get grinderId {
    final $$GrindersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.grinderId,
      referencedTable: $db.grinders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GrindersTableFilterComposer(
            $db: $db,
            $table: $db.grinders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GrindMemoryTableOrderingComposer
    extends Composer<_$AppDatabase, $GrindMemoryTable> {
  $$GrindMemoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get beanKey => $composableBuilder(
    column: $table.beanKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get setting => $composableBuilder(
    column: $table.setting,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$GrindersTableOrderingComposer get grinderId {
    final $$GrindersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.grinderId,
      referencedTable: $db.grinders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GrindersTableOrderingComposer(
            $db: $db,
            $table: $db.grinders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GrindMemoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $GrindMemoryTable> {
  $$GrindMemoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get beanKey =>
      $composableBuilder(column: $table.beanKey, builder: (column) => column);

  GeneratedColumn<String> get setting =>
      $composableBuilder(column: $table.setting, builder: (column) => column);

  GeneratedColumn<int> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => column,
  );

  $$GrindersTableAnnotationComposer get grinderId {
    final $$GrindersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.grinderId,
      referencedTable: $db.grinders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GrindersTableAnnotationComposer(
            $db: $db,
            $table: $db.grinders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GrindMemoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GrindMemoryTable,
          GrindMemoryData,
          $$GrindMemoryTableFilterComposer,
          $$GrindMemoryTableOrderingComposer,
          $$GrindMemoryTableAnnotationComposer,
          $$GrindMemoryTableCreateCompanionBuilder,
          $$GrindMemoryTableUpdateCompanionBuilder,
          (GrindMemoryData, $$GrindMemoryTableReferences),
          GrindMemoryData,
          PrefetchHooks Function({bool grinderId})
        > {
  $$GrindMemoryTableTableManager(_$AppDatabase db, $GrindMemoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GrindMemoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GrindMemoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GrindMemoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> grinderId = const Value.absent(),
                Value<String> beanKey = const Value.absent(),
                Value<String> setting = const Value.absent(),
                Value<int> lastUsedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GrindMemoryCompanion(
                grinderId: grinderId,
                beanKey: beanKey,
                setting: setting,
                lastUsedAt: lastUsedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String grinderId,
                required String beanKey,
                required String setting,
                required int lastUsedAt,
                Value<int> rowid = const Value.absent(),
              }) => GrindMemoryCompanion.insert(
                grinderId: grinderId,
                beanKey: beanKey,
                setting: setting,
                lastUsedAt: lastUsedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GrindMemoryTable, GrindMemoryData>(table),
                  $$GrindMemoryTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({grinderId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (grinderId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.grinderId,
                                referencedTable: $$GrindMemoryTableReferences
                                    ._grinderIdTable(db),
                                referencedColumn: $$GrindMemoryTableReferences
                                    ._grinderIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$GrindMemoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GrindMemoryTable,
      GrindMemoryData,
      $$GrindMemoryTableFilterComposer,
      $$GrindMemoryTableOrderingComposer,
      $$GrindMemoryTableAnnotationComposer,
      $$GrindMemoryTableCreateCompanionBuilder,
      $$GrindMemoryTableUpdateCompanionBuilder,
      (GrindMemoryData, $$GrindMemoryTableReferences),
      GrindMemoryData,
      PrefetchHooks Function({bool grinderId})
    >;
typedef $$ShotsTableCreateCompanionBuilder =
    ShotsCompanion Function({
      required String id,
      required DateTime recordedAt,
      Value<String?> beanId,
      Value<String?> grinderId,
      Value<String?> grindSetting,
      Value<double?> doseGrams,
      Value<double?> finalWeight,
      required int durationMillis,
      required String snapshotJson,
      Value<int> rowid,
    });
typedef $$ShotsTableUpdateCompanionBuilder =
    ShotsCompanion Function({
      Value<String> id,
      Value<DateTime> recordedAt,
      Value<String?> beanId,
      Value<String?> grinderId,
      Value<String?> grindSetting,
      Value<double?> doseGrams,
      Value<double?> finalWeight,
      Value<int> durationMillis,
      Value<String> snapshotJson,
      Value<int> rowid,
    });

final class $$ShotsTableReferences
    extends BaseReferences<_$AppDatabase, $ShotsTable, Shot> {
  $$ShotsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BeansTable _beanIdTable(_$AppDatabase db) =>
      db.beans.createAlias('shots__bean_id__beans__id');

  $$BeansTableProcessedTableManager? get beanId {
    final $_column = $_itemColumn<String>('bean_id');
    if ($_column == null) return null;
    final manager = $$BeansTableTableManager(
      $_db,
      $_db.beans,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_beanIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $GrindersTable _grinderIdTable(_$AppDatabase db) =>
      db.grinders.createAlias('shots__grinder_id__grinders__id');

  $$GrindersTableProcessedTableManager? get grinderId {
    final $_column = $_itemColumn<String>('grinder_id');
    if ($_column == null) return null;
    final manager = $$GrindersTableTableManager(
      $_db,
      $_db.grinders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_grinderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ShotsTableFilterComposer extends Composer<_$AppDatabase, $ShotsTable> {
  $$ShotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get grindSetting => $composableBuilder(
    column: $table.grindSetting,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get doseGrams => $composableBuilder(
    column: $table.doseGrams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get finalWeight => $composableBuilder(
    column: $table.finalWeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMillis => $composableBuilder(
    column: $table.durationMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get snapshotJson => $composableBuilder(
    column: $table.snapshotJson,
    builder: (column) => ColumnFilters(column),
  );

  $$BeansTableFilterComposer get beanId {
    final $$BeansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.beanId,
      referencedTable: $db.beans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BeansTableFilterComposer(
            $db: $db,
            $table: $db.beans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GrindersTableFilterComposer get grinderId {
    final $$GrindersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.grinderId,
      referencedTable: $db.grinders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GrindersTableFilterComposer(
            $db: $db,
            $table: $db.grinders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShotsTableOrderingComposer
    extends Composer<_$AppDatabase, $ShotsTable> {
  $$ShotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get grindSetting => $composableBuilder(
    column: $table.grindSetting,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get doseGrams => $composableBuilder(
    column: $table.doseGrams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get finalWeight => $composableBuilder(
    column: $table.finalWeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMillis => $composableBuilder(
    column: $table.durationMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get snapshotJson => $composableBuilder(
    column: $table.snapshotJson,
    builder: (column) => ColumnOrderings(column),
  );

  $$BeansTableOrderingComposer get beanId {
    final $$BeansTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.beanId,
      referencedTable: $db.beans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BeansTableOrderingComposer(
            $db: $db,
            $table: $db.beans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GrindersTableOrderingComposer get grinderId {
    final $$GrindersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.grinderId,
      referencedTable: $db.grinders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GrindersTableOrderingComposer(
            $db: $db,
            $table: $db.grinders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShotsTable> {
  $$ShotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get grindSetting => $composableBuilder(
    column: $table.grindSetting,
    builder: (column) => column,
  );

  GeneratedColumn<double> get doseGrams =>
      $composableBuilder(column: $table.doseGrams, builder: (column) => column);

  GeneratedColumn<double> get finalWeight => $composableBuilder(
    column: $table.finalWeight,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMillis => $composableBuilder(
    column: $table.durationMillis,
    builder: (column) => column,
  );

  GeneratedColumn<String> get snapshotJson => $composableBuilder(
    column: $table.snapshotJson,
    builder: (column) => column,
  );

  $$BeansTableAnnotationComposer get beanId {
    final $$BeansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.beanId,
      referencedTable: $db.beans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BeansTableAnnotationComposer(
            $db: $db,
            $table: $db.beans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GrindersTableAnnotationComposer get grinderId {
    final $$GrindersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.grinderId,
      referencedTable: $db.grinders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GrindersTableAnnotationComposer(
            $db: $db,
            $table: $db.grinders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShotsTable,
          Shot,
          $$ShotsTableFilterComposer,
          $$ShotsTableOrderingComposer,
          $$ShotsTableAnnotationComposer,
          $$ShotsTableCreateCompanionBuilder,
          $$ShotsTableUpdateCompanionBuilder,
          (Shot, $$ShotsTableReferences),
          Shot,
          PrefetchHooks Function({bool beanId, bool grinderId})
        > {
  $$ShotsTableTableManager(_$AppDatabase db, $ShotsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<String?> beanId = const Value.absent(),
                Value<String?> grinderId = const Value.absent(),
                Value<String?> grindSetting = const Value.absent(),
                Value<double?> doseGrams = const Value.absent(),
                Value<double?> finalWeight = const Value.absent(),
                Value<int> durationMillis = const Value.absent(),
                Value<String> snapshotJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShotsCompanion(
                id: id,
                recordedAt: recordedAt,
                beanId: beanId,
                grinderId: grinderId,
                grindSetting: grindSetting,
                doseGrams: doseGrams,
                finalWeight: finalWeight,
                durationMillis: durationMillis,
                snapshotJson: snapshotJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime recordedAt,
                Value<String?> beanId = const Value.absent(),
                Value<String?> grinderId = const Value.absent(),
                Value<String?> grindSetting = const Value.absent(),
                Value<double?> doseGrams = const Value.absent(),
                Value<double?> finalWeight = const Value.absent(),
                required int durationMillis,
                required String snapshotJson,
                Value<int> rowid = const Value.absent(),
              }) => ShotsCompanion.insert(
                id: id,
                recordedAt: recordedAt,
                beanId: beanId,
                grinderId: grinderId,
                grindSetting: grindSetting,
                doseGrams: doseGrams,
                finalWeight: finalWeight,
                durationMillis: durationMillis,
                snapshotJson: snapshotJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ShotsTable, Shot>(table),
                  $$ShotsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({beanId = false, grinderId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (beanId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.beanId,
                                referencedTable: $$ShotsTableReferences
                                    ._beanIdTable(db),
                                referencedColumn: $$ShotsTableReferences
                                    ._beanIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (grinderId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.grinderId,
                                referencedTable: $$ShotsTableReferences
                                    ._grinderIdTable(db),
                                referencedColumn: $$ShotsTableReferences
                                    ._grinderIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ShotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShotsTable,
      Shot,
      $$ShotsTableFilterComposer,
      $$ShotsTableOrderingComposer,
      $$ShotsTableAnnotationComposer,
      $$ShotsTableCreateCompanionBuilder,
      $$ShotsTableUpdateCompanionBuilder,
      (Shot, $$ShotsTableReferences),
      Shot,
      PrefetchHooks Function({bool beanId, bool grinderId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BeansTableTableManager get beans =>
      $$BeansTableTableManager(_db, _db.beans);
  $$GrindersTableTableManager get grinders =>
      $$GrindersTableTableManager(_db, _db.grinders);
  $$GrindMemoryTableTableManager get grindMemory =>
      $$GrindMemoryTableTableManager(_db, _db.grindMemory);
  $$ShotsTableTableManager get shots =>
      $$ShotsTableTableManager(_db, _db.shots);
}
