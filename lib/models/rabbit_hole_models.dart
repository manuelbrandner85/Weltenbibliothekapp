/// WELTENBIBLIOTHEK v5.13 – KANINCHENBAU-SYSTEM (RABBIT HOLE)
/// 
/// Automatische Vertiefung in Ebenen ohne manuelle Suche
/// 
/// EBENEN-LOGIK:
/// Ebene 1: Ereignis / Thema
/// Ebene 2: Beteiligte Akteure
/// Ebene 3: Organisationen & Netzwerke
/// Ebene 4: Geldflüsse & Interessen
/// Ebene 5: Historischer Kontext
/// Ebene 6: Metastrukturen & Narrative
library;

import 'package:flutter/material.dart';

/// Kaninchenbau-Ebene
enum RabbitHoleLevel {
  ereignis(1, 'Ereignis / Thema', Icons.event, Colors.blue),
  akteure(2, 'Beteiligte Akteure', Icons.people, Colors.green),
  organisationen(3, 'Organisationen & Netzwerke', Icons.account_tree, Colors.orange),
  geldfluss(4, 'Geldflüsse & Interessen', Icons.attach_money, Colors.red),
  kontext(5, 'Historischer Kontext', Icons.history, Colors.purple),
  metastruktur(6, 'Metastrukturen & Narrative', Icons.psychology, Colors.deepPurple);

  final int depth;
  final String label;
  final IconData icon;
  final Color color;

  const RabbitHoleLevel(this.depth, this.label, this.icon, this.color);

  /// Gibt nächste Ebene zurück
  RabbitHoleLevel? get next {
    if (depth >= 6) return null;
    return RabbitHoleLevel.values[depth]; // depth ist 1-based, array ist 0-based
  }

  /// Prüft ob Ebene erreicht werden kann
  bool canReach(int currentDepth) => depth <= currentDepth;
}

/// Status des Kaninchenbaus
enum RabbitHoleStatus {
  idle('Bereit', Colors.grey),
  exploring('Erkundet...', Colors.blue),
  completed('Abgeschlossen', Colors.green),
  error('Fehler', Colors.red);

  final String label;
  final Color color;

  const RabbitHoleStatus(this.label, this.color);
}

/// Einzelner Kaninchenbau-Knoten (Discovery)
class RabbitHoleNode {
  final RabbitHoleLevel level;
  final String title;
  final String content;
  final List<String> sources;
  final List<String> keyFindings;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;
  final int trustScore;
  final bool isFallback; // 🆕 Markiert KI-Fallback oder übersprungene Ebenen

  const RabbitHoleNode({
    required this.level,
    required this.title,
    required this.content,
    required this.sources,
    required this.keyFindings,
    this.metadata,
    required this.timestamp,
    required this.trustScore,
    this.isFallback = false, // 🆕 Default: keine Fallback-Daten
  });

  /// Factory: Aus JSON
  factory RabbitHoleNode.fromJson(Map<String, dynamic> json) {
    return RabbitHoleNode(
      level: RabbitHoleLevel.values.firstWhere(
        (l) => l.depth == json['level'],
        orElse: () => RabbitHoleLevel.ereignis,
      ),
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      sources: List<String>.from(json['sources'] ?? []),
      keyFindings: List<String>.from(json['key_findings'] ?? []),
      metadata: json['metadata'] as Map<String, dynamic>?,
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      trustScore: json['trust_score'] ?? 50,
      isFallback: json['is_fallback'] ?? false, // 🆕
    );
  }

  /// To JSON
  Map<String, dynamic> toJson() => {
    'level': level.depth,
    'title': title,
    'content': content,
    'sources': sources,
    'key_findings': keyFindings,
    'metadata': metadata,
    'timestamp': timestamp.toIso8601String(),
    'trust_score': trustScore,
    'is_fallback': isFallback, // 🆕
  };
}

/// Vollständiger Kaninchenbau (komplette Recherche)
class RabbitHoleAnalysis {
  final String topic;
  final List<RabbitHoleNode> nodes;
  final RabbitHoleStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  final int maxDepth;
  final String? errorMessage;

  const RabbitHoleAnalysis({
    required this.topic,
    required this.nodes,
    required this.status,
    required this.startTime,
    this.endTime,
    required this.maxDepth,
    this.errorMessage,
  });

  /// Gibt alle Knoten einer bestimmten Ebene zurück
  List<RabbitHoleNode> getNodesAtLevel(RabbitHoleLevel level) {
    return nodes.where((n) => n.level == level).toList();
  }

  /// Gibt aktuelle Tiefe zurück
  int get currentDepth {
    if (nodes.isEmpty) return 0;
    return nodes.map((n) => n.level.depth).reduce((a, b) => a > b ? a : b);
  }

  /// Prüft ob Kaninchenbau vollständig ist
  bool get isComplete => currentDepth >= maxDepth || status == RabbitHoleStatus.completed;

  /// Gibt Fortschritt zurück (0.0 - 1.0)
  double get progress => currentDepth / maxDepth;

  /// Gesamtanzahl Quellen
  int get totalSources => nodes.fold(0, (sum, node) => sum + node.sources.length);

  /// Durchschnittlicher Trust-Score
  double get averageTrustScore {
    if (nodes.isEmpty) return 0.0;
    return nodes.fold(0, (sum, node) => sum + node.trustScore) / nodes.length;
  }

  /// Dauer der Analyse
  Duration get duration {
    if (endTime == null) return DateTime.now().difference(startTime);
    return endTime!.difference(startTime);
  }

  /// Factory: Aus JSON
  factory RabbitHoleAnalysis.fromJson(Map<String, dynamic> json) {
    return RabbitHoleAnalysis(
      topic: json['topic'] ?? '',
      nodes: (json['nodes'] as List<dynamic>?)
          ?.map((n) => RabbitHoleNode.fromJson(n as Map<String, dynamic>))
          .toList() ?? [],
      status: RabbitHoleStatus.values.firstWhere(
        (s) => s.label == json['status'],
        orElse: () => RabbitHoleStatus.idle,
      ),
      startTime: DateTime.parse(json['start_time'] ?? DateTime.now().toIso8601String()),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      maxDepth: json['max_depth'] ?? 6,
      errorMessage: json['error_message'],
    );
  }

  /// To JSON
  Map<String, dynamic> toJson() => {
    'topic': topic,
    'nodes': nodes.map((n) => n.toJson()).toList(),
    'status': status.label,
    'start_time': startTime.toIso8601String(),
    'end_time': endTime?.toIso8601String(),
    'max_depth': maxDepth,
    'error_message': errorMessage,
  };
}

/// Kaninchenbau-Konfiguration
class RabbitHoleConfig {
  final int maxDepth;
  final bool autoProgress;
  final Duration delayBetweenLevels;
  final List<RabbitHoleLevel> enabledLevels;

  const RabbitHoleConfig({
    this.maxDepth = 6,
    this.autoProgress = true,
    this.delayBetweenLevels = const Duration(seconds: 2),
    this.enabledLevels = const [
      RabbitHoleLevel.ereignis,
      RabbitHoleLevel.akteure,
      RabbitHoleLevel.organisationen,
      RabbitHoleLevel.geldfluss,
      RabbitHoleLevel.kontext,
      RabbitHoleLevel.metastruktur,
    ],
  });

  /// Standard-Konfiguration
  static const standard = RabbitHoleConfig();

  /// Schnelle Konfiguration (nur 4 Ebenen)
  static const quick = RabbitHoleConfig(
    maxDepth: 4,
    enabledLevels: [
      RabbitHoleLevel.ereignis,
      RabbitHoleLevel.akteure,
      RabbitHoleLevel.organisationen,
      RabbitHoleLevel.geldfluss,
    ],
  );

  /// Tiefe Konfiguration (alle 6 Ebenen)
  static const deep = RabbitHoleConfig(
    maxDepth: 6,
    delayBetweenLevels: Duration(seconds: 3),
  );
}

/// Kaninchenbau-Event (für UI-Updates)
abstract class RabbitHoleEvent {
  final DateTime timestamp = DateTime.now();
}

class RabbitHoleStarted extends RabbitHoleEvent {
  final String topic;
  RabbitHoleStarted(this.topic);
}

class RabbitHoleLevelCompleted extends RabbitHoleEvent {
  final RabbitHoleLevel level;
  final RabbitHoleNode node;
  RabbitHoleLevelCompleted(this.level, this.node);
}

class RabbitHoleCompleted extends RabbitHoleEvent {
  final RabbitHoleAnalysis analysis;
  RabbitHoleCompleted(this.analysis);
}

class RabbitHoleError extends RabbitHoleEvent {
  final String message;
  final RabbitHoleLevel? level;
  RabbitHoleError(this.message, [this.level]);
}
