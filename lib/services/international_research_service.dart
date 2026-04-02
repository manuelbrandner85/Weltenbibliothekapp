/// WELTENBIBLIOTHEK v5.11.1 – INTERNATIONALE API-INTEGRATION
/// 
/// Parallele API-Aufrufe für verschiedene Regionen/Sprachen
library;

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/international_perspectives.dart';

/// Service für internationale Recherche-Anfragen
class InternationalResearchService {
  final String workerUrl;
  
  InternationalResearchService({
    required this.workerUrl,
  });
  
  /// Führt parallele Recherche in mehreren Regionen durch
  /// 
  /// Entspricht JavaScript:
  /// ```js
  /// async function fetchInternational(query) {
  ///   return {
  ///     de: await crawl(query, "de"),
  ///     en: await crawl(query, "en"),
  ///     global: await crawl(query, "global")
  ///   };
  /// }
  /// ```
  Future<Map<String, Map<String, dynamic>>> fetchInternational(
    String query, {
    List<String>? regions,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    // Standard-Regionen wenn nicht angegeben
    final targetRegions = regions ?? ['de', 'en', 'fr', 'ru', 'global'];
    
    // Erstelle parallele API-Anfragen
    final futures = <String, Future<Map<String, dynamic>>>{};
    
    for (final region in targetRegions) {
      futures[region] = _crawlRegion(query, region, timeout);
    }
    
    // Warte auf alle Anfragen parallel (mit Fehlerbehandlung)
    final results = <String, Map<String, dynamic>>{};
    
    await Future.wait(
      futures.entries.map((entry) async {
        try {
          results[entry.key] = await entry.value;
        } catch (e) {
          // Bei Fehler: Leeres Ergebnis für diese Region
          results[entry.key] = {
            'error': true,
            'message': e.toString(),
            'sources': [],
          };
        }
      }),
    );
    
    return results;
  }
  
  /// Crawlt eine spezifische Region
  Future<Map<String, dynamic>> _crawlRegion(
    String query,
    String region,
    Duration timeout,
  ) async {
    // Baue URL mit Region-Parameter
    final uri = Uri.parse(workerUrl).replace(
      queryParameters: {
        'q': query,
        'region': region,
        'lang': _regionToLanguage(region),
      },
    );
    
    try {
      final response = await http
          .get(uri)
          .timeout(timeout);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 429) {
        throw Exception('Rate-Limit: Bitte 60 Sekunden warten');
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Timeout: Server antwortet nicht');
    } catch (e) {
      rethrow;
    }
  }
  
  /// Konvertiert Region zu Sprach-Code
  String _regionToLanguage(String region) {
    switch (region) {
      case 'de':
        return 'de';
      case 'en':
      case 'us':
        return 'en';
      case 'fr':
        return 'fr';
      case 'ru':
        return 'ru';
      default:
        return 'en'; // Global = English
    }
  }
  
  /// Vereinfachte Methode: Nur wichtigste Regionen
  Future<InternationalResearchResult> fetchQuickInternational(
    String query,
  ) async {
    final results = await fetchInternational(
      query,
      regions: ['de', 'en', 'global'],
    );
    
    return InternationalResearchResult(
      query: query,
      regionResults: results,
      timestamp: DateTime.now(),
    );
  }
  
  /// Stream-basierte Anfrage mit Progress-Updates
  Stream<InternationalProgressUpdate> fetchInternationalStream(
    String query, {
    List<String>? regions,
  }) async* {
    final targetRegions = regions ?? ['de', 'en', 'fr', 'ru', 'global'];
    final totalRegions = targetRegions.length;
    
    yield InternationalProgressUpdate(
      status: 'started',
      completedRegions: 0,
      totalRegions: totalRegions,
      currentRegion: null,
    );
    
    final results = <String, Map<String, dynamic>>{};
    int completed = 0;
    
    for (final region in targetRegions) {
      yield InternationalProgressUpdate(
        status: 'processing',
        completedRegions: completed,
        totalRegions: totalRegions,
        currentRegion: region,
      );
      
      try {
        results[region] = await _crawlRegion(
          query,
          region,
          const Duration(seconds: 30),
        );
        completed++;
        
        yield InternationalProgressUpdate(
          status: 'region_complete',
          completedRegions: completed,
          totalRegions: totalRegions,
          currentRegion: region,
          result: results[region],
        );
      } catch (e) {
        results[region] = {
          'error': true,
          'message': e.toString(),
          'sources': [],
        };
        completed++;
        
        yield InternationalProgressUpdate(
          status: 'region_error',
          completedRegions: completed,
          totalRegions: totalRegions,
          currentRegion: region,
          error: e.toString(),
        );
      }
    }
    
    yield InternationalProgressUpdate(
      status: 'completed',
      completedRegions: completed,
      totalRegions: totalRegions,
      currentRegion: null,
      allResults: results,
    );
  }
}

/// Ergebnis einer internationalen Recherche
class InternationalResearchResult {
  final String query;
  final Map<String, Map<String, dynamic>> regionResults;
  final DateTime timestamp;
  
  const InternationalResearchResult({
    required this.query,
    required this.regionResults,
    required this.timestamp,
  });
  
  /// Extrahiert alle Quellen
  List<String> getAllSources() {
    final sources = <String>[];
    for (final result in regionResults.values) {
      if (result['sources'] != null) {
        sources.addAll((result['sources'] as List).map((s) => s.toString()));
      }
    }
    return sources;
  }
  
  /// Zählt Quellen pro Region
  Map<String, int> getSourceCounts() {
    return regionResults.map((region, result) {
      final sources = result['sources'] as List? ?? [];
      return MapEntry(region, sources.length);
    });
  }
  
  /// Gibt erfolgreiche Regionen zurück
  List<String> getSuccessfulRegions() {
    return regionResults.entries
        .where((e) => e.value['error'] != true)
        .map((e) => e.key)
        .toList();
  }
  
  /// Gibt fehlgeschlagene Regionen zurück
  List<String> getFailedRegions() {
    return regionResults.entries
        .where((e) => e.value['error'] == true)
        .map((e) => e.key)
        .toList();
  }
  
  /// Parst zu InternationalPerspectivesAnalysis
  InternationalPerspectivesAnalysis? toAnalysis() {
    try {
      // Kombiniere alle Quellen
      // UNUSED: final allSources = getAllSources();
      
      // Gruppiere nach Region
// UNUSED: final sourcesByRegion = RegionDetector.groupSourcesByRegion(allSources);
// UNUSED: final sourceDistribution = RegionDetector.countSourcesByRegion(allSources);
      
      // Erstelle Perspektiven
      final perspectives = <InternationalPerspective>[];
      
      for (final entry in regionResults.entries) {
        if (entry.value['error'] == true) continue;
        
        final region = entry.key;
        final regionDef = InternationalPerspective.getRegionDefinition(region);
        if (regionDef == null) continue;
        
        final sources = (entry.value['sources'] as List?)
            ?.map((s) => s.toString())
            .toList() ?? [];
        
        if (sources.isEmpty) continue;
        
        perspectives.add(InternationalPerspective(
          region: region,
          regionLabel: regionDef.label,
          sources: sources,
          narrative: _extractNarrative(entry.value),
          keyPoints: _extractKeyPoints(entry.value),
          tone: _extractTone(entry.value),
        ));
      }
      
      return InternationalPerspectivesAnalysis(
        topic: query,
        perspectives: perspectives,
        commonPoints: _extractCommonPoints(regionResults),
        differences: _extractDifferences(regionResults),
      );
    } catch (e) {
      return null;
    }
  }
  
  String _extractNarrative(Map<String, dynamic> result) {
    if (result['analyse'] != null) {
      final analyse = result['analyse'] as Map<String, dynamic>?;
      return analyse?['inhalt'] as String? ?? 'Keine Narrative verfügbar';
    }
    return 'Keine Narrative verfügbar';
  }
  
  List<String> _extractKeyPoints(Map<String, dynamic> result) {
    // Extrahiere Hauptpunkte aus strukturierten Daten
    if (result['structured'] != null) {
      final structured = result['structured'] as Map<String, dynamic>?;
      if (structured?['faktenbasis'] != null) {
        final fb = structured!['faktenbasis'] as Map<String, dynamic>;
        final facts = fb['facts'] as List? ?? [];
        return facts.take(3).map((f) => f.toString()).toList();
      }
    }
    return ['Hauptpunkt 1', 'Hauptpunkt 2'];
  }
  
  String _extractTone(Map<String, dynamic> result) {
    // Placeholder - könnte Sentiment-Analyse nutzen
    return 'neutral';
  }
  
  List<String> _extractCommonPoints(Map<String, Map<String, dynamic>> results) {
    // Placeholder - würde Gemeinsamkeiten zwischen Regionen finden
    return ['Gemeinsamer Punkt 1', 'Gemeinsamer Punkt 2'];
  }
  
  List<String> _extractDifferences(Map<String, Map<String, dynamic>> results) {
    // Placeholder - würde Unterschiede zwischen Regionen finden
    return ['Unterschied 1', 'Unterschied 2'];
  }
}

/// Progress-Update für Stream-basierte Anfragen
class InternationalProgressUpdate {
  final String status;              // 'started', 'processing', 'region_complete', 'region_error', 'completed'
  final int completedRegions;
  final int totalRegions;
  final String? currentRegion;
  final Map<String, dynamic>? result;
  final Map<String, Map<String, dynamic>>? allResults;
  final String? error;
  
  const InternationalProgressUpdate({
    required this.status,
    required this.completedRegions,
    required this.totalRegions,
    this.currentRegion,
    this.result,
    this.allResults,
    this.error,
  });
  
  /// Fortschritt in Prozent
  double get progress => completedRegions / totalRegions;
  
  /// Fortschritt als String
  String get progressText => '$completedRegions/$totalRegions';
  
  /// Icon basierend auf Status
  String get statusIcon {
    switch (status) {
      case 'started':
        return '🚀';
      case 'processing':
        return '⏳';
      case 'region_complete':
        return '✅';
      case 'region_error':
        return '❌';
      case 'completed':
        return '🎉';
      default:
        return '📊';
    }
  }
  
  /// Benutzerfreundliche Nachricht
  String get message {
    switch (status) {
      case 'started':
        return 'Starte internationale Recherche...';
      case 'processing':
        return 'Durchsuche $currentRegion...';
      case 'region_complete':
        final sourceCount = result?['sources']?.length ?? 0;
        return '$currentRegion: $sourceCount Quellen gefunden';
      case 'region_error':
        return '$currentRegion: Fehler - $error';
      case 'completed':
        return 'Recherche abgeschlossen! ($progressText Regionen)';
      default:
        return 'Status: $status';
    }
  }
}

/// Beispiel-Nutzung:
/// 
/// ```dart
/// final service = InternationalResearchService(
///   workerUrl: ApiConfig.baseUrl,
/// );
/// 
/// // Methode 1: Parallel (schnellste)
/// final results = await service.fetchInternational('MK Ultra');
/// 
/// // Methode 2: Quick (nur wichtigste Regionen)
/// final quickResult = await service.fetchQuickInternational('MK Ultra');
/// 
/// // Methode 3: Stream (mit Progress-Updates)
/// await for (final update in service.fetchInternationalStream('MK Ultra')) {
///   debugPrint('${update.statusIcon} ${update.message}');
///   if (update.status == 'completed') {
///     final analysis = InternationalResearchResult(
///       query: 'MK Ultra',
///       regionResults: update.allResults!,
///       timestamp: DateTime.now(),
///     ).toAnalysis();
///   }
/// }
/// ```
