import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_interface.dart';

/// Web-Implementierung des Storage-Backends via SharedPreferences.
///
/// SharedPreferences speichert auf Web im localStorage des Browsers.
/// Format: Schlüssel = "wb__<box>__<key>", Wert = JSON-String.
class WebStorageBackend implements StorageBackend {
  WebStorageBackend._();
  static final WebStorageBackend instance = WebStorageBackend._();

  SharedPreferences? _prefs;

  // In-Memory-Cache für synchrone Lesezugriffe
  final Map<String, dynamic> _cache = {};

  String _spKey(String box, String key) => 'wb__${box}__$key';
  String _ck(String box, String key) => '$box\x00$key';

  @override
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadCache();
  }

  Future<void> _loadCache() async {
    final prefs = _prefs!;
    _cache.clear();
    for (final spKey in prefs.getKeys()) {
      if (!spKey.startsWith('wb__')) continue;
      // Format: wb__<box>__<key>
      final withoutPrefix = spKey.substring(4); // remove 'wb__'
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

  @override
  Future<void> put(String box, String key, dynamic value) async {
    _cache[_ck(box, key)] = value;
    await _prefs!.setString(_spKey(box, key), jsonEncode(value));
  }

  @override
  Future<dynamic> get(String box, String key) async => getSync(box, key);

  @override
  Future<List<dynamic>> getAll(String box) async => getAllSync(box);

  @override
  Future<Map<String, dynamic>> getAllWithKeys(String box) async {
    final prefix = '$box\x00';
    return {
      for (final e in _cache.entries.where((e) => e.key.startsWith(prefix)))
        e.key.substring(prefix.length): e.value,
    };
  }

  @override
  dynamic getSync(String box, String key) => _cache[_ck(box, key)];

  @override
  List<dynamic> getAllSync(String box) {
    final prefix = '$box\x00';
    return _cache.entries
        .where((e) => e.key.startsWith(prefix))
        .map((e) => e.value)
        .toList();
  }

  @override
  bool containsKeySync(String box, String key) =>
      _cache.containsKey(_ck(box, key));

  @override
  Future<bool> containsKey(String box, String key) async =>
      containsKeySync(box, key);

  @override
  Future<void> delete(String box, String key) async {
    _cache.remove(_ck(box, key));
    await _prefs!.remove(_spKey(box, key));
  }

  @override
  Future<void> clear(String box) async {
    final prefix = '$box\x00';
    _cache.removeWhere((k, _) => k.startsWith(prefix));
    final prefs = _prefs!;
    final spPrefix = 'wb__${box}__';
    final keysToRemove =
        prefs.getKeys().where((k) => k.startsWith(spPrefix)).toList();
    for (final k in keysToRemove) {
      await prefs.remove(k);
    }
  }

  @override
  Future<void> refresh() async {
    if (_prefs == null) return;
    await _loadCache();
  }
}
