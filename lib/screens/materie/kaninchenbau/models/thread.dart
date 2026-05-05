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

/// Schlüsselperson mit Rolle + optionalem Bild (Wikidata SPARQL).
class KeyPerson {
  final String id;
  final String name;
  final String description;
  final String role;
  final String? imageUrl;
  const KeyPerson({
    required this.id,
    required this.name,
    required this.description,
    required this.role,
    this.imageUrl,
  });
}

/// EU-Lobbying-Eintrag (LobbyFacts.eu).
class LobbyEntry {
  final String name;
  final String country;
  final String category;
  final num? budget; // EUR pro Jahr
  final int? fullTimeStaff;
  final int? lobbyists;
  final int? meetings;
  final String url;
  const LobbyEntry({
    required this.name,
    required this.country,
    required this.category,
    required this.url,
    this.budget,
    this.fullTimeStaff,
    this.lobbyists,
    this.meetings,
  });
}

/// DE Politiker-Eintrag (abgeordnetenwatch.de).
class Abgeordneter {
  final int? id;
  final String name;
  final String party;
  final int? birthYear;
  final String? profession;
  final String? url;
  const Abgeordneter({
    required this.name,
    required this.party,
    this.id,
    this.birthYear,
    this.profession,
    this.url,
  });
}

/// Skandal/Kontroverse aus GDELT (negativer Tonfall).
class Skandal {
  final String title;
  final String url;
  final String domain;
  final String date;
  final double tone;
  const Skandal({
    required this.title,
    required this.url,
    required this.domain,
    required this.date,
    required this.tone,
  });
}

/// Bündelt Knoten + echte Beziehungs-Kanten eines Wikidata-Sub-Graphen.
class NetworkGraph {
  final List<NetworkNode> nodes;
  final List<NetworkEdge> edges;
  const NetworkGraph({required this.nodes, required this.edges});
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


// ─── RSS-Aggregator-Item ───────────────────────────────────────────────────────

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

// ═══════════════════════════════════════════════════════════════════════════
// MINDBLOW-TIER — 18 Tiefenquellen
// ═══════════════════════════════════════════════════════════════════════════

class UsaSpendingAward {
  final String recipientName;
  final num awardAmount;
  final String awardType;
  final String description;
  final String piid;
  final String agency;
  final String url;
  const UsaSpendingAward({
    required this.recipientName,
    required this.awardAmount,
    required this.awardType,
    required this.description,
    required this.piid,
    required this.agency,
    required this.url,
  });
  factory UsaSpendingAward.fromJson(Map<String, dynamic> j) => UsaSpendingAward(
        recipientName: (j['recipientName'] ?? '').toString(),
        awardAmount: (j['awardAmount'] is num) ? j['awardAmount'] as num : 0,
        awardType: (j['awardType'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
        piid: (j['piid'] ?? '').toString(),
        agency: (j['agency'] ?? '').toString(),
        url: (j['url'] ?? '').toString(),
      );
}

class WorldBankProject {
  final String id;
  final String name;
  final String country;
  final String approved;
  final String status;
  final num amount;
  final String sector;
  final String url;
  const WorldBankProject({
    required this.id,
    required this.name,
    required this.country,
    required this.approved,
    required this.status,
    required this.amount,
    required this.sector,
    required this.url,
  });
  factory WorldBankProject.fromJson(Map<String, dynamic> j) => WorldBankProject(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        country: (j['country'] ?? '').toString(),
        approved: (j['approved'] ?? '').toString(),
        status: (j['status'] ?? '').toString(),
        amount: (j['amount'] is num) ? j['amount'] as num : 0,
        sector: (j['sector'] ?? '').toString(),
        url: (j['url'] ?? '').toString(),
      );
}

class OpenOwnershipEntity {
  final String name;
  final String jurisdiction;
  final String type;
  final String controlChain;
  final String url;
  const OpenOwnershipEntity({
    required this.name,
    required this.jurisdiction,
    required this.type,
    required this.controlChain,
    required this.url,
  });
  factory OpenOwnershipEntity.fromJson(Map<String, dynamic> j) => OpenOwnershipEntity(
        name: (j['name'] ?? '').toString(),
        jurisdiction: (j['jurisdiction'] ?? '').toString(),
        type: (j['type'] ?? '').toString(),
        controlChain: (j['controlChain'] ?? '').toString(),
        url: (j['url'] ?? '').toString(),
      );
}

class OpenSpendingEntry {
  final String title;
  final String country;
  final String year;
  final num amount;
  final String currency;
  final String source;
  final String url;
  const OpenSpendingEntry({
    required this.title,
    required this.country,
    required this.year,
    required this.amount,
    required this.currency,
    required this.source,
    required this.url,
  });
  factory OpenSpendingEntry.fromJson(Map<String, dynamic> j) => OpenSpendingEntry(
        title: (j['title'] ?? '').toString(),
        country: (j['country'] ?? '').toString(),
        year: (j['year'] ?? '').toString(),
        amount: (j['amount'] is num) ? j['amount'] as num : 0,
        currency: (j['currency'] ?? '').toString(),
        source: (j['source'] ?? '').toString(),
        url: (j['url'] ?? '').toString(),
      );
}

class CourtListenerCase {
  final String caseName;
  final String court;
  final String dateFiled;
  final String citation;
  final String snippet;
  final String status;
  final String url;
  const CourtListenerCase({
    required this.caseName,
    required this.court,
    required this.dateFiled,
    required this.citation,
    required this.snippet,
    required this.status,
    required this.url,
  });
  factory CourtListenerCase.fromJson(Map<String, dynamic> j) => CourtListenerCase(
        caseName: (j['caseName'] ?? '').toString(),
        court: (j['court'] ?? '').toString(),
        dateFiled: (j['dateFiled'] ?? '').toString(),
        citation: (j['citation'] ?? '').toString(),
        snippet: (j['snippet'] ?? '').toString(),
        status: (j['status'] ?? '').toString(),
        url: (j['url'] ?? '').toString(),
      );
}

class MuckRockFoia {
  final String title;
  final String agency;
  final String status;
  final String dateRequested;
  final String datePromised;
  final bool hasDocuments;
  final String url;
  const MuckRockFoia({
    required this.title,
    required this.agency,
    required this.status,
    required this.dateRequested,
    required this.datePromised,
    required this.hasDocuments,
    required this.url,
  });
  factory MuckRockFoia.fromJson(Map<String, dynamic> j) => MuckRockFoia(
        title: (j['title'] ?? '').toString(),
        agency: (j['agency'] ?? '').toString(),
        status: (j['status'] ?? '').toString(),
        dateRequested: (j['dateRequested'] ?? '').toString(),
        datePromised: (j['datePromised'] ?? '').toString(),
        hasDocuments: j['hasDocuments'] == true,
        url: (j['url'] ?? '').toString(),
      );
}

class HudocCase {
  final String title;
  final String country;
  final String date;
  final String docId;
  final String url;
  const HudocCase({
    required this.title,
    required this.country,
    required this.date,
    required this.docId,
    required this.url,
  });
  factory HudocCase.fromJson(Map<String, dynamic> j) => HudocCase(
        title: (j['title'] ?? '').toString(),
        country: (j['country'] ?? '').toString(),
        date: (j['date'] ?? '').toString(),
        docId: (j['docId'] ?? '').toString(),
        url: (j['url'] ?? '').toString(),
      );
}

class EuCuriaCase {
  final String title;
  final String author;
  final String journal;
  final String year;
  final String doi;
  final String url;
  const EuCuriaCase({
    required this.title,
    required this.author,
    required this.journal,
    required this.year,
    required this.doi,
    required this.url,
  });
  factory EuCuriaCase.fromJson(Map<String, dynamic> j) => EuCuriaCase(
        title: (j['title'] ?? '').toString(),
        author: (j['author'] ?? '').toString(),
        journal: (j['journal'] ?? '').toString(),
        year: (j['year'] ?? '').toString(),
        doi: (j['doi'] ?? '').toString(),
        url: (j['url'] ?? '').toString(),
      );
}

class OpenSecretsOrg {
  final String orgname;
  final String orgid;
  final String url;
  const OpenSecretsOrg({
    required this.orgname,
    required this.orgid,
    required this.url,
  });
  factory OpenSecretsOrg.fromJson(Map<String, dynamic> j) => OpenSecretsOrg(
        orgname: (j['orgname'] ?? '').toString(),
        orgid: (j['orgid'] ?? '').toString(),
        url: (j['url'] ?? '').toString(),
      );
}

class FecCandidate {
  final String name;
  final String party;
  final String office;
  final String state;
  final String district;
  final String candidateId;
  final String url;
  const FecCandidate({
    required this.name,
    required this.party,
    required this.office,
    required this.state,
    required this.district,
    required this.candidateId,
    required this.url,
  });
  factory FecCandidate.fromJson(Map<String, dynamic> j) => FecCandidate(
        name: (j['name'] ?? '').toString(),
        party: (j['party'] ?? '').toString(),
        office: (j['office'] ?? '').toString(),
        state: (j['state'] ?? '').toString(),
        district: (j['district'] ?? '').toString(),
        candidateId: (j['candidateId'] ?? '').toString(),
        url: (j['url'] ?? '').toString(),
      );
}

class LittleSisEntity {
  final String name;
  final String type;
  final String summary;
  final String url;
  const LittleSisEntity({
    required this.name,
    required this.type,
    required this.summary,
    required this.url,
  });
  factory LittleSisEntity.fromJson(Map<String, dynamic> j) => LittleSisEntity(
        name: (j['name'] ?? '').toString(),
        type: (j['type'] ?? '').toString(),
        summary: (j['summary'] ?? '').toString(),
        url: (j['url'] ?? '').toString(),
      );
}

class EveryPolitician {
  final String name;
  final String country;
  final String party;
  final String position;
  final String url;
  const EveryPolitician({
    required this.name,
    required this.country,
    required this.party,
    required this.position,
    required this.url,
  });
  factory EveryPolitician.fromJson(Map<String, dynamic> j) => EveryPolitician(
        name: (j['name'] ?? '').toString(),
        country: (j['country'] ?? '').toString(),
        party: (j['party'] ?? '').toString(),
        position: (j['position'] ?? '').toString(),
        url: (j['url'] ?? '').toString(),
      );
}

class DocumentCloudDoc {
  final String title;
  final String source;
  final String organization;
  final int pageCount;
  final String language;
  final String dateUploaded;
  final String url;
  final String pdf;
  const DocumentCloudDoc({
    required this.title,
    required this.source,
    required this.organization,
    required this.pageCount,
    required this.language,
    required this.dateUploaded,
    required this.url,
    required this.pdf,
  });
  factory DocumentCloudDoc.fromJson(Map<String, dynamic> j) => DocumentCloudDoc(
        title: (j['title'] ?? '').toString(),
        source: (j['source'] ?? '').toString(),
        organization: (j['organization'] ?? '').toString(),
        pageCount: (j['pageCount'] is int)
            ? j['pageCount'] as int
            : int.tryParse((j['pageCount'] ?? '0').toString()) ?? 0,
        language: (j['language'] ?? '').toString(),
        dateUploaded: (j['dateUploaded'] ?? '').toString(),
        url: (j['url'] ?? '').toString(),
        pdf: (j['pdf'] ?? '').toString(),
      );
}

class WikiLeaksDoc {
  final String title;
  final String date;
  final String description;
  final String url;
  const WikiLeaksDoc({
    required this.title,
    required this.date,
    required this.description,
    required this.url,
  });
  factory WikiLeaksDoc.fromJson(Map<String, dynamic> j) => WikiLeaksDoc(
        title: (j['title'] ?? '').toString(),
        date: (j['date'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
        url: (j['url'] ?? '').toString(),
      );
}

class CiaCrestDoc {
  final String title;
  final String date;
  final String description;
  final String url;
  const CiaCrestDoc({
    required this.title,
    required this.date,
    required this.description,
    required this.url,
  });
  factory CiaCrestDoc.fromJson(Map<String, dynamic> j) => CiaCrestDoc(
        title: (j['title'] ?? '').toString(),
        date: (j['date'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
        url: (j['url'] ?? '').toString(),
      );
}

class SnowdenDoc {
  final String title;
  final String date;
  final String description;
  final String url;
  const SnowdenDoc({
    required this.title,
    required this.date,
    required this.description,
    required this.url,
  });
  factory SnowdenDoc.fromJson(Map<String, dynamic> j) => SnowdenDoc(
        title: (j['title'] ?? '').toString(),
        date: (j['date'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
        url: (j['url'] ?? '').toString(),
      );
}

class OcNetworkOfficer {
  final String companyName;
  final String officerName;
  final String position;
  final String startDate;
  final String endDate;
  final List<String> otherCompanies;
  final String url;
  const OcNetworkOfficer({
    required this.companyName,
    required this.officerName,
    required this.position,
    required this.startDate,
    required this.endDate,
    required this.otherCompanies,
    required this.url,
  });
  factory OcNetworkOfficer.fromJson(Map<String, dynamic> j) => OcNetworkOfficer(
        companyName: (j['companyName'] ?? '').toString(),
        officerName: (j['officerName'] ?? '').toString(),
        position: (j['position'] ?? '').toString(),
        startDate: (j['startDate'] ?? '').toString(),
        endDate: (j['endDate'] ?? '').toString(),
        otherCompanies: ((j['otherCompanies'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        url: (j['url'] ?? '').toString(),
      );
}

class CorpWatchArticle {
  final String title;
  final String domain;
  final String date;
  final double tone;
  final String url;
  const CorpWatchArticle({
    required this.title,
    required this.domain,
    required this.date,
    required this.tone,
    required this.url,
  });
  factory CorpWatchArticle.fromJson(Map<String, dynamic> j) => CorpWatchArticle(
        title: (j['title'] ?? '').toString(),
        domain: (j['domain'] ?? '').toString(),
        date: (j['date'] ?? '').toString(),
        tone: (j['tone'] is num)
            ? (j['tone'] as num).toDouble()
            : double.tryParse((j['tone'] ?? '0').toString()) ?? 0.0,
        url: (j['url'] ?? '').toString(),
      );
}
