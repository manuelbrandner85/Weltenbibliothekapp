import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Service für Chat-Tool-Ergebnisse (Meditation, Traumanalyse, etc.)
/// Speichert Tool-Daten in Cloudflare D1 und macht sie für alle Nutzer sichtbar
class ChatToolsService {
  static const String baseUrl = 'https://weltenbibliothek-api-v2.brandy13062.workers.dev';
  
  // Singleton Pattern
  static final ChatToolsService _instance = ChatToolsService._internal();
  factory ChatToolsService() => _instance;
  ChatToolsService._internal();
  
  /// Tool-Ergebnis speichern
  Future<Map<String, dynamic>> saveToolResult({
    required String roomId,
    required String toolType,
    required String username,
    required Map<String, dynamic> data,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('💾 Speichere Tool-Ergebnis: $toolType in Raum $roomId');
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/tools/results'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'room_id': roomId,
          'tool_type': toolType,
          'username': username,
          'data': json.encode(data),
        }),
      );
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (kDebugMode) {
          debugPrint('✅ Tool-Ergebnis gespeichert: ${result['id']}');
        }
        return result;
      } else {
        throw Exception('Failed to save tool result: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Speichern: $e');
      }
      rethrow;
    }
  }
  
  /// Tool-Ergebnisse für einen Raum laden
  Future<List<Map<String, dynamic>>> getToolResults({
    required String roomId,
    String? toolType,
    int limit = 50,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('📖 Lade Tool-Ergebnisse für Raum: $roomId, Tool: ${toolType ?? 'alle'}');
      }
      
      final params = {
        'room_id': roomId,
        'limit': limit.toString(),
      };
      
      if (toolType != null) {
        params['tool_type'] = toolType;
      }
      
      final uri = Uri.parse('$baseUrl/tools/results').replace(queryParameters: params);
      final response = await http.get(uri, headers: {'Content-Type': 'application/json'});
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final results = data.map((item) {
          return {
            'id': item['id'],
            'room_id': item['room_id'],
            'tool_type': item['tool_type'],
            'username': item['username'],
            'data': json.decode(item['data'].toString()),
            'created_at': item['created_at'],
          };
        }).toList();
        
        if (kDebugMode) {
          debugPrint('✅ ${results.length} Tool-Ergebnisse geladen');
        }
        
        return results;
      } else {
        throw Exception('Failed to load tool results: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Laden: $e');
      }
      return []; // Return empty list on error
    }
  }
  
  /// Tool-Ergebnis löschen (nur eigene)
  Future<void> deleteToolResult({
    required String resultId,
    required String username,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🗑️ Lösche Tool-Ergebnis: $resultId');
      }
      
      final response = await http.delete(
        Uri.parse('$baseUrl/tools/results/$resultId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username}),
      );
      
      if (response.statusCode == 200) {
        if (kDebugMode) {
          debugPrint('✅ Tool-Ergebnis gelöscht');
        }
      } else {
        throw Exception('Failed to delete tool result: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Löschen: $e');
      }
      rethrow;
    }
  }
}
