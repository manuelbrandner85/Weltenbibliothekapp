import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite-basierter Key-Value-Store als Hive-Ersatz.
///
/// Tabelle kv_store: box TEXT, key TEXT, value TEXT (JSON), PRIMARY KEY (box, key)
///
/// Hält zusätzlich einen In-Memory-Cache, damit synchrone Lesezugriffe
/// (getSync / getAllSync / containsKeySync) ohne await funktionieren —
/// identisches Verhalten zum alten Hive-API.
class SqliteStorageService {
  SqliteStorageService._();
  static final instance = SqliteStorageService._();

  Database? _db;

  // Cache: '$box\x00$key' → decoded value (beliebiger Dart-Typ)
  final Map<String, dynamic> _cache = {};

  String _ck(String box, String key) => '$box\x00$key';

  // ── Init ────────────────────────────────────────────────────────────────────

  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, 'weltenbibliothek.db'),
      version: 1,
      onCreate: (db, v) => db.execute('''
        CREATE TABLE kv_store (
          box  TEXT NOT NULL,
          key  TEXT NOT NULL,
          value TEXT,
          PRIMARY KEY (box, key)
        )
      '''),
    );
    await _loadCache();
  }

  Future<void> _loadCache() async {
    final rows = await _db!.query('kv_store');
    _cache.clear();
    for (final r in rows) {
      final raw = r['value'] as String?;
      if (raw == null) continue;
      try {
        _cache[_ck(r['box'] as String, r['key'] as String)] = jsonDecode(raw);
      } catch (_) {
        _cache[_ck(r['box'] as String, r['key'] as String)] = raw;
      }
    }
  }

  Database get _database {
    assert(_db != null, 'SqliteStorageService.init() must be called first');
    return _db!;
  }

  // ── Sync reads (aus Cache — kein await nötig) ───────────────────────────────

  dynamic getSync(String box, String key) => _cache[_ck(box, key)];

  List<dynamic> getAllSync(String box) {
    final prefix = '$box\x00';
    return _cache.entries
        .where((e) => e.key.startsWith(prefix))
        .map((e) => e.value)
        .toList();
  }

  bool containsKeySync(String box, String key) =>
      _cache.containsKey(_ck(box, key));

  // ── Async reads (lesen ebenfalls aus Cache, konsistent) ─────────────────────

  Future<dynamic> get(String box, String key) async => getSync(box, key);

  Future<List<dynamic>> getAll(String box) async => getAllSync(box);

  Future<Map<String, dynamic>> getAllWithKeys(String box) async {
    final prefix = '$box\x00';
    return {
      for (final e in _cache.entries.where((e) => e.key.startsWith(prefix)))
        e.key.substring(prefix.length): e.value,
    };
  }

  Future<bool> containsKey(String box, String key) async =>
      containsKeySync(box, key);

  Future<int> count(String box) async {
    final prefix = '$box\x00';
    return _cache.keys.where((k) => k.startsWith(prefix)).length;
  }

  Future<List<String>> getKeys(String box) async {
    final prefix = '$box\x00';
    return _cache.keys
        .where((k) => k.startsWith(prefix))
        .map((k) => k.substring(prefix.length))
        .toList();
  }

  // ── Writes (Cache + SQLite) ─────────────────────────────────────────────────

  Future<void> put(String box, String key, dynamic value) async {
    _cache[_ck(box, key)] = value;
    await _database.insert(
      'kv_store',
      {'box': box, 'key': key, 'value': jsonEncode(value)},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String box, String key) async {
    _cache.remove(_ck(box, key));
    await _database.delete(
      'kv_store',
      where: 'box = ? AND key = ?',
      whereArgs: [box, key],
    );
  }

  Future<void> clear(String box) async {
    _cache.removeWhere((k, _) => k.startsWith('$box\x00'));
    await _database.delete('kv_store', where: 'box = ?', whereArgs: [box]);
  }
}

/// Hive-Box-kompatibler Shim über SqliteStorageService.
///
/// Bildet die von Legacy-Callern genutzte Hive-Box-API ab
/// (put/get/delete/values/length/isEmpty/isNotEmpty/keys), damit nach der
/// Hive→sqflite-Migration bestehender Code weiterläuft ohne Call-Site-Rewrite.
class BoxShim {
  BoxShim(this._boxName);
  final String _boxName;
  SqliteStorageService get _db => SqliteStorageService.instance;

  Future<void> put(dynamic key, dynamic value) =>
      _db.put(_boxName, key.toString(), value);

  dynamic get(dynamic key) => _db.getSync(_boxName, key.toString());

  Future<void> delete(dynamic key) => _db.delete(_boxName, key.toString());

  Iterable<dynamic> get values => _db.getAllSync(_boxName);

  int get length => _db.getAllSync(_boxName).length;

  bool get isEmpty => length == 0;
  bool get isNotEmpty => length > 0;

  Iterable<String> get keys {
    final prefix = '$_boxName\x00';
    return _db._cache.keys
        .where((k) => k.startsWith(prefix))
        .map((k) => k.substring(prefix.length));
  }
}
