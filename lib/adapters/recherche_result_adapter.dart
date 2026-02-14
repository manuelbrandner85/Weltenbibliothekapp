/// 🔄 RECHERCHE RESULT ADAPTER
/// 
/// Converts old InternetSearchResult to new RechercheResult model
/// 
/// Purpose:
/// - Bridge between existing backend service and new UI widgets
/// - Convert SearchSource to RechercheSource
/// - Map data structures to production-ready models
/// 
/// Usage:
/// ```dart
/// final oldResult = await backendService.searchInternet(query);
/// final newResult = RechercheResultAdapter.convert(oldResult, mode);
/// ```
library;

import '../services/backend_recherche_service.dart';
import '../models/recherche_view_state.dart';

/// Recherche Result Adapter
/// 
/// Converts legacy InternetSearchResult to RechercheResult
class RechercheResultAdapter {
  /// Convert InternetSearchResult to RechercheResult
  static RechercheResult convert(
    InternetSearchResult oldResult,
    RechercheMode mode,
  ) {
    return RechercheResult(
      query: oldResult.query,
      mode: mode,
      sources: _convertSources(oldResult.sources),
      summary: oldResult.summary,
      keyFindings: oldResult.followUpQuestions,
      facts: _extractFacts(oldResult),
      rabbitLayers: _extractRabbitLayers(oldResult),
      perspectives: _extractPerspectives(oldResult),
      confidence: _calculateConfidence(oldResult),
      metadata: _extractMetadata(oldResult),
      timestamp: oldResult.timestamp,
    );
  }
  
  /// Convert SearchSource list to RechercheSource list
  static List<RechercheSource> _convertSources(List<SearchSource> sources) {
    return sources.map((source) {
      return RechercheSource(
        title: source.title,
        url: source.url,
        excerpt: source.snippet,
        relevance: 0.8, // Default relevance score
        sourceType: _mapSourceType(source.sourceType),
        publishDate: source.timestamp,
      );
    }).toList();
  }
  
  /// Map SourceType enum to sourceType string
  static String _mapSourceType(SourceType sourceType) {
    switch (sourceType) {
      case SourceType.mainstream:
        return 'article';
      case SourceType.alternative:
        return 'website';
      case SourceType.independent:
        return 'document';
    }
  }
  
  /// Extract facts from search result
  static List<String> _extractFacts(InternetSearchResult result) {
    final facts = <String>[];
    
    // Extract from multimedia section
    if (result.multimedia != null) {
      final keyPoints = result.multimedia!['key_points'] as List<dynamic>?;
      if (keyPoints != null) {
        facts.addAll(keyPoints.map((p) => p.toString()));
      }
    }
    
    // Extract from top sources snippets
    if (facts.isEmpty && result.sources.isNotEmpty) {
      final topSources = result.sources.take(3);
      for (final source in topSources) {
        if (source.snippet.length > 50) {
          facts.add(source.snippet);
        }
      }
    }
    
    return facts;
  }
  
  /// Extract rabbit layers from timeline
  static List<RabbitLayer> _extractRabbitLayers(InternetSearchResult result) {
    if (result.timeline == null || result.timeline!.isEmpty) {
      return [];
    }
    
    final layers = <RabbitLayer>[];
    
    for (int i = 0; i < result.timeline!.length; i++) {
      final timelineItem = result.timeline![i];
      
      final layer = RabbitLayer(
        layerNumber: i + 1,
        layerName: timelineItem['title']?.toString() ?? 'Layer ${i + 1}',
        description: timelineItem['description']?.toString() ?? '',
        sources: _extractLayerSources(timelineItem),
        connections: _extractConnections(timelineItem),
        depth: (i + 1) / result.timeline!.length,
      );
      
      layers.add(layer);
    }
    
    return layers;
  }
  
  /// Extract sources for a rabbit layer
  static List<RechercheSource> _extractLayerSources(Map<String, dynamic> timelineItem) {
    final sources = <RechercheSource>[];
    
    final referencesData = timelineItem['references'];
    if (referencesData is List) {
      for (final ref in referencesData) {
        if (ref is Map<String, dynamic>) {
          sources.add(RechercheSource(
            title: ref['title']?.toString() ?? 'Source',
            url: ref['url']?.toString() ?? '',
            excerpt: ref['description']?.toString() ?? '',
            relevance: 0.7,
            sourceType: 'reference',
          ));
        }
      }
    }
    
    return sources;
  }
  
  /// Extract connections for a rabbit layer
  static List<String> _extractConnections(Map<String, dynamic> timelineItem) {
    final connections = <String>[];
    
    final connectionsData = timelineItem['connections'];
    if (connectionsData is List) {
      connections.addAll(connectionsData.map((c) => c.toString()));
    }
    
    return connections;
  }
  
  /// Extract perspectives from related topics
  static List<Perspective> _extractPerspectives(InternetSearchResult result) {
    if (result.relatedTopics == null || result.relatedTopics!.isEmpty) {
      return [];
    }
    
    final perspectives = <Perspective>[];
    
    for (final topic in result.relatedTopics!) {
      final perspective = Perspective(
        perspectiveName: topic['title']?.toString() ?? 'Perspective',
        viewpoint: topic['description']?.toString() ?? '',
        arguments: _extractArguments(topic),
        supportingSources: _extractPerspectiveSources(topic),
        credibility: 0.8,
        type: _determinePerspectiveType(topic),
      );
      
      perspectives.add(perspective);
    }
    
    return perspectives;
  }
  
  /// Extract arguments from topic
  static List<String> _extractArguments(Map<String, dynamic> topic) {
    final args = <String>[];
    
    final pointsData = topic['key_points'];
    if (pointsData is List) {
      args.addAll(pointsData.map((p) => p.toString()));
    }
    
    // Fallback: use description as single argument
    if (args.isEmpty) {
      final desc = topic['description']?.toString();
      if (desc != null && desc.isNotEmpty) {
        args.add(desc);
      }
    }
    
    return args;
  }
  
  /// Extract sources for perspective
  static List<RechercheSource> _extractPerspectiveSources(Map<String, dynamic> topic) {
    final sources = <RechercheSource>[];
    
    final sourcesData = topic['sources'];
    if (sourcesData is List) {
      for (final src in sourcesData) {
        if (src is Map<String, dynamic>) {
          sources.add(RechercheSource(
            title: src['title']?.toString() ?? 'Source',
            url: src['url']?.toString() ?? '',
            excerpt: src['excerpt']?.toString() ?? '',
            relevance: 0.75,
            sourceType: 'reference',
          ));
        }
      }
    }
    
    return sources;
  }
  
  /// Determine perspective type from topic metadata
  static PerspectiveType _determinePerspectiveType(Map<String, dynamic> topic) {
    final typeStr = topic['type']?.toString().toLowerCase() ?? '';
    
    if (typeStr.contains('support')) return PerspectiveType.supporting;
    if (typeStr.contains('oppos')) return PerspectiveType.opposing;
    if (typeStr.contains('alternat')) return PerspectiveType.alternative;
    if (typeStr.contains('controvers')) return PerspectiveType.controversial;
    
    return PerspectiveType.neutral;
  }
  
  /// Calculate confidence score based on sources
  static double _calculateConfidence(InternetSearchResult result) {
    if (result.sources.isEmpty) return 0.0;
    
    // Use fixed confidence based on source count
    final sourceScore = (result.sources.length / 10).clamp(0.0, 0.7);
    
    // Bonus for multimedia content
    final multimediaBonus = result.multimedia != null ? 0.1 : 0.0;
    
    // Bonus for timeline depth
    final timelineBonus = result.timeline != null && result.timeline!.isNotEmpty ? 0.1 : 0.0;
    
    // Bonus for related topics
    final topicsBonus = result.relatedTopics != null && result.relatedTopics!.isNotEmpty ? 0.1 : 0.0;
    
    // Clamp to 0.0-1.0 range
    final confidence = (sourceScore + multimediaBonus + timelineBonus + topicsBonus).clamp(0.0, 1.0);
    
    return confidence;
  }
  
  /// Extract metadata from result
  static Map<String, dynamic> _extractMetadata(InternetSearchResult result) {
    return {
      'has_multimedia': result.multimedia != null,
      'has_timeline': result.timeline != null && result.timeline!.isNotEmpty,
      'has_related_topics': result.relatedTopics != null && result.relatedTopics!.isNotEmpty,
      'source_count': result.sources.length,
      'follow_up_count': result.followUpQuestions.length,
      'timestamp': result.timestamp.toIso8601String(),
    };
  }
}

// ============================================================================
// USAGE EXAMPLE
// ============================================================================

/// Example usage:
/// 
/// ```dart
/// final backendService = BackendRechercheService();
/// final oldResult = await backendService.searchInternet('UFOs');
/// 
/// // Convert to new model
/// final newResult = RechercheResultAdapter.convert(
///   oldResult,
///   RechercheMode.conspiracy,
/// );
/// 
/// // Use with new widgets
/// return Column(
///   children: [
///     ResultSummaryCard(result: newResult),
///     FactsList(facts: newResult.facts),
///     SourcesList(sources: newResult.sources),
///     PerspectivesView(perspectives: newResult.perspectives),
///     RabbitHoleView(layers: newResult.rabbitLayers),
///   ],
/// );
/// ```
