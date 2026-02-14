import 'dart:convert';
import 'package:http/http.dart' as http;

/// Extended AI Service für Weltenbibliothek V2.4
/// 17 neue KI-Features von Cloudflare AI
class AIServiceExtended {
  static const String _baseUrl = 'https://weltenbibliothek-api-v2.brandy13062.workers.dev';
  static const Duration _timeout = Duration(seconds: 45);

  // ==========================================
  // ENERGIE-WELT FEATURES
  // ==========================================

  /// #17 - Traum-Analyse
  /// Analysiert Träume symbolisch und spirituell
  static Future<Map<String, dynamic>> analyzeDream({
    required String dreamText,
    String? date,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/ai/dream-analysis'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'dream_text': dreamText,
              if (date != null) 'date': date,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Dream analysis failed: ${response.statusCode}');
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'fallback_advice': 'Offline-Modus: Traum konnte nicht analysiert werden.',
      };
    }
  }

  /// #18 - Chakra-Empfehlungen
  /// Gibt Heilempfehlungen basierend auf Symptomen
  static Future<Map<String, dynamic>> getChakraAdvice({
    required List<String> symptoms,
    String? energyLevel,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/ai/chakra-advice'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'symptoms': symptoms,
              if (energyLevel != null) 'energy_level': energyLevel,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Chakra advice failed: ${response.statusCode}');
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'fallback_advice': 'Offline-Modus: Chakra-Empfehlungen nicht verfügbar.',
      };
    }
  }

  /// #19 - Meditation-Script-Generator
  /// Erstellt personalisierte Meditationsskripte
  static Future<Map<String, dynamic>> generateMeditationScript({
    required String intention,
    int durationMinutes = 10,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/ai/meditation-script'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'intention': intention,
              'duration_minutes': durationMinutes,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Meditation script failed: ${response.statusCode}');
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'fallback_script': 'Offline-Modus: Meditation-Skript nicht verfügbar.',
      };
    }
  }

  // ==========================================
  // ANALYSE & INSIGHTS
  // ==========================================

  /// #12 - Verschwörungs-Netzwerk-Analyse
  /// Analysiert Verbindungen zwischen Akteuren
  static Future<Map<String, dynamic>> analyzeNetwork({
    required String topic,
    required List<String> entities,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/ai/network-analysis'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'topic': topic,
              'entities': entities,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Network analysis failed: ${response.statusCode}');
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'nodes': [],
        'connections': [],
      };
    }
  }

  /// #13 - Fakten-Check Assistent
  /// Prüft Aussagen und liefert Quellen
  static Future<Map<String, dynamic>> checkFacts({
    required String statement,
    String perspective = 'neutral',
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/ai/fact-check'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'statement': statement,
              'perspective': perspective,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Fact check failed: ${response.statusCode}');
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'verification_status': 'unknown',
      };
    }
  }

  /// #14 - Zeitstrahl-Generator
  /// Erstellt chronologische Event-Timelines
  static Future<Map<String, dynamic>> generateTimeline({
    required String topic,
    int? startYear,
    int? endYear,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/ai/timeline'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'topic': topic,
              if (startYear != null) 'start_year': startYear,
              if (endYear != null) 'end_year': endYear,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Timeline generation failed: ${response.statusCode}');
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'events': [],
      };
    }
  }

  // ==========================================
  // SPRACHE & ÜBERSETZUNG
  // ==========================================

  /// #10 - Echtzeit-Übersetzung
  /// Übersetzt Text in Zielsprache
  static Future<Map<String, dynamic>> translateText({
    required String text,
    required String targetLang,
    String? sourceLang,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/ai/translate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'text': text,
              'target_lang': targetLang,
              if (sourceLang != null) 'source_lang': sourceLang,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Translation failed: ${response.statusCode}');
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'translated_text': text, // Fallback: Original
      };
    }
  }

  /// #11 - Sprach-Erkennung
  /// Erkennt Sprache von Text oder Audio
  static Future<Map<String, dynamic>> detectLanguage({
    required String text,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/ai/detect-language'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'text': text,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Language detection failed: ${response.statusCode}');
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'detected_language': 'unknown',
      };
    }
  }

  // ==========================================
  // IMAGE & MEDIA
  // ==========================================

  /// #7 - Automatische Bildbeschreibung
  /// Beschreibt Bildinhalt mit AI Vision
  static Future<Map<String, dynamic>> describeImage({
    String? imageUrl,
    String? imageBase64,
  }) async {
    if (imageUrl == null && imageBase64 == null) {
      throw ArgumentError('Either imageUrl or imageBase64 required');
    }

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/ai/image-describe'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              if (imageUrl != null) 'image_url': imageUrl,
              if (imageBase64 != null) 'image_base64': imageBase64,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Image description failed: ${response.statusCode}');
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'description': 'Bildbeschreibung nicht verfügbar.',
      };
    }
  }

  /// #8 - Bild-Kategorisierung
  /// Klassifiziert Bilder in Kategorien
  static Future<Map<String, dynamic>> classifyImage({
    String? imageUrl,
    String? imageBase64,
  }) async {
    if (imageUrl == null && imageBase64 == null) {
      throw ArgumentError('Either imageUrl or imageBase64 required');
    }

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/ai/image-classify'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              if (imageUrl != null) 'image_url': imageUrl,
              if (imageBase64 != null) 'image_base64': imageBase64,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Image classification failed: ${response.statusCode}');
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'categories': [],
      };
    }
  }

  // ==========================================
  // MODERATION
  // ==========================================

  /// #20 - Auto-Moderation
  /// Prüft Content auf Toxizität
  static Future<Map<String, dynamic>> moderateContent({
    required String content,
    String type = 'chat',
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/ai/moderate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'content': content,
              'type': type,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Moderation failed: ${response.statusCode}');
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'action': 'approve', // Fallback: erlauben
      };
    }
  }

  // ==========================================
  // PERSONALISIERUNG
  // ==========================================

  /// #15 - Content-Empfehlungen
  /// Gibt personalisierte Empfehlungen
  static Future<Map<String, dynamic>> getRecommendations({
    required String userId,
    String? currentContent,
    int limit = 5,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/ai/content-recommend'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': userId,
              if (currentContent != null) 'current_content': currentContent,
              'limit': limit,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Recommendations failed: ${response.statusCode}');
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'recommendations': [],
      };
    }
  }
}
