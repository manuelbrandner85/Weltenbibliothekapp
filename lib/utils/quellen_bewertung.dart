/// WELTENBIBLIOTHEK v5.7 – QUELLEN-BEWERTUNGSSYSTEM
/// 
/// Transparente Bewertung der Quellenqualität mit Vertrauensindikatoren:
/// 
/// POSITIVE INDIKATOREN (+):
/// - Öffentlich zugängliche Quelle
/// - Mehrere unabhängige Bestätigungen
/// - Originaldokumente vorhanden
/// - Nachvollziehbare Autoren
/// 
/// NEGATIVE INDIKATOREN (-):
/// - Anonyme Quelle
/// - Nur Einzelnennung
/// - Starke emotionale Sprache
/// - Fehlender Kontext
library;

import 'package:flutter/material.dart';

/// Quellen-Bewertungsmodell
class QuellenBewertung {
  final String quelle;
  final List<VertrauensIndikator> positiveIndikatoren;
  final List<VertrauensIndikator> negativeIndikatoren;
  final bool istBewertet;  // 🆕 v5.8: Kein Score berechenbar → "nicht bewertet"
  final String? bewertungsHinweis;  // 🆕 v5.8: Optional: Grund warum nicht bewertet
  
  const QuellenBewertung({
    required this.quelle,
    this.positiveIndikatoren = const [],
    this.negativeIndikatoren = const [],
    this.istBewertet = true,  // 🆕 v5.8: Standard = bewertet
    this.bewertungsHinweis,   // 🆕 v5.8: Optional
  });
  
  /// Berechnet Vertrauensscore (0-100) mit differenzierter Gewichtung
  /// 🆕 v5.8: Score niemals blockierend - gibt -1 zurück wenn nicht bewertet
  int get vertrauensScore {
    // 🆕 v5.8: Kein Score berechenbar → -1 zurückgeben
    if (!istBewertet) return -1;
    int score = 50; // Basiswert
    
    // POSITIVE INDIKATOREN (Max +50 Punkte)
    for (final indikator in positiveIndikatoren) {
      switch (indikator) {
        case VertrauensIndikator.oeffentlichZugaenglich:
          score += 15; // Wichtigster positiver Indikator
          break;
        case VertrauensIndikator.mehrfachBestaetigt:
          score += 15; // Wichtigster positiver Indikator
          break;
        case VertrauensIndikator.originaldokumente:
          score += 10;
          break;
        case VertrauensIndikator.nachvollziehbareAutoren:
          score += 10;
          break;
        default:
          break;
      }
    }
    
    // NEGATIVE INDIKATOREN (Max -55 Punkte)
    for (final indikator in negativeIndikatoren) {
      switch (indikator) {
        case VertrauensIndikator.anonymeQuelle:
          score -= 15; // Stärkster negativer Indikator
          break;
        case VertrauensIndikator.nurEinzelnennung:
          score -= 10;
          break;
        case VertrauensIndikator.emotionaleSprache:
          score -= 10;
          break;
        case VertrauensIndikator.fehlenderKontext:
          score -= 10;
          break;
        case VertrauensIndikator.sekundaereQuelle:
          score -= 10; // Sekundäre Analyse statt Primärquelle
          break;
        default:
          break;
      }
    }
    
    // Auf 0-100 begrenzen
    return score.clamp(0, 100);
  }
  
  /// Vertrauensstufe basierend auf Score
  VertrauensStufe get vertrauensStufe {
    if (vertrauensScore >= 75) return VertrauensStufe.hoch;
    if (vertrauensScore >= 50) return VertrauensStufe.mittel;
    if (vertrauensScore >= 25) return VertrauensStufe.niedrig;
    return VertrauensStufe.sehrNiedrig;
  }
  
  /// 🆕 v5.8: Factory für unbewertete Quelle
  factory QuellenBewertung.nichtBewertet(String quelle, String grund) {
    return QuellenBewertung(
      quelle: quelle,
      istBewertet: false,
      bewertungsHinweis: grund,
    );
  }
  
  /// Analysiert Quelle und erstellt automatische Bewertung
  /// 🆕 v5.8: Robustes Fehlerhandling - Score niemals blockierend
  factory QuellenBewertung.analyseQuelle(String quelle) {
    // 🆕 v5.8: Keine Quelle → nicht bewertet
    if (quelle.trim().isEmpty) {
      return QuellenBewertung.nichtBewertet(
        'Keine Quelle angegeben',
        'Leere Quellenangabe',
      );
    }
    
    // 🆕 v5.8: Teilweise Daten → Teil-Score (normal weiter)
    try {
      final positiv = <VertrauensIndikator>[];
      final negativ = <VertrauensIndikator>[];
      
      final quelleLower = quelle.toLowerCase();
    
    // POSITIVE INDIKATOREN PRÜFEN
    
    // 1. Öffentlich zugängliche Quelle
    if (_istOeffentlichZugaenglich(quelleLower)) {
      positiv.add(VertrauensIndikator.oeffentlichZugaenglich);
    }
    
    // 2. Mehrere unabhängige Bestätigungen
    if (_hatMehrfachBestaetigungen(quelle)) {
      positiv.add(VertrauensIndikator.mehrfachBestaetigt);
    }
    
    // 3. Originaldokumente vorhanden
    if (_hatOriginaldokumente(quelleLower)) {
      positiv.add(VertrauensIndikator.originaldokumente);
    }
    
    // 4. Nachvollziehbare Autoren
    if (_hatNachvollziehbareAutoren(quelle)) {
      positiv.add(VertrauensIndikator.nachvollziehbareAutoren);
    }
    
    // NEGATIVE INDIKATOREN PRÜFEN
    
    // 1. Anonyme Quelle
    if (_istAnonym(quelleLower)) {
      negativ.add(VertrauensIndikator.anonymeQuelle);
    }
    
    // 2. Nur Einzelnennung
    if (_istNurEinzelnennung(quelle)) {
      negativ.add(VertrauensIndikator.nurEinzelnennung);
    }
    
    // 3. Starke emotionale Sprache
    if (_hatEmotionaleSprache(quelle)) {
      negativ.add(VertrauensIndikator.emotionaleSprache);
    }
    
    // 4. Fehlender Kontext
    if (_fehltKontext(quelle)) {
      negativ.add(VertrauensIndikator.fehlenderKontext);
    }
    
    // 5. Sekundäre Quelle (keine Primärquelle)
    if (_istSekundaereQuelle(quelle)) {
      negativ.add(VertrauensIndikator.sekundaereQuelle);
    }
    
      return QuellenBewertung(
        quelle: quelle,
        positiveIndikatoren: positiv,
        negativeIndikatoren: negativ,
        istBewertet: true,
      );
    } catch (e) {
      // 🆕 v5.8: Bei Fehler → nicht blockierend, Fallback-Bewertung
      return QuellenBewertung.nichtBewertet(
        quelle,
        'Bewertung fehlgeschlagen: $e',
      );
    }
  }
  
  // ERKENNUNGS-FUNKTIONEN
  
  static bool _istOeffentlichZugaenglich(String quelle) {
    final keywords = [
      'wikipedia', 'gov', '.edu', 'archive.org', 
      'cia.gov', 'fbi.gov', 'library',
      'pubmed', 'arxiv', 'doi:', 'isbn:',
      'nytimes', 'bbc', 'reuters', 'ap news',
      'scientific', 'journal', 'paper',
    ];
    return keywords.any((kw) => quelle.contains(kw));
  }
  
  static bool _hatMehrfachBestaetigungen(String quelle) {
    final multi = quelle.contains(',') || 
                  quelle.contains(';') || 
                  quelle.contains(' und ') ||
                  quelle.contains(' + ');
    final mentions = ['mehrere', 'verschiedene', 'zahlreiche', 'multiple'];
    return multi || mentions.any((m) => quelle.toLowerCase().contains(m));
  }
  
  static bool _hatOriginaldokumente(String quelle) {
    final keywords = [
      'dokument', 'akte', 'file', 'declassified',
      'original', 'pdf', 'scan', 'archiv',
      'primärquelle', 'originalquelle',
    ];
    return keywords.any((kw) => quelle.toLowerCase().contains(kw));
  }
  
  static bool _hatNachvollziehbareAutoren(String quelle) {
    // Prüft auf Namens-Patterns (z.B. "Dr. Smith", "Prof. Müller")
    final patterns = [
      RegExp(r'dr\.\s+\w+', caseSensitive: false),
      RegExp(r'prof\.\s+\w+', caseSensitive: false),
      RegExp(r'[A-Z][a-z]+\s+[A-Z][a-z]+'), // Vor- und Nachname
      RegExp(r'autor:', caseSensitive: false),
      RegExp(r'by\s+[A-Z][a-z]+', caseSensitive: false),
    ];
    return patterns.any((p) => p.hasMatch(quelle));
  }
  
  static bool _istAnonym(String quelle) {
    final keywords = [
      'anonym', 'unbekannt', 'geheim', 'vertraulich',
      'anonymous', 'unknown', 'confidential',
      'whistleblower', 'insider', 'quelle:',
    ];
    return keywords.any((kw) => quelle.toLowerCase().contains(kw));
  }
  
  static bool _istNurEinzelnennung(String quelle) {
    final notMulti = !_hatMehrfachBestaetigungen(quelle);
    final notOfficial = !_istOeffentlichZugaenglich(quelle);
    final short = quelle.length < 50;
    return notMulti && notOfficial && short;
  }
  
  static bool _hatEmotionaleSprache(String quelle) {
    final keywords = [
      'skandal', 'schock', 'unglaublich', 'unfassbar',
      'katastrophe', 'horror', 'sensation',
      '!!!', '!!!', 'müssen wissen',
    ];
    return keywords.any((kw) => quelle.toLowerCase().contains(kw));
  }
  
  static bool _fehltKontext(String quelle) {
    final kurz = quelle.length < 30;
    final keineDetails = !quelle.contains('(') && 
                         !quelle.contains('[') &&
                         !quelle.contains('http');
    return kurz && keineDetails;
  }
  
  static bool _istSekundaereQuelle(String quelle) {
    final keywords = [
      'analyse', 'zusammenfassung', 'bericht über', 
      'artikel über', 'kommentar', 'meinung',
      'basierend auf', 'laut', 'gemäß',
      'blog', 'rezension', 'review',
      'sekundär', 'interpretation',
    ];
    
    // Prüfe ob Quelle sekundär ist (analysiert andere Quellen)
    // ABER nicht wenn es Originaldokumente hat
    final istSekundaer = keywords.any((kw) => quelle.toLowerCase().contains(kw));
    final hatOriginal = _hatOriginaldokumente(quelle.toLowerCase());
    
    return istSekundaer && !hatOriginal;
  }
}

/// Vertrauensindikatoren
enum VertrauensIndikator {
  // POSITIV (+)
  oeffentlichZugaenglich('Öffentlich zugängliche Quelle', true),
  mehrfachBestaetigt('Mehrere unabhängige Bestätigungen', true),
  originaldokumente('Originaldokumente vorhanden', true),
  nachvollziehbareAutoren('Nachvollziehbare Autoren', true),
  
  // NEGATIV (-)
  anonymeQuelle('Anonyme Quelle', false),
  nurEinzelnennung('Nur Einzelnennung', false),
  emotionaleSprache('Starke emotionale Sprache', false),
  fehlenderKontext('Fehlender Kontext', false),
  sekundaereQuelle('Sekundäre Analyse (keine Primärquelle)', false);
  
  final String label;
  final bool isPositiv;
  
  const VertrauensIndikator(this.label, this.isPositiv);
  
  IconData get icon {
    if (isPositiv) {
      switch (this) {
        case VertrauensIndikator.oeffentlichZugaenglich:
          return Icons.public;
        case VertrauensIndikator.mehrfachBestaetigt:
          return Icons.verified;
        case VertrauensIndikator.originaldokumente:
          return Icons.article;
        case VertrauensIndikator.nachvollziehbareAutoren:
          return Icons.person;
        default:
          return Icons.check_circle;
      }
    } else {
      switch (this) {
        case VertrauensIndikator.anonymeQuelle:
          return Icons.visibility_off;
        case VertrauensIndikator.nurEinzelnennung:
          return Icons.warning;
        case VertrauensIndikator.emotionaleSprache:
          return Icons.sentiment_very_dissatisfied;
        case VertrauensIndikator.fehlenderKontext:
          return Icons.help_outline;
        case VertrauensIndikator.sekundaereQuelle:
          return Icons.filter_2;
        default:
          return Icons.cancel;
      }
    }
  }
  
  Color get color {
    return isPositiv ? Colors.green : Colors.red;
  }
}

/// Vertrauensstufen
enum VertrauensStufe {
  hoch('Hohe Vertrauenswürdigkeit', Colors.green, Icons.verified),
  mittel('Mittlere Vertrauenswürdigkeit', Colors.orange, Icons.info),
  niedrig('Niedrige Vertrauenswürdigkeit', Colors.deepOrange, Icons.warning),
  sehrNiedrig('Sehr niedrige Vertrauenswürdigkeit', Colors.red, Icons.dangerous);
  
  final String label;
  final Color color;
  final IconData icon;
  
  const VertrauensStufe(this.label, this.color, this.icon);
}

/// Widget: Quellen-Bewertungskarte
class QuellenBewertungsCard extends StatelessWidget {
  final QuellenBewertung bewertung;
  final bool showDetails;
  
  const QuellenBewertungsCard({
    super.key,
    required this.bewertung,
    this.showDetails = true,
  });
  
  @override
  Widget build(BuildContext context) {
    // 🆕 v5.8: Behandle "nicht bewertet" Status
    if (!bewertung.istBewertet) {
      return _buildNichtBewertetCard(context);
    }
    
    final stufe = bewertung.vertrauensStufe;
    final score = bewertung.vertrauensScore;
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // QUELLE & SCORE
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vertrauensstufe-Icon
                Icon(stufe.icon, color: stufe.color, size: 28),
                const SizedBox(width: 12),
                
                // Quelle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bewertung.quelle,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: stufe.color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              stufe.label,
                              style: TextStyle(
                                fontSize: 11,
                                color: stufe.color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Score: $score/100',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // DETAILS (optional)
            if (showDetails && (bewertung.positiveIndikatoren.isNotEmpty || 
                                bewertung.negativeIndikatoren.isNotEmpty)) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              
              // POSITIVE INDIKATOREN
              if (bewertung.positiveIndikatoren.isNotEmpty) ...[
                _buildIndikatorenListe(
                  'Positive Indikatoren',
                  bewertung.positiveIndikatoren,
                  Colors.green,
                ),
                const SizedBox(height: 8),
              ],
              
              // NEGATIVE INDIKATOREN
              if (bewertung.negativeIndikatoren.isNotEmpty) ...[
                _buildIndikatorenListe(
                  'Negative Indikatoren',
                  bewertung.negativeIndikatoren,
                  Colors.red,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
  
  /// 🆕 v5.8: Widget für nicht bewertete Quellen
  Widget _buildNichtBewertetCard(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.help_outline, color: Colors.grey[600], size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bewertung.quelle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Nicht bewertet',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (bewertung.bewertungsHinweis != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      bewertung.bewertungsHinweis!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildIndikatorenListe(
    String titel,
    List<VertrauensIndikator> indikatoren,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        ...indikatoren.map((indikator) => Padding(
          padding: const EdgeInsets.only(left: 8, top: 4),
          child: Row(
            children: [
              Icon(indikator.icon, size: 16, color: indikator.color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  indikator.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}

/// Helper: Analysiert Liste von Quellen
class QuellenAnalyzer {
  /// Analysiert mehrere Quellen und gibt Bewertungen zurück
  static List<QuellenBewertung> analyseQuellen(List<String> quellen) {
    return quellen
        .map((q) => QuellenBewertung.analyseQuelle(q))
        .toList();
  }
  
  /// Berechnet durchschnittlichen Vertrauensscore
  /// 🆕 v5.8: Ignoriert nicht bewertete Quellen (Score -1)
  static double durchschnittlicherScore(List<QuellenBewertung> bewertungen) {
    if (bewertungen.isEmpty) return 0.0;
    
    // 🆕 v5.8: Nur bewertete Quellen berücksichtigen
    final bewerteteQuellen = bewertungen.where((b) => b.istBewertet).toList();
    if (bewerteteQuellen.isEmpty) return 0.0;
    
    final summe = bewerteteQuellen.fold<int>(
      0, 
      (sum, b) => sum + b.vertrauensScore,
    );
    return summe / bewerteteQuellen.length;
  }
  
  /// Gibt Anzahl pro Vertrauensstufe zurück
  static Map<VertrauensStufe, int> verteilungNachStufe(
    List<QuellenBewertung> bewertungen,
  ) {
    final verteilung = <VertrauensStufe, int>{
      VertrauensStufe.hoch: 0,
      VertrauensStufe.mittel: 0,
      VertrauensStufe.niedrig: 0,
      VertrauensStufe.sehrNiedrig: 0,
    };
    
    for (final bewertung in bewertungen) {
      verteilung[bewertung.vertrauensStufe] = 
          (verteilung[bewertung.vertrauensStufe] ?? 0) + 1;
    }
    
    return verteilung;
  }
}
