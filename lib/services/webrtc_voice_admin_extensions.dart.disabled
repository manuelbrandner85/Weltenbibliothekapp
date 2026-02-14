/// WEBRTC VOICE ADMIN EXTENSIONS
/// Erweiterte Admin-Funktionen für Voice Chat
/// 
/// Features:
/// - Kick mit Grund & Cooldown
/// - Mute/Unmute mit Admin-Lock
/// - Ban aus Voice Chat
/// - Participant-Info für Admins
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/admin_action.dart';

/// Voice Admin Actions Extension
extension WebRTCVoiceAdminExtensions on dynamic {
  
  /// 🚫 KICK USER WITH REASON (Enhanced)
  Future<bool> kickUserWithReason({
    required String userId,
    required String username,
    required String adminId,
    required String adminUsername,
    String? reason,
    String? roomId,
  }) async {
    try {
      // Log admin action
      await adminService.kickUser(
        adminId: adminId,
        adminUsername: adminUsername,
        targetUserId: userId,
        targetUsername: username,
        reason: reason,
        roomId: roomId,
      );
      
      // Perform kick
      final success = await kickUser(
        userId: userId,
        adminId: adminId,
      );
      
      if (success && kDebugMode) {
        debugPrint('🚫 [VOICE ADMIN] $adminUsername kicked $username${reason != null ? " (Grund: $reason)" : ""}');
      }
      
      return success;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [VOICE ADMIN] Kick with reason failed: $e');
      }
      return false;
    }
  }
  
  /// 🔇 MUTE USER WITH REASON (Enhanced)
  Future<bool> muteUserWithReason({
    required String userId,
    required String username,
    required String adminId,
    required String adminUsername,
    String? reason,
    String? roomId,
  }) async {
    try {
      // Log admin action
      await adminService.muteUser(
        adminId: adminId,
        adminUsername: adminUsername,
        targetUserId: userId,
        targetUsername: username,
        reason: reason,
        roomId: roomId,
      );
      
      // Perform mute
      final success = await muteUser(
        userId: userId,
        adminId: adminId,
      );
      
      if (success && kDebugMode) {
        debugPrint('🔇 [VOICE ADMIN] $adminUsername muted $username${reason != null ? " (Grund: $reason)" : ""}');
      }
      
      return success;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [VOICE ADMIN] Mute with reason failed: $e');
      }
      return false;
    }
  }
  
  /// 🔊 UNMUTE USER (New)
  Future<bool> unmuteUser({
    required String userId,
    required String username,
    required String adminId,
    required String adminUsername,
    String? roomId,
  }) async {
    try {
      // Log admin action
      await adminService.unmuteUser(
        adminId: adminId,
        adminUsername: adminUsername,
        targetUserId: userId,
        targetUsername: username,
        roomId: roomId,
      );
      
      // Send unmute message via signaling
      if (_currentRoomId == null) {
        if (kDebugMode) {
          debugPrint('❌ WebRTC: Cannot unmute - not in room');
        }
        return false;
      }
      
      await _signaling.sendMessage(
        room: _currentRoomId!,
        message: jsonEncode({
          'type': 'voice_admin_unmute',
          'userId': userId,
          'adminId': adminId,
          'muted': false,
        }),
        username: 'admin',
        realm: 'voice',
      );
      
      // Update participant state
      if (_participants.containsKey(userId)) {
        _participants[userId] = _participants[userId]!.copyWith(isMuted: false);
        _participantsController.add(participants);
      }
      
      if (kDebugMode) {
        debugPrint('🔊 [VOICE ADMIN] $adminUsername unmuted $username');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [VOICE ADMIN] Unmute failed: $e');
      }
      return false;
    }
  }
  
  /// ⚠️ WARN USER (New)
  Future<bool> warnUserInVoice({
    required String userId,
    required String username,
    required String adminId,
    required String adminUsername,
    required String reason,
    String? roomId,
  }) async {
    try {
      // Log warning
      final success = await adminService.warnUser(
        adminId: adminId,
        adminUsername: adminUsername,
        targetUserId: userId,
        targetUsername: username,
        reason: reason,
        roomId: roomId,
      );
      
      if (success) {
        // Send warning notification via signaling
        if (_currentRoomId != null) {
          await _signaling.sendMessage(
            room: _currentRoomId!,
            message: jsonEncode({
              'type': 'voice_warning',
              'userId': userId,
              'adminId': adminId,
              'reason': reason,
              'warningCount': adminService.getWarningCount(userId),
            }),
            username: 'admin',
            realm: 'voice',
          );
        }
        
        if (kDebugMode) {
          final count = adminService.getWarningCount(userId);
          debugPrint('⚠️ [VOICE ADMIN] $adminUsername warned $username ($count/3) - Grund: $reason');
        }
      }
      
      return success;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [VOICE ADMIN] Warning failed: $e');
      }
      return false;
    }
  }
  
  /// 🔴 BAN USER FROM VOICE (New)
  Future<bool> banUserFromVoice({
    required String userId,
    required String username,
    required String adminId,
    required String adminUsername,
    String? reason,
    BanDuration duration = BanDuration.permanent,
    String? roomId,
  }) async {
    try {
      // Log ban
      await adminService.banUser(
        adminId: adminId,
        adminUsername: adminUsername,
        targetUserId: userId,
        targetUsername: username,
        reason: reason,
        duration: duration,
      );
      
      // Kick user from voice chat
      await kickUser(
        userId: userId,
        adminId: adminId,
      );
      
      // Send ban notification
      if (_currentRoomId != null) {
        await _signaling.sendMessage(
          room: _currentRoomId!,
          message: jsonEncode({
            'type': 'voice_ban',
            'userId': userId,
            'adminId': adminId,
            'reason': reason,
            'duration': duration.name,
          }),
          username: 'admin',
          realm: 'voice',
        );
      }
      
      if (kDebugMode) {
        debugPrint('🔴 [VOICE ADMIN] $adminUsername banned $username from voice (${duration.name})${reason != null ? " - Grund: $reason" : ""}');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [VOICE ADMIN] Ban failed: $e');
      }
      return false;
    }
  }
  
  /// Check if user is banned from voice
  bool isUserBannedFromVoice(String userId) {
    return adminService.isUserBanned(userId);
  }
  
  /// Get participant info for admin view
  Map<String, dynamic> getParticipantAdminInfo(String userId) {
    final banInfo = adminService.getBanInfo(userId);
    final warnings = adminService.getUserWarnings(userId);
    final actions = adminService.getUserActions(userId);
    
    return {
      'userId': userId,
      'isBanned': banInfo != null,
      'banInfo': banInfo?.toJson(),
      'warningCount': warnings.length,
      'warnings': warnings.map((w) => w.toJson()).toList(),
      'recentActions': actions.take(5).map((a) => a.toJson()).toList(),
    };
  }
}
