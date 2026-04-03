/// 💾 UNIFIED STORAGE SERVICE - Universal Storage API
/// 
/// Provides a unified interface for all storage operations.
/// Works with Hive and SharedPreferences for local storage.
library;

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// 📦 UNIFIED STORAGE SERVICE
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class UnifiedStorageService {
  static final UnifiedStorageService _instance = UnifiedStorageService._internal();
  factory UnifiedStorageService() => _instance;
  UnifiedStorageService._internal();

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// 👤 USER MANAGEMENT
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Get current user ID
  Future<String?> getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_id');
    } catch (e) {
      debugPrint('❌ Error getting user ID: $e');
      return null;
    }
  }

  /// Save current user ID
  Future<void> saveCurrentUserId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', userId);
    } catch (e) {
      debugPrint('❌ Error saving user ID: $e');
    }
  }

  /// Get username for world
  String? getUsername(String world) {
    try {
      // Box muss geöffnet sein (wird in main.dart geöffnet)
      if (!Hive.isBoxOpen('user_data')) return null;
      final box = Hive.box('user_data');
      return box.get('username_$world') as String?;
    } catch (e) {
      debugPrint('❌ Error getting username: $e');
      return null;
    }
  }

  /// Get user role for world
  String? getRole(String world) {
    try {
      if (!Hive.isBoxOpen('user_data')) return 'user';
      final box = Hive.box('user_data');
      return box.get('role_$world') as String?;
    } catch (e) {
      debugPrint('❌ Error getting role: $e');
      return 'user'; // Default role
    }
  }

  /// Get user profile for world
  Map<String, dynamic>? getProfile(String world) {
    try {
      if (!Hive.isBoxOpen('user_data')) return null;
      final box = Hive.box('user_data');
      return box.get('profile_$world') as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('❌ Error getting profile: $e');
      return null;
    }
  }

  /// Save user profile for world
  /// Also writes username_ and role_ keys so AdminStateNotifier can read them.
  Future<void> saveProfile(String world, Map<String, dynamic> profile) async {
    try {
      // Öffne Box falls noch nicht geöffnet
      if (!Hive.isBoxOpen('user_data')) {
        await Hive.openBox('user_data');
      }
      final box = Hive.box('user_data');
      await box.put('profile_$world', profile);
      // Mirror username and role for fast synchronous reads used by AdminStateNotifier
      final username = profile['username'] as String?;
      final role = profile['role'] as String?;
      if (username != null && username.isNotEmpty) {
        await box.put('username_$world', username);
      }
      if (role != null && role.isNotEmpty) {
        await box.put('role_$world', role);
      }
    } catch (e) {
      debugPrint('❌ Error saving profile: $e');
    }
  }

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// 🔖 BOOKMARKS
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Get all bookmarks for current user
  Future<List<Map<String, dynamic>>> getBookmarks() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) return [];

      final box = await Hive.openBox('bookmarks_$userId');
      return box.values.cast<Map<String, dynamic>>().toList();
    } catch (e) {
      debugPrint('❌ Error getting bookmarks: $e');
      return [];
    }
  }

  /// Add bookmark
  Future<void> addBookmark(Map<String, dynamic> bookmark) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) return;

      final box = await Hive.openBox('bookmarks_$userId');
      final bookmarkId = bookmark['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
      await box.put(bookmarkId, bookmark);
      
      debugPrint('✅ Bookmark added: $bookmarkId');
    } catch (e) {
      debugPrint('❌ Error adding bookmark: $e');
    }
  }

  /// Remove bookmark
  Future<void> removeBookmark(String bookmarkId) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) return;

      final box = await Hive.openBox('bookmarks_$userId');
      await box.delete(bookmarkId);
      
      debugPrint('✅ Bookmark removed: $bookmarkId');
    } catch (e) {
      debugPrint('❌ Error removing bookmark: $e');
    }
  }

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// 📚 READING HISTORY
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Get reading history
  Future<List<Map<String, dynamic>>> getReadingHistory() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) return [];

      final box = await Hive.openBox('reading_history_$userId');
      return box.values.cast<Map<String, dynamic>>().toList();
    } catch (e) {
      debugPrint('❌ Error getting reading history: $e');
      return [];
    }
  }

  /// Add to reading history
  Future<void> addToReadingHistory(Map<String, dynamic> item) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) return;

      final box = await Hive.openBox('reading_history_$userId');
      final itemId = item['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
      
      // Add timestamp
      item['timestamp'] = DateTime.now().toIso8601String();
      
      await box.put(itemId, item);
      debugPrint('✅ Added to reading history: $itemId');
    } catch (e) {
      debugPrint('❌ Error adding to reading history: $e');
    }
  }

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// 📋 READING LISTS
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Create reading list
  Future<void> createReadingList(String name, List<String> items) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) return;

      final box = await Hive.openBox('reading_lists_$userId');
      final listId = DateTime.now().millisecondsSinceEpoch.toString();
      
      await box.put(listId, {
        'id': listId,
        'name': name,
        'items': items,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      debugPrint('✅ Reading list created: $name');
    } catch (e) {
      debugPrint('❌ Error creating reading list: $e');
    }
  }

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// 🔔 NOTIFICATION PREFERENCES
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Get notification preferences
  Future<Map<String, dynamic>> getNotificationPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'chat_notifications': prefs.getBool('notif_chat') ?? true,
        'research_notifications': prefs.getBool('notif_research') ?? true,
        'admin_notifications': prefs.getBool('notif_admin') ?? true,
        'sound_enabled': prefs.getBool('notif_sound') ?? true,
        'vibration_enabled': prefs.getBool('notif_vibration') ?? true,
      };
    } catch (e) {
      debugPrint('❌ Error getting notification preferences: $e');
      return {};
    }
  }

  /// Save notification preference
  Future<void> saveNotificationPreference(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notif_$key', value);
      debugPrint('✅ Notification preference saved: $key = $value');
    } catch (e) {
      debugPrint('❌ Error saving notification preference: $e');
    }
  }

  /// Save notification preference (String value)
  Future<void> saveNotificationPreferenceString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('notif_$key', value);
      debugPrint('✅ Notification preference saved: $key = $value');
    } catch (e) {
      debugPrint('❌ Error saving notification preference: $e');
    }
  }

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// 🗑️ CACHE MANAGEMENT
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Clear all caches
  Future<void> clearAllCaches() async {
    try {
      final userId = await getCurrentUserId();
      if (userId != null) {
        await Hive.box('bookmarks_$userId').clear();
        await Hive.box('reading_history_$userId').clear();
        await Hive.box('reading_lists_$userId').clear();
      }
      debugPrint('✅ All caches cleared');
    } catch (e) {
      debugPrint('❌ Error clearing caches: $e');
    }
  }
}
