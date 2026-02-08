/// Read Receipts Service
/// Handles message read status tracking
/// Backend: Cloudflare Worker POST /messages/{messageId}/read
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'cloudflare_api_service.dart';

class ReadReceiptsService extends ChangeNotifier {
  static final ReadReceiptsService _instance = ReadReceiptsService._internal();
  factory ReadReceiptsService() => _instance;
  ReadReceiptsService._internal();

  final String _baseUrl = CloudflareApiService.chatFeaturesApiUrl;

  // Cache für Read Receipts: messageId -> List<{userId, username, readAt}>
  final Map<String, List<Map<String, dynamic>>> _receiptsCache = {};

  /// Nachricht als gelesen markieren
  Future<bool> markAsRead({
    required String messageId,
    required String userId,
    required String username,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('📖 [ReadReceipts] Marking message as read: $messageId');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/messages/$messageId/read'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'username': username,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (kDebugMode) {
          debugPrint('✅ [ReadReceipts] Marked as read: ${data['receipts']?.length ?? 0} readers');
        }

        // Cache aktualisieren
        if (data['receipts'] != null) {
          _receiptsCache[messageId] = List<Map<String, dynamic>>.from(
            (data['receipts'] as List).map((r) => Map<String, dynamic>.from(r)),
          );
          notifyListeners();
        }

        return true;
      } else {
        if (kDebugMode) {
          debugPrint('❌ [ReadReceipts] Failed: ${response.statusCode}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [ReadReceipts] Error marking as read: $e');
      }
      return false;
    }
  }

  /// Read Receipts für eine Nachricht abrufen
  Future<List<Map<String, dynamic>>> getReceipts(String messageId) async {
    try {
      // Zuerst aus Cache
      if (_receiptsCache.containsKey(messageId)) {
        return _receiptsCache[messageId]!;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/messages/$messageId/receipts'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['receipts'] != null) {
          final receipts = List<Map<String, dynamic>>.from(
            (data['receipts'] as List).map((r) => Map<String, dynamic>.from(r)),
          );

          // Cache aktualisieren
          _receiptsCache[messageId] = receipts;
          notifyListeners();

          return receipts;
        }
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [ReadReceipts] Error loading receipts: $e');
      }
      return [];
    }
  }

  /// Prüfen, ob User die Nachricht gelesen hat
  bool hasUserRead(String messageId, String userId) {
    if (!_receiptsCache.containsKey(messageId)) return false;
    return _receiptsCache[messageId]!.any((r) => r['userId'] == userId);
  }

  /// Anzahl der Leser
  int getReaderCount(String messageId) {
    return _receiptsCache[messageId]?.length ?? 0;
  }

  /// Liste der Leser-Namen
  List<String> getReaderNames(String messageId) {
    if (!_receiptsCache.containsKey(messageId)) return [];
    return _receiptsCache[messageId]!
        .map((r) => r['username'] as String)
        .toList();
  }

  /// Cache für Nachricht löschen (z.B. nach Raum-Wechsel)
  void clearCache([String? messageId]) {
    if (messageId != null) {
      _receiptsCache.remove(messageId);
    } else {
      _receiptsCache.clear();
    }
    notifyListeners();
  }
}
