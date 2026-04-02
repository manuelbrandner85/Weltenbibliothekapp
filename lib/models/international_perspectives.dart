/// WELTENBIBLIOTHEK v5.11 – INTERNATIONALE PERSPEKTIVEN-SYSTEM
/// 
/// Zeigt wie dasselbe Thema international unterschiedlich dargestellt wird:
/// - Quellen-Aufteilung nach Sprache/Region
/// - Narrative-Vergleich zwischen Ländern
/// - Kulturelle Unterschiede in der Berichterstattung
library;

import 'package:flutter/material.dart';

/// Internationale Perspektive auf ein Thema
class InternationalPerspective {
  final String region;              // "de", "us", "fr", "ru", "global"
  final String regionLabel;         // "🇩🇪 Deutschsprachiger Raum"
  final List<String> sources;       // Quellen aus dieser Region
  final String narrative;           // Wie wird das Thema hier dargestellt?
  final List<String> keyPoints;     // Hauptpunkte dieser Perspektive
  final String tone;                // "kritisch", "neutral", "befürwortend"
  
  const InternationalPerspective({
    required this.region,
    required this.regionLabel,
    required this.sources,
    required this.narrative,
    required this.keyPoints,
    required this.tone,
  });
  
  /// Erstelle aus Backend JSON
  factory InternationalPerspective.fromJson(Map<String, dynamic> json) {
    return InternationalPerspective(
      region: json['region'] ?? 'unknown',
      regionLabel: json['regionLabel'] ?? 'Unknown Region',
      sources: List<String>.from(json['sources'] ?? []),
      narrative: json['narrative'] ?? '',
      keyPoints: List<String>.from(json['keyPoints'] ?? []),
      tone: json['tone'] ?? 'neutral',
    );
  }
  
  /// Vordefinierte Regionen
  static const regions = [
    RegionDefinition('de', '🇩🇪 Deutschsprachiger Raum', Colors.black),
    RegionDefinition('us', '🇺🇸 Englisch / USA', Colors.blue),
    RegionDefinition('fr', '🇫🇷 Französisch / Frankreich', Colors.indigo),
    RegionDefinition('ru', '🇷🇺 Russisch / Russland', Colors.red),
    RegionDefinition('global', '🌍 International / Global', Colors.green),
  ];
  
  /// Findet Region-Definition
  static RegionDefinition? getRegionDefinition(String regionCode) {
    try {
      return regions.firstWhere((r) => r.code == regionCode);
    } catch (e) {
      return null;
    }
  }
}

/// Region-Definition
class RegionDefinition {
  final String code;
  final String label;
  final Color color;
  
  const RegionDefinition(this.code, this.label, this.color);
}

/// Internationale Perspektiven-Analyse
class InternationalPerspectivesAnalysis {
  final String topic;
  final List<InternationalPerspective> perspectives;
  final List<String> commonPoints;              // Gemeinsame Punkte
  final List<String> differences;               // Unterschiede
  
  const InternationalPerspectivesAnalysis({
    required this.topic,
    required this.perspectives,
    required this.commonPoints,
    required this.differences,
  });
  
  /// Findet Perspektive für Region
  InternationalPerspective? getPerspectiveByRegion(String region) {
    try {
      return perspectives.firstWhere((p) => p.region == region);
    } catch (e) {
      return null;
    }
  }
  
  /// Gibt alle Regionen zurück
  List<String> get availableRegions => 
      perspectives.map((p) => p.region).toList();
  
  /// Hauptregion (meiste Quellen)
  String get primaryRegion {
    if (perspectives.isEmpty) return 'global';
    return perspectives
        .reduce((a, b) => a.sources.length > b.sources.length ? a : b)
        .region;
  }
}

/// Helper: Extrahiert Region aus Quelle
class RegionDetector {
  /// Detektiert Region basierend auf Domain/Sprache
  static String detectRegion(String quelle) {
    final lower = quelle.toLowerCase();
    
    // Deutschsprachiger Raum
    if (_isGermanSource(lower)) return 'de';
    
    // US/Englisch
    if (_isUSSource(lower)) return 'us';
    
    // Französisch
    if (_isFrenchSource(lower)) return 'fr';
    
    // Russisch
    if (_isRussianSource(lower)) return 'ru';
    
    // International/Global
    return 'global';
  }
  
  static bool _isGermanSource(String source) {
    return source.contains('.de') ||
           source.contains('.at') ||
           source.contains('.ch') ||
           source.contains('spiegel') ||
           source.contains('zeit') ||
           source.contains('faz') ||
           source.contains('sueddeutsche') ||
           source.contains('tagesschau') ||
           source.contains('deutschsprachig');
  }
  
  static bool _isUSSource(String source) {
    return source.contains('.com') ||
           source.contains('.us') ||
           source.contains('nytimes') ||
           source.contains('washingtonpost') ||
           source.contains('cnn') ||
           source.contains('bbc') ||
           source.contains('reuters') ||
           source.contains('ap news') ||
           source.contains('english');
  }
  
  static bool _isFrenchSource(String source) {
    return source.contains('.fr') ||
           source.contains('lemonde') ||
           source.contains('figaro') ||
           source.contains('liberation') ||
           source.contains('france') ||
           source.contains('french');
  }
  
  static bool _isRussianSource(String source) {
    return source.contains('.ru') ||
           source.contains('tass') ||
           source.contains('ria') ||
           source.contains('sputnik') ||
           source.contains('pravda') ||
           source.contains('russian');
  }
  
  /// Gruppiert Quellen nach Region
  static Map<String, List<String>> groupSourcesByRegion(List<String> sources) {
    final grouped = <String, List<String>>{
      'de': [],
      'us': [],
      'fr': [],
      'ru': [],
      'global': [],
    };
    
    for (final source in sources) {
      final region = detectRegion(source);
      grouped[region]?.add(source);
    }
    
    return grouped;
  }
  
  /// Zählt Quellen pro Region
  static Map<String, int> countSourcesByRegion(List<String> sources) {
    final grouped = groupSourcesByRegion(sources);
    return grouped.map((region, sources) => MapEntry(region, sources.length));
  }
}

/// Parser für internationale Perspektiven aus API-Response
class InternationalPerspectivesParser {
  /// Parst strukturierte Daten zu internationalen Perspektiven
  static InternationalPerspectivesAnalysis? parse(
    Map<String, dynamic> data,
    String query,
  ) {
    try {
      // Extrahiere alle Quellen
      final allSources = _extractAllSources(data);
      
      // Gruppiere nach Region
      final sourcesByRegion = RegionDetector.groupSourcesByRegion(allSources);
      
      // Erstelle Perspektiven
      final perspectives = <InternationalPerspective>[];
      
      for (final entry in sourcesByRegion.entries) {
        if (entry.value.isEmpty) continue;
        
        final region = entry.key;
        final regionDef = InternationalPerspective.getRegionDefinition(region);
        
        if (regionDef != null) {
          perspectives.add(InternationalPerspective(
            region: region,
            regionLabel: regionDef.label,
            sources: entry.value,
            narrative: _extractNarrativeForRegion(data, region),
            keyPoints: _extractKeyPointsForRegion(data, region),
            tone: _detectTone(data, region),
          ));
        }
      }
      
      return InternationalPerspectivesAnalysis(
        topic: query,
        perspectives: perspectives,
        commonPoints: _extractCommonPoints(data),
        differences: _extractDifferences(data),
      );
    } catch (e) {
      return null;
    }
  }
  
  static List<String> _extractAllSources(Map<String, dynamic> data) {
    final sources = <String>[];
    
    // Aus strukturierten Daten
    if (data.containsKey('structured')) {
      final structured = data['structured'] as Map<String, dynamic>?;
      if (structured != null) {
        // Sichtweise 1 (Offiziell)
        if (structured.containsKey('sichtweise1_offiziell')) {
          final view1 = structured['sichtweise1_offiziell'] as Map<String, dynamic>?;
          if (view1?['quellen'] != null) {
            sources.addAll((view1!['quellen'] as List).map((q) => q.toString()));
          }
        }
        
        // Sichtweise 2 (Alternativ)
        if (structured.containsKey('sichtweise2_alternativ')) {
          final view2 = structured['sichtweise2_alternativ'] as Map<String, dynamic>?;
          if (view2?['quellen'] != null) {
            sources.addAll((view2!['quellen'] as List).map((q) => q.toString()));
          }
        }
      }
    }
    
    return sources;
  }
  
  static String _extractNarrativeForRegion(Map<String, dynamic> data, String region) {
    // Placeholder - würde in echtem System regionsspezifische Narrative extrahieren
    switch (region) {
      case 'de':
        return 'Deutsche Perspektive mit Fokus auf europäische Auswirkungen';
      case 'us':
        return 'US-amerikanische Perspektive mit Fokus auf nationale Sicherheit';
      case 'fr':
        return 'Französische Perspektive mit Fokus auf diplomatische Aspekte';
      case 'ru':
        return 'Russische Perspektive mit staatlicher Interpretation';
      default:
        return 'Internationale neutrale Perspektive';
    }
  }
  
  static List<String> _extractKeyPointsForRegion(Map<String, dynamic> data, String region) {
    // Placeholder
    return ['Hauptpunkt 1', 'Hauptpunkt 2', 'Hauptpunkt 3'];
  }
  
  static String _detectTone(Map<String, dynamic> data, String region) {
    // Placeholder
    return 'neutral';
  }
  
  static List<String> _extractCommonPoints(Map<String, dynamic> data) {
    // Placeholder
    return ['Gemeinsamer Punkt 1', 'Gemeinsamer Punkt 2'];
  }
  
  static List<String> _extractDifferences(Map<String, dynamic> data) {
    // Placeholder
    return ['Unterschied 1', 'Unterschied 2'];
  }
}
