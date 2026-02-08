/// Deep-Recherche Models
/// Für echte Multi-Source Recherche mit vollständigen Inhalten
library;


/// Quellentyp-Kategorien
enum QuellenTyp {
  nachrichten,
  wissenschaft,
  regierung,
  recht,
  archive,
  multimedia,
  buecher,
}

/// Extension für Quellentyp
extension QuellenTypExtension on QuellenTyp {
  String get label {
    switch (this) {
      case QuellenTyp.nachrichten:
        return 'Nachrichten';
      case QuellenTyp.wissenschaft:
        return 'Wissenschaft';
      case QuellenTyp.regierung:
        return 'Regierung';
      case QuellenTyp.recht:
        return 'Recht & Archive';
      case QuellenTyp.archive:
        return 'Archive';
      case QuellenTyp.multimedia:
        return 'Multimedia';
      case QuellenTyp.buecher:
        return 'Bücher';
    }
  }

  String get icon {
    switch (this) {
      case QuellenTyp.nachrichten:
        return '📰';
      case QuellenTyp.wissenschaft:
        return '🔬';
      case QuellenTyp.regierung:
        return '🏛️';
      case QuellenTyp.recht:
        return '⚖️';
      case QuellenTyp.archive:
        return '📚';
      case QuellenTyp.multimedia:
        return '🎥';
      case QuellenTyp.buecher:
        return '📖';
    }
  }
}

/// Status einer einzelnen Quelle
enum QuellenStatus {
  pending,    // Wartet auf Verarbeitung
  loading,    // Wird gerade geladen
  success,    // Erfolgreich geladen
  failed,     // Fehler beim Laden
  noContent,  // Keine Inhalte gefunden
}

/// Einzelne Recherche-Quelle mit vollem Inhalt
class RechercheQuelle {
  final String id;
  final String titel;
  final String url;
  final QuellenTyp typ;
  final String? autor;
  final DateTime? datum;
  final String volltext;  // ← WICHTIG: Tatsächlicher Inhalt der Seite
  final String zusammenfassung;  // KI-generierte Zusammenfassung
  final QuellenStatus status;
  final String? fehlerMeldung;
  final int zeichenAnzahl;
  final DateTime abgerufenAm;

  RechercheQuelle({
    required this.id,
    required this.titel,
    required this.url,
    required this.typ,
    this.autor,
    this.datum,
    this.volltext = '',
    this.zusammenfassung = '',
    this.status = QuellenStatus.pending,
    this.fehlerMeldung,
    int? zeichenAnzahl,
    DateTime? abgerufenAm,
  })  : zeichenAnzahl = zeichenAnzahl ?? volltext.length,
        abgerufenAm = abgerufenAm ?? DateTime.now();

  /// Kopie mit geänderten Werten
  RechercheQuelle copyWith({
    String? id,
    String? titel,
    String? url,
    QuellenTyp? typ,
    String? autor,
    DateTime? datum,
    String? volltext,
    String? zusammenfassung,
    QuellenStatus? status,
    String? fehlerMeldung,
    int? zeichenAnzahl,
    DateTime? abgerufenAm,
  }) {
    return RechercheQuelle(
      id: id ?? this.id,
      titel: titel ?? this.titel,
      url: url ?? this.url,
      typ: typ ?? this.typ,
      autor: autor ?? this.autor,
      datum: datum ?? this.datum,
      volltext: volltext ?? this.volltext,
      zusammenfassung: zusammenfassung ?? this.zusammenfassung,
      status: status ?? this.status,
      fehlerMeldung: fehlerMeldung ?? this.fehlerMeldung,
      zeichenAnzahl: zeichenAnzahl ?? this.zeichenAnzahl,
      abgerufenAm: abgerufenAm ?? this.abgerufenAm,
    );
  }

  /// Lesedauer in Minuten (basierend auf 200 Wörter/Minute)
  int get lesedauerMinuten {
    final woerter = volltext.split(RegExp(r'\s+')).length;
    return (woerter / 200).ceil();
  }

  /// Ist die Quelle erfolgreich geladen?
  bool get istErfolgreich => status == QuellenStatus.success && volltext.isNotEmpty;

  /// Vorschau-Text (erste 200 Zeichen)
  String get vorschau {
    if (zusammenfassung.isNotEmpty && zusammenfassung.length > 50) {
      return zusammenfassung.length > 200
          ? '${zusammenfassung.substring(0, 200)}...'
          : zusammenfassung;
    }
    if (volltext.isEmpty) return 'Keine Inhalte verfügbar';
    return volltext.length > 200
        ? '${volltext.substring(0, 200)}...'
        : volltext;
  }
}

/// Gesamte Recherche-Ergebnisse
class RechercheErgebnis {
  final String suchbegriff;
  final List<RechercheQuelle> quellen;
  final DateTime startZeit;
  final DateTime? endZeit;
  final int gesamtQuellen;
  final int erfolgreicheQuellen;
  final int fehlgeschlageneQuellen;
  final bool istAbgeschlossen;
  
  // MULTI-MEDIA Support
  final Map<String, dynamic>? media; // Videos, PDFs, Bilder, Audios

  RechercheErgebnis({
    required this.suchbegriff,
    required this.quellen,
    required this.startZeit,
    this.endZeit,
    int? gesamtQuellen,
    int? erfolgreicheQuellen,
    int? fehlgeschlageneQuellen,
    this.istAbgeschlossen = false,
    this.media, // MULTI-MEDIA Support
  })  : gesamtQuellen = gesamtQuellen ?? quellen.length,
        erfolgreicheQuellen = erfolgreicheQuellen ??
            quellen.where((q) => q.istErfolgreich).length,
        fehlgeschlageneQuellen = fehlgeschlageneQuellen ??
            quellen.where((q) => q.status == QuellenStatus.failed).length;

  /// Dauer der Recherche
  Duration get dauer {
    final ende = endZeit ?? DateTime.now();
    return ende.difference(startZeit);
  }

  /// Fortschritt in Prozent (0.0 - 1.0)
  double get fortschritt {
    if (gesamtQuellen == 0) return 0.0;
    final verarbeitet = quellen.where((q) => 
      q.status == QuellenStatus.success || 
      q.status == QuellenStatus.failed ||
      q.status == QuellenStatus.noContent
    ).length;
    return verarbeitet / gesamtQuellen;
  }

  /// Erfolgsrate in Prozent (0.0 - 1.0)
  double get erfolgsRate {
    if (gesamtQuellen == 0) return 0.0;
    return erfolgreicheQuellen / gesamtQuellen;
  }

  /// Quellen nach Typ gruppiert
  Map<QuellenTyp, List<RechercheQuelle>> get quellenNachTyp {
    final grouped = <QuellenTyp, List<RechercheQuelle>>{};
    for (final typ in QuellenTyp.values) {
      grouped[typ] = quellen.where((q) => q.typ == typ).toList();
    }
    return grouped;
  }

  /// Nur erfolgreich geladene Quellen
  List<RechercheQuelle> get erfolgreicheQuellenListe {
    return quellen.where((q) => q.istErfolgreich).toList();
  }

  /// Kopie mit geänderten Werten
  RechercheErgebnis copyWith({
    String? suchbegriff,
    List<RechercheQuelle>? quellen,
    DateTime? startZeit,
    DateTime? endZeit,
    int? gesamtQuellen,
    int? erfolgreicheQuellen,
    int? fehlgeschlageneQuellen,
    bool? istAbgeschlossen,
    Map<String, dynamic>? media,
  }) {
    return RechercheErgebnis(
      suchbegriff: suchbegriff ?? this.suchbegriff,
      quellen: quellen ?? this.quellen,
      startZeit: startZeit ?? this.startZeit,
      endZeit: endZeit ?? this.endZeit,
      gesamtQuellen: gesamtQuellen ?? this.gesamtQuellen,
      erfolgreicheQuellen: erfolgreicheQuellen ?? this.erfolgreicheQuellen,
      fehlgeschlageneQuellen: fehlgeschlageneQuellen ?? this.fehlgeschlageneQuellen,
      istAbgeschlossen: istAbgeschlossen ?? this.istAbgeschlossen,
      media: media ?? this.media,
    );
  }

  /// Quelle aktualisieren
  RechercheErgebnis updateQuelle(RechercheQuelle quelle) {
    final neueQuellen = quellen.map((q) {
      return q.id == quelle.id ? quelle : q;
    }).toList();

    return copyWith(
      quellen: neueQuellen,
      erfolgreicheQuellen: neueQuellen.where((q) => q.istErfolgreich).length,
      fehlgeschlageneQuellen: neueQuellen.where((q) => q.status == QuellenStatus.failed).length,
    );
  }

  /// Alle Quellen als abgeschlossen markieren
  RechercheErgebnis abschliessen() {
    return copyWith(
      istAbgeschlossen: true,
      endZeit: DateTime.now(),
    );
  }
}

/// Recherche-Konfiguration
class RechercheConfig {
  final List<String> nachrichtenQuellen;
  final List<String> wissenschaftQuellen;
  final List<String> regierungsQuellen;
  final List<String> rechtQuellen;
  final List<String> archivQuellen;
  final int maxQuellenProTyp;
  final Duration timeout;
  final bool parallelVerarbeitung;

  const RechercheConfig({
    this.nachrichtenQuellen = const [
      'reuters.com',
      'spiegel.de',
      'zeit.de',
      'sueddeutsche.de',
      'bbc.com',
      'aljazeera.com',
    ],
    this.wissenschaftQuellen = const [
      'scholar.google.com',
      'ncbi.nlm.nih.gov',
      'arxiv.org',
    ],
    this.regierungsQuellen = const [
      'bundesregierung.de',
      'bundestag.de',
      'europarl.europa.eu',
    ],
    this.rechtQuellen = const [
      'bundesverfassungsgericht.de',
      'eur-lex.europa.eu',
    ],
    this.archivQuellen = const [
      'archive.org',
    ],
    this.maxQuellenProTyp = 5,
    this.timeout = const Duration(seconds: 30),
    this.parallelVerarbeitung = true,
  });
}
