import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

/// 🛠️ TOOL API SERVICE - Gemeinsame Cloud-Tools für alle Nutzer
class ToolApiService {
  final String baseUrl;
  final String apiToken;
  
  ToolApiService({
    this.baseUrl = '',  // Empty = same origin (proxy)
    this.apiToken = '_C578hgIAimVPG0WjfeAjk23RxQMQ9gox0W7ebLv',
  });

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $apiToken',
  };

  // ========== NEWS-TRACKER ==========
  Future<List<Map<String, dynamic>>> getNewsTrackerItems(String roomId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/tools/news-tracker?room_id=$roomId&limit=100'),
      headers: _headers,
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Failed to load news: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> addNewsTrackerItem({
    required String roomId,
    required String userId,
    required String username,
    required String title,
    String? source,
    String? link,
    String? notes,
    bool important = false,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/tools/news-tracker'),
      headers: _headers,
      body: json.encode({
        'room_id': roomId,
        'user_id': userId,
        'username': username,
        'title': title,
        'source': source ?? '',
        'link': link ?? '',
        'notes': notes ?? '',
        'important': important,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 201) {
      return json.decode(response.body);
    }
    throw Exception('Failed to add news: ${response.statusCode}');
  }

  Future<void> deleteNewsTrackerItem(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/tools/news-tracker/$id'),
      headers: _headers,
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete news: ${response.statusCode}');
    }
  }

  // ========== ARTEFAKT-DATENBANK ==========
  Future<List<Map<String, dynamic>>> getArtefakte(String roomId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/tools/artefakt?room_id=$roomId&limit=100'),
      headers: _headers,
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Failed to load artefakte: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> addArtefakt({
    required String roomId,
    required String userId,
    required String username,
    required String name,
    String? location,
    String? period,
    String? description,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/tools/artefakt'),
      headers: _headers,
      body: json.encode({
        'room_id': roomId,
        'user_id': userId,
        'username': username,
        'name': name,
        'location': location ?? '',
        'period': period ?? '',
        'description': description ?? '',
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 201) {
      return json.decode(response.body);
    }
    throw Exception('Failed to add artefakt: ${response.statusCode}');
  }

  Future<void> deleteArtefakt(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/tools/artefakt/$id'),
      headers: _headers,
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete artefakt: ${response.statusCode}');
    }
  }

  // ========== UFO-SICHTUNGEN ==========
  Future<List<Map<String, dynamic>>> getUfoSichtungen(String roomId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/tools/ufo?room_id=$roomId&limit=100'),
      headers: _headers,
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Failed to load UFO sichtungen: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> addUfoSichtung({
    required String roomId,
    required String userId,
    required String username,
    required String location,
    String? description,
    bool verified = false,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/tools/ufo'),
      headers: _headers,
      body: json.encode({
        'room_id': roomId,
        'user_id': userId,
        'username': username,
        'location': location,
        'description': description ?? '',
        'verified': verified,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 201) {
      return json.decode(response.body);
    }
    throw Exception('Failed to add UFO sichtung: ${response.statusCode}');
  }

  Future<void> deleteUfoSichtung(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/tools/ufo/$id'),
      headers: _headers,
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete UFO sichtung: ${response.statusCode}');
    }
  }

  // ========== CONNECTIONS-BOARD ==========
  Future<List<Map<String, dynamic>>> getConnections(String roomId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/tools/connections?room_id=$roomId&limit=100'),
      headers: _headers,
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Failed to load connections: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> addConnection({
    required String roomId,
    required String userId,
    required String username,
    required String entity,
    String? connection,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/tools/connections'),
      headers: _headers,
      body: json.encode({
        'room_id': roomId,
        'user_id': userId,
        'username': username,
        'entity': entity,
        'connection': connection ?? '',
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 201) {
      return json.decode(response.body);
    }
    throw Exception('Failed to add connection: ${response.statusCode}');
  }

  Future<void> deleteConnection(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/tools/connections/$id'),
      headers: _headers,
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete connection: ${response.statusCode}');
    }
  }

  // ========== PATENT-ARCHIV ==========
  Future<List<Map<String, dynamic>>> getPatente(String roomId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/tools/patent?room_id=$roomId&limit=100'),
      headers: _headers,
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Failed to load patente: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> addPatent({
    required String roomId,
    required String userId,
    required String username,
    required String title,
    String? inventor,
    String? description,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/tools/patent'),
      headers: _headers,
      body: json.encode({
        'room_id': roomId,
        'user_id': userId,
        'username': username,
        'title': title,
        'inventor': inventor ?? '',
        'description': description ?? '',
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 201) {
      return json.decode(response.body);
    }
    throw Exception('Failed to add patent: ${response.statusCode}');
  }

  Future<void> deletePatent(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/tools/patent/$id'),
      headers: _headers,
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete patent: ${response.statusCode}');
    }
  }

  // ========== TRAUM-TAGEBUCH ==========
  Future<List<Map<String, dynamic>>> getTraeume(String roomId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/tools/traum?room_id=$roomId&limit=100'),
      headers: _headers,
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Failed to load träume: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> addTraum({
    required String roomId,
    required String userId,
    required String username,
    required String title,
    String? description,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/tools/traum'),
      headers: _headers,
      body: json.encode({
        'room_id': roomId,
        'user_id': userId,
        'username': username,
        'title': title,
        'description': description ?? '',
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 201) {
      return json.decode(response.body);
    }
    throw Exception('Failed to add traum: ${response.statusCode}');
  }

  Future<void> deleteTraum(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/tools/traum/$id'),
      headers: _headers,
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete traum: ${response.statusCode}');
    }
  }

  // ========== BEWUSSTSEINS-JOURNAL ==========
  Future<List<Map<String, dynamic>>> getJournalEntries(String roomId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/tools/journal?room_id=$roomId&limit=100'),
      headers: _headers,
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Failed to load journal: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> addJournalEntry({
    required String roomId,
    required String userId,
    required String username,
    required String entry,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/tools/journal'),
      headers: _headers,
      body: json.encode({
        'room_id': roomId,
        'user_id': userId,
        'username': username,
        'entry': entry,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 201) {
      return json.decode(response.body);
    }
    throw Exception('Failed to add journal entry: ${response.statusCode}');
  }

  Future<void> deleteJournalEntry(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/tools/journal/$id'),
      headers: _headers,
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete journal entry: ${response.statusCode}');
    }
  }

  // ========== GENERISCHE METHODEN (für alle Tools) ==========
  
  Future<List<Map<String, dynamic>>> getToolData({
    required String endpoint,
    required String roomId,
    int limit = 100,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint?room_id=$roomId&limit=$limit'),
      headers: _headers,
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is List) {
        return List<Map<String, dynamic>>.from(decoded);
      }
      return [];
    }
    throw Exception('Failed to load data from $endpoint: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> postToolData({
    required String endpoint,
    required Map<String, dynamic> data,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
      body: json.encode(data),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    }
    throw Exception('Failed to post data to $endpoint: ${response.statusCode}');
  }

  Future<void> deleteToolData({
    required String endpoint,
    required String itemId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint/$itemId'),
      headers: _headers,
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete data from $endpoint: ${response.statusCode}');
    }
  }
}
