import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/api_config.dart';
import 'mentor_personas.dart'; // 🎭 L1: welt-spezifische Personas
import 'sqlite_storage_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 🧠 KI-MENTOR SERVICE — 4 Persönlichkeiten, Groq + Workers AI Fallback
// ═══════════════════════════════════════════════════════════════════════════

/// Mentor-Persönlichkeiten, eine pro Welt.
enum MentorPersonality {
  stratege, // VORHANG — Machtanalyst, kalt-logisch
  alchemist, // URSPRUNG — Bewusstseinsexperte, mystisch
  heiler, // ENERGIE — Empathisch, heilend
  forscher, // MATERIE — Wissenschaftlich, faktisch
}

/// Mapping Welt → Mentor-Persönlichkeit.
MentorPersonality mentorForWorld(String world) {
  switch (world) {
    case 'vorhang':
      return MentorPersonality.stratege;
    case 'ursprung':
      return MentorPersonality.alchemist;
    case 'energie':
      return MentorPersonality.heiler;
    case 'materie':
    default:
      return MentorPersonality.forscher;
  }
}

/// Display-Name des Mentors.
String mentorDisplayName(MentorPersonality p) {
  switch (p) {
    case MentorPersonality.stratege:
      return 'Der Stratege';
    case MentorPersonality.alchemist:
      return 'Der Alchemist';
    case MentorPersonality.heiler:
      return 'Der Heiler';
    case MentorPersonality.forscher:
      return 'Der Forscher';
  }
}

// ── Response Models ──────────────────────────────────────────────────────

class MentorResponse {
  final String reply;
  final String modelUsed;
  final DateTime timestamp;

  MentorResponse({
    required this.reply,
    required this.modelUsed,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory MentorResponse.fromJson(Map<String, dynamic> json) {
    return MentorResponse(
      reply: json['reply'] as String? ?? '',
      modelUsed: json['model_used'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class FactCheckResponse {
  final String verdict;
  final List<FactCheckSource> sources;
  final String explanation;

  FactCheckResponse({
    required this.verdict,
    required this.sources,
    required this.explanation,
  });

  factory FactCheckResponse.fromJson(Map<String, dynamic> json) {
    return FactCheckResponse(
      verdict: json['verdict'] as String? ?? 'Unbekannt',
      explanation: json['explanation'] as String? ?? '',
      sources: (json['sources'] as List<dynamic>?)
              ?.map((s) => FactCheckSource.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class FactCheckSource {
  final String claim;
  final String source;
  final String rating;
  final String url;

  FactCheckSource({
    required this.claim,
    required this.source,
    required this.rating,
    this.url = '',
  });

  factory FactCheckSource.fromJson(Map<String, dynamic> json) {
    return FactCheckSource(
      claim: json['claim'] as String? ?? '',
      source: json['source'] as String? ?? '',
      rating: json['rating'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }
}

class YouTubeVideo {
  final String title;
  final String videoId;
  final String thumbnail;
  final String channel;
  final String description;

  YouTubeVideo({
    required this.title,
    required this.videoId,
    required this.thumbnail,
    required this.channel,
    this.description = '',
  });

  factory YouTubeVideo.fromJson(Map<String, dynamic> json) {
    return YouTubeVideo(
      title: json['title'] as String? ?? '',
      videoId: json['videoId'] as String? ?? '',
      thumbnail: json['thumbnail'] as String? ?? '',
      channel: json['channel'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

class InvestigationResult {
  final String summary;
  final List<String> facts;
  final List<InvestigationSource> sources;
  final List<String> relatedTopics;
  final String modelUsed;

  InvestigationResult({
    required this.summary,
    required this.facts,
    required this.sources,
    required this.relatedTopics,
    this.modelUsed = '',
  });

  factory InvestigationResult.fromJson(Map<String, dynamic> json) {
    return InvestigationResult(
      summary: json['summary'] as String? ?? '',
      facts: (json['facts'] as List<dynamic>?)
              ?.map((f) => f.toString())
              .toList() ??
          [],
      sources: (json['sources'] as List<dynamic>?)
              ?.map((s) =>
                  InvestigationSource.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      relatedTopics: (json['relatedTopics'] as List<dynamic>?)
              ?.map((t) => t.toString())
              .toList() ??
          [],
      modelUsed: json['model_used'] as String? ?? '',
    );
  }
}

class InvestigationSource {
  final String author;
  final String title;
  final String year;

  InvestigationSource({
    required this.author,
    required this.title,
    this.year = '',
  });

  factory InvestigationSource.fromJson(Map<String, dynamic> json) {
    return InvestigationSource(
      author: json['author'] as String? ?? '',
      title: json['title'] as String? ?? '',
      year: json['year'] as String? ?? '',
    );
  }
}

/// Chat-Nachricht im lokalen Verlauf.
class MentorChatMessage {
  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime timestamp;
  final String? type; // null=normal, 'factcheck', 'youtube', 'investigation'
  final Map<String, dynamic>? metadata; // Extra-Daten (FactCheck-Ergebnis etc.)

  MentorChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.type,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        if (type != null) 'type': type,
        if (metadata != null) 'metadata': metadata,
      };

  factory MentorChatMessage.fromJson(Map<String, dynamic> json) {
    return MentorChatMessage(
      role: json['role'] as String? ?? 'user',
      content: json['content'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      type: json['type'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MENTOR SERVICE (Singleton)
// ═══════════════════════════════════════════════════════════════════════════

class MentorService {
  MentorService._internal();
  static final MentorService _instance = MentorService._internal();
  factory MentorService() => _instance;

  static const String _boxName = 'mentor_chats';
  static const int _maxContextMessages = 50;

  final _client = http.Client();

  // ── Basis-URL ──
  String get _baseUrl => ApiConfig.workerUrl;

  // ── Auth-Header (Supabase JWT wenn eingeloggt) ──
  Map<String, String> get _headers {
    final token =
        Supabase.instance.client.auth.currentSession?.accessToken ?? '';
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  String? get _userId => Supabase.instance.client.auth.currentUser?.id;

  // ═══════════════════════════════════════════════════════════
  // API CALLS
  // ═══════════════════════════════════════════════════════════

  /// Sendet Nachricht an den KI-Mentor.
  Future<MentorResponse> sendMessage({
    required MentorPersonality personality,
    required String message,
    required List<MentorChatMessage> history,
    required String world,
  }) async {
    try {
      final res = await _client
          .post(
            Uri.parse('$_baseUrl/api/mentor/chat'),
            headers: _headers,
            body: jsonEncode({
              'personality': personality.name,
              'message': message,
              'conversationHistory': history
                  .where((m) => m.type == null) // Nur echte Chat-Nachrichten
                  .toList()
                  .reversed
                  .take(_maxContextMessages)
                  .toList()
                  .reversed
                  .map((m) => {'role': m.role, 'content': m.content})
                  .toList(),
              'world': world,
              'userId': _userId ?? '',
              // 🎭 L1: Welt-spezifische Persona als System-Prompt-Override.
              // Worker übernimmt diesen wenn vorhanden (statt Generic).
              'systemPrompt': MentorPersonas.systemPrompt(world),
              'mentorDisplayName': MentorPersonas.displayName(world),
              'mentorAvatarEmoji': MentorPersonas.avatarEmoji(world),
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode == 429) {
        final body = jsonDecode(res.body);
        throw Exception(body['error'] ?? 'Rate-Limit erreicht');
      }
      if (res.statusCode != 200) {
        throw Exception('Server-Fehler (${res.statusCode})');
      }

      return MentorResponse.fromJson(jsonDecode(res.body));
    } catch (e) {
      if (kDebugMode) debugPrint('❌ MentorService.sendMessage: $e');
      rethrow;
    }
  }

  /// Fakten-Check einer Behauptung.
  Future<FactCheckResponse> factCheck(String claim) async {
    try {
      final res = await _client
          .post(
            Uri.parse('$_baseUrl/api/mentor/factcheck'),
            headers: _headers,
            body: jsonEncode({'claim': claim}),
          )
          .timeout(const Duration(seconds: 20));

      if (res.statusCode != 200) {
        throw Exception('Faktencheck fehlgeschlagen (${res.statusCode})');
      }

      return FactCheckResponse.fromJson(jsonDecode(res.body));
    } catch (e) {
      if (kDebugMode) debugPrint('❌ MentorService.factCheck: $e');
      rethrow;
    }
  }

  /// YouTube-Suche zu einem Thema.
  Future<List<YouTubeVideo>> searchYouTube(String query) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/mentor/youtube-search')
          .replace(queryParameters: {'q': query, 'maxResults': '5'});

      final res = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) return [];

      final data = jsonDecode(res.body);
      return (data['videos'] as List<dynamic>?)
              ?.map((v) => YouTubeVideo.fromJson(v as Map<String, dynamic>))
              .toList() ??
          [];
    } catch (e) {
      if (kDebugMode) debugPrint('❌ MentorService.searchYouTube: $e');
      return [];
    }
  }

  /// Tiefenrecherche zu einem Thema.
  Future<InvestigationResult> investigate(String topic,
      {String depth = 'basic'}) async {
    try {
      final res = await _client
          .post(
            Uri.parse('$_baseUrl/api/mentor/investigate'),
            headers: _headers,
            body: jsonEncode({'topic': topic, 'depth': depth}),
          )
          .timeout(const Duration(seconds: 45));

      if (res.statusCode != 200) {
        throw Exception('Recherche fehlgeschlagen (${res.statusCode})');
      }

      return InvestigationResult.fromJson(jsonDecode(res.body));
    } catch (e) {
      if (kDebugMode) debugPrint('❌ MentorService.investigate: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // LOKALER CHAT-VERLAUF (SQLite)
  // ═══════════════════════════════════════════════════════════

  /// Lade Chat-Verlauf für eine bestimmte Welt.
  List<MentorChatMessage> loadHistory(String world) {
    try {
      final raw = SqliteStorageService.instance.getSync(_boxName, world);
      if (raw == null) return [];
      final list = (raw as List<dynamic>)
          .map((e) =>
              MentorChatMessage.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      return list;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ MentorService.loadHistory: $e');
      return [];
    }
  }

  /// Speichere Chat-Verlauf für eine Welt.
  Future<void> saveHistory(
      String world, List<MentorChatMessage> messages) async {
    try {
      // Max 200 Nachrichten lokal speichern (ältere abschneiden)
      final trimmed = messages.length > 200
          ? messages.sublist(messages.length - 200)
          : messages;
      await SqliteStorageService.instance.put(
        _boxName,
        world,
        trimmed.map((m) => m.toJson()).toList(),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ MentorService.saveHistory: $e');
    }
  }

  /// Lösche Chat-Verlauf für eine Welt.
  Future<void> clearHistory(String world) async {
    try {
      await SqliteStorageService.instance.delete(_boxName, world);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ MentorService.clearHistory: $e');
    }
  }
}
