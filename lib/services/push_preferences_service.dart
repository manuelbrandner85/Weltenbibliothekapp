import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';

/// 🔔 Push Preferences Service — User-toggleable Notification Filters
///
/// Lokal in SharedPreferences gespeichert. Filter werden im
/// `PushNotificationManager._showLocal` angewandt — wenn der User einen
/// Typ deaktiviert, wird die eingehende Notification nicht angezeigt
/// (Item bleibt in `notification_queue`/`notifications`-Tabelle für
/// In-App-Center).
///
/// Klassen-Singleton damit der Manager den State ohne Re-Init lesen kann.
class PushPreferencesService {
  PushPreferencesService._();
  static final PushPreferencesService instance = PushPreferencesService._();

  // SharedPreferences-Keys
  static const _kEnabledMaster   = 'push_pref_master';
  static const _kEnabledChat     = 'push_pref_chat';
  static const _kEnabledMention  = 'push_pref_mention';
  static const _kEnabledReply    = 'push_pref_reply';
  static const _kEnabledLike     = 'push_pref_like';
  static const _kEnabledComment  = 'push_pref_comment';
  static const _kEnabledFollow   = 'push_pref_follow';
  static const _kEnabledArticle  = 'push_pref_article';
  static const _kEnabledSystem   = 'push_pref_system';

  // In-Memory-Cache für synchrone Reads aus PushNotificationManager
  bool _master = true;
  bool _chat = true;
  bool _mention = true;
  bool _reply = true;
  bool _like = true;
  bool _comment = true;
  bool _follow = true;
  bool _article = true;
  bool _system = true;
  bool _initialized = false;

  // Stream für UI um auf Änderungen zu reagieren
  final _changeController = StreamController<void>.broadcast();
  Stream<void> get onChange => _changeController.stream;

  /// Hydriert den Cache aus SharedPreferences. Idempotent.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _master  = prefs.getBool(_kEnabledMaster)  ?? true;
      _chat    = prefs.getBool(_kEnabledChat)    ?? true;
      _mention = prefs.getBool(_kEnabledMention) ?? true;
      _reply   = prefs.getBool(_kEnabledReply)   ?? true;
      _like    = prefs.getBool(_kEnabledLike)    ?? true;
      _comment = prefs.getBool(_kEnabledComment) ?? true;
      _follow  = prefs.getBool(_kEnabledFollow)  ?? true;
      _article = prefs.getBool(_kEnabledArticle) ?? true;
      _system  = prefs.getBool(_kEnabledSystem)  ?? true;
      if (kDebugMode) debugPrint('🔔 PushPreferences hydriert (master=$_master)');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ PushPreferences init failed: $e');
    }
  }

  // ── Synchrone Reads (von PushNotificationManager genutzt) ─────────────

  bool get isMasterEnabled => _master;

  /// Ist der Notification-Typ aktuell aktiv? Wird von PushNotificationManager
  /// vor `_showLocal` geprüft. False → Notification wird verworfen.
  bool isTypeEnabled(String type) {
    if (!_master) return false;
    switch (type) {
      case 'chat_message':
        return _chat;
      case 'mention':
        return _mention;
      case 'reply':
        return _reply;
      case 'like':
        return _like;
      case 'comment':
      case 'message':
        return _comment;
      case 'follow':
        return _follow;
      case 'new_article':
        return _article;
      case 'achievement':
      case 'system':
        return _system;
      default:
        // Unbekannte Typen durchlassen (Forward-Compat)
        return true;
    }
  }

  // ── UI-Reads (Bool-Getter pro Toggle) ─────────────────────────────────

  bool get chat => _chat;
  bool get mention => _mention;
  bool get reply => _reply;
  bool get like => _like;
  bool get comment => _comment;
  bool get follow => _follow;
  bool get article => _article;
  bool get system => _system;

  // ── Writes (UI ruft diese Setter) ──────────────────────────────────────

  Future<void> setMaster(bool v) async {
    _master = v;
    await _persist(_kEnabledMaster, v);
  }
  Future<void> setChat(bool v) async {
    _chat = v;
    await _persist(_kEnabledChat, v);
  }
  Future<void> setMention(bool v) async {
    _mention = v;
    await _persist(_kEnabledMention, v);
  }
  Future<void> setReply(bool v) async {
    _reply = v;
    await _persist(_kEnabledReply, v);
  }
  Future<void> setLike(bool v) async {
    _like = v;
    await _persist(_kEnabledLike, v);
  }
  Future<void> setComment(bool v) async {
    _comment = v;
    await _persist(_kEnabledComment, v);
  }
  Future<void> setFollow(bool v) async {
    _follow = v;
    await _persist(_kEnabledFollow, v);
  }
  Future<void> setArticle(bool v) async {
    _article = v;
    await _persist(_kEnabledArticle, v);
  }
  Future<void> setSystem(bool v) async {
    _system = v;
    await _persist(_kEnabledSystem, v);
  }

  Future<void> _persist(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
      _changeController.add(null);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ PushPreferences persist failed: $e');
    }
  }

  Future<void> dispose() async {
    await _changeController.close();
  }
}
