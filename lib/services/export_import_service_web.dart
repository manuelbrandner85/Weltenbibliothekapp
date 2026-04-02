/// Data Export/Import Service (WEB VERSION)
/// Backup and restore app data as JSON
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'spirit_journal_service.dart';
import 'synchronicity_service.dart';
import 'streak_tracking_service.dart';
import 'dart:html' as html; // 🌐 Web-only

/// Export/Import Service
class ExportImportService {
  static final ExportImportService _instance = ExportImportService._internal();
  factory ExportImportService() => _instance;
  ExportImportService._internal();

  final SpiritJournalService _journalService = SpiritJournalService();
  final SynchronicityService _syncService = SynchronicityService();
  // UNUSED FIELD: final FavoritesService _favoritesService = FavoritesService();
  final StreakTrackingService _streakService = StreakTrackingService();
  // UNUSED FIELD: final AchievementService _achievementService = AchievementService();

  // ============================================
  // EXPORT
  // ============================================

  /// Export all data to JSON
  Future<Map<String, dynamic>> exportAllData() async {
    try {
      if (kDebugMode) {
        debugPrint('📤 Exporting all data...');
      }

      // Gather all data
      final exportData = {
        'version': '1.0.0',
        'exported_at': DateTime.now().toIso8601String(),
        'app': 'Weltenbibliothek',
        'data': {
          'journal_entries': _journalService.entries.map((e) => e.toJson()).toList(),
          'synchronicity_entries': _syncService.entries.map((e) => e.toJson()).toList(),
          'favorites': await _exportFavorites(),
          'streak_data': await _exportStreakData(),
          'achievements': await _exportAchievements(),
          'settings': await _exportSettings(),
        },
        'statistics': {
          'total_journal_entries': _journalService.entries.length,
          'total_synchronicities': _syncService.entries.length,
          'total_favorites': (await _exportFavorites()).length,
          'current_streak': _streakService.currentStreak,
          'longest_streak': _streakService.longestStreak,
          'unlocked_achievements': 0, // _achievementService.unlockedCount,
        },
      };

      if (kDebugMode) {
        debugPrint('✅ Export complete: ${_journalService.entries.length} journal, ${_syncService.entries.length} sync');
      }

      return exportData;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Export error: $e');
      }
      rethrow;
    }
  }

  /// Export favorites
  Future<List<Map<String, dynamic>>> _exportFavorites() async {
    // Note: FavoritesService only stores IDs, not full objects
    // We return a simplified structure
    return []; // Simplified - favorites are IDs only
  }

  /// Export streak data
  Future<Map<String, dynamic>> _exportStreakData() async {
    return {
      'current_streak': _streakService.currentStreak,
      'longest_streak': _streakService.longestStreak,
      'login_history': _streakService.loginHistory
          .map((d) => d.toIso8601String())
          .toList(),
    };
  }

  /// Export achievements
  Future<Map<String, dynamic>> _exportAchievements() async {
    return {
      'unlocked_count': 0, // _achievementService.unlockedCount,
      // Note: Achievement details are derived from AchievementsData
    };
  }

  /// Export settings
  Future<Map<String, dynamic>> _exportSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'notifications_enabled': prefs.getBool('notifications_enabled') ?? false,
        'auto_sync_enabled': prefs.getBool('auto_sync_enabled') ?? false,
        'theme_mode': prefs.getString('theme_mode') ?? 'dark',
      };
    } catch (e) {
      return {};
    }
  }

  /// Download export as JSON file
  Future<void> downloadExportFile() async {
    if (!kIsWeb) {
      throw Exception('Download is only supported on web platform');
    }

    try {
      // Export data
      final exportData = await exportAllData();
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // Create filename with timestamp
      final timestamp = DateTime.now().toIso8601String().split('.')[0].replaceAll(':', '-');
      final filename = 'weltenbibliothek_backup_$timestamp.json';

      // Create download link
      final bytes = utf8.encode(jsonString);
      final blob = html.Blob([bytes], 'application/json');
      final url = html.Url.createObjectUrlFromBlob(blob);

      // Trigger download
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();

      // Cleanup
      html.Url.revokeObjectUrl(url);

      if (kDebugMode) {
        debugPrint('✅ Download triggered: $filename');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Download error: $e');
      }
      rethrow;
    }
  }

  // ============================================
  // IMPORT
  // ============================================

  /// Import data from JSON
  Future<ImportResult> importData(String jsonString) async {
    try {
      if (kDebugMode) {
        debugPrint('📥 Importing data...');
      }

      // Parse JSON
      final importData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate version
      final version = importData['version'] as String?;
      if (version == null) {
        return ImportResult(
          success: false,
          message: 'Invalid backup file: missing version',
        );
      }

      // Extract data
      final data = importData['data'] as Map<String, dynamic>?;
      if (data == null) {
        return ImportResult(
          success: false,
          message: 'Invalid backup file: missing data',
        );
      }

      int importedCount = 0;

      // Import journal entries
      if (data['journal_entries'] != null) {
        final entries = (data['journal_entries'] as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
        for (final entry in entries) {
          await _journalService.createEntry(
            category: entry['category'] ?? 'meditation',
            content: entry['content'] ?? '',
            mood: entry['mood'] ?? 'neutral',
            tags: List<String>.from(entry['tags'] ?? []),
            rating: entry['rating'] ?? 3,
          );
          importedCount++;
        }
      }

      // Import synchronicity entries
      if (data['synchronicity_entries'] != null) {
        final entries = (data['synchronicity_entries'] as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
        for (final entry in entries) {
          // Parse numbers correctly
          final numbers = (entry['numbers'] as List?)
              ?.map((n) => n is int ? n : int.tryParse(n.toString()) ?? 0)
              .toList();
          
          await _syncService.createEntry(
            event: entry['event'] ?? '',
            meaning: entry['meaning'] ?? '',
            significance: entry['significance'] ?? 3,
            numbers: numbers,
            tags: List<String>.from(entry['tags'] ?? []),
          );
          importedCount++;
        }
      }

      // Import settings
      if (data['settings'] != null) {
        await _importSettings(data['settings'] as Map<String, dynamic>);
      }

      if (kDebugMode) {
        debugPrint('✅ Import complete: $importedCount items');
      }

      return ImportResult(
        success: true,
        message: '$importedCount Einträge importiert',
        importedCount: importedCount,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Import error: $e');
      }

      return ImportResult(
        success: false,
        message: 'Import fehlgeschlagen: $e',
      );
    }
  }

  /// Import settings
  Future<void> _importSettings(Map<String, dynamic> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (settings['notifications_enabled'] != null) {
        await prefs.setBool('notifications_enabled', settings['notifications_enabled']);
      }
      if (settings['auto_sync_enabled'] != null) {
        await prefs.setBool('auto_sync_enabled', settings['auto_sync_enabled']);
      }
      if (settings['theme_mode'] != null) {
        await prefs.setString('theme_mode', settings['theme_mode']);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Settings import error: $e');
      }
    }
  }

  /// Import from file (web file picker)
  Future<ImportResult> importFromFile() async {
    if (!kIsWeb) {
      throw Exception('File picker is only supported on web platform');
    }

    try {
      // Create file input
      final input = html.FileUploadInputElement()..accept = '.json';
      input.click();

      // Wait for file selection
      await input.onChange.first;

      if (input.files?.isEmpty ?? true) {
        return ImportResult(
          success: false,
          message: 'Keine Datei ausgewählt',
        );
      }

      final file = input.files![0];
      final reader = html.FileReader();

      // Read file
      reader.readAsText(file);
      await reader.onLoad.first;

      final jsonString = reader.result as String;

      // Import data
      return await importData(jsonString);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ File import error: $e');
      }

      return ImportResult(
        success: false,
        message: 'Datei-Import fehlgeschlagen: $e',
      );
    }
  }
}

/// Import Result
class ImportResult {
  final bool success;
  final String message;
  final int importedCount;

  ImportResult({
    required this.success,
    required this.message,
    this.importedCount = 0,
  });
}
