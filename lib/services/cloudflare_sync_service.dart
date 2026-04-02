import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import '../models/materie_profile.dart';
import '../models/energie_profile.dart';
import 'storage_service.dart';

/// Cloudflare Sync Service für Profile & Chat-History
class CloudflareSyncService {
  static const String baseUrl = 'https://weltenbibliothek-api-v2.brandy13062.workers.dev';
  
  final Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  /// Materie-Profil in Cloud sichern
  Future<bool> backupMaterieProfile(MaterieProfile profile) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/sync/materie-profile'),
        headers: _headers,
        body: json.encode({
          'profile': profile.toJson(),
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Backup Materie profile timeout'),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          debugPrint('✅ Materie-Profil in Cloud gesichert');
        }
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('❌ Backup failed: ${response.statusCode}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Backup error: $e');
      }
      return false;
    }
  }

  /// Energie-Profil in Cloud sichern
  Future<bool> backupEnergieProfile(EnergieProfile profile) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/sync/energie-profile'),
        headers: _headers,
        body: json.encode({
          'profile': profile.toJson(),
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Backup Energie profile timeout'),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          debugPrint('✅ Energie-Profil in Cloud gesichert');
        }
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('❌ Backup failed: ${response.statusCode}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Backup error: $e');
      }
      return false;
    }
  }

  /// Materie-Profil aus Cloud wiederherstellen
  Future<MaterieProfile?> restoreMaterieProfile(String username) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/sync/materie-profile/$username'),
        headers: _headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Restore Materie profile timeout'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (kDebugMode) {
          debugPrint('✅ Materie-Profil aus Cloud wiederhergestellt');
        }
        return MaterieProfile.fromJson(data['profile']);
      } else {
        if (kDebugMode) {
          debugPrint('❌ Restore failed: ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Restore error: $e');
      }
      return null;
    }
  }

  /// Energie-Profil aus Cloud wiederherstellen
  Future<EnergieProfile?> restoreEnergieProfile(String username) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/sync/energie-profile/$username'),
        headers: _headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Restore Energie profile timeout'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (kDebugMode) {
          debugPrint('✅ Energie-Profil aus Cloud wiederhergestellt');
        }
        return EnergieProfile.fromJson(data['profile']);
      } else {
        if (kDebugMode) {
          debugPrint('❌ Restore failed: ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Restore error: $e');
      }
      return null;
    }
  }

  /// Chat-History sichern
  Future<bool> backupChatHistory({
    required String roomId,
    required String realm,
    required List<Map<String, dynamic>> messages,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/sync/chat-history'),
        headers: _headers,
        body: json.encode({
          'room_id': roomId,
          'realm': realm,
          'messages': messages,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Backup chat history timeout'),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          debugPrint('✅ Chat-History gesichert: $roomId');
        }
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('❌ Chat backup failed: ${response.statusCode}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Chat backup error: $e');
      }
      return false;
    }
  }

  /// Chat-History wiederherstellen
  Future<List<Map<String, dynamic>>?> restoreChatHistory({
    required String roomId,
    required String realm,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/sync/chat-history/$realm/$roomId'),
        headers: _headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Restore chat history timeout'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (kDebugMode) {
          debugPrint('✅ Chat-History wiederhergestellt: $roomId');
        }
        return List<Map<String, dynamic>>.from(data['messages']);
      } else {
        if (kDebugMode) {
          debugPrint('❌ Chat restore failed: ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Chat restore error: $e');
      }
      return null;
    }
  }

  /// Auto-Sync: Lokal + Cloud synchronisieren
  Future<bool> autoSync() async {
    try {
      final storage = StorageService();
      await storage.init();
      
      // Materie-Profil sync
      final materieProfile = storage.getMaterieProfile();
      if (materieProfile != null && materieProfile.isValid) {
        await backupMaterieProfile(materieProfile);
      }
      
      // Energie-Profil sync
      final energieProfile = storage.getEnergieProfile();
      if (energieProfile != null && energieProfile.isValid) {
        await backupEnergieProfile(energieProfile);
      }
      
      if (kDebugMode) {
        debugPrint('✅ Auto-Sync abgeschlossen');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Auto-Sync error: $e');
      }
      return false;
    }
  }

  /// Prüfe Sync-Status
  Future<Map<String, dynamic>> getSyncStatus(String username) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/sync/status/$username'),
        headers: _headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Get sync status timeout'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': 'Failed to get sync status'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
