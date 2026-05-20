/// ADMIN ACTION SERVICE (v103)
///
/// Persistente Admin-Aktionen via Supabase. Vorher waren Bans/Warnings/
/// Kicks rein In-Memory -- App-Neustart hat alle Bans vergessen. Jetzt
/// werden alle Aktionen in admin_actions/admin_bans/admin_warnings
/// persistiert (RLS gegen Profile-Rolle abgesichert, siehe v103 SQL).
///
/// Features:
/// - Audit-Log aller Admin-Aktionen (admin_actions)
/// - Ban-System (admin_bans, permanent + temporaer)
/// - Warning-System mit 3-Strike-Rule (admin_warnings)
/// - SlowMode bleibt In-Memory (pro Session reicht aus)
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_action.dart';
import 'push_notification_helper.dart';
import 'supabase_service.dart';

class AdminActionService {
  AdminActionService._();
  static final AdminActionService instance = AdminActionService._();

  // SlowMode bleibt In-Memory (Per-Room, Per-Session). Persistierung waere
  // overkill -- ein App-Neustart resetted ohnehin den Chat-Zustand.
  final Map<String, int> _slowModeSettings = {};

  // Cache fuer aktive Bans, vermeidet pro Message-Check eine Supabase-Query.
  // Wird via Realtime-Channel invalidiert.
  final Map<String, UserBanInfo> _bansCache = {};
  bool _bansCachePopulated = false;
  RealtimeChannel? _bansChannel;

  // Streams fuer UI (Admin-Dashboard, Chat-Filter).
  final _actionLogController = StreamController<List<AdminAction>>.broadcast();
  final _bannedUsersController =
      StreamController<Map<String, UserBanInfo>>.broadcast();

  Stream<List<AdminAction>> get actionLogStream => _actionLogController.stream;
  Stream<Map<String, UserBanInfo>> get bannedUsersStream =>
      _bannedUsersController.stream;

  // ── PUBLIC API ────────────────────────────────────────────────────────────

  /// 🚫 KICK USER (Voice-Chat-Ausschluss, nur Audit-Log -- Voice-Server
  /// kickt direkt via LiveKit API).
  Future<bool> kickUser({
    required String adminId,
    required String adminUsername,
    required String targetUserId,
    required String targetUsername,
    String? reason,
    String? roomId,
  }) =>
      _logAction(
        adminId: adminId,
        adminUsername: adminUsername,
        targetUserId: targetUserId,
        targetUsername: targetUsername,
        type: AdminActionType.kick,
        reason: reason,
        roomId: roomId,
      );

  Future<bool> muteUser({
    required String adminId,
    required String adminUsername,
    required String targetUserId,
    required String targetUsername,
    String? reason,
    String? roomId,
  }) async {
    final ok = await _logAction(
      adminId: adminId,
      adminUsername: adminUsername,
      targetUserId: targetUserId,
      targetUsername: targetUsername,
      type: AdminActionType.mute,
      reason: reason,
      roomId: roomId,
    );
    // v103 (4.4): Push an den gemuteten User.
    PushNotificationHelper.instance.fireAndForget(PushNotificationHelper.instance.sendToUser(
      targetUserId: targetUserId,
      type: 'admin_mute',
      title: '🔇 Stummgeschaltet',
      body:
          'Du wurdest stummgeschaltet.${reason != null ? " Grund: $reason" : ""}',
      data: {'action': 'mute', 'reason': reason},
    ), context: 'admin-action');
    return ok;
  }

  Future<bool> unmuteUser({
    required String adminId,
    required String adminUsername,
    required String targetUserId,
    required String targetUsername,
    String? roomId,
  }) =>
      _logAction(
        adminId: adminId,
        adminUsername: adminUsername,
        targetUserId: targetUserId,
        targetUsername: targetUsername,
        type: AdminActionType.unmute,
        roomId: roomId,
      );

  /// 🔴 BAN USER -- persistent in admin_bans + admin_actions.
  Future<bool> banUser({
    required String adminId,
    required String adminUsername,
    required String targetUserId,
    required String targetUsername,
    String? reason,
    BanDuration duration = BanDuration.permanent,
  }) async {
    try {
      final now = DateTime.now().toUtc();
      DateTime? expires;
      switch (duration) {
        case BanDuration.fiveMinutes:
          expires = now.add(const Duration(minutes: 5));
          break;
        case BanDuration.thirtyMinutes:
          expires = now.add(const Duration(minutes: 30));
          break;
        case BanDuration.oneHour:
          expires = now.add(const Duration(hours: 1));
          break;
        case BanDuration.oneDay:
          expires = now.add(const Duration(hours: 24));
          break;
        case BanDuration.permanent:
          expires = null;
          break;
      }
      final isPermanent = duration == BanDuration.permanent;

      await supabase.from('admin_bans').upsert({
        'user_id': targetUserId,
        'username': targetUsername,
        'admin_id': adminId,
        'admin_username': adminUsername,
        'reason': reason,
        'is_permanent': isPermanent,
        'expires_at': expires?.toIso8601String(),
      }, onConflict: 'user_id');

      final ok = await _logAction(
        adminId: adminId,
        adminUsername: adminUsername,
        targetUserId: targetUserId,
        targetUsername: targetUsername,
        type: isPermanent ? AdminActionType.ban : AdminActionType.timeout,
        reason: reason,
        duration: duration,
        expiresAt: expires,
      );

      // Cache lokal aktualisieren.
      _bansCache[targetUserId] = UserBanInfo(
        userId: targetUserId,
        username: targetUsername,
        adminId: adminId,
        adminUsername: adminUsername,
        reason: reason,
        bannedAt: now,
        expiresAt: expires,
        isPermanent: isPermanent,
      );
      _bannedUsersController.add(Map.unmodifiable(_bansCache));

      // v103 (4.1): Push an den gebannten User. Fire-and-forget.
      PushNotificationHelper.instance.fireAndForget(PushNotificationHelper.instance.sendToUser(
        targetUserId: targetUserId,
        type: 'admin_ban',
        title: '🚫 Account gesperrt',
        body: isPermanent
            ? 'Dein Account wurde dauerhaft gesperrt.${reason != null ? " Grund: $reason" : ""}'
            : 'Dein Account wurde vorübergehend gesperrt.${reason != null ? " Grund: $reason" : ""}',
        data: {
          'action': 'ban',
          'reason': reason,
          'is_permanent': isPermanent,
        },
      ), context: 'admin-action');

      return ok;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AdminAction.banUser: $e');
      return false;
    }
  }

  /// ✅ UNBAN USER -- loescht aus admin_bans + Audit-Log.
  Future<bool> unbanUser({
    required String adminId,
    required String adminUsername,
    required String targetUserId,
    required String targetUsername,
  }) async {
    try {
      await supabase.from('admin_bans').delete().eq('user_id', targetUserId);
      _bansCache.remove(targetUserId);
      _bannedUsersController.add(Map.unmodifiable(_bansCache));
      final ok = await _logAction(
        adminId: adminId,
        adminUsername: adminUsername,
        targetUserId: targetUserId,
        targetUsername: targetUsername,
        type: AdminActionType.unban,
      );
      // v103 (4.2): Push an den entbannten User.
      PushNotificationHelper.instance.fireAndForget(PushNotificationHelper.instance.sendToUser(
        targetUserId: targetUserId,
        type: 'admin_unban',
        title: '✅ Sperre aufgehoben',
        body: 'Deine Account-Sperre wurde aufgehoben. Willkommen zurück!',
        data: {'action': 'unban'},
      ), context: 'admin-action');
      return ok;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AdminAction.unbanUser: $e');
      return false;
    }
  }

  /// ⚠️ WARN USER -- erstellt Warning + Audit. Bei 3 Warnungen -> auto 24h Ban.
  Future<bool> warnUser({
    required String adminId,
    required String adminUsername,
    required String targetUserId,
    required String targetUsername,
    required String reason,
    String? roomId,
  }) async {
    try {
      await supabase.from('admin_warnings').insert({
        'user_id': targetUserId,
        'username': targetUsername,
        'admin_id': adminId,
        'admin_username': adminUsername,
        'reason': reason,
        'room_id': roomId,
      });
      await _logAction(
        adminId: adminId,
        adminUsername: adminUsername,
        targetUserId: targetUserId,
        targetUsername: targetUsername,
        type: AdminActionType.warning,
        reason: reason,
        roomId: roomId,
      );

      // v103 (4.3): Push an den verwarnten User. Vor dem 3-Strike-Check
      // damit auch die Warnung selbst eine Notification ausloest.
      PushNotificationHelper.instance.fireAndForget(PushNotificationHelper.instance.sendToUser(
        targetUserId: targetUserId,
        type: 'admin_warning',
        title: '⚠️ Verwarnung erhalten',
        body: 'Du hast eine Verwarnung erhalten. Grund: $reason',
        data: {'action': 'warning', 'reason': reason},
      ), context: 'admin-action');

      // 3-Strike-Rule
      final count = await getWarningCount(targetUserId);
      if (count >= 3) {
        if (kDebugMode) {
          debugPrint(
              '⚠️ AdminAction: $targetUsername hat 3 Warnungen -> Auto-24h-Ban');
        }
        await banUser(
          adminId: adminId,
          adminUsername: adminUsername,
          targetUserId: targetUserId,
          targetUsername: targetUsername,
          reason: '3 Verwarnungen erhalten',
          duration: BanDuration.oneDay,
        );
      }
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AdminAction.warnUser: $e');
      return false;
    }
  }

  /// Pruefe Ban-Status. Nutzt Cache, faellt bei Miss zu Supabase zurueck.
  Future<bool> isUserBanned(String userId) async {
    if (_bansCachePopulated) {
      final cached = _bansCache[userId];
      if (cached == null) return false;
      if (cached.isPermanent) return true;
      if (cached.expiresAt == null) return true;
      if (DateTime.now().toUtc().isAfter(cached.expiresAt!.toUtc())) {
        _bansCache.remove(userId);
        _bannedUsersController.add(Map.unmodifiable(_bansCache));
        return false;
      }
      return true;
    }
    try {
      final res = await supabase
          .from('admin_bans')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (res == null) return false;
      final ban = _rowToBan(res);
      if (!ban.isPermanent &&
          ban.expiresAt != null &&
          DateTime.now().toUtc().isAfter(ban.expiresAt!.toUtc())) {
        await supabase.from('admin_bans').delete().eq('user_id', userId);
        return false;
      }
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AdminAction.isUserBanned: $e');
      return false;
    }
  }

  Future<UserBanInfo?> getBanInfo(String userId) async {
    try {
      final res = await supabase
          .from('admin_bans')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (res == null) return null;
      return _rowToBan(res);
    } catch (_) {
      return null;
    }
  }

  Future<List<UserWarning>> getUserWarnings(String userId) async {
    try {
      final res = await supabase
          .from('admin_warnings')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (res as List).map((r) => _rowToWarning(r as Map)).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<int> getWarningCount(String userId) async {
    try {
      final res = await supabase
          .from('admin_warnings')
          .select('id')
          .eq('user_id', userId);
      return (res as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> clearWarnings(String userId) async {
    try {
      await supabase.from('admin_warnings').delete().eq('user_id', userId);
    } catch (_) {}
  }

  /// Letzte N Admin-Aktionen.
  Future<List<AdminAction>> getRecentActions(int count) async {
    try {
      final res = await supabase
          .from('admin_actions')
          .select()
          .order('created_at', ascending: false)
          .limit(count);
      return (res as List).map((r) => _rowToAction(r as Map)).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<AdminAction>> getUserActions(String userId) async {
    try {
      final res = await supabase
          .from('admin_actions')
          .select()
          .eq('target_user_id', userId)
          .order('created_at', ascending: false);
      return (res as List).map((r) => _rowToAction(r as Map)).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Slow-Mode (In-Memory).
  void setSlowMode(String roomId, int seconds) {
    if (seconds > 0) {
      _slowModeSettings[roomId] = seconds;
    } else {
      _slowModeSettings.remove(roomId);
    }
  }

  int getSlowMode(String roomId) => _slowModeSettings[roomId] ?? 0;

  /// Cache initial befuellen + Realtime-Subscription.
  /// Wird beim ersten getBans()-Aufruf oder explizit via initialize() benutzt.
  Future<void> initialize() async {
    if (_bansCachePopulated) return;
    try {
      final res = await supabase.from('admin_bans').select();
      for (final r in (res as List)) {
        final ban = _rowToBan(r as Map);
        _bansCache[ban.userId] = ban;
      }
      _bansCachePopulated = true;
      _bannedUsersController.add(Map.unmodifiable(_bansCache));

      // Realtime-Channel fuer Ban-Aenderungen.
      _bansChannel = supabase
          .channel('admin_bans_changes')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'admin_bans',
            callback: _onBanChange,
          )
          .subscribe();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AdminAction.initialize: $e');
    }
  }

  Future<void> dispose() async {
    await _bansChannel?.unsubscribe();
    await _actionLogController.close();
    await _bannedUsersController.close();
  }

  // ── INTERNAL ──────────────────────────────────────────────────────────────

  Future<bool> _logAction({
    required String adminId,
    required String adminUsername,
    required String targetUserId,
    required String targetUsername,
    required AdminActionType type,
    String? reason,
    String? roomId,
    BanDuration? duration,
    DateTime? expiresAt,
  }) async {
    try {
      await supabase.from('admin_actions').insert({
        'admin_id': adminId,
        'admin_username': adminUsername,
        'target_user_id': targetUserId,
        'target_username': targetUsername,
        'action_type': _typeToString(type),
        'reason': reason,
        'room_id': roomId,
        'duration': duration?.name,
        'expires_at': expiresAt?.toIso8601String(),
      });
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AdminAction._logAction: $e');
      return false;
    }
  }

  void _onBanChange(PostgresChangePayload payload) {
    try {
      final newRow = payload.newRecord;
      final oldRow = payload.oldRecord;
      if (payload.eventType == PostgresChangeEvent.delete) {
        final uid = (oldRow['user_id'] as String?) ?? '';
        if (uid.isNotEmpty) _bansCache.remove(uid);
      } else {
        final ban = _rowToBan(newRow);
        _bansCache[ban.userId] = ban;
      }
      _bannedUsersController.add(Map.unmodifiable(_bansCache));
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AdminAction._onBanChange: $e');
    }
  }

  static String _typeToString(AdminActionType t) {
    switch (t) {
      case AdminActionType.kick:
        return 'kick';
      case AdminActionType.mute:
        return 'mute';
      case AdminActionType.unmute:
        return 'unmute';
      case AdminActionType.ban:
        return 'ban';
      case AdminActionType.unban:
        return 'unban';
      case AdminActionType.timeout:
        return 'timeout';
      case AdminActionType.warning:
        return 'warning';
      case AdminActionType.deleteMessage:
        return 'delete_message';
      case AdminActionType.slowMode:
        return 'slow_mode';
    }
  }

  static AdminActionType _typeFromString(String s) {
    switch (s) {
      case 'kick':
        return AdminActionType.kick;
      case 'mute':
        return AdminActionType.mute;
      case 'unmute':
        return AdminActionType.unmute;
      case 'ban':
        return AdminActionType.ban;
      case 'unban':
        return AdminActionType.unban;
      case 'timeout':
        return AdminActionType.timeout;
      case 'warning':
        return AdminActionType.warning;
      case 'delete_message':
        return AdminActionType.deleteMessage;
      case 'slow_mode':
        return AdminActionType.slowMode;
      default:
        return AdminActionType.warning;
    }
  }

  UserBanInfo _rowToBan(Map row) => UserBanInfo(
        userId: row['user_id'] as String,
        username: row['username'] as String? ?? '',
        adminId: row['admin_id'] as String? ?? '',
        adminUsername: row['admin_username'] as String? ?? '',
        reason: row['reason'] as String?,
        bannedAt: DateTime.parse(row['created_at'] as String),
        expiresAt: row['expires_at'] == null
            ? null
            : DateTime.parse(row['expires_at'] as String),
        isPermanent: row['is_permanent'] as bool? ?? true,
      );

  UserWarning _rowToWarning(Map row) => UserWarning(
        id: row['id'] as String,
        userId: row['user_id'] as String,
        username: row['username'] as String? ?? '',
        adminId: row['admin_id'] as String? ?? '',
        adminUsername: row['admin_username'] as String? ?? '',
        reason: row['reason'] as String? ?? '',
        timestamp: DateTime.parse(row['created_at'] as String),
        roomId: row['room_id'] as String?,
      );

  AdminAction _rowToAction(Map row) => AdminAction(
        id: row['id'] as String,
        adminId: row['admin_id'] as String? ?? '',
        adminUsername: row['admin_username'] as String? ?? '',
        targetUserId: row['target_user_id'] as String? ?? '',
        targetUsername: row['target_username'] as String? ?? '',
        type: _typeFromString(row['action_type'] as String? ?? 'warning'),
        reason: row['reason'] as String?,
        timestamp: DateTime.parse(row['created_at'] as String),
        roomId: row['room_id'] as String?,
        duration: row['duration'] == null
            ? null
            : _durationFromString(row['duration'] as String),
        expiresAt: row['expires_at'] == null
            ? null
            : DateTime.parse(row['expires_at'] as String),
      );

  static BanDuration _durationFromString(String s) {
    switch (s) {
      case 'fiveMinutes':
        return BanDuration.fiveMinutes;
      case 'thirtyMinutes':
        return BanDuration.thirtyMinutes;
      case 'oneHour':
        return BanDuration.oneHour;
      case 'oneDay':
        return BanDuration.oneDay;
      default:
        return BanDuration.permanent;
    }
  }
}
