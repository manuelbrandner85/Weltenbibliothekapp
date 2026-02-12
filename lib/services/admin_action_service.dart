/// ADMIN ACTION SERVICE
/// Verwaltet alle Admin-Aktionen: Kick, Mute, Ban, Timeout, Warnings
/// 
/// Features:
/// - Log aller Admin-Aktionen
/// - Ban-System (permanent & temporary)
/// - Warning-System (3-Strike-Rule)
/// - Timeout-System
/// - Admin-Transparenz

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/admin_action.dart';

class AdminActionService {
  // In-Memory Storage (in production würde man Firestore verwenden)
  final List<AdminAction> _actionLog = [];
  final Map<String, UserBanInfo> _bannedUsers = {};
  final Map<String, List<UserWarning>> _userWarnings = {};
  final Map<String, int> _slowModeSettings = {}; // roomId -> seconds
  
  // Streams für Echtzeit-Updates
  final _actionLogController = StreamController<List<AdminAction>>.broadcast();
  final _bannedUsersController = StreamController<Map<String, UserBanInfo>>.broadcast();
  final _warningsController = StreamController<Map<String, List<UserWarning>>>.broadcast();
  
  Stream<List<AdminAction>> get actionLogStream => _actionLogController.stream;
  Stream<Map<String, UserBanInfo>> get bannedUsersStream => _bannedUsersController.stream;
  Stream<Map<String, List<UserWarning>>> get warningsStream => _warningsController.stream;
  
  // Getters
  List<AdminAction> get actionLog => List.unmodifiable(_actionLog);
  Map<String, UserBanInfo> get bannedUsers => Map.unmodifiable(_bannedUsers);
  
  /// 🚫 KICK USER (aus Voice Chat entfernen)
  Future<bool> kickUser({
    required String adminId,
    required String adminUsername,
    required String targetUserId,
    required String targetUsername,
    String? reason,
    String? roomId,
  }) async {
    try {
      final action = AdminAction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        adminId: adminId,
        adminUsername: adminUsername,
        targetUserId: targetUserId,
        targetUsername: targetUsername,
        type: AdminActionType.kick,
        reason: reason,
        timestamp: DateTime.now(),
        roomId: roomId,
      );
      
      _actionLog.insert(0, action);
      _actionLogController.add(actionLog);
      
      if (kDebugMode) {
        debugPrint('🚫 [ADMIN] $adminUsername kicked $targetUsername${reason != null ? " (Grund: $reason)" : ""}');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [ADMIN] Kick failed: $e');
      }
      return false;
    }
  }
  
  /// 🔇 MUTE USER (Voice Chat)
  Future<bool> muteUser({
    required String adminId,
    required String adminUsername,
    required String targetUserId,
    required String targetUsername,
    String? reason,
    String? roomId,
  }) async {
    try {
      final action = AdminAction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        adminId: adminId,
        adminUsername: adminUsername,
        targetUserId: targetUserId,
        targetUsername: targetUsername,
        type: AdminActionType.mute,
        reason: reason,
        timestamp: DateTime.now(),
        roomId: roomId,
      );
      
      _actionLog.insert(0, action);
      _actionLogController.add(actionLog);
      
      if (kDebugMode) {
        debugPrint('🔇 [ADMIN] $adminUsername muted $targetUsername${reason != null ? " (Grund: $reason)" : ""}');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [ADMIN] Mute failed: $e');
      }
      return false;
    }
  }
  
  /// 🔊 UNMUTE USER (Stummschaltung aufheben)
  Future<bool> unmuteUser({
    required String adminId,
    required String adminUsername,
    required String targetUserId,
    required String targetUsername,
    String? roomId,
  }) async {
    try {
      final action = AdminAction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        adminId: adminId,
        adminUsername: adminUsername,
        targetUserId: targetUserId,
        targetUsername: targetUsername,
        type: AdminActionType.unmute,
        timestamp: DateTime.now(),
        roomId: roomId,
      );
      
      _actionLog.insert(0, action);
      _actionLogController.add(actionLog);
      
      if (kDebugMode) {
        debugPrint('🔊 [ADMIN] $adminUsername unmuted $targetUsername');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [ADMIN] Unmute failed: $e');
      }
      return false;
    }
  }
  
  /// 🔴 BAN USER (Permanent oder Temporär)
  Future<bool> banUser({
    required String adminId,
    required String adminUsername,
    required String targetUserId,
    required String targetUsername,
    String? reason,
    BanDuration duration = BanDuration.permanent,
  }) async {
    try {
      final now = DateTime.now();
      DateTime? expiresAt;
      
      // Berechne Ablaufzeit basierend auf Duration
      if (duration != BanDuration.permanent) {
        switch (duration) {
          case BanDuration.fiveMinutes:
            expiresAt = now.add(const Duration(minutes: 5));
            break;
          case BanDuration.thirtyMinutes:
            expiresAt = now.add(const Duration(minutes: 30));
            break;
          case BanDuration.oneHour:
            expiresAt = now.add(const Duration(hours: 1));
            break;
          case BanDuration.oneDay:
            expiresAt = now.add(const Duration(hours: 24));
            break;
          case BanDuration.permanent:
            expiresAt = null;
            break;
        }
      }
      
      final banInfo = UserBanInfo(
        userId: targetUserId,
        username: targetUsername,
        adminId: adminId,
        adminUsername: adminUsername,
        reason: reason,
        bannedAt: now,
        expiresAt: expiresAt,
        isPermanent: duration == BanDuration.permanent,
      );
      
      _bannedUsers[targetUserId] = banInfo;
      _bannedUsersController.add(bannedUsers);
      
      final action = AdminAction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        adminId: adminId,
        adminUsername: adminUsername,
        targetUserId: targetUserId,
        targetUsername: targetUsername,
        type: duration == BanDuration.permanent 
            ? AdminActionType.ban 
            : AdminActionType.timeout,
        reason: reason,
        timestamp: now,
        duration: duration,
        expiresAt: expiresAt,
      );
      
      _actionLog.insert(0, action);
      _actionLogController.add(actionLog);
      
      if (kDebugMode) {
        debugPrint('🔴 [ADMIN] $adminUsername banned $targetUsername (${duration.name})${reason != null ? " (Grund: $reason)" : ""}');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [ADMIN] Ban failed: $e');
      }
      return false;
    }
  }
  
  /// ✅ UNBAN USER (Ban aufheben)
  Future<bool> unbanUser({
    required String adminId,
    required String adminUsername,
    required String targetUserId,
    required String targetUsername,
  }) async {
    try {
      _bannedUsers.remove(targetUserId);
      _bannedUsersController.add(bannedUsers);
      
      final action = AdminAction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        adminId: adminId,
        adminUsername: adminUsername,
        targetUserId: targetUserId,
        targetUsername: targetUsername,
        type: AdminActionType.unban,
        timestamp: DateTime.now(),
      );
      
      _actionLog.insert(0, action);
      _actionLogController.add(actionLog);
      
      if (kDebugMode) {
        debugPrint('✅ [ADMIN] $adminUsername unbanned $targetUsername');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [ADMIN] Unban failed: $e');
      }
      return false;
    }
  }
  
  /// ⚠️ WARN USER (Verwarnung aussprechen)
  Future<bool> warnUser({
    required String adminId,
    required String adminUsername,
    required String targetUserId,
    required String targetUsername,
    required String reason,
    String? roomId,
  }) async {
    try {
      final warning = UserWarning(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: targetUserId,
        username: targetUsername,
        adminId: adminId,
        adminUsername: adminUsername,
        reason: reason,
        timestamp: DateTime.now(),
        roomId: roomId,
      );
      
      if (!_userWarnings.containsKey(targetUserId)) {
        _userWarnings[targetUserId] = [];
      }
      _userWarnings[targetUserId]!.add(warning);
      _warningsController.add(_userWarnings);
      
      final action = AdminAction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        adminId: adminId,
        adminUsername: adminUsername,
        targetUserId: targetUserId,
        targetUsername: targetUsername,
        type: AdminActionType.warning,
        reason: reason,
        timestamp: DateTime.now(),
        roomId: roomId,
      );
      
      _actionLog.insert(0, action);
      _actionLogController.add(actionLog);
      
      // 3-Strike-Rule: Bei 3 Verwarnungen automatisch 24h Ban
      final warningCount = _userWarnings[targetUserId]!.length;
      if (warningCount >= 3) {
        if (kDebugMode) {
          debugPrint('⚠️ [ADMIN] $targetUsername hat 3 Verwarnungen → Automatischer 24h Ban');
        }
        await banUser(
          adminId: adminId,
          adminUsername: adminUsername,
          targetUserId: targetUserId,
          targetUsername: targetUsername,
          reason: '3 Verwarnungen erhalten',
          duration: BanDuration.oneDay,
        );
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ [ADMIN] $adminUsername warned $targetUsername ($warningCount/3) - Grund: $reason');
        }
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [ADMIN] Warning failed: $e');
      }
      return false;
    }
  }
  
  /// 🐌 SET SLOW MODE (Rate Limiting)
  void setSlowMode(String roomId, int seconds) {
    if (seconds > 0) {
      _slowModeSettings[roomId] = seconds;
      if (kDebugMode) {
        debugPrint('🐌 [ADMIN] Slow mode set to $seconds seconds for room $roomId');
      }
    } else {
      _slowModeSettings.remove(roomId);
      if (kDebugMode) {
        debugPrint('🐌 [ADMIN] Slow mode disabled for room $roomId');
      }
    }
  }
  
  /// Check if user is banned
  bool isUserBanned(String userId) {
    final banInfo = _bannedUsers[userId];
    if (banInfo == null) return false;
    
    // Check if temporary ban expired
    if (!banInfo.isPermanent && banInfo.expiresAt != null) {
      if (DateTime.now().isAfter(banInfo.expiresAt!)) {
        _bannedUsers.remove(userId);
        _bannedUsersController.add(bannedUsers);
        return false;
      }
    }
    
    return true;
  }
  
  /// Get ban info for user
  UserBanInfo? getBanInfo(String userId) {
    return _bannedUsers[userId];
  }
  
  /// Get warnings for user
  List<UserWarning> getUserWarnings(String userId) {
    return _userWarnings[userId] ?? [];
  }
  
  /// Get warning count
  int getWarningCount(String userId) {
    return _userWarnings[userId]?.length ?? 0;
  }
  
  /// Get slow mode setting for room
  int getSlowMode(String roomId) {
    return _slowModeSettings[roomId] ?? 0;
  }
  
  /// Get recent actions (last N)
  List<AdminAction> getRecentActions(int count) {
    return _actionLog.take(count).toList();
  }
  
  /// Get actions for specific user
  List<AdminAction> getUserActions(String userId) {
    return _actionLog.where((a) => a.targetUserId == userId).toList();
  }
  
  /// Clear all warnings for user
  void clearWarnings(String userId) {
    _userWarnings.remove(userId);
    _warningsController.add(_userWarnings);
  }
  
  /// Dispose
  void dispose() {
    _actionLogController.close();
    _bannedUsersController.close();
    _warningsController.close();
  }
}
