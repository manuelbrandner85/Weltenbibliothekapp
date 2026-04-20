import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite-basierter Key-Value-Store als Hive-Ersatz.
/// Tabelle: kv_store (box TEXT, key TEXT, value TEXT, PRIMARY KEY (box, key))
class SqliteStorageService {
  SqliteStorageService._();
  static final instance = SqliteStorageService._();

  Database? _db;

  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, 'weltenbibliothek.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE kv_store (
            box TEXT NOT NULL,
            key TEXT NOT NULL,
            value TEXT,
            PRIMARY KEY (box, key)
          )
        ''');
      },
    );
  }

  Database get _database {
    assert(_db != null, 'SqliteStorageService.init() must be called first');
    return _db!;
  }

  Future<dynamic> get(String box, String key) async {
    final rows = await _database.query(
      'kv_store',
      where: 'box = ? AND key = ?',
      whereArgs: [box, key],
    );
    if (rows.isEmpty) return null;
    final raw = rows.first['value'] as String?;
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return raw;
    }
  }

  Future<void> put(String box, String key, dynamic value) async {
    await _database.insert(
      'kv_store',
      {'box': box, 'key': key, 'value': jsonEncode(value)},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String box, String key) async {
    await _database.delete(
      'kv_store',
      where: 'box = ? AND key = ?',
      whereArgs: [box, key],
    );
  }

  Future<List<dynamic>> getAll(String box) async {
    final rows = await _database.query(
      'kv_store',
      where: 'box = ?',
      whereArgs: [box],
    );
    return rows
        .map((r) {
          final raw = r['value'] as String?;
          if (raw == null) return null;
          try {
            return jsonDecode(raw);
          } catch (_) {
            return raw;
          }
        })
        .whereType<dynamic>()
        .toList();
  }

  Future<Map<String, dynamic>> getAllWithKeys(String box) async {
    final rows = await _database.query(
      'kv_store',
      where: 'box = ?',
      whereArgs: [box],
    );
    final result = <String, dynamic>{};
    for (final r in rows) {
      final k = r['key'] as String;
      final raw = r['value'] as String?;
      if (raw != null) {
        try {
          result[k] = jsonDecode(raw);
        } catch (_) {
          result[k] = raw;
        }
      }
    }
    return result;
  }

  Future<void> clear(String box) async {
    await _database.delete('kv_store', where: 'box = ?', whereArgs: [box]);
  }

  Future<bool> containsKey(String box, String key) async {
    final rows = await _database.query(
      'kv_store',
      where: 'box = ? AND key = ?',
      whereArgs: [box, key],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<int> count(String box) async {
    final result = await _database.rawQuery(
      'SELECT COUNT(*) as c FROM kv_store WHERE box = ?',
      [box],
    );
    return (result.first['c'] as int?) ?? 0;
  }

  /// Gibt alle Schlüssel einer Box zurück.
  Future<List<String>> getKeys(String box) async {
    final rows = await _database.query(
      'kv_store',
      columns: ['key'],
      where: 'box = ?',
      whereArgs: [box],
    );
    return rows.map((r) => r['key'] as String).toList();
  }
}
