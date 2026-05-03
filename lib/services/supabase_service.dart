/// 🟢 SUPABASE SERVICE – Zentrale Supabase-Integration
///
/// Verantwortlich für:
/// - Auth (Login, Logout, Registrierung, Session)
/// - Profile (User-Stammdaten)
/// - Community (Artikel, Kommentare, Likes, Bookmarks)
/// - Chat (Text-Nachrichten via Supabase Realtime)
/// - Notifications
///
/// Initialisierung: Supabase.initialize() in main.dart aufrufen.
/// Konfiguration: Über dart-define oder api_config.dart.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'sqlite_storage_service.dart';
import 'push_notification_manager.dart';
import '../config/api_config.dart';

// ──────────────────────────────────────────────────────────────
// INITIALISIERUNG
// ──────────────────────────────────────────────────────────────

/// Supabase einmalig initialisieren – in main() aufrufen.
/// Erstellt automatisch eine anonyme Session wenn kein User eingeloggt ist,
/// damit RLS-Policies und Chat-Funktionen ohne E-Mail-Login funktionieren.
Future<void> initSupabase() async {
  await Supabase.initialize(
    url: ApiConfig.supabaseUrl,
    anonKey: ApiConfig.supabaseAnonKey,
    debug: kDebugMode,
  );
  if (kDebugMode) {
    debugPrint('✅ [Supabase] Initialisiert: ${ApiConfig.supabaseUrl}');
  }

  // Automatisch anonyme Auth-Session erstellen wenn kein User eingeloggt.
  // Voraussetzung: Authentication → Providers → Anonymous Sign-ins im
  // Supabase-Dashboard aktiviert. Bei Fehler: stiller Fallback (allowAnonymous=true).
  final client = Supabase.instance.client;
  if (client.auth.currentUser == null) {
    try {
      await client.auth.signInAnonymously();
      if (kDebugMode) {
        debugPrint('✅ [Supabase] Anonyme Session erstellt: ${client.auth.currentUser?.id}');
      }
    } catch (e) {
      // Tritt auf wenn Anonymous Sign-ins im Dashboard nicht aktiviert.
      // App funktioniert trotzdem via allowAnonymous=true in sendMessage.
      if (kDebugMode) {
        debugPrint('⚠️ [Supabase] signInAnonymously fehlgeschlagen (Dashboard-Setting?): $e');
      }
    }
  }
}

/// Schnellzugriff auf den Supabase-Client.
SupabaseClient get supabase => Supabase.instance.client;

// ──────────────────────────────────────────────────────────────
// AUTH SERVICE
// ──────────────────────────────────────────────────────────────

class SupabaseAuthService {
  static SupabaseAuthService? _instance;
  static SupabaseAuthService get instance =>
      _instance ??= SupabaseAuthService._();
  SupabaseAuthService._();

  /// Aktueller User (null = nicht eingeloggt)
  User? get currentUser => supabase.auth.currentUser;

  /// Aktuelle Session
  Session? get currentSession => supabase.auth.currentSession;

  /// Ist der User eingeloggt?
  bool get isLoggedIn => currentUser != null;

  /// Auth-Status-Stream
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  // ── REGISTRIERUNG ──────────────────────────────────────────

  /// Neuen User registrieren (Email + Passwort).
  /// username wird als user_metadata gespeichert → trigger erstellt profil.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
    String world = 'materie',
  }) async {
    if (kDebugMode) debugPrint('📝 [Auth] SignUp: $email');

    final response = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'username': username,
        'display_name': username,
        'world': world,
      },
    );

    if (kDebugMode && response.user != null) {
      debugPrint('✅ [Auth] Registriert: ${response.user!.id}');
    }
    return response;
  }

  // ── LOGIN ──────────────────────────────────────────────────

  /// Login mit Email + Passwort.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    if (kDebugMode) debugPrint('🔐 [Auth] SignIn: $email');
    return await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // ── LOGOUT ────────────────────────────────────────────────

  Future<void> signOut() async {
    if (kDebugMode) debugPrint('🚪 [Auth] SignOut');
    // Bundle P-E6: Push-Token deaktivieren BEVOR Session gekappt wird,
    // damit der Worker den User aus push_subscriptions auf inactive setzen
    // kann. Sonst bekommt der nächste Login auf demselben Gerät noch
    // Pushes für den vorigen User.
    try {
      await PushNotificationManager.instance
          .unsubscribeCurrent()
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Push-Unsubscribe vor SignOut: $e');
    }
    await supabase.auth.signOut();
    await _clearLocalData();
  }

  /// Löscht alle lokalen Auth- und Profil-Caches nach Logout.
  Future<void> _clearLocalData() async {
    final db = SqliteStorageService.instance;
    for (final boxName in [
      'user_data',
      'materie_profiles',
      'energie_profiles',
      'auth_storage',
    ]) {
      try {
        await db.clear(boxName);
        if (kDebugMode) debugPrint('🗑️ [Auth] Cleared: $boxName');
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ [Auth] Clear $boxName failed: $e');
      }
    }
  }

  // ── PASSWORT RESET ────────────────────────────────────────

  Future<void> resetPassword(String email) async {
    await supabase.auth.resetPasswordForEmail(email);
  }

  // ── SESSION REFRESH ───────────────────────────────────────

  Future<void> refreshSession() async {
    await supabase.auth.refreshSession();
  }
}

// ──────────────────────────────────────────────────────────────
// PROFILE SERVICE
// ──────────────────────────────────────────────────────────────

class SupabaseProfileService {
  static SupabaseProfileService? _instance;
  static SupabaseProfileService get instance =>
      _instance ??= SupabaseProfileService._();
  SupabaseProfileService._();

  /// Eigenes Profil laden.
  Future<Map<String, dynamic>?> getMyProfile() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    return response;
  }

  /// Profil nach ID laden.
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    return await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
  }

  /// Eigenes Profil updaten.
  Future<void> updateProfile({
    String? username,
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? world,
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Nicht eingeloggt');

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (username != null) updates['username'] = username;
    if (displayName != null) updates['display_name'] = displayName;
    if (bio != null) updates['bio'] = bio;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (world != null) updates['world'] = world;

    try {
      await supabase.from('profiles').update(updates).eq('id', userId);
      if (kDebugMode) debugPrint('✅ [Profile] Aktualisiert: $userId');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [Profile] update failed: $e');
      rethrow;
    }
  }

  /// Avatar hochladen und URL in Profil speichern.
  Future<String> uploadAvatar(List<int> bytes, String fileExtension) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Nicht eingeloggt');

    final fileName = '$userId/avatar.$fileExtension';
    await supabase.storage.from('avatars').uploadBinary(
          fileName,
          Uint8List.fromList(bytes),
          fileOptions: const FileOptions(upsert: true),
        );

    final url = supabase.storage.from('avatars').getPublicUrl(fileName);
    await updateProfile(avatarUrl: url);
    return url;
  }
}

// ──────────────────────────────────────────────────────────────
// COMMUNITY SERVICE (Artikel, Kommentare, Likes, Bookmarks)
// ──────────────────────────────────────────────────────────────

class SupabaseCommunityService {
  static SupabaseCommunityService? _instance;
  static SupabaseCommunityService get instance =>
      _instance ??= SupabaseCommunityService._();
  SupabaseCommunityService._();

  // ── ARTIKEL ───────────────────────────────────────────────

  /// Artikel laden (optional nach World und Kategorie filtern).
  Future<List<Map<String, dynamic>>> getArticles({
    String? world,
    String? category,
    int limit = 20,
    int offset = 0,
  }) async {
    var query = supabase
        .from('articles')
        .select('*, profiles(username, avatar_url)')
        .eq('is_published', true);

    if (world != null) query = query.eq('world', world);
    if (category != null) query = query.eq('category', category);

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Artikel erstellen.
  Future<Map<String, dynamic>> createArticle({
    required String title,
    required String content,
    required String world,
    String? category,
    List<String> tags = const [],
    String? imageUrl,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Nicht eingeloggt');

    final profile = await SupabaseProfileService.instance.getMyProfile();
    final username = profile?['username'] ?? user.email?.split('@').first ?? 'Anonym';

    // Slug aus Titel generieren (Pflichtfeld in DB).
    // Thread-safe via UUID-Random-Suffix statt millisecondsSinceEpoch — bei
    // schnellen parallelen Posts würde ms-Suffix kollidieren.
    final randomSuffix = (DateTime.now().microsecondsSinceEpoch % 1000000)
        .toRadixString(36);
    final slug = '${title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '')}-$randomSuffix';

    final response = await supabase.from('articles').insert({
      'user_id': user.id,
      'username': username,
      'title': title,
      'slug': slug,
      'content': content,
      'world': world,
      'category': category,
      'tags': tags,
      'image_url': imageUrl,
      'cover_image_url': imageUrl,  // Beide Spalten befüllen
      'is_published': true,
    }).select().single();

    if (kDebugMode) debugPrint('✅ [Community] Artikel erstellt: ${response['id']}');
    return response;
  }

  // ── LIKES ────────────────────────────────────────────────

  Future<void> likeArticle(String articleId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Nicht eingeloggt');

    try {
      await supabase.from('likes').insert({
        'article_id': articleId,
        'user_id': userId,
      });
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ likeArticle failed: $e');
      rethrow;
    }
  }

  Future<void> unlikeArticle(String articleId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Nicht eingeloggt');

    try {
      await supabase
          .from('likes')
          .delete()
          .eq('article_id', articleId)
          .eq('user_id', userId);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ unlikeArticle failed: $e');
      rethrow;
    }
  }

  Future<bool> hasLiked(String articleId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final response = await supabase
          .from('likes')
          .select('id')
          .eq('article_id', articleId)
          .eq('user_id', userId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ hasLiked failed: $e');
      return false;
    }
  }

  // ── BOOKMARKS ────────────────────────────────────────────

  Future<void> bookmarkArticle(String articleId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Nicht eingeloggt');

    try {
      await supabase.from('bookmarks').insert({
        'article_id': articleId,
        'user_id': userId,
      });
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ bookmarkArticle failed: $e');
      rethrow;
    }
  }

  Future<void> removeBookmark(String articleId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Nicht eingeloggt');

    try {
      await supabase
          .from('bookmarks')
          .delete()
          .eq('article_id', articleId)
          .eq('user_id', userId);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ removeBookmark failed: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getMyBookmarks() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await supabase
          .from('bookmarks')
          .select('*, articles(*, profiles(username, avatar_url))')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ getMyBookmarks failed: $e');
      return [];
    }
  }

  // ── KOMMENTARE ────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getComments(String articleId) async {
    try {
      final response = await supabase
          .from('comments')
          .select('*, profiles(username, avatar_url)')
          .eq('article_id', articleId)
          .eq('is_deleted', false)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ getComments failed: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> addComment({
    required String articleId,
    required String content,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Nicht eingeloggt');

    final profile = await SupabaseProfileService.instance.getMyProfile();
    final username = profile?['username'] ?? 'Anonym';

    final response = await supabase.from('comments').insert({
      'article_id': articleId,
      'user_id': user.id,
      'username': username,
      'content': content,
    }).select().single();

    return response;
  }
}

// ──────────────────────────────────────────────────────────────
// CHAT SERVICE (Echtzeit-Chat via Supabase Realtime)
// ──────────────────────────────────────────────────────────────

class SupabaseChatService {
  static SupabaseChatService? _instance;
  static SupabaseChatService get instance =>
      _instance ??= SupabaseChatService._();
  SupabaseChatService._();

  /// Per-Room Channels. Vorher war das ein einziges `_activeChannel` —
  /// der wurde beim Wechsel zwischen Materie/Energie-Welt jeweils gekappt
  /// und die andere Welt verlor still ihre Realtime-Verbindung.
  /// Jetzt: Map keyed by roomId, jede Welt behält ihre eigene Subscription.
  final Map<String, RealtimeChannel> _channels = {};

  /// Nachrichten für einen Raum laden (letzte 50).
  /// Sortiert aufsteigend nach created_at (ältere zuerst → neueste unten).
  /// Optimiert: order(ascending:true) + .limit() → kein .reversed.toList()
  /// post-processing nötig, spart O(n) Allocation.
  Future<List<Map<String, dynamic>>> getMessages(String roomId,
      {int limit = 50}) async {
    try {
      final response = await supabase
          .from('chat_messages')
          .select()
          .eq('room_id', roomId)
          .eq('is_deleted', false)
          .order('created_at', ascending: true)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ getMessages failed: $e');
      return [];
    }
  }

  /// Pagination: Nachrichten älter als [before] laden.
  /// Bundle 6.5: Tie-Breaking via `(created_at, id)` damit Nachrichten mit
  /// identischem Timestamp nicht über Page-Boundaries verschwinden.
  /// `beforeId` ist optional für die erste Seite.
  Future<List<Map<String, dynamic>>> getMessagesBefore(
    String roomId, {
    required String before,
    String? beforeId,
    int limit = 50,
  }) async {
    var query = supabase
        .from('chat_messages')
        .select()
        .eq('room_id', roomId)
        .eq('is_deleted', false);
    if (beforeId != null && beforeId.isNotEmpty) {
      // Älter ALS (timestamp, id) — entweder strikt älterer Timestamp oder
      // gleicher Timestamp + lexikographisch kleinere ID.
      query = query.or(
        'created_at.lt.$before,'
        'and(created_at.eq.$before,id.lt.$beforeId)',
      );
    } else {
      query = query.lt('created_at', before);
    }
    final response = await query
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(response.reversed.toList());
  }

  /// Nachricht senden.
  /// Anonyme Posts sind erlaubt (user_id bleibt null) — konsistent mit
  /// vorherigem Worker-Verhalten. RLS erlaubt anon-INSERT (v18 migration).
  ///
  /// Reply-Support (v36): Wenn [replyToId] gesetzt ist, wird ein Telegram-Style
  /// Quote-Snapshot mitgespeichert. Der Snapshot (content/sender_name) bleibt
  /// sichtbar auch wenn die Original-Nachricht später gelöscht wird.
  Future<Map<String, dynamic>> sendMessage({
    required String roomId,
    required String message,
    String? username,
    String? avatarUrl,
    String? avatarEmoji,
    String? messageType,
    String? mediaUrl,
    bool allowAnonymous = true,
    String? replyToId,
    String? replyToContent,
    String? replyToSenderName,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null && !allowAnonymous) {
      throw Exception('Nicht eingeloggt – bitte anmelden, um Nachrichten zu senden.');
    }

    // Username/Avatar: explizit gesetzt > Profil > Email-Prefix > 'Anonym'
    String effectiveUsername =
        (username != null && username.trim().isNotEmpty) ? username.trim() : '';
    String? effectiveAvatar = avatarUrl;
    if (user != null && effectiveUsername.isEmpty) {
      try {
        final profile = await SupabaseProfileService.instance.getMyProfile();
        final profileUsername = (profile?['username'] as String?)?.trim();
        if (profileUsername != null && profileUsername.isNotEmpty) {
          effectiveUsername = profileUsername;
        } else if (user.email != null && user.email!.isNotEmpty) {
          effectiveUsername = user.email!.split('@').first;
        }
        effectiveAvatar ??= profile?['avatar_url'] as String?;
      } catch (e) {
        // Profil-Fetch fehlgeschlagen – fallen unten auf 'Anonym' zurück.
        if (kDebugMode) {
          debugPrint('⚠️ SupabaseService: Profil-Fetch failed — $e');
        }
      }
    }
    if (effectiveUsername.isEmpty) effectiveUsername = 'Anonym';

    final insertData = <String, dynamic>{
      'room_id': roomId,
      'username': effectiveUsername,
      'content': message, // NOT NULL
      'message': message, // Kompat-Spalte
    };
    if (user != null) insertData['user_id'] = user.id;
    if (effectiveAvatar != null) insertData['avatar_url'] = effectiveAvatar;
    if (avatarEmoji != null && avatarEmoji.isNotEmpty) {
      insertData['avatar_emoji'] = avatarEmoji;
    }
    if (messageType != null) insertData['message_type'] = messageType;
    // 🆕 mediaUrl wurde vorher komplett verschluckt → Image/Voice-Messages
    // landeten ohne URL in der DB, UI zeigte „leere" Nachrichten.
    if (mediaUrl != null && mediaUrl.isNotEmpty) {
      insertData['media_url'] = mediaUrl;
    }
    if (replyToId != null && replyToId.isNotEmpty) {
      insertData['reply_to_id'] = replyToId;
      // Snapshot auf max. 280 Zeichen kürzen (Telegram-Style Quote).
      final snippet = (replyToContent ?? '').trim();
      insertData['reply_to_content'] =
          snippet.length > 280 ? '${snippet.substring(0, 280)}…' : snippet;
      insertData['reply_to_sender_name'] =
          (replyToSenderName ?? '').trim().isEmpty ? null : replyToSenderName!.trim();
    }

    final response = await supabase
        .from('chat_messages')
        .insert(insertData)
        .select()
        .single();

    return response;
  }

  /// Eigene Nachricht bearbeiten (RLS prüft Ownership).
  /// [isAdmin] = true: versucht auch fremde Nachrichten zu bearbeiten (admin-policy).
  Future<Map<String, dynamic>> editMessage({
    required String messageId,
    required String newMessage,
    bool isAdmin = false,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Nicht eingeloggt – Bearbeiten nicht möglich.');
    }

    final updateData = <String, dynamic>{
      'message': newMessage,
      'content': newMessage,
      'edited_at': DateTime.now().toUtc().toIso8601String(),
    };

    final query = supabase.from('chat_messages').update(updateData);
    // Ownership-Check via RLS – kein .eq('user_id', user.id) nötig wenn Policy sauber.
    // Für Admin: RLS-Policy für Admins sollte greifen.
    final result = await query.eq('id', messageId).select().single();
    return result;
  }

  /// Nachricht löschen — Hard-Delete (v36).
  /// RLS-Policy "User kann eigene Nachrichten löschen" greift. Admin-Löschung
  /// läuft über Worker-Endpoint mit SERVICE_ROLE (nicht hier).
  Future<void> deleteMessage({
    required String messageId,
    bool isAdmin = false,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Nicht eingeloggt – Löschen nicht möglich.');
    }

    await supabase.from('chat_messages').delete().eq('id', messageId);
  }

  /// Echtzeit-Subscription auf Chat-Nachrichten.
  /// - [onMessage]: neue INSERT-Nachricht
  /// - [onUpdate]: bearbeitete Nachricht (edit)
  /// - [onDelete]: hart gelöschte Nachricht (nur `id` im payload enthalten)
  RealtimeChannel subscribeToRoom(
    String roomId, {
    required void Function(Map<String, dynamic>) onMessage,
    void Function(Map<String, dynamic>)? onUpdate,
    void Function(String messageId)? onDelete,
  }) {
    // Wenn dieselbe Welt nochmal subscribed → erst alte Channel kappen,
    // damit keine doppelten Callbacks (z.B. nach Hot-Reload).
    _channels.remove(roomId)?.unsubscribe();

    final filter = PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'room_id',
      value: roomId,
    );

    final channel = supabase
        .channel('chat_room_$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: filter,
          callback: (payload) {
            if (kDebugMode) debugPrint('💬 [Chat] INSERT in $roomId');
            onMessage(Map<String, dynamic>.from(payload.newRecord));
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'chat_messages',
          filter: filter,
          callback: (payload) {
            if (kDebugMode) debugPrint('✏️ [Chat] UPDATE in $roomId');
            onUpdate?.call(Map<String, dynamic>.from(payload.newRecord));
          },
        )
        .onPostgresChanges(
          // DELETE: oldRecord enthält bei DEFAULT REPLICA IDENTITY nur den PK (id).
          // room_id ist immer NULL im oldRecord — deshalb KEIN room_id-Filter.
          // Ein fremdes DELETE einer unbekannten ID ist harmlos (removeWhere findet nichts).
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'chat_messages',
          callback: (payload) {
            final old = Map<String, dynamic>.from(payload.oldRecord);
            final id = old['id']?.toString();
            if (id == null || id.isEmpty) return;
            if (kDebugMode) debugPrint('🗑️ [Chat] DELETE $id');
            onDelete?.call(id);
          },
        )
        .subscribe();

    _channels[roomId] = channel;
    if (kDebugMode) debugPrint('🔌 [Chat] Subscribed: $roomId');
    return channel;
  }

  /// Subscription beenden — optional auf einen spezifischen Raum begrenzt.
  /// Ohne Argument werden ALLE aktiven Subscriptions gekappt (z.B. bei
  /// Logout).
  Future<void> unsubscribe([String? roomId]) async {
    if (roomId != null) {
      final ch = _channels.remove(roomId);
      if (ch != null) {
        await ch.unsubscribe();
        if (kDebugMode) debugPrint('🔌 [Chat] Unsubscribed: $roomId');
      }
      return;
    }
    final all = List.of(_channels.values);
    _channels.clear();
    for (final ch in all) {
      await ch.unsubscribe();
    }
    if (kDebugMode) debugPrint('🔌 [Chat] Unsubscribed all (${all.length})');
  }

  /// Chat-Räume laden.
  Future<List<Map<String, dynamic>>> getChatRooms({String? world}) async {
    var query = supabase
        .from('chat_rooms')
        .select()
        .eq('is_active', true);

    if (world != null) query = query.eq('world', world);

    final response = await query.order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  // ── READ RECEIPTS ──────────────────────────────────────────────

  /// Nachricht als gelesen markieren (read_by Array in Supabase).
  /// Fügt die userId zum read_by-Array hinzu (SQL: array_append).
  Future<void> markMessageAsRead({
    required String messageId,
    required String userId,
  }) async {
    try {
      // RPC-Funktion für atomic array_append (ohne Duplikate)
      await supabase.rpc('mark_message_as_read', params: {
        'p_message_id': messageId,
        'p_user_id': userId,
      });
      if (kDebugMode) debugPrint('📖 [Chat] Gelesen: $messageId');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [Chat] markMessageAsRead failed: $e');
    }
  }

  /// Alle ungelesenen Nachrichten im Raum als gelesen markieren.
  Future<void> markRoomMessagesAsRead({
    required String roomId,
    required String userId,
  }) async {
    try {
      await supabase.rpc('mark_room_messages_as_read', params: {
        'p_room_id': roomId,
        'p_user_id': userId,
      });
      if (kDebugMode) debugPrint('📖 [Chat] Alle Nachrichten in $roomId gelesen');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [Chat] markRoomMessagesAsRead failed: $e');
    }
  }

  // ── TYPING INDICATORS via Supabase Realtime Broadcast ──────────

  /// Typing-Indikator senden (Broadcast, kein DB-Insert).
  Future<void> sendTypingIndicator({
    required String roomId,
    required String userId,
    required String username,
    bool isTyping = true,
  }) async {
    try {
      // Broadcast auf den Channel des spezifischen Raums senden, nicht
      // mehr auf einen Singleton.
      _channels[roomId]?.sendBroadcastMessage(
        event: 'typing',
        payload: {
          'userId': userId,
          'username': username,
          'isTyping': isTyping,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [Chat] Typing broadcast failed: $e');
    }
  }

  /// Subscription erweitern: Typing-Events + Read-Receipt-Updates empfangen.
  RealtimeChannel subscribeToRoomFull(
    String roomId, {
    required void Function(Map<String, dynamic>) onMessage,
    void Function(String userId, String username, bool isTyping)? onTyping,
    void Function(String messageId, String userId)? onRead,
  }) {
    _channels.remove(roomId)?.unsubscribe();

    var channel = supabase
        .channel('chat_room_$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (payload) {
            if (kDebugMode) debugPrint('💬 [Chat] Neue Nachricht in $roomId');
            onMessage(Map<String, dynamic>.from(payload.newRecord));
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (payload) {
            // Read-Receipt Update: read_by Array wurde geändert
            final updated = Map<String, dynamic>.from(payload.newRecord);
            if (onRead != null) {
              final readBy = updated['read_by'];
              if (readBy is List && readBy.isNotEmpty) {
                onRead(updated['id'] as String, readBy.last as String);
              }
            }
            // Auch als Nachrichtenupdate weiterleiten (z.B. für edits)
            onMessage(updated);
          },
        );

    // Typing-Broadcast nur wenn Callback vorhanden
    if (onTyping != null) {
      channel = channel.onBroadcast(
        event: 'typing',
        callback: (payload) {
          final userId = payload['userId'] as String? ?? '';
          final username = payload['username'] as String? ?? '';
          final isTyping = payload['isTyping'] as bool? ?? false;
          onTyping(userId, username, isTyping);
        },
      );
    }

    final subscribed = channel.subscribe();
    _channels[roomId] = subscribed;

    if (kDebugMode) debugPrint('🔌 [Chat] Full-Subscribe: $roomId');
    return subscribed;
  }
}

// ──────────────────────────────────────────────────────────────
// NOTIFICATION SERVICE
// ──────────────────────────────────────────────────────────────

class SupabaseNotificationService {
  static SupabaseNotificationService? _instance;
  static SupabaseNotificationService get instance =>
      _instance ??= SupabaseNotificationService._();
  SupabaseNotificationService._();

  Future<List<Map<String, dynamic>>> getNotifications({
    bool unreadOnly = false,
    int limit = 30,
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    var query = supabase
        .from('notifications')
        .select()
        .eq('user_id', userId);

    if (unreadOnly) query = query.eq('is_read', false);

    final response = await query
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> markAsRead(String notificationId) async {
    await supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  Future<void> markAllAsRead() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    await supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  /// Echtzeit-Subscription auf Notifications.
  RealtimeChannel subscribeToNotifications({
    required void Function(Map<String, dynamic>) onNotification,
  }) {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Nicht eingeloggt');

    return supabase
        .channel('notifications_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) =>
              onNotification(Map<String, dynamic>.from(payload.newRecord)),
        )
        .subscribe();
  }
}

// ──────────────────────────────────────────────────────────────
// STORAGE SERVICE
// ──────────────────────────────────────────────────────────────

class SupabaseStorageService {
  static SupabaseStorageService? _instance;
  static SupabaseStorageService get instance =>
      _instance ??= SupabaseStorageService._();
  SupabaseStorageService._();

  /// Bild in 'media' Bucket hochladen.
  Future<String> uploadMediaImage(
    List<int> bytes,
    String fileName, {
    String contentType = 'image/jpeg',
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Nicht eingeloggt');

    final path = '$userId/$fileName';
    await supabase.storage.from('media').uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );

    return supabase.storage.from('media').getPublicUrl(path);
  }

  /// Avatar hochladen.
  Future<String> uploadAvatar(List<int> bytes, String extension) async {
    return await SupabaseProfileService.instance
        .uploadAvatar(bytes, extension);
  }
}
