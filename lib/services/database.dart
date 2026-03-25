import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'dart:io';

part 'database.g.dart';

class DailyNotes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get date => text()();
  TextColumn get content => text()();
  TextColumn get mood => text().nullable()();
  IntColumn get timestamp => integer()();
}

class RawLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get date => text()();
  TextColumn get type => text()();
  TextColumn get data => text()(); // JSON string
  IntColumn get timestamp => integer()();
}

class AppMetadata extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [DailyNotes, RawLogs, AppMetadata])
class AppDatabase extends _$AppDatabase {
  AppDatabase._internal(super.e);

  static AppDatabase? _instance;

  static Future<AppDatabase> getInstance() async {
    if (_instance != null) return _instance!;
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'life_companion.db'));
    _instance = AppDatabase._internal(NativeDatabase.createInBackground(file));
    return _instance!;
  }

  @override
  int get schemaVersion => 1;

  // --- Daily Notes ---

  Future<List<DailyNote>> getAllNotes() async {
    return (select(dailyNotes)
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
        .get();
  }

  Future<List<DailyNote>> getNotesForDate(String dateStr) async {
    return (select(dailyNotes)..where((t) => t.date.equals(dateStr))).get();
  }

  Future<List<DailyNote>> getRecentNotes({int limit = 3}) async {
    return (select(dailyNotes)
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
          ..limit(limit))
        .get();
  }

  Future<List<String>> getNoteDates() async {
    final rows = await (selectOnly(dailyNotes, distinct: true)
          ..addColumns([dailyNotes.date]))
        .get();
    return rows.map((r) => r.read(dailyNotes.date)!).toList();
  }

  Future<int> addNote({
    required String date,
    required String content,
    String? mood,
    required int timestamp,
  }) {
    return into(dailyNotes).insert(DailyNotesCompanion.insert(
      date: date,
      content: content,
      mood: Value(mood),
      timestamp: timestamp,
    ));
  }

  Future<void> deleteNote(int id) async {
    await (delete(dailyNotes)..where((t) => t.id.equals(id))).go();
  }

  Stream<List<DailyNote>> watchAllNotes() {
    return (select(dailyNotes)
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
        .watch();
  }

  Stream<List<DailyNote>> watchRecentNotes({int limit = 3}) {
    return (select(dailyNotes)
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
          ..limit(limit))
        .watch();
  }

  Stream<List<String>> watchNoteDates() {
    return (selectOnly(dailyNotes, distinct: true)
          ..addColumns([dailyNotes.date]))
        .watch()
        .map((rows) => rows.map((r) => r.read(dailyNotes.date)!).toList());
  }

  // --- Raw Logs ---

  Future<List<RawLog>> getLogsForDate(String dateStr) async {
    return (select(rawLogs)..where((t) => t.date.equals(dateStr))).get();
  }

  Future<bool> hasLogForDateAndType(String dateStr, String logType) async {
    final count = await (selectOnly(rawLogs)
          ..addColumns([rawLogs.id.count()])
          ..where(
              rawLogs.date.equals(dateStr) & rawLogs.type.equals(logType)))
        .getSingle();
    return (count.read(rawLogs.id.count()) ?? 0) > 0;
  }

  Future<int> addLog({
    required String date,
    required String type,
    required Map<String, dynamic> data,
    required int timestamp,
  }) {
    return into(rawLogs).insert(RawLogsCompanion.insert(
      date: date,
      type: type,
      data: jsonEncode(data),
      timestamp: timestamp,
    ));
  }

  Stream<List<RawLog>> watchLogsForDate(String dateStr) {
    return (select(rawLogs)..where((t) => t.date.equals(dateStr))).watch();
  }

  // --- Metadata ---

  Future<String?> getMetadata(String key) async {
    final row = await (select(appMetadata)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setMetadata(String key, String value) async {
    await into(appMetadata).insertOnConflictUpdate(
      AppMetadataCompanion.insert(key: key, value: value),
    );
  }
}

/// Helper to parse RawLog.data as JSON map
Map<String, dynamic> parseLogData(RawLog log) {
  try {
    return jsonDecode(log.data) as Map<String, dynamic>;
  } catch (_) {
    return {};
  }
}
