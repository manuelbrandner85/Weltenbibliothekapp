import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

/// 🦞 OpenClaw AI Gateway Service
/// Verbindet Weltenbibliothek mit OpenClaw AI Agent auf Hostinger VPS
/// 
/// Features:
/// - Gateway Token Authentication
/// - Multi-Model Support (Claude, GPT, Gemini)
/// - Automatic Fallback to Cloudflare
/// - Rate Limiting & Error Handling
/// - Self-Hosted on Hostinger VPS
class OpenClawGatewayService {
  // ═══════════════════════════════════════════════════════════
  // CONFIGURATION
  // ═══════════════════════════════════════════════════════════
  
  /// OpenClaw Gateway Base URL (Hostinger VPS)
  /// Beispiel: https://openclaw.deine-domain.com
  /// Oder: http://123.456.789.10:3000
  static String get gatewayUrl {
    // Try environment variable first
    const envUrl = String.fromEnvironment('OPENCLAW_GATEWAY_URL', defaultValue: '');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    // Fallback to ApiConfig
    return ApiConfig.openClawGatewayUrl;
  }
  
  /// OpenClaw Gateway Token
  /// Get from: openclaw get-api-key
  static String get gatewayToken {
    const envToken = String.fromEnvironment('OPENCLAW_GATEWAY_TOKEN', defaultValue: '');
    if (envToken.isNotEmpty) {
      return envToken;
    }
    return ApiConfig.openClawGatewayToken;
  }
  
  /// Timeout für API-Requests
  static const Duration requestTimeout = Duration(seconds: 30);
  
  /// Max Retries bei Fehlern
  static const int maxRetries = 2;
  
  // Singleton Pattern
  static final OpenClawGatewayService _instance = OpenClawGatewayService._internal();
  factory OpenClawGatewayService() => _instance;
  OpenClawGatewayService._internal();
  
  // ═══════════════════════════════════════════════════════════
  // HEALTH CHECK
  // ═══════════════════════════════════════════════════════════
  
  /// Prüft, ob OpenClaw Gateway erreichbar ist
  Future<bool> isAvailable() async {
    try {
      final response = await http.get(
        Uri.parse('$gatewayUrl/health'),
        headers: _headers,
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('⚠️ OpenClaw Gateway nicht erreichbar: $e');
      return false;
    }
  }
  
  /// Gateway Status abrufen
  Future<Map<String, dynamic>> getStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$gatewayUrl/api/status'),
        headers: _headers,
      ).timeout(requestTimeout);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      
      throw Exception('Status check failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ OpenClaw Status Error: $e');
      return {'available': false, 'error': e.toString()};
    }
  }
  
  // ═══════════════════════════════════════════════════════════
  // HEADERS
  // ═══════════════════════════════════════════════════════════
  
  Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $gatewayToken',
      'X-Client': 'Weltenbibliothek-Flutter',
    };
  }
  
  // ═══════════════════════════════════════════════════════════
  // AI TEXT GENERATION
  // ═══════════════════════════════════════════════════════════
  
  /// Generiert Text mit OpenClaw AI
  /// 
  /// Beispiel:
  /// ```dart
  /// final result = await openClaw.generateText(
  ///   prompt: 'Analysiere diesen Text auf Propaganda',
  ///   context: 'Nachrichtentext...',
  ///   model: 'claude-3-5-sonnet',
  /// );
  /// ```
  Future<String> generateText({
    required String prompt,
    String? context,
    String model = 'claude-3-5-sonnet',
    int maxTokens = 2000,
    double temperature = 0.7,
  }) async {
    try {
      final body = {
        'model': model,
        'prompt': prompt,
        if (context != null) 'context': context,
        'max_tokens': maxTokens,
        'temperature': temperature,
      };
      
      final response = await _makeRequest(
        endpoint: '/api/generate',
        body: body,
      );
      
      return response['text'] as String? ?? response['content'] as String? ?? '';
      
    } catch (e) {
      debugPrint('❌ OpenClaw generateText Error: $e');
      rethrow;
    }
  }
  
  // ═══════════════════════════════════════════════════════════
  // RECHERCHE & ANALYSE
  // ═══════════════════════════════════════════════════════════
  
  /// Recherche zu einem Thema mit Multi-Source Aggregation
  Future<Map<String, dynamic>> research({
    required String query,
    List<String> sources = const ['official', 'alternative'],
    int maxResults = 10,
  }) async {
    try {
      final body = {
        'query': query,
        'sources': sources,
        'max_results': maxResults,
        'language': 'de',
      };
      
      final response = await _makeRequest(
        endpoint: '/api/research',
        body: body,
      );
      
      return response;
      
    } catch (e) {
      debugPrint('❌ OpenClaw research Error: $e');
      rethrow;
    }
  }
  
  /// Propaganda-Detektor
  Future<Map<String, dynamic>> detectPropaganda({
    required String text,
  }) async {
    try {
      final prompt = '''
Analysiere den folgenden Text auf Propaganda-Techniken:

Text: """
$text
"""

Identifiziere:
1. Verwendete Propaganda-Techniken
2. Emotionale Trigger
3. Manipulationsstrategien
4. Objektivitäts-Score (0-100)
5. Empfehlungen für kritisches Lesen

Antworte im JSON-Format.
''';
      
      final response = await generateText(
        prompt: prompt,
        model: 'claude-3-5-sonnet',
        temperature: 0.3,
      );
      
      // Parse JSON response
      try {
        return json.decode(response);
      } catch (_) {
        return {
          'analysis': response,
          'score': 50,
          'techniques': [],
        };
      }
      
    } catch (e) {
      debugPrint('❌ OpenClaw detectPropaganda Error: $e');
      rethrow;
    }
  }
  
  // ═══════════════════════════════════════════════════════════
  // TRAUM-ANALYSE (ENERGIE-WELT)
  // ═══════════════════════════════════════════════════════════
  
  /// Traum-Analyse mit symbolischer & spiritueller Interpretation
  Future<Map<String, dynamic>> analyzeDream({
    required String dreamText,
    String? mood,
    List<String>? symbols,
  }) async {
    try {
      final prompt = '''
Analysiere den folgenden Traum aus spiritueller und psychologischer Perspektive:

Traum: """
$dreamText
"""

${mood != null ? 'Stimmung beim Aufwachen: $mood' : ''}
${symbols != null && symbols.isNotEmpty ? 'Bemerkte Symbole: ${symbols.join(", ")}' : ''}

Erstelle eine detaillierte Traum-Analyse mit:
1. Symbolische Bedeutungen
2. Spirituelle Interpretation
3. Psychologische Aspekte
4. Chakra-Verbindungen
5. Handlungsempfehlungen
6. Affirmationen

Antworte im JSON-Format auf Deutsch.
''';
      
      final response = await generateText(
        prompt: prompt,
        model: 'claude-3-5-sonnet',
        temperature: 0.8,
        maxTokens: 3000,
      );
      
      try {
        return json.decode(response);
      } catch (_) {
        return {
          'analysis': response,
          'symbols': symbols ?? [],
          'chakras': [],
        };
      }
      
    } catch (e) {
      debugPrint('❌ OpenClaw analyzeDream Error: $e');
      rethrow;
    }
  }
  
  // ═══════════════════════════════════════════════════════════
  // CHAKRA-EMPFEHLUNGEN
  // ═══════════════════════════════════════════════════════════
  
  /// Personalisierte Chakra-Empfehlungen
  Future<Map<String, dynamic>> getChakraRecommendations({
    required String chakra,
    List<String>? symptoms,
    String? intention,
  }) async {
    try {
      final prompt = '''
Erstelle personalisierte Empfehlungen für das $chakra-Chakra:

${symptoms != null && symptoms.isNotEmpty ? 'Symptome/Blockaden: ${symptoms.join(", ")}' : ''}
${intention != null ? 'Intention: $intention' : ''}

Gib Empfehlungen für:
1. Heilsteine (mit Anwendung)
2. Frequenzen (Solfeggio)
3. Yoga-Übungen (detailliert)
4. Meditation (geführte Anleitung)
5. Affirmationen
6. Aromatherapie
7. Ernährung
8. Farb-Therapie

Antworte im JSON-Format auf Deutsch, sehr detailliert.
''';
      
      final response = await generateText(
        prompt: prompt,
        model: 'claude-3-5-sonnet',
        temperature: 0.7,
        maxTokens: 4000,
      );
      
      try {
        return json.decode(response);
      } catch (_) {
        return {
          'recommendations': response,
          'chakra': chakra,
        };
      }
      
    } catch (e) {
      debugPrint('❌ OpenClaw getChakraRecommendations Error: $e');
      rethrow;
    }
  }
  
  // ═══════════════════════════════════════════════════════════
  // MEDITATION-GENERATOR
  // ═══════════════════════════════════════════════════════════
  
  /// Generiert personalisierte Meditation
  Future<Map<String, dynamic>> generateMeditation({
    required String intention,
    int duration = 10, // Minuten
    String? chakra,
    String? theme,
  }) async {
    try {
      final prompt = '''
Erstelle eine ${duration}-minütige geführte Meditation:

Intention: $intention
${chakra != null ? 'Chakra-Fokus: $chakra' : ''}
${theme != null ? 'Thema: $theme' : ''}

Erstelle ein detailliertes Meditationsskript mit:
1. Einleitung (Grounding)
2. Körper-Scan
3. Atem-Übung
4. Visualisierung (detailliert)
5. Affirmationen
6. Integration
7. Abschluss

Zeitangaben für jede Phase.
Antworte im JSON-Format auf Deutsch.
''';
      
      final response = await generateText(
        prompt: prompt,
        model: 'claude-3-5-sonnet',
        temperature: 0.8,
        maxTokens: 4000,
      );
      
      try {
        return json.decode(response);
      } catch (_) {
        return {
          'script': response,
          'duration': duration,
          'intention': intention,
        };
      }
      
    } catch (e) {
      debugPrint('❌ OpenClaw generateMeditation Error: $e');
      rethrow;
    }
  }
  
  // ═══════════════════════════════════════════════════════════
  // CHAT ENHANCEMENT
  // ═══════════════════════════════════════════════════════════
  
  /// Smart Reply Suggestions für Chat
  Future<List<String>> getSuggestedReplies({
    required String message,
    String? context,
    int maxSuggestions = 3,
  }) async {
    try {
      final prompt = '''
Generiere $maxSuggestions passende Antwort-Vorschläge auf diese Nachricht:

Nachricht: "$message"
${context != null ? 'Kontext: $context' : ''}

Vorschläge sollen:
- Hilfsbereit und freundlich sein
- Zum Kontext der Weltenbibliothek passen
- Kurz und prägnant sein (max 2 Sätze)

Antworte nur mit den Vorschlägen, als JSON-Array.
''';
      
      final response = await generateText(
        prompt: prompt,
        model: 'claude-3-5-haiku',
        temperature: 0.9,
        maxTokens: 500,
      );
      
      try {
        final List<dynamic> suggestions = json.decode(response);
        return suggestions.map((s) => s.toString()).toList();
      } catch (_) {
        return [];
      }
      
    } catch (e) {
      debugPrint('❌ OpenClaw getSuggestedReplies Error: $e');
      return [];
    }
  }
  
  // ═══════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════
  
  /// Macht HTTP Request mit Retry-Logic
  Future<Map<String, dynamic>> _makeRequest({
    required String endpoint,
    required Map<String, dynamic> body,
    int retryCount = 0,
  }) async {
    try {
      final url = Uri.parse('$gatewayUrl$endpoint');
      
      final response = await http.post(
        url,
        headers: _headers,
        body: json.encode(body),
      ).timeout(requestTimeout);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      
      if (response.statusCode == 401) {
        throw Exception('OpenClaw Gateway Token ungültig');
      }
      
      if (response.statusCode == 429) {
        throw Exception('Rate Limit erreicht. Bitte warte kurz.');
      }
      
      // Retry bei Server-Fehler
      if (response.statusCode >= 500 && retryCount < maxRetries) {
        await Future.delayed(Duration(seconds: retryCount + 1));
        return _makeRequest(
          endpoint: endpoint,
          body: body,
          retryCount: retryCount + 1,
        );
      }
      
      throw Exception('Request failed: ${response.statusCode} - ${response.body}');
      
    } catch (e) {
      if (retryCount < maxRetries && e is! FormatException) {
        await Future.delayed(Duration(seconds: retryCount + 1));
        return _makeRequest(
          endpoint: endpoint,
          body: body,
          retryCount: retryCount + 1,
        );
      }
      rethrow;
    }
  }
}
