/// Datenmodelle für Kaninchenbau-Recherche-Faden.
library;

import 'package:flutter/material.dart';

enum CardKind {
  identity,
  network,
  money,
  sources,
  timeline,
  aiInsight,
  related,
}

/// Eine einzelne Karte im Faden.
class ThreadCard {
  final CardKind kind;
  final String title;
  final IconData icon;
  final Color accent;
  final Map<String, dynamic> data;
  final bool loading;
  final String? error;

  const ThreadCard({
    required this.kind,
    required this.title,
    required this.icon,
    required this.accent,
    this.data = const {},
    this.loading = false,
    this.error,
  });

  ThreadCard copyWith({
    Map<String, dynamic>? data,
    bool? loading,
    String? error,
  }) =>
      ThreadCard(
        kind: kind,
        title: title,
        icon: icon,
        accent: accent,
        data: data ?? this.data,
        loading: loading ?? this.loading,
        error: error,
      );
}

/// Ein vollständiger Faden — ein Thema mit allen Karten.
class RabbitThread {
  final String topic;
  final DateTime createdAt;
  final List<ThreadCard> cards;
  final String? aiInsight;

  const RabbitThread({
    required this.topic,
    required this.createdAt,
    required this.cards,
    this.aiInsight,
  });

  RabbitThread copyWithCards(List<ThreadCard> next, {String? aiInsight}) =>
      RabbitThread(
        topic: topic,
        createdAt: createdAt,
        cards: next,
        aiInsight: aiInsight ?? this.aiInsight,
      );
}

/// Knoten im Netzwerk-Graph.
class NetworkNode {
  final String id;
  final String label;
  final String type; // person | company | org | concept
  final double weight; // 0..1 für Knotengröße
  const NetworkNode({
    required this.id,
    required this.label,
    required this.type,
    this.weight = 0.5,
  });
}

/// Verbindung zwischen zwei Knoten.
class NetworkEdge {
  final String fromId;
  final String toId;
  final String label;
  final double strength; // 0..1
  const NetworkEdge({
    required this.fromId,
    required this.toId,
    required this.label,
    this.strength = 0.5,
  });
}

/// Zeitstrahl-Eintrag.
class TimelineEntry {
  final int year;
  final String title;
  final String? sourceUrl;
  const TimelineEntry({
    required this.year,
    required this.title,
    this.sourceUrl,
  });
}

/// Quelle mit Glaubwürdigkeits-Score.
class SourceItem {
  final String title;
  final String url;
  final String snippet;
  final SourceLens lens; // official | critical | neutral
  final int credibility; // 0..100
  const SourceItem({
    required this.title,
    required this.url,
    required this.snippet,
    required this.lens,
    this.credibility = 70,
  });
}

enum SourceLens { official, critical, neutral }

/// Geldfluss-Eintrag.
class MoneyFlow {
  final String from;
  final String to;
  final double amountUsd;
  final String? purpose;
  final int? year;
  const MoneyFlow({
    required this.from,
    required this.to,
    required this.amountUsd,
    this.purpose,
    this.year,
  });
}

/// Ein geleaktes/FOIA Dokument.
class LeakedDocument {
  final String title;
  final String url;
  final String? snippet;
  final String archive; // 'WikiLeaks', 'Internet Archive', 'FOIA', 'CIA Reading Room'
  final String? date;
  const LeakedDocument({
    required this.title,
    required this.url,
    required this.archive,
    this.snippet,
    this.date,
  });
}

/// Region mit Sentiment-Score für globale Heatmap.
class GlobalImpact {
  final String country; // ISO-Code z.B. 'US', 'DE', 'CN'
  final String name;
  final int mentions;
  final double sentiment; // -1.0 (negativ) bis +1.0 (positiv)
  const GlobalImpact({
    required this.country,
    required this.name,
    required this.mentions,
    required this.sentiment,
  });
}

/// Position einer Quelle auf dem Medien-Kompass (links/rechts × Establishment/Alt).
class MediaCompassPoint {
  final String name;
  final double xAxis; // -1 (links) bis +1 (rechts)
  final double yAxis; // -1 (alternativ) bis +1 (Establishment)
  final int credibility; // 0..100
  const MediaCompassPoint({
    required this.name,
    required this.xAxis,
    required this.yAxis,
    required this.credibility,
  });
}

/// Wissenschaftliches Paper aus OpenAlex/Semantic Scholar.
class AcademicPaper {
  final String title;
  final String? doi;
  final String? abstractText;
  final List<String> authors;
  final int? year;
  final int citations;
  final String? url;
  final String source; // 'OpenAlex' | 'SemanticScholar'
  const AcademicPaper({
    required this.title,
    required this.authors,
    required this.citations,
    required this.source,
    this.doi,
    this.abstractText,
    this.year,
    this.url,
  });
}

/// Sanktions-Eintrag (OpenSanctions).
class SanctionEntry {
  final String name;
  final String? type; // Person, Organization, Vessel
  final List<String> sanctioningAuthorities; // ['OFAC', 'EU', 'UK', 'UN']
  final String? country;
  final String? reason;
  final String? url;
  const SanctionEntry({
    required this.name,
    required this.sanctioningAuthorities,
    this.type,
    this.country,
    this.reason,
    this.url,
  });
}

/// Aktien-/Eigentums-Beteiligung (SEC EDGAR / OpenCorporates).
class Shareholding {
  final String holder;
  final String company;
  final double? sharePercent;
  final double? valueUsd;
  final String? source; // 'SEC EDGAR' | 'OpenCorporates'
  final String? url;
  const Shareholding({
    required this.holder,
    required this.company,
    this.sharePercent,
    this.valueUsd,
    this.source,
    this.url,
  });
}

/// Power-Broker-Beziehung (LittleSis).
class PowerRelation {
  final String entity1;
  final String entity2;
  final String relationType; // 'donation', 'board', 'family', 'employment', 'ownership'
  final String description;
  final int? amount; // bei donations in USD
  final String? url;
  const PowerRelation({
    required this.entity1,
    required this.entity2,
    required this.relationType,
    required this.description,
    this.amount,
    this.url,
  });
}

/// Wayback-Snapshot.
class WaybackSnapshot {
  final String url;
  final String archiveUrl;
  final String timestamp; // YYYYMMDDHHMMSS
  final int statusCode;
  final String? title;
  const WaybackSnapshot({
    required this.url,
    required this.archiveUrl,
    required this.timestamp,
    required this.statusCode,
    this.title,
  });

  DateTime get date {
    if (timestamp.length < 8) return DateTime.now();
    final y = int.tryParse(timestamp.substring(0, 4)) ?? 2000;
    final m = int.tryParse(timestamp.substring(4, 6)) ?? 1;
    final d = int.tryParse(timestamp.substring(6, 8)) ?? 1;
    return DateTime(y, m, d);
  }
}

/// Gerichtsfall (CourtListener).
class CourtCase {
  final String caseName;
  final String court; // 'US Supreme Court', 'SDNY', etc.
  final String? snippet;
  final String? date;
  final String? url;
  const CourtCase({
    required this.caseName,
    required this.court,
    this.snippet,
    this.date,
    this.url,
  });
}

/// Fact-Check-Eintrag (Google Fact Check Tools API).
class FactCheck {
  final String claim;
  final String? claimant;
  final String verdict; // 'True', 'False', 'Mostly false', etc.
  final String publisher;
  final String? url;
  final String? date;
  const FactCheck({
    required this.claim,
    required this.verdict,
    required this.publisher,
    this.claimant,
    this.url,
    this.date,
  });
}

/// Sherlock-Treffer: Username auf einer Plattform.
class SherlockHit {
  final String platform;
  final String url;
  final bool found;
  final int statusCode;
  const SherlockHit({
    required this.platform,
    required this.url,
    required this.found,
    required this.statusCode,
  });
}

/// RSS-Aggregator-Item.
class RssItem {
  final String title;
  final String url;
  final String source;
  final String lens;
  final String? date;
  const RssItem({
    required this.title,
    required this.url,
    required this.source,
    required this.lens,
    this.date,
  });
}
