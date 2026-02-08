// lib/services/narrative_connection_service.dart
// WELTENBIBLIOTHEK v9.0 - SPRINT 2: AI RESEARCH ASSISTANT
// Feature 14.3: Narrative Connection Engine
// Auto-discover related narratives with similarity scoring

import 'package:flutter/foundation.dart';
import '../models/narrative.dart';

/// Narrative Connection Service - Singleton
/// Discovers and scores relationships between narratives
class NarrativeConnectionService {
  static final NarrativeConnectionService _instance = NarrativeConnectionService._internal();
  factory NarrativeConnectionService() => _instance;
  NarrativeConnectionService._internal();

  // Cache for connections
  final Map<String, List<NarrativeConnection>> _connectionsCache = {};
  DateTime? _lastCacheUpdate;
  static const _cacheDuration = Duration(minutes: 30);

  /// Find related narratives for a given narrative
  Future<List<NarrativeConnection>> findRelatedNarratives(
    Narrative narrative, {
    int limit = 10,
    double minSimilarity = 0.3,
  }) async {
    try {
      // Check cache first
      final cached = _getCachedConnections(narrative.id);
      if (cached != null && cached.isNotEmpty) {
        return cached.take(limit).toList();
      }

      // Get all narratives from storage
      final allNarratives = await _getAllNarratives();
      
      // Calculate similarity scores
      final connections = <NarrativeConnection>[];
      
      for (final otherNarrative in allNarratives) {
        // Skip self
        if (otherNarrative.id == narrative.id) continue;
        
        // Calculate similarity
        final similarity = _calculateSimilarity(narrative, otherNarrative);
        
        if (similarity >= minSimilarity) {
          connections.add(NarrativeConnection(
            sourceId: narrative.id,
            targetId: otherNarrative.id,
            targetNarrative: otherNarrative,
            similarityScore: similarity,
            connectionType: _determineConnectionType(narrative, otherNarrative, similarity),
            sharedTags: _getSharedTags(narrative, otherNarrative),
            sharedKeywords: _getSharedKeywords(narrative, otherNarrative),
          ));
        }
      }
      
      // Sort by similarity (highest first)
      connections.sort((a, b) => b.similarityScore.compareTo(a.similarityScore));
      
      // Cache results
      _cacheConnections(narrative.id, connections);
      
      if (kDebugMode) {
        debugPrint('🔗 Found ${connections.length} connections for: ${narrative.titel}');
      }
      
      return connections.take(limit).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ NarrativeConnection error: $e');
      }
      return [];
    }
  }

  /// Calculate similarity between two narratives
  double _calculateSimilarity(Narrative n1, Narrative n2) {
    double score = 0.0;

    // 1. Category similarity (30%)
    if (n1.kategorie == n2.kategorie) {
      score += 0.3;
    }

    // 2. Tag similarity (40%)
    final sharedTags = _getSharedTags(n1, n2);
    if (sharedTags.isNotEmpty) {
      final totalTags = (n1.tags?.length ?? 0) + (n2.tags?.length ?? 0);
      if (totalTags > 0) {
        final tagSimilarity = (sharedTags.length * 2) / totalTags;
        score += tagSimilarity * 0.4;
      }
    }

    // 3. Keyword similarity (20%)
    final sharedKeywords = _getSharedKeywords(n1, n2);
    if (sharedKeywords.isNotEmpty) {
      final keywordScore = (sharedKeywords.length / 10).clamp(0.0, 1.0);
      score += keywordScore * 0.2;
    }

    // 4. Temporal proximity (10%)
    // Narratives from similar time periods might be related
    final n1Year = _extractYear(n1);
    final n2Year = _extractYear(n2);
    if (n1Year != null && n2Year != null) {
      final yearDiff = (n1Year - n2Year).abs();
      if (yearDiff < 50) {
        final temporalScore = (50 - yearDiff) / 50;
        score += temporalScore * 0.1;
      }
    }

    return score.clamp(0.0, 1.0);
  }

  /// Determine connection type based on similarity factors
  ConnectionType _determineConnectionType(Narrative n1, Narrative n2, double similarity) {
    // Check for direct references
    if (_hasDirectReference(n1, n2)) {
      return ConnectionType.directReference;
    }

    // Check category match
    if (n1.kategorie == n2.kategorie) {
      if (similarity > 0.7) {
        return ConnectionType.strongSimilarity;
      } else if (similarity > 0.5) {
        return ConnectionType.sameTopic;
      }
    }

    // Check temporal connection
    final n1Year = _extractYear(n1);
    final n2Year = _extractYear(n2);
    if (n1Year != null && n2Year != null && (n1Year - n2Year).abs() < 20) {
      return ConnectionType.temporal;
    }

    // Check tag-based connection
    final sharedTags = _getSharedTags(n1, n2);
    if (sharedTags.isNotEmpty) {
      return ConnectionType.tagBased;
    }

    return ConnectionType.weakSimilarity;
  }

  /// Get shared tags between two narratives
  List<String> _getSharedTags(Narrative n1, Narrative n2) {
    final tags1 = n1.tags ?? [];
    final tags2 = n2.tags ?? [];
    
    return tags1.where((tag) => tags2.contains(tag)).toList();
  }

  /// Get shared keywords (extracted from titles and descriptions)
  List<String> _getSharedKeywords(Narrative n1, Narrative n2) {
    final keywords1 = _extractKeywords(n1);
    final keywords2 = _extractKeywords(n2);
    
    return keywords1.where((kw) => keywords2.contains(kw)).toList();
  }

  /// Extract keywords from narrative
  List<String> _extractKeywords(Narrative narrative) {
    final text = '${narrative.titel} ${narrative.zusammenfassung ?? ''}'.toLowerCase();
    
    // Remove common words and extract significant terms
    final words = text.split(RegExp(r'\W+'));
    final stopWords = {'der', 'die', 'das', 'und', 'oder', 'ein', 'eine', 'von', 'zu', 'im', 'in', 'auf', 'für', 'mit', 'ist', 'sind', 'war', 'wurden'};
    
    return words
        .where((word) => word.length > 3 && !stopWords.contains(word))
        .toSet()
        .toList();
  }

  /// Extract year from narrative (if mentioned)
  int? _extractYear(Narrative narrative) {
    final text = '${narrative.titel} ${narrative.zusammenfassung ?? ''}';
    final yearPattern = RegExp(r'\b(1[0-9]{3}|2[0-9]{3})\b');
    final match = yearPattern.firstMatch(text);
    
    if (match != null) {
      return int.tryParse(match.group(0)!);
    }
    
    return null;
  }

  /// Check if one narrative directly references another
  bool _hasDirectReference(Narrative n1, Narrative n2) {
    final n1Text = '${n1.titel} ${n1.zusammenfassung ?? ''}'.toLowerCase();
    final n2TitleWords = n2.titel.toLowerCase().split(' ');
    
    // Check if n2's title appears in n1's text
    for (final word in n2TitleWords) {
      if (word.length > 4 && n1Text.contains(word)) {
        return true;
      }
    }
    
    return false;
  }

  /// Get all narratives from storage
  Future<List<Narrative>> _getAllNarratives() async {
    try {
      // This is a placeholder - in production, this would fetch from your data source
      // For now, return empty list or mock data
      final narratives = <Narrative>[];
      
      // You can add mock narratives here for testing
      // or integrate with your actual data source
      
      if (kDebugMode) {
        debugPrint('📚 Loaded ${narratives.length} narratives');
      }
      
      return narratives;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to load narratives: $e');
      }
      return [];
    }
  }

  /// Get cached connections
  List<NarrativeConnection>? _getCachedConnections(String narrativeId) {
    if (_lastCacheUpdate == null || 
        DateTime.now().difference(_lastCacheUpdate!) > _cacheDuration) {
      _connectionsCache.clear();
      return null;
    }
    
    return _connectionsCache[narrativeId];
  }

  /// Cache connections
  void _cacheConnections(String narrativeId, List<NarrativeConnection> connections) {
    _connectionsCache[narrativeId] = connections;
    _lastCacheUpdate = DateTime.now();
  }

  /// Clear cache
  void clearCache() {
    _connectionsCache.clear();
    _lastCacheUpdate = null;
    
    if (kDebugMode) {
      debugPrint('🧹 NarrativeConnection cache cleared');
    }
  }

  /// Find narrative clusters (groups of highly connected narratives)
  Future<List<NarrativeCluster>> findNarrativeClusters({
    int minClusterSize = 3,
    double minSimilarity = 0.5,
  }) async {
    try {
      final allNarratives = await _getAllNarratives();
      final clusters = <NarrativeCluster>[];
      final processed = <String>{};
      
      for (final narrative in allNarratives) {
        if (processed.contains(narrative.id)) continue;
        
        // Find all connections for this narrative
        final connections = await findRelatedNarratives(
          narrative,
          limit: 20,
          minSimilarity: minSimilarity,
        );
        
        if (connections.length >= minClusterSize - 1) {
          final clusterNarratives = [narrative];
          clusterNarratives.addAll(connections.map((c) => c.targetNarrative));
          
          clusters.add(NarrativeCluster(
            id: 'cluster_${narrative.id}',
            narratives: clusterNarratives,
            averageSimilarity: connections.isEmpty 
                ? 0.0 
                : connections.map((c) => c.similarityScore).reduce((a, b) => a + b) / connections.length,
            commonTags: _findCommonTags(clusterNarratives),
          ));
          
          // Mark all cluster members as processed
          for (final n in clusterNarratives) {
            processed.add(n.id);
          }
        }
      }
      
      // Sort clusters by average similarity
      clusters.sort((a, b) => b.averageSimilarity.compareTo(a.averageSimilarity));
      
      if (kDebugMode) {
        debugPrint('🗂️ Found ${{clusters.length}} narrative clusters');
      }
      
      return clusters;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Cluster finding error: $e');
      }
      return [];
    }
  }

  /// Find common tags across multiple narratives
  List<String> _findCommonTags(List<Narrative> narratives) {
    if (narratives.isEmpty) return [];
    
    final tagCounts = <String, int>{};
    
    for (final narrative in narratives) {
      for (final tag in (narrative.tags ?? [])) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }
    
    // Return tags that appear in at least 50% of narratives
    final threshold = (narratives.length / 2).ceil();
    return tagCounts.entries
        .where((e) => e.value >= threshold)
        .map((e) => e.key)
        .toList();
  }
}

/// Narrative Connection Data Class
class NarrativeConnection {
  final String sourceId;
  final String targetId;
  final Narrative targetNarrative;
  final double similarityScore;
  final ConnectionType connectionType;
  final List<String> sharedTags;
  final List<String> sharedKeywords;

  NarrativeConnection({
    required this.sourceId,
    required this.targetId,
    required this.targetNarrative,
    required this.similarityScore,
    required this.connectionType,
    required this.sharedTags,
    required this.sharedKeywords,
  });

  /// Get similarity percentage (0-100)
  int get similarityPercent => (similarityScore * 100).round();

  /// Get connection strength label
  String get strengthLabel {
    if (similarityScore >= 0.8) return 'Sehr stark';
    if (similarityScore >= 0.6) return 'Stark';
    if (similarityScore >= 0.4) return 'Mittel';
    return 'Schwach';
  }

  @override
  String toString() {
    return 'NarrativeConnection(target: ${targetNarrative.titel}, similarity: $similarityPercent%, type: $connectionType)';
  }
}

/// Connection Type Enum
enum ConnectionType {
  directReference,    // One narrative directly mentions the other
  strongSimilarity,   // Very similar topics (>70%)
  sameTopic,          // Same category, similar content (>50%)
  temporal,           // Related by time period
  tagBased,           // Share multiple tags
  weakSimilarity,     // Some similarity (<40%)
}

/// Extension for ConnectionType labels
extension ConnectionTypeExtension on ConnectionType {
  String get label {
    switch (this) {
      case ConnectionType.directReference:
        return 'Direkter Bezug';
      case ConnectionType.strongSimilarity:
        return 'Sehr ähnlich';
      case ConnectionType.sameTopic:
        return 'Gleiches Thema';
      case ConnectionType.temporal:
        return 'Zeitliche Verbindung';
      case ConnectionType.tagBased:
        return 'Ähnliche Tags';
      case ConnectionType.weakSimilarity:
        return 'Verwandt';
    }
  }

  String get icon {
    switch (this) {
      case ConnectionType.directReference:
        return '🔗';
      case ConnectionType.strongSimilarity:
        return '⭐';
      case ConnectionType.sameTopic:
        return '📚';
      case ConnectionType.temporal:
        return '⏳';
      case ConnectionType.tagBased:
        return '🏷️';
      case ConnectionType.weakSimilarity:
        return '🔍';
    }
  }
}

/// Narrative Cluster Data Class
class NarrativeCluster {
  final String id;
  final List<Narrative> narratives;
  final double averageSimilarity;
  final List<String> commonTags;

  NarrativeCluster({
    required this.id,
    required this.narratives,
    required this.averageSimilarity,
    required this.commonTags,
  });

  int get size => narratives.length;

  @override
  String toString() {
    return 'NarrativeCluster(size: $size, avgSimilarity: ${(averageSimilarity * 100).toStringAsFixed(0)}%, tags: ${commonTags.join(", ")})';
  }
}
