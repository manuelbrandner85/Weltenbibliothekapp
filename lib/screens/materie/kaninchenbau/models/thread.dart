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
