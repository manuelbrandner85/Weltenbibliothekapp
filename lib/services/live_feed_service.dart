/// LIVE-FEED-SERVICE
/// Aggregiert deutschsprachige Inhalte aus dem Internet via RSS
/// Aktualisierung alle 10 Minuten
/// ECHTE QUELLEN: Amerika21, SWP Berlin, Yoga Vidya, etc.
library;

import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import '../models/live_feed_entry.dart';
import 'rss_parser_service.dart';

class LiveFeedService {
  static final LiveFeedService _instance = LiveFeedService._internal();
  factory LiveFeedService() => _instance;
  LiveFeedService._internal();

  Timer? _updateTimer;
  final List<MaterieFeedEntry> _materieFeeds = [];
  final List<EnergieFeedEntry> _energieFeeds = [];
  DateTime? _lastUpdate;
  
  // RSS Parser für echte Feeds
  final RSSParserService _rssParser = RSSParserService();
  
  // Callback für UI-Updates
  Function(List<LiveFeedEntry>)? onFeedsUpdated;

  /// Starte Auto-Update (alle 10 Minuten)
  void startAutoUpdate() {
    // Initiales Laden
    _updateAllFeeds();
    
    // Timer für 10-Minuten-Updates
    _updateTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      _updateAllFeeds();
    });
  }

  void stopAutoUpdate() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  Future<void> _updateAllFeeds() async {
    if (kDebugMode) {
      debugPrint('🔄 Live-Feed Update gestartet...');
    }
    
    await Future.wait([
      _updateMaterieFeeds(),
      _updateEnergieFeeds(),
    ]);
    
    _lastUpdate = DateTime.now();
    
    // Benachrichtige UI
    if (onFeedsUpdated != null) {
      final allFeeds = [..._materieFeeds, ..._energieFeeds];
      onFeedsUpdated!(allFeeds);
    }
    
    if (kDebugMode) {
      debugPrint('✅ Live-Feed Update abgeschlossen: ${_materieFeeds.length} Materie + ${_energieFeeds.length} Energie');
    }
  }

  Future<void> _updateMaterieFeeds() async {
    _materieFeeds.clear();
    
    // ⚡ PARALLELES LADEN: 3 Quellen gleichzeitig (5-10x schneller!)
    try {
      if (kDebugMode) {
        debugPrint('📡 Lade MATERIE RSS-Feeds (PARALLEL-Modus: 3 Quellen)...');
      }
      
      final realFeeds = await _rssParser.parseLimitedFeedsParallel(
        FeedWorld.materie,
        maxSources: 3, // 3 Quellen parallel laden
      ).catchError((error) {
        if (kDebugMode) {
          debugPrint('⚠️ RSS-Parser-Fehler (Materie): $error');
        }
        return <LiveFeedEntry>[]; // Leere Liste bei Fehler
      });
      
      if (realFeeds.isNotEmpty) {
        _materieFeeds.addAll(realFeeds.cast<MaterieFeedEntry>());
        
        if (kDebugMode) {
          debugPrint('✅ ${realFeeds.length} echte Materie-Feeds erfolgreich geladen!');
        }
        return; // Erfolg! Keine Demo-Daten nötig
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ RSS-Feed Fehler: $e');
      }
    }
    
    // Fallback nur wenn RSS-Loading fehlschlägt
    if (kDebugMode) {
      debugPrint('⚠️ Lade Fallback-Demo-Daten für Materie...');
    }
    _loadDemoMaterieFeeds();
  }
  
  void _loadDemoMaterieFeeds() {
    final now = DateTime.now();
    _materieFeeds.addAll([
      MaterieFeedEntry(
        feedId: 'mat_${now.millisecondsSinceEpoch}_1',
        titel: 'Operation Gladio: NATO-Geheimarmeen in Europa',
        quelle: 'Historisches Archiv',
        sourceUrl: 'https://archive.org/details/gladio',
        quellentyp: QuellenTyp.archiv,
        fetchTimestamp: now,
        lastChecked: now,
        updateType: UpdateType.neu,
        thema: 'Geopolitik & NATO',
        tiefeLevel: 4,
        zusammenfassung: 'Detaillierte Analyse der Stay-Behind-Organisationen in Europa während des Kalten Krieges. Dokumentierte Verbindungen zu terroristischen Anschlägen in Italien.',
        zentraleFragestellung: 'Wie wurden NATO-Geheimarmeen nach dem Zweiten Weltkrieg aufgebaut und welche Rolle spielten sie in der europäischen Politik?',
        alternativeNarrative: [
          'Offizielle NATO-Position: Defensive Maßnahmen gegen sowjetische Invasion',
          'Alternative Sicht: Werkzeug zur Manipulation europäischer Politik',
        ],
        historischerKontext: '1990 enthüllte der italienische Premierminister Giulio Andreotti die Existenz von Gladio. Weitere Stay-Behind-Netzwerke wurden in 13 europäischen Ländern nachgewiesen.',
        empfohleneVerknuepfungen: ['Karte: NATO-Stützpunkte', 'Zeitachse: Kalter Krieg', 'Thema: False Flag Operationen'],
        warumAngezeigtGrund: 'Basierend auf deinem Interesse an Geopolitik',
      ),
      MaterieFeedEntry(
        feedId: 'mat_${now.millisecondsSinceEpoch}_2',
        titel: 'MK-ULTRA Dokumente: CIA Mind Control Experimente',
        quelle: 'CIA Reading Room',
        sourceUrl: 'https://www.cia.gov/readingroom/collection/mkultra',
        quellentyp: QuellenTyp.pdf,
        fetchTimestamp: now.subtract(const Duration(minutes: 5)),
        lastChecked: now,
        updateType: UpdateType.aktualisiert,
        thema: 'Geheimdienste & Experimente',
        tiefeLevel: 5,
        zusammenfassung: 'Freigegebene CIA-Dokumente zu Verhaltenskontroll-Experimenten (1953-1973). Einsatz von LSD, Hypnose, sensorischer Deprivation und Folter.',
        zentraleFragestellung: 'Welche Methoden nutzte die CIA zur Bewusstseinskontrolle und welche ethischen Grenzen wurden überschritten?',
        alternativeNarrative: [
          'Offizielle Version: Defensive Forschung gegen sowjetische Programme',
          'Alternative Sicht: Systematischer Missbrauch für Verhaltenskontrolle',
        ],
        historischerKontext: '1975 deckte die Church Commission die Experimente auf. Trotz Vernichtung der meisten Akten 1973 blieben 20.000 Dokumente erhalten.',
        empfohleneVerknuepfungen: ['Thema: Verhaltenskontrolle', 'Personen: Sidney Gottlieb', 'Zeitachse: CIA-Programme'],
      ),
      MaterieFeedEntry(
        feedId: 'mat_${now.millisecondsSinceEpoch}_3',
        titel: 'Bilderberg-Konferenz 2024: Teilnehmerliste analysiert',
        quelle: 'Analyse-Blog',
        sourceUrl: 'https://example.com/bilderberg-2024',
        quellentyp: QuellenTyp.analyse,
        fetchTimestamp: now.subtract(const Duration(hours: 2)),
        lastChecked: now,
        updateType: UpdateType.unveraendert,
        thema: 'Eliten & Netzwerke',
        tiefeLevel: 3,
        zusammenfassung: 'Detailanalyse der Teilnehmerliste 2024. Schwerpunkt: Technologie-CEOs, Zentralbanker und Regierungsvertreter. Hauptthemen: KI, Cybersecurity, Geopolitik.',
        zentraleFragestellung: 'Welche Machtnetzwerke treffen sich hinter verschlossenen Türen und welchen Einfluss haben diese Treffen?',
        alternativeNarrative: [
          'Offizielle Version: Informeller Gedankenaustausch ohne Beschlüsse',
          'Alternative Sicht: Koordination globaler Entscheidungen außerhalb demokratischer Kontrolle',
        ],
        historischerKontext: 'Seit 1954 jährliches Treffen einflussreicher Personen aus Politik, Wirtschaft und Medien. Chatham-House-Regel: Inhalte dürfen nicht zitiert werden.',
        empfohleneVerknuepfungen: ['Netzwerk: Council on Foreign Relations', 'Thema: Globalismus'],
      ),
    ]);
  }

  Future<void> _updateEnergieFeeds() async {
    _energieFeeds.clear();
    
    // ⚡ PARALLELES LADEN: 3 Quellen gleichzeitig (5-10x schneller!)
    try {
      if (kDebugMode) {
        debugPrint('📡 Lade ENERGIE RSS-Feeds (PARALLEL-Modus: 3 Quellen)...');
      }
      
      final realFeeds = await _rssParser.parseLimitedFeedsParallel(
        FeedWorld.energie,
        maxSources: 3, // 3 Quellen parallel laden
      ).catchError((error) {
        if (kDebugMode) {
          debugPrint('⚠️ RSS-Parser-Fehler (Energie): $error');
        }
        return <LiveFeedEntry>[]; // Leere Liste bei Fehler
      });
      
      if (realFeeds.isNotEmpty) {
        _energieFeeds.addAll(realFeeds.cast<EnergieFeedEntry>());
        
        if (kDebugMode) {
          debugPrint('✅ ${realFeeds.length} echte Energie-Feeds erfolgreich geladen!');
        }
        return; // Erfolg! Keine Demo-Daten nötig
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ RSS-Feed Fehler: $e');
      }
    }
    
    // Fallback nur wenn RSS-Loading fehlschlägt
    if (kDebugMode) {
      debugPrint('⚠️ Lade Fallback-Demo-Daten für Energie...');
    }
    _loadDemoEnergieFeeds();
  }
  
  void _loadDemoEnergieFeeds() {
    final now = DateTime.now();
    _energieFeeds.addAll([
      EnergieFeedEntry(
        feedId: 'ene_${now.millisecondsSinceEpoch}_1',
        titel: 'Der Schatten in der Kabbala: Qliphoth als Spiegelung',
        quelle: 'Hermetische Texte',
        sourceUrl: 'https://example.com/qliphoth',
        quellentyp: QuellenTyp.fachtext,
        fetchTimestamp: now,
        lastChecked: now,
        updateType: UpdateType.neu,
        spiritThema: 'Kabbala & Schattenarbeit',
        symbolSchwerpunkte: ['Lebensbaum', 'Qliphoth', 'Sephiroth', 'Dualität'],
        numerischeBezuege: ['10 Sephiroth', '22 Pfade', '32 Weisheitswege'],
        archetypen: ['Schatten (Jung)', 'Dunkle Mutter', 'Innerer Dämon'],
        symbolischeEinordnung: 'Die Qliphoth repräsentieren die umgekehrte Seite des kabbalistischen Lebensbaums - nicht als "böse", sondern als notwendiger Spiegel zur Selbsterkenntnis.',
        reflexionsfragen: [
          'Welche Aspekte meines Selbst vermeide ich zu sehen?',
          'Wie zeigt sich mein Schatten in meinen Projektionen?',
          'Was könnte ich lernen, wenn ich das Abgelehnte integriere?',
        ],
        verknuepfungMitModulen: ['Kabbala-Rechner', 'Archetypen-Test', 'Traumdeutung'],
        warumAngezeigtGrund: 'Basierend auf deinem Interesse an Kabbala',
      ),
      EnergieFeedEntry(
        feedId: 'ene_${now.millisecondsSinceEpoch}_2',
        titel: 'Heilige Geometrie: Das Vesica Piscis als Schöpfungssymbol',
        quelle: 'Symbollexikon',
        sourceUrl: 'https://example.com/vesica-piscis',
        quellentyp: QuellenTyp.symbollexikon,
        fetchTimestamp: now.subtract(const Duration(minutes: 15)),
        lastChecked: now,
        updateType: UpdateType.aktualisiert,
        spiritThema: 'Heilige Geometrie',
        symbolSchwerpunkte: ['Vesica Piscis', 'Mandorla', 'Ichthys', 'Yoni'],
        numerischeBezuege: ['√3 (Seitenverhältnis)', 'Goldener Schnitt'],
        archetypen: ['Geburt', 'Vereinigung', 'Portal'],
        symbolischeEinordnung: 'Zwei sich überschneidende Kreise bilden die Vesica Piscis - Symbol der Schöpfung durch Vereinigung von Gegensätzen. In vielen Kulturen als heiliges Portal verstanden.',
        reflexionsfragen: [
          'Wo in meinem Leben treffen Gegensätze aufeinander?',
          'Welche neuen Möglichkeiten entstehen aus Vereinigung statt Trennung?',
          'Was wird "geboren", wenn ich verschiedene Perspektiven zusammenbringe?',
        ],
        verknuepfungMitModulen: ['Geometrie-Visualisierung', 'Meditation'],
      ),
      EnergieFeedEntry(
        feedId: 'ene_${now.millisecondsSinceEpoch}_3',
        titel: 'Numerologie: Die Bedeutung der Meisterzahl 33',
        quelle: 'Numerologie-Fachportal',
        sourceUrl: 'https://example.com/meisterzahl-33',
        quellentyp: QuellenTyp.fachtext,
        fetchTimestamp: now.subtract(const Duration(hours: 1)),
        lastChecked: now,
        updateType: UpdateType.unveraendert,
        spiritThema: 'Numerologie & Meisterzahlen',
        symbolSchwerpunkte: ['Meisterzahl', 'Dreifaltigkeit', 'Erleuchtung'],
        numerischeBezuege: ['3 + 3 = 6', '33 = 11 × 3', 'Christus-Zahl'],
        archetypen: ['Meisterlehrer', 'Heiler', 'Erleuchteter'],
        symbolischeEinordnung: 'Die 33 verbindet die kreative Kraft der 3 mit spiritueller Meisterschaft. Symbol des Lehrers, der durch eigene Transformation andere inspiriert.',
        reflexionsfragen: [
          'Wo lehre ich durch mein Beispiel, nicht nur durch Worte?',
          'Welche Verantwortung kommt mit spirituellem Wissen?',
          'Wie kann ich Wissen in praktische Heilung transformieren?',
        ],
        verknuepfungMitModulen: ['Numerologie-Rechner', 'Gematria', 'Lebensweg-Analyse'],
        warumAngezeigtGrund: 'Dein Lebensweg enthält die Zahl 3',
      ),
    ]);
  }

  /// Hole Materie-Feeds
  /// Hole Materie-Feeds (lädt automatisch beim ersten Aufruf)
  Future<List<MaterieFeedEntry>> getMaterieFeeds({String? themenFilter}) async {
    // 🚀 AUTO-LOAD: Beim ersten Aufruf automatisch laden
    if (_materieFeeds.isEmpty && _lastUpdate == null) {
      if (kDebugMode) {
        debugPrint('🚀 Erstes Mal getMaterieFeeds() aufgerufen - starte Auto-Load');
      }
      await _updateMaterieFeeds();
    }
    
    if (themenFilter == null) return List.from(_materieFeeds);
    return _materieFeeds.where((f) => f.thema.contains(themenFilter)).toList();
  }

  /// Hole Energie-Feeds (lädt automatisch beim ersten Aufruf)
  Future<List<EnergieFeedEntry>> getEnergieFeeds({String? themenFilter}) async {
    // 🚀 AUTO-LOAD: Beim ersten Aufruf automatisch laden
    if (_energieFeeds.isEmpty && _lastUpdate == null) {
      if (kDebugMode) {
        debugPrint('🚀 Erstes Mal getEnergieFeeds() aufgerufen - starte Auto-Load');
      }
      await _updateEnergieFeeds();
    }
    
    if (themenFilter == null) return List.from(_energieFeeds);
    return _energieFeeds.where((f) => f.spiritThema.contains(themenFilter)).toList();
  }

  /// Hole neue Feeds (seit letztem Check)
  List<LiveFeedEntry> getNeueFeeds() {
    return [
      ..._materieFeeds.where((f) => f.isNeu),
      ..._energieFeeds.where((f) => f.isNeu),
    ];
  }

  /// Hole aktualisierte Feeds
  List<LiveFeedEntry> getAktualisierteFeed() {
    return [
      ..._materieFeeds.where((f) => f.isAktualisiert),
      ..._energieFeeds.where((f) => f.isAktualisiert),
    ];
  }

  DateTime? get lastUpdate => _lastUpdate;
  int get materieFeedCount => _materieFeeds.length;
  int get energieFeedCount => _energieFeeds.length;
}

