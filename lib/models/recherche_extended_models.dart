/// Erweiterte Recherche-Models für V16.0 Engine
/// Beinhaltet: Machtanalyse, Netzwerk, Timeline, Narrativ-Vergleich, Meta-System
library;

/// Machtanalyse Model
class Machtanalyse {
  final List<Akteur> akteure;
  final List<Mechanismus> mechanismen;
  final List<String> profiteure;
  final String zusammenfassung;

  Machtanalyse({
    required this.akteure,
    required this.mechanismen,
    required this.profiteure,
    required this.zusammenfassung,
  });

  factory Machtanalyse.fromJson(Map<String, dynamic> json) {
    return Machtanalyse(
      akteure: (json['akteure'] as List?)
              ?.map((a) => Akteur.fromJson(a))
              .toList() ??
          [],
      mechanismen: (json['mechanismen'] as List?)
              ?.map((m) => Mechanismus.fromJson(m))
              .toList() ??
          [],
      profiteure: (json['profiteure'] as List?)?.cast<String>() ?? [],
      zusammenfassung: json['zusammenfassung'] ?? '',
    );
  }
}

class Akteur {
  final String name;
  final String typ; // "Konzern", "Organisation", "Regierung", "Person"
  final String rolle;
  final String einfluss;

  Akteur({
    required this.name,
    required this.typ,
    required this.rolle,
    required this.einfluss,
  });

  factory Akteur.fromJson(Map<String, dynamic> json) {
    return Akteur(
      name: json['name'] ?? '',
      typ: json['typ'] ?? 'Organisation',
      rolle: json['rolle'] ?? '',
      einfluss: json['einfluss'] ?? '',
    );
  }
}

class Mechanismus {
  final String name;
  final String beschreibung;
  final String beispiel;

  Mechanismus({
    required this.name,
    required this.beschreibung,
    required this.beispiel,
  });

  factory Mechanismus.fromJson(Map<String, dynamic> json) {
    return Mechanismus(
      name: json['name'] ?? '',
      beschreibung: json['beschreibung'] ?? '',
      beispiel: json['beispiel'] ?? '',
    );
  }
}

/// Netzwerk-Analyse Model
class NetzwerkAnalyse {
  final List<NetzwerkNode> nodes;
  final List<NetzwerkEdge> edges;
  final Map<String, int> zentrale_akteure;

  NetzwerkAnalyse({
    required this.nodes,
    required this.edges,
    required this.zentrale_akteure,
  });

  factory NetzwerkAnalyse.fromJson(Map<String, dynamic> json) {
    return NetzwerkAnalyse(
      nodes: (json['nodes'] as List?)
              ?.map((n) => NetzwerkNode.fromJson(n))
              .toList() ??
          [],
      edges: (json['edges'] as List?)
              ?.map((e) => NetzwerkEdge.fromJson(e))
              .toList() ??
          [],
      zentrale_akteure: Map<String, int>.from(json['zentrale_akteure'] ?? {}),
    );
  }
}

class NetzwerkNode {
  final String id;
  final String label;
  final String type; // "person", "org", "event", "document"

  NetzwerkNode({
    required this.id,
    required this.label,
    required this.type,
  });

  factory NetzwerkNode.fromJson(Map<String, dynamic> json) {
    return NetzwerkNode(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
      type: json['type'] ?? 'org',
    );
  }
}

class NetzwerkEdge {
  final String source;
  final String target;
  final String relation;
  final int weight;

  NetzwerkEdge({
    required this.source,
    required this.target,
    required this.relation,
    this.weight = 1,
  });

  factory NetzwerkEdge.fromJson(Map<String, dynamic> json) {
    return NetzwerkEdge(
      source: json['source'] ?? '',
      target: json['target'] ?? '',
      relation: json['relation'] ?? 'verbunden',
      weight: json['weight'] ?? 1,
    );
  }
}

/// Timeline Model
class TimelineAnalyse {
  final List<TimelineEvent> events;

  TimelineAnalyse({
    required this.events,
  });

  factory TimelineAnalyse.fromJson(dynamic json) {
    // Timeline kann entweder ein Array oder ein Objekt mit events sein
    if (json is List) {
      return TimelineAnalyse(
        events: json.map((e) => TimelineEvent.fromJson(e)).toList(),
      );
    } else if (json is Map<String, dynamic>) {
      return TimelineAnalyse(
        events: (json['events'] as List?)
                ?.map((e) => TimelineEvent.fromJson(e))
                .toList() ??
            [],
      );
    }
    return TimelineAnalyse(events: []);
  }
}

class TimelineEvent {
  final String datum;
  final String ereignis;
  final String bedeutung;

  TimelineEvent({
    required this.datum,
    required this.ereignis,
    required this.bedeutung,
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      datum: json['jahr'] ?? json['datum'] ?? '',
      ereignis: json['ereignis'] ?? '',
      bedeutung: json['einordnung'] ?? json['bedeutung'] ?? '',
    );
  }
}

/// Narrativ-Vergleich Model
class NarrativVergleich {
  final String mainstream;
  final String alternative;
  final dynamic zentrale_unterschiede; // Kann String oder List sein

  NarrativVergleich({
    required this.mainstream,
    required this.alternative,
    required this.zentrale_unterschiede,
  });

  factory NarrativVergleich.fromJson(Map<String, dynamic> json) {
    return NarrativVergleich(
      mainstream: json['mainstream'] ?? '',
      alternative: json['alternative'] ?? '',
      zentrale_unterschiede: json['zentrale_unterschiede'] ?? [],
    );
  }

  List<String> get unterschiedeList {
    if (zentrale_unterschiede is List) {
      return (zentrale_unterschiede as List).cast<String>();
    } else if (zentrale_unterschiede is String) {
      return [zentrale_unterschiede as String];
    }
    return [];
  }
}

/// Meta-Systemanalyse Model
class MetaSystemanalyse {
  final List<SystemEbene> systeme;
  final List<String> querverbindungen;
  final String gesamteinschaetzung;

  MetaSystemanalyse({
    required this.systeme,
    required this.querverbindungen,
    required this.gesamteinschaetzung,
  });

  factory MetaSystemanalyse.fromJson(Map<String, dynamic> json) {
    return MetaSystemanalyse(
      systeme: (json['systeme'] as List?)
              ?.map((s) => SystemEbene.fromJson(s))
              .toList() ??
          [],
      querverbindungen:
          (json['querverbindungen'] as List?)?.cast<String>() ?? [],
      gesamteinschaetzung: json['gesamteinschaetzung'] ?? '',
    );
  }
}

class SystemEbene {
  final String name; // "Medien", "Politik", "Wirtschaft", "Ideologie", "Technologie"
  final List<String> mechanismen;
  final List<String> akteure;
  final String einfluss;

  SystemEbene({
    required this.name,
    required this.mechanismen,
    required this.akteure,
    required this.einfluss,
  });

  factory SystemEbene.fromJson(Map<String, dynamic> json) {
    return SystemEbene(
      name: json['name'] ?? '',
      mechanismen: (json['mechanismen'] as List?)?.cast<String>() ?? [],
      akteure: (json['akteure'] as List?)?.cast<String>() ?? [],
      einfluss: json['einfluss'] ?? '',
    );
  }
}

/// Nutzer-Display Model (V16.0 Format)
class NutzerDisplay {
  final String titel;
  final String einordnung;
  final List<String> gefundeneFakten;
  final String alternativeSichtweise;
  final List<String> machtstrukturen;
  final List<String> offeneFragen;
  final int quellenAnzahl;

  NutzerDisplay({
    required this.titel,
    required this.einordnung,
    required this.gefundeneFakten,
    required this.alternativeSichtweise,
    required this.machtstrukturen,
    required this.offeneFragen,
    required this.quellenAnzahl,
  });

  factory NutzerDisplay.fromJson(Map<String, dynamic> json) {
    return NutzerDisplay(
      titel: json['titel'] ?? 'Recherche-Ergebnis',
      einordnung: json['einordnung'] ?? '',
      gefundeneFakten:
          (json['gefundene_fakten'] as List?)?.cast<String>() ?? [],
      alternativeSichtweise: json['alternative_sichtweise'] ?? '',
      machtstrukturen: (json['machtstrukturen'] as List?)?.cast<String>() ?? [],
      offeneFragen: (json['offene_fragen'] as List?)?.cast<String>() ?? [],
      quellenAnzahl: json['quellen_anzahl'] ?? 0,
    );
  }
}
