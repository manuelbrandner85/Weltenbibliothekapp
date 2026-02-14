/// 🔍 RECHERCHE VIEW STATE
/// 
/// Production-ready state model for Recherche/Research functionality
/// 
/// Features:
/// - Immutable state management
/// - Type-safe state transitions
/// - Error handling support
/// - Progress tracking
/// - Copy-with pattern for updates
library;

import 'package:flutter/foundation.dart';

/// Recherche Mode (Research Type)
enum RechercheMode {
  /// Simple text-based research
  simple,
  
  /// Advanced research with filters
  advanced,
  
  /// Deep research with multiple sources
  deep,
  
  /// Conspiracy theory research
  conspiracy,
  
  /// Historical research
  historical,
  
  /// Scientific research
  scientific,
}

/// Extension for RechercheMode display names
extension RechercheModeName on RechercheMode {
  String get displayName {
    switch (this) {
      case RechercheMode.simple:
        return 'Einfache Recherche';
      case RechercheMode.advanced:
        return 'Erweiterte Recherche';
      case RechercheMode.deep:
        return 'Tiefenrecherche';
      case RechercheMode.conspiracy:
        return 'Verschwörungstheorie-Recherche';
      case RechercheMode.historical:
        return 'Historische Recherche';
      case RechercheMode.scientific:
        return 'Wissenschaftliche Recherche';
    }
  }
  
  String get icon {
    switch (this) {
      case RechercheMode.simple:
        return '🔍';
      case RechercheMode.advanced:
        return '🔬';
      case RechercheMode.deep:
        return '🕵️';
      case RechercheMode.conspiracy:
        return '🔺';
      case RechercheMode.historical:
        return '📜';
      case RechercheMode.scientific:
        return '⚗️';
    }
  }
}

/// Recherche Result Model (Enhanced)
class RechercheResult {
  final String query;
  final RechercheMode mode;
  final List<RechercheSource> sources;
  final String summary;
  final List<String> keyFindings;
  final List<String> facts;
  final List<RabbitLayer> rabbitLayers;
  final List<Perspective> perspectives;
  final double confidence;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  
  const RechercheResult({
    required this.query,
    required this.mode,
    required this.sources,
    required this.summary,
    required this.keyFindings,
    this.facts = const [],
    this.rabbitLayers = const [],
    this.perspectives = const [],
    required this.confidence,
    required this.metadata,
    required this.timestamp,
  });
  
  factory RechercheResult.fromJson(Map<String, dynamic> json) {
    return RechercheResult(
      query: json['query'] as String,
      mode: RechercheMode.values.firstWhere(
        (m) => m.name == json['mode'],
        orElse: () => RechercheMode.simple,
      ),
      sources: (json['sources'] as List<dynamic>?)
          ?.map((s) => RechercheSource.fromJson(s as Map<String, dynamic>))
          .toList() ?? [],
      summary: json['summary'] as String? ?? '',
      keyFindings: (json['key_findings'] as List<dynamic>?)
          ?.map((f) => f.toString())
          .toList() ?? [],
      facts: (json['facts'] as List<dynamic>?)
          ?.map((f) => f.toString())
          .toList() ?? [],
      rabbitLayers: (json['rabbit_layers'] as List<dynamic>?)
          ?.map((l) => RabbitLayer.fromJson(l as Map<String, dynamic>))
          .toList() ?? [],
      perspectives: (json['perspectives'] as List<dynamic>?)
          ?.map((p) => Perspective.fromJson(p as Map<String, dynamic>))
          .toList() ?? [],
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'mode': mode.name,
      'sources': sources.map((s) => s.toJson()).toList(),
      'summary': summary,
      'key_findings': keyFindings,
      'facts': facts,
      'rabbit_layers': rabbitLayers.map((l) => l.toJson()).toList(),
      'perspectives': perspectives.map((p) => p.toJson()).toList(),
      'confidence': confidence,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
    };
  }
  
  RechercheResult copyWith({
    String? query,
    RechercheMode? mode,
    List<RechercheSource>? sources,
    String? summary,
    List<String>? keyFindings,
    List<String>? facts,
    List<RabbitLayer>? rabbitLayers,
    List<Perspective>? perspectives,
    double? confidence,
    Map<String, dynamic>? metadata,
    DateTime? timestamp,
  }) {
    return RechercheResult(
      query: query ?? this.query,
      mode: mode ?? this.mode,
      sources: sources ?? this.sources,
      summary: summary ?? this.summary,
      keyFindings: keyFindings ?? this.keyFindings,
      facts: facts ?? this.facts,
      rabbitLayers: rabbitLayers ?? this.rabbitLayers,
      perspectives: perspectives ?? this.perspectives,
      confidence: confidence ?? this.confidence,
      metadata: metadata ?? this.metadata,
      timestamp: timestamp ?? this.timestamp,
    );
  }
  
  /// Get confidence percentage
  int get confidencePercent => (confidence * 100).round();
  
  /// Check if result has rabbit layers (deep research)
  bool get hasRabbitLayers => rabbitLayers.isNotEmpty;
  
  /// Check if result has multiple perspectives
  bool get hasPerspectives => perspectives.isNotEmpty;
  
  /// Get total source count across all layers
  int get totalSourceCount {
    int count = sources.length;
    for (final layer in rabbitLayers) {
      count += layer.sources.length;
    }
    return count;
  }
}

/// Recherche Source Model
class RechercheSource {
  final String title;
  final String url;
  final String excerpt;
  final double relevance;
  final String sourceType; // 'book', 'article', 'document', 'website'
  final DateTime? publishDate;
  
  const RechercheSource({
    required this.title,
    required this.url,
    required this.excerpt,
    required this.relevance,
    required this.sourceType,
    this.publishDate,
  });
  
  factory RechercheSource.fromJson(Map<String, dynamic> json) {
    return RechercheSource(
      title: json['title'] as String,
      url: json['url'] as String,
      excerpt: json['excerpt'] as String? ?? '',
      relevance: (json['relevance'] as num?)?.toDouble() ?? 0.0,
      sourceType: json['source_type'] as String? ?? 'unknown',
      publishDate: json['publish_date'] != null 
          ? DateTime.parse(json['publish_date'] as String)
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'excerpt': excerpt,
      'relevance': relevance,
      'source_type': sourceType,
      'publish_date': publishDate?.toIso8601String(),
    };
  }
}

/// Rabbit Layer Model (for Deep/Rabbit Hole research)
class RabbitLayer {
  final int layerNumber;
  final String layerName;
  final String description;
  final List<RechercheSource> sources;
  final List<String> connections;
  final double depth;
  
  const RabbitLayer({
    required this.layerNumber,
    required this.layerName,
    required this.description,
    required this.sources,
    this.connections = const [],
    required this.depth,
  });
  
  factory RabbitLayer.fromJson(Map<String, dynamic> json) {
    return RabbitLayer(
      layerNumber: json['layer_number'] as int,
      layerName: json['layer_name'] as String,
      description: json['description'] as String? ?? '',
      sources: (json['sources'] as List<dynamic>?)
          ?.map((s) => RechercheSource.fromJson(s as Map<String, dynamic>))
          .toList() ?? [],
      connections: (json['connections'] as List<dynamic>?)
          ?.map((c) => c.toString())
          .toList() ?? [],
      depth: (json['depth'] as num?)?.toDouble() ?? 0.0,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'layer_number': layerNumber,
      'layer_name': layerName,
      'description': description,
      'sources': sources.map((s) => s.toJson()).toList(),
      'connections': connections,
      'depth': depth,
    };
  }
  
  /// Get depth percentage (0-100)
  int get depthPercent => (depth * 100).round();
}

/// Perspective Model (for multi-perspective analysis)
class Perspective {
  final String perspectiveName;
  final String viewpoint;
  final List<String> arguments;
  final List<RechercheSource> supportingSources;
  final double credibility;
  final PerspectiveType type;
  
  const Perspective({
    required this.perspectiveName,
    required this.viewpoint,
    required this.arguments,
    this.supportingSources = const [],
    required this.credibility,
    this.type = PerspectiveType.neutral,
  });
  
  factory Perspective.fromJson(Map<String, dynamic> json) {
    return Perspective(
      perspectiveName: json['perspective_name'] as String,
      viewpoint: json['viewpoint'] as String,
      arguments: (json['arguments'] as List<dynamic>?)
          ?.map((a) => a.toString())
          .toList() ?? [],
      supportingSources: (json['supporting_sources'] as List<dynamic>?)
          ?.map((s) => RechercheSource.fromJson(s as Map<String, dynamic>))
          .toList() ?? [],
      credibility: (json['credibility'] as num?)?.toDouble() ?? 0.0,
      type: PerspectiveType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => PerspectiveType.neutral,
      ),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'perspective_name': perspectiveName,
      'viewpoint': viewpoint,
      'arguments': arguments,
      'supporting_sources': supportingSources.map((s) => s.toJson()).toList(),
      'credibility': credibility,
      'type': type.name,
    };
  }
  
  /// Get credibility percentage (0-100)
  int get credibilityPercent => (credibility * 100).round();
}

/// Perspective Type Enum
enum PerspectiveType {
  /// Supporting perspective
  supporting,
  
  /// Opposing perspective
  opposing,
  
  /// Neutral/balanced perspective
  neutral,
  
  /// Alternative perspective
  alternative,
  
  /// Controversial perspective
  controversial,
}

/// Extension for PerspectiveType display
extension PerspectiveTypeName on PerspectiveType {
  String get displayName {
    switch (this) {
      case PerspectiveType.supporting:
        return 'Unterstützend';
      case PerspectiveType.opposing:
        return 'Gegensätzlich';
      case PerspectiveType.neutral:
        return 'Neutral';
      case PerspectiveType.alternative:
        return 'Alternative Sichtweise';
      case PerspectiveType.controversial:
        return 'Kontrovers';
    }
  }
  
  String get icon {
    switch (this) {
      case PerspectiveType.supporting:
        return '✅';
      case PerspectiveType.opposing:
        return '❌';
      case PerspectiveType.neutral:
        return '⚖️';
      case PerspectiveType.alternative:
        return '🔄';
      case PerspectiveType.controversial:
        return '⚠️';
    }
  }
}

/// Recherche View State (Immutable)
@immutable
class RechercheViewState {
  final RechercheMode mode;
  final bool isLoading;
  final double progress;
  final RechercheResult? result;
  final String? error;
  final String? query;
  final DateTime? startedAt;
  final DateTime? completedAt;

  const RechercheViewState({
    required this.mode,
    this.isLoading = false,
    this.progress = 0.0,
    this.result,
    this.error,
    this.query,
    this.startedAt,
    this.completedAt,
  });
  
  /// Initial state factory
  factory RechercheViewState.initial() {
    return const RechercheViewState(
      mode: RechercheMode.simple,
      isLoading: false,
      progress: 0.0,
    );
  }
  
  /// Loading state factory
  factory RechercheViewState.loading({
    required RechercheMode mode,
    required String query,
    double progress = 0.0,
  }) {
    return RechercheViewState(
      mode: mode,
      isLoading: true,
      progress: progress,
      query: query,
      startedAt: DateTime.now(),
    );
  }
  
  /// Success state factory
  factory RechercheViewState.success({
    required RechercheMode mode,
    required RechercheResult result,
    required DateTime startedAt,
  }) {
    return RechercheViewState(
      mode: mode,
      isLoading: false,
      progress: 1.0,
      result: result,
      query: result.query,
      startedAt: startedAt,
      completedAt: DateTime.now(),
    );
  }
  
  /// Error state factory
  factory RechercheViewState.error({
    required RechercheMode mode,
    required String error,
    String? query,
    DateTime? startedAt,
  }) {
    return RechercheViewState(
      mode: mode,
      isLoading: false,
      progress: 0.0,
      error: error,
      query: query,
      startedAt: startedAt,
      completedAt: DateTime.now(),
    );
  }
  
  /// Copy-with pattern for immutable updates
  RechercheViewState copyWith({
    RechercheMode? mode,
    bool? isLoading,
    double? progress,
    RechercheResult? result,
    String? error,
    String? query,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return RechercheViewState(
      mode: mode ?? this.mode,
      isLoading: isLoading ?? this.isLoading,
      progress: progress ?? this.progress,
      result: result ?? this.result,
      error: error,
      query: query ?? this.query,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
  
  /// Check if state has result
  bool get hasResult => result != null;
  
  /// Check if state has error
  bool get hasError => error != null;
  
  /// Check if recherche is in progress
  bool get isInProgress => isLoading && startedAt != null;
  
  /// Get duration of recherche
  Duration? get duration {
    if (startedAt == null) return null;
    final endTime = completedAt ?? DateTime.now();
    return endTime.difference(startedAt!);
  }
  
  /// Get formatted duration string
  String? get formattedDuration {
    final d = duration;
    if (d == null) return null;
    
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    } else if (d.inMinutes > 0) {
      return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
    } else {
      return '${d.inSeconds}s';
    }
  }
  
  /// Get progress percentage as integer (0-100)
  int get progressPercent => (progress * 100).round();
  
  /// Check if recherche is complete
  bool get isComplete => !isLoading && hasResult && !hasError;
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is RechercheViewState &&
        other.mode == mode &&
        other.isLoading == isLoading &&
        other.progress == progress &&
        other.result == result &&
        other.error == error &&
        other.query == query &&
        other.startedAt == startedAt &&
        other.completedAt == completedAt;
  }
  
  @override
  int get hashCode {
    return Object.hash(
      mode,
      isLoading,
      progress,
      result,
      error,
      query,
      startedAt,
      completedAt,
    );
  }
  
  @override
  String toString() {
    return 'RechercheViewState('
        'mode: $mode, '
        'isLoading: $isLoading, '
        'progress: ${progressPercent}%, '
        'hasResult: $hasResult, '
        'hasError: $hasError, '
        'query: $query, '
        'duration: $formattedDuration'
        ')';
  }
}

// ============================================================================
// USAGE EXAMPLES
// ============================================================================

/// Example 1: Initial state
/// 
/// ```dart
/// final state = RechercheViewState.initial();
/// // mode: simple, isLoading: false, progress: 0.0
/// ```

/// Example 2: Loading state
/// 
/// ```dart
/// final state = RechercheViewState.loading(
///   mode: RechercheMode.conspiracy,
///   query: 'Area 51 secrets',
///   progress: 0.3,
/// );
/// ```

/// Example 3: Success state
/// 
/// ```dart
/// final result = RechercheResult(
///   query: 'Area 51',
///   mode: RechercheMode.conspiracy,
///   sources: [...],
///   summary: '...',
///   keyFindings: [...],
///   metadata: {},
///   timestamp: DateTime.now(),
/// );
/// 
/// final state = RechercheViewState.success(
///   mode: RechercheMode.conspiracy,
///   result: result,
///   startedAt: startTime,
/// );
/// ```

/// Example 4: Error state
/// 
/// ```dart
/// final state = RechercheViewState.error(
///   mode: RechercheMode.deep,
///   error: 'API rate limit exceeded',
///   query: 'Ancient civilizations',
///   startedAt: startTime,
/// );
/// ```

/// Example 5: Progress updates
/// 
/// ```dart
/// var state = RechercheViewState.loading(
///   mode: RechercheMode.scientific,
///   query: 'Quantum physics',
/// );
/// 
/// // Update progress
/// state = state.copyWith(progress: 0.5);
/// state = state.copyWith(progress: 0.75);
/// state = state.copyWith(progress: 1.0);
/// ```
