import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Web-Stub für SqliteStorageService.
/// Verwendet SharedPreferences (localStorage) statt sqflite.
/// Gleiche öffentliche API wie sqlite_storage_service_io.dart.
class SqliteStorageService {
  SqliteStorageService._();
  static final instance = SqliteStorageService._();

  SharedPreferences? _prefs;
  final Map<String, dynamic> _cache = {};

  String _ck(String box, String key) => '$box\x00$key';
  String _spKey(String box, String key) => 'wb__${box}__$key';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadCache();
  }

  Future<void> _loadCache() async {
    final prefs = _prefs!;
    _cache.clear();
    for (final spKey in prefs.getKeys()) {
      if (!spKey.startsWith('wb__')) continue;
      final withoutPrefix = spKey.substring(4);
      final sepIdx = withoutPrefix.indexOf('__');
      if (sepIdx < 0) continue;
      final box = withoutPrefix.substring(0, sepIdx);
      final key = withoutPrefix.substring(sepIdx + 2);
      final raw = prefs.getString(spKey);
      if (raw == null) continue;
      try {
        _cache[_ck(box, key)] = jsonDecode(raw);
      } catch (_) {
        _cache[_ck(box, key)] = raw;
      }
    }
  }

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

  Future<void> put(String box, String key, dynamic value) async {
    _cache[_ck(box, key)] = value;
    await _prefs!.setString(_spKey(box, key), jsonEncode(value));
  }

  Future<void> delete(String box, String key) async {
    _cache.remove(_ck(box, key));
    await _prefs!.remove(_spKey(box, key));
  }

  Future<void> clear(String box) async {
    final prefix = '$box\x00';
    _cache.removeWhere((k, _) => k.startsWith(prefix));
    final prefs = _prefs!;
    final spPrefix = 'wb__${box}__';
    for (final k in prefs.getKeys().where((k) => k.startsWith(spPrefix)).toList()) {
      await prefs.remove(k);
    }
  }

  Future<void> refresh() async {
    if (_prefs == null) return;
    await _loadCache();
  }

  Future<void> refreshBox(String box) async {
    if (_prefs == null) return;
    final prefix = '$box\x00';
    final spPrefix = 'wb__${box}__';
    _cache.removeWhere((k, _) => k.startsWith(prefix));
    for (final spKey in _prefs!.getKeys().where((k) => k.startsWith(spPrefix))) {
      final withoutPrefix = spKey.substring(4);
      final sepIdx = withoutPrefix.indexOf('__');
      if (sepIdx < 0) continue;
      final key = withoutPrefix.substring(sepIdx + 2);
      final raw = _prefs!.getString(spKey);
      if (raw == null) continue;
      try {
        _cache[_ck(box, key)] = jsonDecode(raw);
      } catch (_) {
        _cache[_ck(box, key)] = raw;
      }
    }
  }
}

/// Hive-Box-kompatibler Shim — identische API wie in sqlite_storage_service_io.dart.
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
