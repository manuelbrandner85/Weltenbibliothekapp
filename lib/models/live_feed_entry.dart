/// LIVE-FEED EINTRAG
/// Für MATERIE und ENERGIE Live-Feeds
/// Aktualisierung alle 10 Minuten
library;

enum FeedWorld {
  materie,
  energie,
}

enum QuellenTyp {
  essay,
  archiv,
  pdf,
  analyse,
  fachtext,
  symbollexikon,
  uebersetzung,
  tiefenpsychologie,
}

enum UpdateType {
  neu,
  aktualisiert,
  unveraendert,
}

/// Basis-Klasse für alle Feed-Einträge
abstract class LiveFeedEntry {
  final String feedId;
  final FeedWorld welt;
  final String titel;
  final String quelle;
  final String sourceUrl;
  final QuellenTyp quellentyp;
  final DateTime fetchTimestamp;
  final DateTime lastChecked;
  final UpdateType updateType;
  
  LiveFeedEntry({
    required this.feedId,
    required this.welt,
    required this.titel,
    required this.quelle,
    required this.sourceUrl,
    required this.quellentyp,
    required this.fetchTimestamp,
    required this.lastChecked,
    required this.updateType,
  });
  
  String get quellenTypLabel {
    switch (quellentyp) {
      case QuellenTyp.essay:
        return 'ESSAY';
      case QuellenTyp.archiv:
        return 'ARCHIV';
      case QuellenTyp.pdf:
        return 'PDF';
      case QuellenTyp.analyse:
        return 'ANALYSE';
      case QuellenTyp.fachtext:
        return 'FACHTEXT';
      case QuellenTyp.symbollexikon:
        return 'SYMBOLLEXIKON';
      case QuellenTyp.uebersetzung:
        return 'ÜBERSETZUNG';
      case QuellenTyp.tiefenpsychologie:
        return 'TIEFENPSYCHOLOGIE';
    }
  }
  
  String get updateTypeLabel {
    switch (updateType) {
      case UpdateType.neu:
        return '🆕 NEU';
      case UpdateType.aktualisiert:
        return '🔄 AKTUALISIERT';
      case UpdateType.unveraendert:
        return '✓ AKTUELL';
    }
  }
  
  bool get isNeu => updateType == UpdateType.neu;
  bool get isAktualisiert => updateType == UpdateType.aktualisiert;
  
  String get zeitSeitUpdate {
    final diff = DateTime.now().difference(fetchTimestamp);
    if (diff.inMinutes < 60) {
      return 'vor ${diff.inMinutes} Min';
    } else if (diff.inHours < 24) {
      return 'vor ${diff.inHours} Std';
    } else {
      return 'vor ${diff.inDays} Tagen';
    }
  }
}

/// MATERIE Feed-Eintrag
class MaterieFeedEntry extends LiveFeedEntry {
  final String thema;
  final int tiefeLevel; // 1-5
  final String zusammenfassung;
  final String zentraleFragestellung;
  final List<String> alternativeNarrative;
  final String historischerKontext;
  final List<String> empfohleneVerknuepfungen;
  final String? warumAngezeigtGrund; // Personalisierung
  
  MaterieFeedEntry({
    required super.feedId,
    required super.titel,
    required super.quelle,
    required super.sourceUrl,
    required super.quellentyp,
    required super.fetchTimestamp,
    required super.lastChecked,
    required super.updateType,
    required this.thema,
    required this.tiefeLevel,
    required this.zusammenfassung,
    required this.zentraleFragestellung,
    this.alternativeNarrative = const [],
    this.historischerKontext = '',
    this.empfohleneVerknuepfungen = const [],
    this.warumAngezeigtGrund,
  }) : super(welt: FeedWorld.materie);
  
  String get tiefeLevelLabel {
    switch (tiefeLevel) {
      case 1:
        return 'Einstieg';
      case 2:
        return 'Grundlagen';
      case 3:
        return 'Vertiefung';
      case 4:
        return 'Fortgeschritten';
      case 5:
        return 'Experte';
      default:
        return 'Mittel';
    }
  }
}

/// ENERGIE Feed-Eintrag
class EnergieFeedEntry extends LiveFeedEntry {
  final String spiritThema;
  final List<String> symbolSchwerpunkte;
  final List<String> numerischeBezuege;
  final List<String> archetypen;
  final String symbolischeEinordnung;
  final List<String> reflexionsfragen;
  final List<String> verknuepfungMitModulen;
  final String? warumAngezeigtGrund; // Personalisierung
  
  EnergieFeedEntry({
    required super.feedId,
    required super.titel,
    required super.quelle,
    required super.sourceUrl,
    required super.quellentyp,
    required super.fetchTimestamp,
    required super.lastChecked,
    required super.updateType,
    required this.spiritThema,
    this.symbolSchwerpunkte = const [],
    this.numerischeBezuege = const [],
    this.archetypen = const [],
    required this.symbolischeEinordnung,
    this.reflexionsfragen = const [],
    this.verknuepfungMitModulen = const [],
    this.warumAngezeigtGrund,
  }) : super(welt: FeedWorld.energie);
}
