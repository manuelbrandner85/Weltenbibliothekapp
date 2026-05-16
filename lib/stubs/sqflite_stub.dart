// Web-Stub für sqflite (Android/iOS/macOS only).
// Alle Klassen und Funktionen sind No-Ops für den Web-Build.

enum ConflictAlgorithm { rollback, abort, fail, ignore, replace }

class Database {
  Future<void> execute(String sql, [List<Object?>? arguments]) async {}

  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async =>
      0;

  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async =>
      [];

  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async =>
      0;

  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) async =>
      0;

  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async =>
      [];

  Future<int> rawDelete(String sql, [List<Object?>? arguments]) async => 0;

  Future<int> rawInsert(String sql, [List<Object?>? arguments]) async => 0;

  Future<void> close() async {}
}

Future<String> getDatabasesPath() async => '/web-noop';

Future<Database> openDatabase(
  String path, {
  int? version,
  Future<void> Function(Database db, int version)? onCreate,
  Future<void> Function(Database db, int oldVersion, int newVersion)? onUpgrade,
  Future<void> Function(Database db, int version)? onOpen,
  bool? readOnly,
  bool? singleInstance,
}) async {
  final db = Database();
  if (onCreate != null && version != null) {
    await onCreate(db, version);
  }
  return db;
}
