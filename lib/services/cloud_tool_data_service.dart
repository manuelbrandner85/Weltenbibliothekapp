/// ☁️ CLOUD TOOL DATA SERVICE
///
/// Generische Cloud-Synchronisation für Spirit-Tool-Daten.
/// Mappt Hive-Boxen 1:1 auf die Supabase-Tabelle `user_tool_data`
/// (siehe Migration v27).
///
/// Designprinzip:
///   • Storage bleibt offline-first (Hive = Source of Truth für Reads).
///   • Jeder Write triggert fire-and-forget `upsert()` in die Cloud.
///   • `pullAll()` kann beim Login ausgeführt werden, um Cloud → Hive
///     zu rehydrieren (z. B. nach Reinstall auf neuem Gerät).
///   • Offline / anonyme User: alle Calls werden still übersprungen.
library;

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';

class CloudToolDataService {
  CloudToolDataService._();
  static final CloudToolDataService instance = CloudToolDataService._();

  static const String _table = 'user_tool_data';

  SupabaseClient get _client => Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  bool get _enabled => _userId != null;

  /// Einzeleintrag speichern oder updaten.
  /// Fire-and-forget: Fehler werden geloggt, aber nicht geworfen —
  /// Hive hat den Eintrag bereits lokal, Cloud ist nur Backup.
  Future<void> upsert({
    required String toolKey,
    required String itemId,
    required Map<String, dynamic> data,
  }) async {
    final uid = _userId;
    if (uid == null) return;

    try {
      await _client.from(_table).upsert({
        'user_id': uid,
        'tool_key': toolKey,
        'item_id': itemId,
        'data': data,
      }, onConflict: 'user_id,tool_key,item_id');
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('⚠️ CloudToolDataService.upsert($toolKey/$itemId) fehlgeschlagen: $e');
        debugPrint('$st');
      }
    }
  }

  /// Ein Tool-Item löschen.
  Future<void> delete({required String toolKey, required String itemId}) async {
    final uid = _userId;
    if (uid == null) return;

    try {
      await _client
          .from(_table)
          .delete()
          .eq('user_id', uid)
          .eq('tool_key', toolKey)
          .eq('item_id', itemId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ CloudToolDataService.delete($toolKey/$itemId) fehlgeschlagen: $e');
      }
    }
  }

  /// Alle Einträge eines Tool-Keys abrufen.
  /// Rückgabe: Liste von Maps mit `item_id` + `data` flach gemerged.
  /// Bei Fehler oder nicht-eingeloggt: leere Liste.
  Future<List<Map<String, dynamic>>> listAll(String toolKey) async {
    final uid = _userId;
    if (uid == null) return const [];

    try {
      final rows = await _client
          .from(_table)
          .select('item_id, data, updated_at')
          .eq('user_id', uid)
          .eq('tool_key', toolKey);

      return (rows as List)
          .map((row) => {
                'item_id': row['item_id'],
                'updated_at': row['updated_at'],
                ...Map<String, dynamic>.from(row['data'] as Map),
              })
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ CloudToolDataService.listAll($toolKey) fehlgeschlagen: $e');
      }
      return const [];
    }
  }

  /// Einzelnes Tool-Item abrufen (Hive-Key → Cloud-Item).
  Future<Map<String, dynamic>?> get({
    required String toolKey,
    required String itemId,
  }) async {
    final uid = _userId;
    if (uid == null) return null;

    try {
      final row = await _client
          .from(_table)
          .select('data')
          .eq('user_id', uid)
          .eq('tool_key', toolKey)
          .eq('item_id', itemId)
          .maybeSingle();

      if (row == null) return null;
      return Map<String, dynamic>.from(row['data'] as Map);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ CloudToolDataService.get($toolKey/$itemId) fehlgeschlagen: $e');
      }
      return null;
    }
  }

  /// Status-Debug.
  bool get isReady => _enabled;
}
