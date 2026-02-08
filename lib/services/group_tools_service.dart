import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:http/http.dart' as http;
import 'dart:convert';

/// 🛠️ Gruppen-Tools Service
/// Verbindung zu Cloudflare Worker API für alle 18 Tools
/// (Migrated to community-api as fallback)
class GroupToolsService {
  static const String _baseUrl = 'https://weltenbibliothek-community-api.brandy13062.workers.dev/api/tools';

  // ========================================
  // 🔮 ENERGIE-WELT TOOLS
  // ========================================

  /// 🧘 Meditation Sessions
  Future<List<Map<String, dynamic>>> getMeditationSessions({
    String roomId = 'meditation',
    int limit = 50,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/energie/meditation?room_id=$roomId&limit=$limit'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['sessions'] ?? []);
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching meditation sessions: $e');
      }
      return [];
    }
  }

  Future<String?> createMeditationSession({
    required String roomId,
    required String userId,
    required int durationMinutes,
    List<String> participants = const [],
    String notes = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/energie/meditation'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'room_id': roomId,
          'created_by': userId,
          'duration_minutes': durationMinutes,
          'participants': participants,
          'notes': notes,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['session_id'];
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error creating meditation session: $e');
      }
      return null;
    }
  }

  /// 🌙 Astrales Tagebuch
  Future<List<Map<String, dynamic>>> getAstralJournal({
    String roomId = 'astralreisen',
    int limit = 50,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/energie/astral?room_id=$roomId&limit=$limit'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['entries'] ?? []);
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching astral journal: $e');
      }
      return [];
    }
  }

  Future<String?> createAstralEntry({
    required String roomId,
    required String userId,
    required String username,
    required String title,
    required String experience,
    List<String> techniques = const [],
    int successLevel = 3,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/energie/astral'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'room_id': roomId,
          'user_id': userId,
          'username': username,
          'title': title,
          'experience': experience,
          'techniques_used': techniques,
          'success_level': successLevel,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['entry_id'];
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error creating astral entry: $e');
      }
      return null;
    }
  }

  /// 💎 Chakra Scans
  Future<List<Map<String, dynamic>>> getChakraScans({
    String roomId = 'chakra',
    String? userId,
    int limit = 50,
  }) async {
    try {
      String url = '$_baseUrl/energie/chakra?room_id=$roomId&limit=$limit';
      if (userId != null) {
        url += '&user_id=$userId';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['scans'] ?? []);
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching chakra scans: $e');
      }
      return [];
    }
  }

  Future<String?> createChakraScan({
    required String roomId,
    required String scannedUserId,
    required String scannedUsername,
    required String scannerUserId,
    required String scannerUsername,
    required Map<String, dynamic> scanData,
    List<String> blockages = const [],
    String recommendations = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/energie/chakra'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'room_id': roomId,
          'scanned_user_id': scannedUserId,
          'scanned_username': scannedUsername,
          'scanner_user_id': scannerUserId,
          'scanner_username': scannerUsername,
          'scan_data': scanData,
          'blockages': blockages,
          'recommendations': recommendations,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['scan_id'];
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error creating chakra scan: $e');
      }
      return null;
    }
  }

  /// 💠 Kristall-Bibliothek
  Future<List<Map<String, dynamic>>> getCrystals({
    String roomId = 'kristalle',
    String? search,
    int limit = 100,
  }) async {
    try {
      String url = '$_baseUrl/energie/crystals?room_id=$roomId&limit=$limit';
      if (search != null && search.isNotEmpty) {
        url += '&search=$search';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['crystals'] ?? []);
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching crystals: $e');
      }
      return [];
    }
  }

  Future<String?> addCrystal({
    required String roomId,
    required String userId,
    required String username,
    required String crystalName,
    String crystalType = '',
    List<String> properties = const [],
    String uses = '',
    String imageUrl = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/energie/crystals'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'room_id': roomId,
          'user_id': userId,
          'username': username,
          'crystal_name': crystalName,
          'crystal_type': crystalType,
          'properties': properties,
          'uses': uses,
          'image_url': imageUrl,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['crystal_id'];
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error adding crystal: $e');
      }
      return null;
    }
  }

  /// 🎵 Frequenz-Sessions
  Future<List<Map<String, dynamic>>> getFrequencySessions({
    String roomId = 'frequenzen',
    int limit = 50,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/energie/frequency?room_id=$roomId&limit=$limit'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['sessions'] ?? []);
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching frequency sessions: $e');
      }
      return [];
    }
  }

  Future<String?> createFrequencySession({
    required String roomId,
    required String userId,
    required String frequencyHz,
    required int durationMinutes,
    List<String> participants = const [],
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/energie/frequency'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'room_id': roomId,
          'user_id': userId,
          'frequency_hz': frequencyHz,
          'duration_minutes': durationMinutes,
          'participants': participants,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['session_id'];
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error creating frequency session: $e');
      }
      return null;
    }
  }

  /// 💫 Traum-Tagebuch
  Future<List<Map<String, dynamic>>> getDreams({
    String roomId = 'traumarbeit',
    int limit = 50,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/energie/dreams?room_id=$roomId&limit=$limit'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['dreams'] ?? []);
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching dreams: $e');
      }
      return [];
    }
  }

  Future<String?> createDream({
    required String roomId,
    required String userId,
    required String username,
    required String title,
    required String description,
    List<String> symbols = const [],
    bool lucid = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/energie/dreams'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'room_id': roomId,
          'user_id': userId,
          'username': username,
          'dream_title': title,
          'dream_description': description,
          'symbols': symbols,
          'lucid': lucid,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['dream_id'];
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error creating dream: $e');
      }
      return null;
    }
  }

  // ========================================
  // 🌍 MATERIE-WELT TOOLS (TODO)
  // ========================================
  // Placeholder methods - werden später implementiert

  // ========================================
  // ✨ SPIRIT-WELT TOOLS (TODO)
  // ========================================
  // 🌍 MATERIE-WELT TOOLS
  // ========================================

  /// 🛸 UFO-Sichtungen
  Future<List<Map<String, dynamic>>> getUfoSightings({
    String roomId = 'ufos',
    int limit = 50,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/materie/ufos?room_id=$roomId&limit=$limit'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['sightings'] ?? []);
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error fetching UFO sightings: $e');
      return [];
    }
  }

  Future<String?> createUfoSighting({
    required String roomId,
    required String userId,
    required String username,
    required String title,
    required String description,
    String objectType = 'light',
    int witnesses = 1,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/materie/ufos'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'room_id': roomId,
          'user_id': userId,
          'username': username,
          'sighting_title': title,
          'sighting_description': description,
          'object_type': objectType,
          'witnesses': witnesses,
        }),
      );
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['sighting_id'];
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error creating UFO sighting: $e');
      return null;
    }
  }

  /// 🏛️ Geschichte-Zeitleiste
  Future<List<Map<String, dynamic>>> getHistoryTimeline({
    String roomId = 'geschichte',
    int limit = 100,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/materie/history?room_id=$roomId&limit=$limit'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['events'] ?? []);
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error fetching history: $e');
      return [];
    }
  }

  Future<String?> createHistoryEvent({
    required String roomId,
    required String userId,
    required String username,
    required String title,
    required String description,
    int? eventYear,
    String civilization = '',
    String category = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/materie/history'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'room_id': roomId,
          'user_id': userId,
          'username': username,
          'event_title': title,
          'event_description': description,
          'event_year': eventYear,
          'civilization': civilization,
          'category': category,
        }),
      );
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['event_id'];
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error creating history event: $e');
      return null;
    }
  }

  /// 🎭 Geopolitik-Kartierung
  Future<List<Map<String, dynamic>>> getGeopoliticsEvents({
    String roomId = 'politik',
    int limit = 50,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/materie/geopolitics?room_id=$roomId&limit=$limit'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['events'] ?? []);
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error fetching geopolitics: $e');
      return [];
    }
  }

  Future<String?> createGeopoliticsEvent({
    required String roomId,
    required String userId,
    required String username,
    required String title,
    required String description,
    List<String> tags = const [],
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/materie/geopolitics'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'room_id': roomId,
          'user_id': userId,
          'username': username,
          'event_title': title,
          'event_description': description,
          'tags': tags,
        }),
      );
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['event_id'];
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error creating geopolitics event: $e');
      return null;
    }
  }
  
  /// 🏛️ Geschichte-Zeitleiste - GET
  Future<List<Map<String, dynamic>>> getHistoryEvents({String roomId = 'geschichte', int limit = 50}) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/materie/history?room_id=$roomId&limit=$limit'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['events'] ?? []);
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error loading history events: $e');
      return [];
    }
  }
  
  /// 👁️ Verschwörungs-Netzwerk - GET
  Future<List<Map<String, dynamic>>> getConspiracyNetwork({String roomId = 'verschwoerungen', int limit = 50}) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/materie/network?room_id=$roomId&limit=$limit'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['connections'] ?? []);
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error loading conspiracy network: $e');
      return [];
    }
  }
  
  Future<String?> createConspiracyConnection({
    required String roomId,
    required String userId,
    required String username,
    required String connectionTitle,
    required String connectionDescription,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/materie/network'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'room_id': roomId,
          'user_id': userId,
          'username': username,
          'connection_title': connectionTitle,
          'connection_description': connectionDescription,
        }),
      );
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['connection_id'];
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error creating conspiracy connection: $e');
      return null;
    }
  }
  
  /// 🔬 Forschungs-Archiv - GET
  Future<List<Map<String, dynamic>>> getResearchArchive({String roomId = 'technologie', int limit = 50}) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/materie/research?room_id=$roomId&limit=$limit'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['documents'] ?? []);
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error loading research archive: $e');
      return [];
    }
  }
  
  Future<String?> createResearchDocument({
    required String roomId,
    required String userId,
    required String username,
    required String documentTitle,
    required String documentDescription,
    String documentType = 'research',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/materie/research'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'room_id': roomId,
          'user_id': userId,
          'username': username,
          'document_title': documentTitle,
          'document_description': documentDescription,
          'document_type': documentType,
        }),
      );
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['document_id'];
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error creating research document: $e');
      return null;
    }
  }
  
  /// 💚 Alternative Heilmethoden
  Future<List<Map<String, dynamic>>> getHealingMethods({String roomId = 'gesundheit', int limit = 50}) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/materie/healing?room_id=$roomId&limit=$limit'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['methods'] ?? []);
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error loading healing methods: $e');
      return [];
    }
  }
  
  Future<String?> createHealingMethod({
    required String roomId,
    required String userId,
    required String username,
    required String methodName,
    required String methodDescription,
    String category = 'alternative',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/materie/healing'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'room_id': roomId,
          'user_id': userId,
          'username': username,
          'method_name': methodName,
          'method_description': methodDescription,
          'category': category,
        }),
      );
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['method_id'];
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error creating healing method: $e');
      return null;
    }
  }

  // ========================================
  // ✨ SPIRIT-WELT TOOLS (TODO)
  // ========================================
  // Placeholder methods - werden später implementiert
}
