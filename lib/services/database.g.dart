// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $DailyNotesTable extends DailyNotes
    with TableInfo<$DailyNotesTable, DailyNote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyNotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _moodMeta = const VerificationMeta('mood');
  @override
  late final GeneratedColumn<String> mood = GeneratedColumn<String>(
    'mood',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, date, content, mood, timestamp];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyNote> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('mood')) {
      context.handle(
        _moodMeta,
        mood.isAcceptableOrUnknown(data['mood']!, _moodMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DailyNote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyNote(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      mood: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mood'],
      ),
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  @override
  $DailyNotesTable createAlias(String alias) {
    return $DailyNotesTable(attachedDatabase, alias);
  }
}

class DailyNote extends DataClass implements Insertable<DailyNote> {
  final int id;
  final String date;
  final String content;
  final String? mood;
  final int timestamp;
  const DailyNote({
    required this.id,
    required this.date,
    required this.content,
    this.mood,
    required this.timestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<String>(date);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || mood != null) {
      map['mood'] = Variable<String>(mood);
    }
    map['timestamp'] = Variable<int>(timestamp);
    return map;
  }

  DailyNotesCompanion toCompanion(bool nullToAbsent) {
    return DailyNotesCompanion(
      id: Value(id),
      date: Value(date),
      content: Value(content),
      mood: mood == null && nullToAbsent ? const Value.absent() : Value(mood),
      timestamp: Value(timestamp),
    );
  }

  factory DailyNote.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyNote(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      content: serializer.fromJson<String>(json['content']),
      mood: serializer.fromJson<String?>(json['mood']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<String>(date),
      'content': serializer.toJson<String>(content),
      'mood': serializer.toJson<String?>(mood),
      'timestamp': serializer.toJson<int>(timestamp),
    };
  }

  DailyNote copyWith({
    int? id,
    String? date,
    String? content,
    Value<String?> mood = const Value.absent(),
    int? timestamp,
  }) => DailyNote(
    id: id ?? this.id,
    date: date ?? this.date,
    content: content ?? this.content,
    mood: mood.present ? mood.value : this.mood,
    timestamp: timestamp ?? this.timestamp,
  );
  DailyNote copyWithCompanion(DailyNotesCompanion data) {
    return DailyNote(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      content: data.content.present ? data.content.value : this.content,
      mood: data.mood.present ? data.mood.value : this.mood,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyNote(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('content: $content, ')
          ..write('mood: $mood, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, content, mood, timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyNote &&
          other.id == this.id &&
          other.date == this.date &&
          other.content == this.content &&
          other.mood == this.mood &&
          other.timestamp == this.timestamp);
}

class DailyNotesCompanion extends UpdateCompanion<DailyNote> {
  final Value<int> id;
  final Value<String> date;
  final Value<String> content;
  final Value<String?> mood;
  final Value<int> timestamp;
  const DailyNotesCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.content = const Value.absent(),
    this.mood = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  DailyNotesCompanion.insert({
    this.id = const Value.absent(),
    required String date,
    required String content,
    this.mood = const Value.absent(),
    required int timestamp,
  }) : date = Value(date),
       content = Value(content),
       timestamp = Value(timestamp);
  static Insertable<DailyNote> custom({
    Expression<int>? id,
    Expression<String>? date,
    Expression<String>? content,
    Expression<String>? mood,
    Expression<int>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (content != null) 'content': content,
      if (mood != null) 'mood': mood,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  DailyNotesCompanion copyWith({
    Value<int>? id,
    Value<String>? date,
    Value<String>? content,
    Value<String?>? mood,
    Value<int>? timestamp,
  }) {
    return DailyNotesCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (mood.present) {
      map['mood'] = Variable<String>(mood.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyNotesCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('content: $content, ')
          ..write('mood: $mood, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

class $RawLogsTable extends RawLogs with TableInfo<$RawLogsTable, RawLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RawLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, date, type, data, timestamp];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'raw_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<RawLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RawLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RawLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  @override
  $RawLogsTable createAlias(String alias) {
    return $RawLogsTable(attachedDatabase, alias);
  }
}

class RawLog extends DataClass implements Insertable<RawLog> {
  final int id;
  final String date;
  final String type;
  final String data;
  final int timestamp;
  const RawLog({
    required this.id,
    required this.date,
    required this.type,
    required this.data,
    required this.timestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<String>(date);
    map['type'] = Variable<String>(type);
    map['data'] = Variable<String>(data);
    map['timestamp'] = Variable<int>(timestamp);
    return map;
  }

  RawLogsCompanion toCompanion(bool nullToAbsent) {
    return RawLogsCompanion(
      id: Value(id),
      date: Value(date),
      type: Value(type),
      data: Value(data),
      timestamp: Value(timestamp),
    );
  }

  factory RawLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RawLog(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      type: serializer.fromJson<String>(json['type']),
      data: serializer.fromJson<String>(json['data']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<String>(date),
      'type': serializer.toJson<String>(type),
      'data': serializer.toJson<String>(data),
      'timestamp': serializer.toJson<int>(timestamp),
    };
  }

  RawLog copyWith({
    int? id,
    String? date,
    String? type,
    String? data,
    int? timestamp,
  }) => RawLog(
    id: id ?? this.id,
    date: date ?? this.date,
    type: type ?? this.type,
    data: data ?? this.data,
    timestamp: timestamp ?? this.timestamp,
  );
  RawLog copyWithCompanion(RawLogsCompanion data) {
    return RawLog(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      type: data.type.present ? data.type.value : this.type,
      data: data.data.present ? data.data.value : this.data,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RawLog(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('type: $type, ')
          ..write('data: $data, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, type, data, timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RawLog &&
          other.id == this.id &&
          other.date == this.date &&
          other.type == this.type &&
          other.data == this.data &&
          other.timestamp == this.timestamp);
}

class RawLogsCompanion extends UpdateCompanion<RawLog> {
  final Value<int> id;
  final Value<String> date;
  final Value<String> type;
  final Value<String> data;
  final Value<int> timestamp;
  const RawLogsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.type = const Value.absent(),
    this.data = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  RawLogsCompanion.insert({
    this.id = const Value.absent(),
    required String date,
    required String type,
    required String data,
    required int timestamp,
  }) : date = Value(date),
       type = Value(type),
       data = Value(data),
       timestamp = Value(timestamp);
  static Insertable<RawLog> custom({
    Expression<int>? id,
    Expression<String>? date,
    Expression<String>? type,
    Expression<String>? data,
    Expression<int>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (type != null) 'type': type,
      if (data != null) 'data': data,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  RawLogsCompanion copyWith({
    Value<int>? id,
    Value<String>? date,
    Value<String>? type,
    Value<String>? data,
    Value<int>? timestamp,
  }) {
    return RawLogsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      type: type ?? this.type,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RawLogsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('type: $type, ')
          ..write('data: $data, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

class $AppMetadataTable extends AppMetadata
    with TableInfo<$AppMetadataTable, AppMetadataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppMetadataData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppMetadataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppMetadataData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppMetadataTable createAlias(String alias) {
    return $AppMetadataTable(attachedDatabase, alias);
  }
}

class AppMetadataData extends DataClass implements Insertable<AppMetadataData> {
  final String key;
  final String value;
  const AppMetadataData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppMetadataCompanion toCompanion(bool nullToAbsent) {
    return AppMetadataCompanion(key: Value(key), value: Value(value));
  }

  factory AppMetadataData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppMetadataData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppMetadataData copyWith({String? key, String? value}) =>
      AppMetadataData(key: key ?? this.key, value: value ?? this.value);
  AppMetadataData copyWithCompanion(AppMetadataCompanion data) {
    return AppMetadataData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppMetadataData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppMetadataData &&
          other.key == this.key &&
          other.value == this.value);
}

class AppMetadataCompanion extends UpdateCompanion<AppMetadataData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppMetadataCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppMetadataCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppMetadataData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppMetadataCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppMetadataCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppMetadataCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DailyNotesTable dailyNotes = $DailyNotesTable(this);
  late final $RawLogsTable rawLogs = $RawLogsTable(this);
  late final $AppMetadataTable appMetadata = $AppMetadataTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    dailyNotes,
    rawLogs,
    appMetadata,
  ];
}

typedef $$DailyNotesTableCreateCompanionBuilder =
    DailyNotesCompanion Function({
      Value<int> id,
      required String date,
      required String content,
      Value<String?> mood,
      required int timestamp,
    });
typedef $$DailyNotesTableUpdateCompanionBuilder =
    DailyNotesCompanion Function({
      Value<int> id,
      Value<String> date,
      Value<String> content,
      Value<String?> mood,
      Value<int> timestamp,
    });

class $$DailyNotesTableFilterComposer
    extends Composer<_$AppDatabase, $DailyNotesTable> {
  $$DailyNotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyNotesTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyNotesTable> {
  $$DailyNotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyNotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyNotesTable> {
  $$DailyNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get mood =>
      $composableBuilder(column: $table.mood, builder: (column) => column);

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);
}

class $$DailyNotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyNotesTable,
          DailyNote,
          $$DailyNotesTableFilterComposer,
          $$DailyNotesTableOrderingComposer,
          $$DailyNotesTableAnnotationComposer,
          $$DailyNotesTableCreateCompanionBuilder,
          $$DailyNotesTableUpdateCompanionBuilder,
          (
            DailyNote,
            BaseReferences<_$AppDatabase, $DailyNotesTable, DailyNote>,
          ),
          DailyNote,
          PrefetchHooks Function()
        > {
  $$DailyNotesTableTableManager(_$AppDatabase db, $DailyNotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> mood = const Value.absent(),
                Value<int> timestamp = const Value.absent(),
              }) => DailyNotesCompanion(
                id: id,
                date: date,
                content: content,
                mood: mood,
                timestamp: timestamp,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String date,
                required String content,
                Value<String?> mood = const Value.absent(),
                required int timestamp,
              }) => DailyNotesCompanion.insert(
                id: id,
                date: date,
                content: content,
                mood: mood,
                timestamp: timestamp,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyNotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyNotesTable,
      DailyNote,
      $$DailyNotesTableFilterComposer,
      $$DailyNotesTableOrderingComposer,
      $$DailyNotesTableAnnotationComposer,
      $$DailyNotesTableCreateCompanionBuilder,
      $$DailyNotesTableUpdateCompanionBuilder,
      (DailyNote, BaseReferences<_$AppDatabase, $DailyNotesTable, DailyNote>),
      DailyNote,
      PrefetchHooks Function()
    >;
typedef $$RawLogsTableCreateCompanionBuilder =
    RawLogsCompanion Function({
      Value<int> id,
      required String date,
      required String type,
      required String data,
      required int timestamp,
    });
typedef $$RawLogsTableUpdateCompanionBuilder =
    RawLogsCompanion Function({
      Value<int> id,
      Value<String> date,
      Value<String> type,
      Value<String> data,
      Value<int> timestamp,
    });

class $$RawLogsTableFilterComposer
    extends Composer<_$AppDatabase, $RawLogsTable> {
  $$RawLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RawLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $RawLogsTable> {
  $$RawLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RawLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RawLogsTable> {
  $$RawLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);
}

class $$RawLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RawLogsTable,
          RawLog,
          $$RawLogsTableFilterComposer,
          $$RawLogsTableOrderingComposer,
          $$RawLogsTableAnnotationComposer,
          $$RawLogsTableCreateCompanionBuilder,
          $$RawLogsTableUpdateCompanionBuilder,
          (RawLog, BaseReferences<_$AppDatabase, $RawLogsTable, RawLog>),
          RawLog,
          PrefetchHooks Function()
        > {
  $$RawLogsTableTableManager(_$AppDatabase db, $RawLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RawLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RawLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RawLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> data = const Value.absent(),
                Value<int> timestamp = const Value.absent(),
              }) => RawLogsCompanion(
                id: id,
                date: date,
                type: type,
                data: data,
                timestamp: timestamp,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String date,
                required String type,
                required String data,
                required int timestamp,
              }) => RawLogsCompanion.insert(
                id: id,
                date: date,
                type: type,
                data: data,
                timestamp: timestamp,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RawLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RawLogsTable,
      RawLog,
      $$RawLogsTableFilterComposer,
      $$RawLogsTableOrderingComposer,
      $$RawLogsTableAnnotationComposer,
      $$RawLogsTableCreateCompanionBuilder,
      $$RawLogsTableUpdateCompanionBuilder,
      (RawLog, BaseReferences<_$AppDatabase, $RawLogsTable, RawLog>),
      RawLog,
      PrefetchHooks Function()
    >;
typedef $$AppMetadataTableCreateCompanionBuilder =
    AppMetadataCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppMetadataTableUpdateCompanionBuilder =
    AppMetadataCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppMetadataTableFilterComposer
    extends Composer<_$AppDatabase, $AppMetadataTable> {
  $$AppMetadataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppMetadataTableOrderingComposer
    extends Composer<_$AppDatabase, $AppMetadataTable> {
  $$AppMetadataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppMetadataTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppMetadataTable> {
  $$AppMetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppMetadataTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppMetadataTable,
          AppMetadataData,
          $$AppMetadataTableFilterComposer,
          $$AppMetadataTableOrderingComposer,
          $$AppMetadataTableAnnotationComposer,
          $$AppMetadataTableCreateCompanionBuilder,
          $$AppMetadataTableUpdateCompanionBuilder,
          (
            AppMetadataData,
            BaseReferences<_$AppDatabase, $AppMetadataTable, AppMetadataData>,
          ),
          AppMetadataData,
          PrefetchHooks Function()
        > {
  $$AppMetadataTableTableManager(_$AppDatabase db, $AppMetadataTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppMetadataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppMetadataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppMetadataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppMetadataCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppMetadataCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppMetadataTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppMetadataTable,
      AppMetadataData,
      $$AppMetadataTableFilterComposer,
      $$AppMetadataTableOrderingComposer,
      $$AppMetadataTableAnnotationComposer,
      $$AppMetadataTableCreateCompanionBuilder,
      $$AppMetadataTableUpdateCompanionBuilder,
      (
        AppMetadataData,
        BaseReferences<_$AppDatabase, $AppMetadataTable, AppMetadataData>,
      ),
      AppMetadataData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DailyNotesTableTableManager get dailyNotes =>
      $$DailyNotesTableTableManager(_db, _db.dailyNotes);
  $$RawLogsTableTableManager get rawLogs =>
      $$RawLogsTableTableManager(_db, _db.rawLogs);
  $$AppMetadataTableTableManager get appMetadata =>
      $$AppMetadataTableTableManager(_db, _db.appMetadata);
}
