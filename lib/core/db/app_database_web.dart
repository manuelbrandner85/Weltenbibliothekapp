// Web-Stub für AppDatabase — sqflite läuft nicht auf Web.
// Alle Datenbankoperationen sind No-Ops. Web-User nutzen keine
// Offline-Sync-Features, daher ist das sicher.

import '../../../stubs/sqflite_stub.dart';

class _WebDatabase {
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

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  final _WebDatabase _db = _WebDatabase();

  Future<_WebDatabase> get db async => _db;

  Future<void> close() async {}
}
