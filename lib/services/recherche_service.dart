import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/recherche_extended_models.dart';

/// Recherche Service für Cloudflare Worker Backend V16.0
/// Worker-URL: https://weltenbibliothek-api-v2.brandy13062.workers.dev
/// Features: 16 Analyse-Module inkl. Machtanalyse, Netzwerk, Timeline, Narrativ-Vergleich, Meta-System
class RechercheService {
  static const String _workerUrl = 'https://weltenbibliothek-api-v2.brandy13062.workers.dev/recherche';
  
  /// Führt eine Recherche durch
  Future<RechercheResult> recherchieren({
    required String query,
    String depth = 'medium', // 'low', 'medium', 'high'
    List<String> perspectives = const ['mainstream', 'kritisch', 'alternativ'],
    String language = 'de',
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_workerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tab_context': 'welt_materie_recherche',
          'query': query,
          'depth': depth,
          'perspectives': perspectives,
          'language': language,
        }),
      ).timeout(
        const Duration(seconds: 120),
        onTimeout: () => throw Exception('Recherche-Timeout'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return RechercheResult.fromJson(data);
      } else {
        throw Exception('Recherche fehlgeschlagen: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Recherche Error: $e');
      }
      rethrow;
    }
  }
}

/// Recherche-Ergebnis Model (V16.0 Extended)
class RechercheResult {
  final String scraperStatus; // "daten_gefunden" oder "keine_daten"
  final List<RechercheQuelle> quellen;
  final String? faktenZusammenfassung;
  final AlternativeAnalyse? alternativeAnalyse;
  
  // V16.0 Erweiterte Module
  final Machtanalyse? machtanalyse;
  final NetzwerkAnalyse? netzwerk;
  final TimelineAnalyse? timeline;
  final NarrativVergleich? narrativVergleich;
  final MetaSystemanalyse? metaSystem;
  final NutzerDisplay? nutzerDisplay;
  
  RechercheResult({
    required this.scraperStatus,
    required this.quellen,
    this.faktenZusammenfassung,
    this.alternativeAnalyse,
    this.machtanalyse,
    this.netzwerk,
    this.timeline,
    this.narrativVergleich,
    this.metaSystem,
    this.nutzerDisplay,
  });
  
  factory RechercheResult.fromJson(Map<String, dynamic> json) {
    return RechercheResult(
      scraperStatus: json['scraper_status'] ?? 'keine_daten',
      quellen: (json['sources'] as List?)
          ?.map((q) => RechercheQuelle.fromJson(q))
          .toList() ?? [],
      faktenZusammenfassung: json['fakten_zusammenfassung'],
      alternativeAnalyse: json['alternative_analyse'] != null
          ? AlternativeAnalyse.fromJson(json['alternative_analyse'])
          : null,
      
      // V16.0 Module
      machtanalyse: json['machtanalyse'] != null
          ? Machtanalyse.fromJson(json['machtanalyse'])
          : null,
      netzwerk: json['netzwerk'] != null
          ? NetzwerkAnalyse.fromJson(json['netzwerk'])
          : null,
      timeline: json['timeline'] != null
          ? TimelineAnalyse.fromJson(json['timeline'])
          : null,
      narrativVergleich: json['narrativ_vergleich'] != null
          ? NarrativVergleich.fromJson(json['narrativ_vergleich'])
          : null,
      metaSystem: json['meta_systemanalyse'] != null
          ? MetaSystemanalyse.fromJson(json['meta_systemanalyse'])
          : null,
      nutzerDisplay: json['nutzer_display'] != null
          ? NutzerDisplay.fromJson(json['nutzer_display'])
          : null,
    );
  }
  
  bool get hatDaten => scraperStatus == 'daten_gefunden' && quellen.isNotEmpty;
  bool get hatErweiterteAnalyse => machtanalyse != null || netzwerk != null || timeline != null;
}

/// Alternative Analyse Model
class AlternativeAnalyse {
  final String kennzeichnung;
  final List<String> perspektiven;
  final String analyse;
  final String disclaimer;
  
  AlternativeAnalyse({
    required this.kennzeichnung,
    required this.perspektiven,
    required this.analyse,
    required this.disclaimer,
  });
  
  factory AlternativeAnalyse.fromJson(Map<String, dynamic> json) {
    return AlternativeAnalyse(
      kennzeichnung: json['kennzeichnung'] ?? '⚠️ Alternative Analyse',
      perspektiven: (json['perspektiven'] as List?)?.cast<String>() ?? [],
      analyse: json['analyse'] ?? '',
      disclaimer: json['disclaimer'] ?? '',
    );
  }
}

/// Einzelne Recherche-Quelle
class RechercheQuelle {
  final String titel;
  final String? autor;
  final String? datum;
  final String typ; // "text", "pdf", "video", "audio"
  final String url;
  final String kurzinhalt;
  
  RechercheQuelle({
    required this.titel,
    this.autor,
    this.datum,
    required this.typ,
    required this.url,
    required this.kurzinhalt,
  });
  
  factory RechercheQuelle.fromJson(Map<String, dynamic> json) {
    return RechercheQuelle(
      titel: json['title'] ?? json['titel'] ?? 'Ohne Titel',
      autor: json['author'] ?? json['autor'],
      datum: json['date'] ?? json['datum'],
      typ: json['media_type'] ?? json['typ'] ?? 'text',
      url: json['url'] ?? '',
      kurzinhalt: json['description'] ?? json['kurzinhalt'] ?? '',
    );
  }
  
  /// Icon basierend auf Typ
  String get typeIcon {
    switch (typ.toLowerCase()) {
      case 'pdf':
        return '📄';
      case 'video':
        return '🎥';
      case 'audio':
        return '🎧';
      default:
        return '📝';
    }
  }
  
  /// Farbe basierend auf Typ
  int get typeColor {
    switch (typ.toLowerCase()) {
      case 'pdf':
        return 0xFFF44336; // Rot
      case 'video':
        return 0xFF2196F3; // Blau
      case 'audio':
        return 0xFF9C27B0; // Lila
      default:
        return 0xFF4CAF50; // Grün
    }
  }
}
