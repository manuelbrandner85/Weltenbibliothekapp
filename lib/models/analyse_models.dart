/// Analyse-Models für STEP 2
/// Tiefenanalyse: Machtstrukturen, Geldflüsse, Akteure, Narrative
/// 
/// VERWENDUNG:
/// Nach STEP 1 (Fakten sammeln) → STEP 2 (Analyse & Alternative Sichtweisen)
library;

import 'package:flutter/material.dart';

/// Akteur (Person, Organisation, Institution)
class Akteur {
  final String id;
  final String name;
  final AkteurTyp typ;
  final String? beschreibung;
  final String? rolle;
  final List<String> verbindungen; // IDs anderer Akteure
  final double? machtindex; // 0.0 - 1.0
  final List<String> interessenFelder;
  final String? quelle;

  Akteur({
    required this.id,
    required this.name,
    required this.typ,
    this.beschreibung,
    this.rolle,
    this.verbindungen = const [],
    this.machtindex,
    this.interessenFelder = const [],
    this.quelle,
  });

  /// Icon für Akteur-Typ
  IconData get icon {
    switch (typ) {
      case AkteurTyp.person:
        return Icons.person;
      case AkteurTyp.organisation:
        return Icons.business;
      case AkteurTyp.regierung:
        return Icons.account_balance;
      case AkteurTyp.konzern:
        return Icons.corporate_fare;
      case AkteurTyp.medien:
        return Icons.newspaper;
      case AkteurTyp.ngo:
        return Icons.volunteer_activism;
      case AkteurTyp.militaer:
        return Icons.shield;
      case AkteurTyp.geheimdienst:
        return Icons.security;
    }
  }

  /// Farbe für Akteur-Typ
  Color get farbe {
    switch (typ) {
      case AkteurTyp.person:
        return Colors.blue;
      case AkteurTyp.organisation:
        return Colors.purple;
      case AkteurTyp.regierung:
        return Colors.red;
      case AkteurTyp.konzern:
        return Colors.orange;
      case AkteurTyp.medien:
        return Colors.green;
      case AkteurTyp.ngo:
        return Colors.teal;
      case AkteurTyp.militaer:
        return Colors.brown;
      case AkteurTyp.geheimdienst:
        return Colors.black;
    }
  }
}

enum AkteurTyp {
  person,
  organisation,
  regierung,
  konzern,
  medien,
  ngo,
  militaer,
  geheimdienst,
}

/// Geldfluss zwischen Akteuren
class Geldfluss {
  final String id;
  final String vonAkteurId;
  final String zuAkteurId;
  final double? betrag; // null wenn unbekannt
  final String? waehrung;
  final DateTime? datum;
  final String zweck;
  final GeldflussTyp typ;
  final bool istVerifiziert;
  final String? quelle;

  Geldfluss({
    required this.id,
    required this.vonAkteurId,
    required this.zuAkteurId,
    this.betrag,
    this.waehrung,
    this.datum,
    required this.zweck,
    required this.typ,
    this.istVerifiziert = false,
    this.quelle,
  });

  /// Formatierter Betrag
  String get betragFormatiert {
    if (betrag == null) return 'Unbekannt';
    final waehr = waehrung ?? '€';
    if (betrag! >= 1000000000) {
      return '${(betrag! / 1000000000).toStringAsFixed(1)} Mrd. $waehr';
    } else if (betrag! >= 1000000) {
      return '${(betrag! / 1000000).toStringAsFixed(1)} Mio. $waehr';
    } else if (betrag! >= 1000) {
      return '${(betrag! / 1000).toStringAsFixed(1)}k $waehr';
    }
    return '${betrag!.toStringAsFixed(2)} $waehr';
  }

  /// Icon für Geldfluss-Typ
  IconData get icon {
    switch (typ) {
      case GeldflussTyp.spende:
        return Icons.volunteer_activism;
      case GeldflussTyp.investition:
        return Icons.trending_up;
      case GeldflussTyp.subvention:
        return Icons.account_balance_wallet;
      case GeldflussTyp.lobbyismus:
        return Icons.handshake;
      case GeldflussTyp.bestechung:
        return Icons.money_off;
      case GeldflussTyp.gehalt:
        return Icons.payments;
      case GeldflussTyp.auftrag:
        return Icons.description;
    }
  }

  Color get farbe {
    switch (typ) {
      case GeldflussTyp.spende:
        return Colors.green;
      case GeldflussTyp.investition:
        return Colors.blue;
      case GeldflussTyp.subvention:
        return Colors.orange;
      case GeldflussTyp.lobbyismus:
        return Colors.purple;
      case GeldflussTyp.bestechung:
        return Colors.red;
      case GeldflussTyp.gehalt:
        return Colors.teal;
      case GeldflussTyp.auftrag:
        return Colors.indigo;
    }
  }
}

enum GeldflussTyp {
  spende,
  investition,
  subvention,
  lobbyismus,
  bestechung,
  gehalt,
  auftrag,
}

/// Narrativ (Erzählstrang in Medien)
class Narrativ {
  final String id;
  final String titel;
  final String beschreibung;
  final NarrativTyp typ;
  final List<String> hauptpunkte;
  final List<String> medienQuellen; // Welche Medien verbreiten dieses Narrativ
  final double verbreitung; // 0.0 - 1.0 (wie weit verbreitet)
  final DateTime? erstErwaehnung;
  final List<String> gegenNarrative; // IDs entgegengesetzter Narrative

  Narrativ({
    required this.id,
    required this.titel,
    required this.beschreibung,
    required this.typ,
    this.hauptpunkte = const [],
    this.medienQuellen = const [],
    this.verbreitung = 0.0,
    this.erstErwaehnung,
    this.gegenNarrative = const [],
  });

  Color get farbe {
    switch (typ) {
      case NarrativTyp.mainstream:
        return Colors.blue;
      case NarrativTyp.kritisch:
        return Colors.orange;
      case NarrativTyp.alternativ:
        return Colors.purple;
      case NarrativTyp.verschwoerung:
        return Colors.red;
    }
  }

  String get typLabel {
    switch (typ) {
      case NarrativTyp.mainstream:
        return 'Mainstream';
      case NarrativTyp.kritisch:
        return 'Kritisch';
      case NarrativTyp.alternativ:
        return 'Alternativ';
      case NarrativTyp.verschwoerung:
        return 'Verschwörungstheorie';
    }
  }
}

enum NarrativTyp {
  mainstream,
  kritisch,
  alternativ,
  verschwoerung,
}

/// Machtstruktur (hierarchische Beziehung)
class Machtstruktur {
  final String id;
  final String name;
  final String beschreibung;
  final List<Akteur> topAkteure;
  final List<Geldfluss> hauptGeldfluesse;
  final MachtBereich bereich;
  final double? einflussFaktor; // 0.0 - 1.0

  Machtstruktur({
    required this.id,
    required this.name,
    required this.beschreibung,
    this.topAkteure = const [],
    this.hauptGeldfluesse = const [],
    required this.bereich,
    this.einflussFaktor,
  });

  Color get farbe {
    switch (bereich) {
      case MachtBereich.politik:
        return Colors.red;
      case MachtBereich.wirtschaft:
        return Colors.green;
      case MachtBereich.medien:
        return Colors.blue;
      case MachtBereich.militaer:
        return Colors.brown;
      case MachtBereich.geheimdienste:
        return Colors.black;
      case MachtBereich.wissenschaft:
        return Colors.purple;
      case MachtBereich.religion:
        return Colors.orange;
    }
  }
}

enum MachtBereich {
  politik,
  wirtschaft,
  medien,
  militaer,
  geheimdienste,
  wissenschaft,
  religion,
}

/// Historischer Kontext (Zeitlinie)
class HistorischerKontext {
  final String id;
  final String ereignis;
  final DateTime datum;
  final String beschreibung;
  final List<String> beteiligte; // Akteur-IDs
  final String? quelle;
  final bool istVerifiziert;

  HistorischerKontext({
    required this.id,
    required this.ereignis,
    required this.datum,
    required this.beschreibung,
    this.beteiligte = const [],
    this.quelle,
    this.istVerifiziert = false,
  });
}

/// Alternative Sichtweise (Kaninchenbau)
class AlternativeSichtweise {
  final String id;
  final String titel;
  final String these;
  final String beschreibung;
  final List<String> argumente;
  final List<String> gegenArgumente;
  final List<String> belege; // URLs zu Quellen
  final GlaubwuerdigkeitsLevel glaubwuerdigkeit;
  final bool istKiGeneriert; // Cloudflare AI Fallback
  final String? disclaimer;

  AlternativeSichtweise({
    required this.id,
    required this.titel,
    required this.these,
    required this.beschreibung,
    this.argumente = const [],
    this.gegenArgumente = const [],
    this.belege = const [],
    this.glaubwuerdigkeit = GlaubwuerdigkeitsLevel.unbekannt,
    this.istKiGeneriert = false,
    this.disclaimer,
  });

  Color get glaubwuerdigkeitFarbe {
    switch (glaubwuerdigkeit) {
      case GlaubwuerdigkeitsLevel.hoch:
        return Colors.green;
      case GlaubwuerdigkeitsLevel.mittel:
        return Colors.orange;
      case GlaubwuerdigkeitsLevel.niedrig:
        return Colors.red;
      case GlaubwuerdigkeitsLevel.unbekannt:
        return Colors.grey;
    }
  }

  String get glaubwuerdigkeitLabel {
    switch (glaubwuerdigkeit) {
      case GlaubwuerdigkeitsLevel.hoch:
        return 'Hohe Glaubwürdigkeit';
      case GlaubwuerdigkeitsLevel.mittel:
        return 'Mittlere Glaubwürdigkeit';
      case GlaubwuerdigkeitsLevel.niedrig:
        return 'Niedrige Glaubwürdigkeit';
      case GlaubwuerdigkeitsLevel.unbekannt:
        return 'Unbekannte Glaubwürdigkeit';
    }
  }
}

enum GlaubwuerdigkeitsLevel {
  hoch,
  mittel,
  niedrig,
  unbekannt,
}

/// Gesamte Analyse-Ergebnisse (STEP 2)
class AnalyseErgebnis {
  final String suchbegriff;
  final DateTime analyseZeit;
  
  // Machtstrukturen
  final List<Machtstruktur> machtstrukturen;
  final List<Akteur> alleAkteure;
  final List<Geldfluss> geldFluesse;
  
  // Narrative & Medien
  final List<Narrativ> narrative;
  
  // Historischer Kontext
  final List<HistorischerKontext> timeline;
  
  // Alternative Sichtweisen
  final List<AlternativeSichtweise> alternativeSichtweisen;
  
  // Meta-Kontext
  final String? metaKontext;
  final bool istKiGeneriert; // Fallback wenn Step 1 leer
  final String? disclaimer;

  AnalyseErgebnis({
    required this.suchbegriff,
    required this.analyseZeit,
    this.machtstrukturen = const [],
    this.alleAkteure = const [],
    this.geldFluesse = const [],
    this.narrative = const [],
    this.timeline = const [],
    this.alternativeSichtweisen = const [],
    this.metaKontext,
    this.istKiGeneriert = false,
    this.disclaimer,
  });

  /// Anzahl der Haupt-Akteure (Machtindex > 0.7)
  int get anzahlHauptAkteure {
    return alleAkteure.where((a) => (a.machtindex ?? 0.0) > 0.7).length;
  }

  /// Gesamte Geldsumme (wenn bekannt)
  double get gesamtGeldsumme {
    return geldFluesse
        .where((g) => g.betrag != null)
        .fold(0.0, (sum, g) => sum + g.betrag!);
  }

  /// Haupt-Narrativ (am weitesten verbreitet)
  Narrativ? get hauptNarrativ {
    if (narrative.isEmpty) return null;
    return narrative.reduce(
      (curr, next) => curr.verbreitung > next.verbreitung ? curr : next,
    );
  }

  /// Gibt es alternative Sichtweisen?
  bool get hatAlternativeSichtweisen {
    return alternativeSichtweisen.isNotEmpty;
  }
}

/// Analyse-Konfiguration
class AnalyseConfig {
  final bool analysiereMachtstrukturen;
  final bool analysiereGeldfluesse;
  final bool analysiereNarrative;
  final bool analysiereTimeline;
  final bool generiereAlternativeSichtweisen;
  final bool verwendeKiFallback; // Cloudflare AI wenn keine Daten
  
  const AnalyseConfig({
    this.analysiereMachtstrukturen = true,
    this.analysiereGeldfluesse = true,
    this.analysiereNarrative = true,
    this.analysiereTimeline = true,
    this.generiereAlternativeSichtweisen = true,
    this.verwendeKiFallback = true,
  });
}
