import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// SupabaseGroupToolsService – direct Supabase queries for group tool screens.
/// Replaces the old Cloudflare-based GroupToolsService.
class SupabaseGroupToolsService {
  static final SupabaseGroupToolsService _instance =
      SupabaseGroupToolsService._internal();
  factory SupabaseGroupToolsService() => _instance;
  SupabaseGroupToolsService._internal();

  final _db = Supabase.instance.client;

  // ── Conspiracy Connections ────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getConspiracyNetwork({
    String roomId = 'verschwoerungen',
    int limit = 50,
  }) async {
    try {
      final rows = await _db
          .from('tool_network_connections')
          .select()
          .eq('room_id', roomId)
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [GroupTools] getConspiracyNetwork error: $e');
      return [];
    }
  }

  Future<void> createConspiracyConnection({
    required String roomId,
    required String connectionTitle,
    required String connectionDescription,
  }) async {
    final user = _db.auth.currentUser;
    if (user == null) throw Exception('Nicht eingeloggt');

    final meta = user.userMetadata;
    await _db.from('tool_network_connections').insert({
      'room_id':                roomId,
      'user_id':                user.id,
      'username':               meta?['username'] as String? ?? 'Anonym',
      'connection_title':       connectionTitle,
      'connection_description': connectionDescription,
    });
  }

  // ── Healing Methods ───────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getHealingMethods({
    String roomId = 'gesundheit',
    int limit = 50,
  }) async {
    try {
      final rows = await _db
          .from('tool_healing_methods')
          .select()
          .eq('room_id', roomId)
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [GroupTools] getHealingMethods error: $e');
      return [];
    }
  }

  Future<void> createHealingMethod({
    required String roomId,
    required String methodName,
    required String methodDescription,
    String category = 'alternative',
  }) async {
    final user = _db.auth.currentUser;
    if (user == null) throw Exception('Nicht eingeloggt');

    final meta = user.userMetadata;
    await _db.from('tool_healing_methods').insert({
      'room_id':            roomId,
      'user_id':            user.id,
      'username':           meta?['username'] as String? ?? 'Anonym',
      'method_name':        methodName,
      'method_description': methodDescription,
      'category':           category,
    });
  }

  // ── Geopolitics Events ────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getGeopoliticsEvents({
    String roomId = 'politik',
    int limit = 50,
  }) async {
    try {
      final rows = await _db
          .from('tool_geopolitics_events')
          .select()
          .eq('room_id', roomId)
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [GroupTools] getGeopoliticsEvents error: $e');
      return [];
    }
  }

  Future<void> createGeopoliticsEvent({
    required String roomId,
    required String title,
    required String description,
  }) async {
    final user = _db.auth.currentUser;
    if (user == null) throw Exception('Nicht eingeloggt');

    final meta = user.userMetadata;
    await _db.from('tool_geopolitics_events').insert({
      'room_id':     roomId,
      'user_id':     user.id,
      'username':    meta?['username'] as String? ?? 'Anonym',
      'event_title': title,
      'description': description,
    });
  }
}
