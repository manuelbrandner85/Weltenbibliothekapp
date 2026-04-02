/// 💾 UNIFIED STORAGE SERVICE - Universal Storage API
/// 
/// Provides a unified interface for all storage operations.
/// Delegates to appropriate storage backends (Hive, SharedPreferences, Cloudflare).
library;

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';
import 'offline_storage_service.dart';
import 'local_chat_storage_service.dart';

/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// 📦 UNIFIED STORAGE SERVICE
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class UnifiedStorageService {
  static final UnifiedStorageService _instance = UnifiedStorageService._internal();
  factory UnifiedStorageService() => _instance;
  UnifiedStorageService._internal();

  final StorageService _storageService = StorageService();
  final OfflineStorageService _offlineStorage = OfflineStorageService();
  final LocalChatStorageService _chatStorage = LocalChatStorageService();

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

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// 🔧 GENERIC HELPERS
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Get string value from shared preferences
  Future<String?> getString(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (e) {
      debugPrint('❌ Error getting string: $e');
      return null;
    }
  }

  /// Set string value in shared preferences
  Future<bool> setString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(key, value);
    } catch (e) {
      debugPrint('❌ Error setting string: $e');
      return false;
    }
  }
}
