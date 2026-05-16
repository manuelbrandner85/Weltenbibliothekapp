/// Abstrakte Schnittstelle für plattformübergreifenden Key-Value-Storage.
///
/// Mobile (Android/iOS): sqflite-basiert (SqliteStorageService)
/// Web: SharedPreferences-basiert (WebStorageBackend)
abstract class StorageBackend {
  Future<void> init();

  /// Wert schreiben
  Future<void> put(String box, String key, dynamic value);

  /// Wert lesen (async)
  Future<dynamic> get(String box, String key);

  /// Alle Werte einer Box lesen (async)
  Future<List<dynamic>> getAll(String box);

  /// Alle Werte einer Box mit ihren Schlüsseln (async)
  Future<Map<String, dynamic>> getAllWithKeys(String box);

  /// Synchrones Lesen aus Cache
  dynamic getSync(String box, String key);

  /// Synchrones Lesen aller Werte aus Cache
  List<dynamic> getAllSync(String box);

  /// Synchrone Existenzprüfung
  bool containsKeySync(String box, String key);

  /// Schlüssel prüfen (async)
  Future<bool> containsKey(String box, String key);

  /// Wert löschen
  Future<void> delete(String box, String key);

  /// Gesamte Box löschen
  Future<void> clear(String box);

  /// Cache aus Persistenz neu laden
  Future<void> refresh();
}
