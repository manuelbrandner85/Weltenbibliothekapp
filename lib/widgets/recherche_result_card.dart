/// WELTENBIBLIOTHEK v5.7 – STRUKTURIERTE ERGEBNIS-DARSTELLUNG MIT QUELLEN-BEWERTUNG
/// 
/// Übersichtliches Layout mit klaren Abschnitten:
/// - TITEL (Thema) mit KI-Fallback-Warnung
/// - FAKTEN (Belegbare Informationen)
/// - QUELLEN (Referenzen und Links) + Vertrauensindikatoren
/// - ANALYSE (Offizielle/Mainstream-Sicht)
/// - ALTERNATIVE SICHT (Kritische/Alternative Perspektive)
/// 
/// Intelligente Features:
/// - KI-Fallback wird prominent markiert
/// - Vergleich nur wenn beide Sichtweisen existieren
/// - Leere Sections werden ausgeblendet
/// - Quellen-Bewertungssystem mit Vertrauensscore
library;

import 'package:flutter/material.dart';
import '../utils/quellen_bewertung.dart';
import '../utils/responsive_utils.dart';
import '../utils/responsive_text_styles.dart';
import '../utils/responsive_spacing.dart';

class RechercheResultCard extends StatelessWidget {
  final Map<String, dynamic> analyseData;
  final String query;

  const RechercheResultCard({
    super.key,
    required this.analyseData,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ RESPONSIVE UTILITIES
    final responsive = context.responsive;
    
    // Strukturierte Daten extrahieren (falls vorhanden)
    final structured = analyseData['structured'] as Map<String, dynamic>?;
    final inhalt = analyseData['inhalt'] as String? ?? '';
    
    // 🆕 v5.6.1: KI-Fallback prüfen
    final isFallback = analyseData['is_fallback'] == true;

    // Fakten extrahieren
    final fakten = _extractFakten(structured, inhalt);
    
    // Quellen extrahieren
    final quellen = _extractQuellen(structured, inhalt);
    
    // Analyse (Offizielle Sicht) extrahieren
    final analyse = _extractAnalyse(structured, inhalt);
    
    // Alternative Sicht extrahieren
    final alternativeSicht = _extractAlternativeSicht(structured, inhalt);
    
    // 🆕 v5.6.1: Prüfe ob beide Sichtweisen existieren
    final hasBothViews = analyse.isNotEmpty && alternativeSicht.isNotEmpty;

    return Card(
      elevation: responsive.elevationMd,
      margin: EdgeInsets.all(responsive.spacingSm),
      child: SingleChildScrollView(
        padding: context.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ━━━━━━━━━━━━━━━━━━
            // TITEL mit KI-Fallback-Warnung
            // ━━━━━━━━━━━━━━━━━━
            _buildTitleSection(context, query, isFallback),
            
            SizedBox(height: responsive.spacingXl),
            
            // ━━━━━━━━━━━━━━━━━━
            // FAKTEN (nur wenn vorhanden)
            // ━━━━━━━━━━━━━━━━━━
            if (fakten.isNotEmpty) ...[
              _buildSection(
                context,
                title: 'FAKTEN',
                icon: Icons.fact_check,
                color: Colors.blue,
                content: fakten,
              ),
              context.vSpaceLg,
            ],
            
            // ━━━━━━━━━━━━━━━━━━
            // QUELLEN mit Bewertungssystem (nur wenn vorhanden)
            // ━━━━━━━━━━━━━━━━━━
            if (quellen.isNotEmpty) ...[
              _buildQuellenSectionMitBewertung(context, structured),
              context.vSpaceLg,
            ],
            
            // ━━━━━━━━━━━━━━━━━━
            // ANALYSE (nur wenn vorhanden)
            // ━━━━━━━━━━━━━━━━━━
            if (analyse.isNotEmpty) ...[
              _buildSection(
                context,
                title: 'ANALYSE',
                icon: Icons.analytics,
                color: Colors.orange,
                content: analyse,
              ),
              context.vSpaceLg,
            ],
            
            // ━━━━━━━━━━━━━━━━━━
            // ALTERNATIVE SICHT (nur wenn vorhanden)
            // ━━━━━━━━━━━━━━━━━━
            if (alternativeSicht.isNotEmpty) ...[
              _buildSection(
                context,
                title: 'ALTERNATIVE SICHT',
                icon: Icons.remove_red_eye,
                color: Colors.purple,
                content: alternativeSicht,
              ),
              context.vSpaceLg,
            ],
            
            // ━━━━━━━━━━━━━━━━━━
            // VERGLEICH (nur wenn beide Sichtweisen existieren)
            // ━━━━━━━━━━━━━━━━━━
            if (hasBothViews && structured != null && structured.containsKey('vergleich')) ...[
              _buildSection(
                context,
                title: 'VERGLEICH',
                icon: Icons.compare_arrows,
                color: Colors.indigo,
                content: _extractVergleich(structured),
              ),
              context.vSpaceLg,
            ],
            
            // ━━━━━━━━━━━━━━━━━━
            // INTERNATIONALER VERGLEICH (v5.12 - DEAKTIVIERT)
            // ━━━━━━━━━━━━━━━━━━
            // Feature temporär deaktiviert wegen context-Fehler
            // if (analyseData.containsKey('international_perspectives')) 
            //   _buildInternationalComparison(analyseData['international_perspectives']),
          ],
        ),
      ),
    );
  }

  /// TITEL-SEKTION mit KI-Fallback-Warnung
  Widget _buildTitleSection(BuildContext context, String query, bool isFallback) {
    final responsive = context.responsive;
    final textStyles = context.textStyles;
    
    return Container(
      width: double.infinity,
      padding: context.paddingMd,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isFallback 
              ? [Colors.orange[700]!, Colors.orange[900]!]  // Orange bei Fallback
              : [Colors.blue[700]!, Colors.blue[900]!],      // Blau bei normalen Daten
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(responsive.borderRadiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'TITEL',
                style: textStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                  letterSpacing: 2,
                ),
              ),
              // 🆕 v5.6.1: KI-Fallback-Badge
              if (isFallback) ...[
                context.hSpaceSm,
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.spacingXs,
                    vertical: responsive.spacingXs / 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red[700],
                    borderRadius: BorderRadius.circular(responsive.borderRadiusXs),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: responsive.iconSizeXs,
                      ),
                      SizedBox(width: responsive.spacingXs / 2),
                      Text(
                        'KI-FALLBACK',
                        style: textStyles.labelSmall.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          context.vSpaceSm,
          Text(
            query,
            style: textStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: responsive.spacingXs / 2),
          Text(
            isFallback 
                ? 'KI-generierte Analyse (Keine externen Quellen verfügbar)'
                : 'Thema der Recherche',
            style: textStyles.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  /// GENERISCHE SECTION
  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section-Header
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: context.responsive.spacingSm,
            vertical: context.responsive.spacingXs,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            border: Border(
              left: BorderSide(
                color: color,
                width: context.responsive.borderRadiusXs / 2,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: color,
                size: context.responsive.iconSizeMd,
              ),
              context.hSpaceXs,
              Text(
                title,
                style: context.textStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        
        // Dekorative Linie
        Container(
          width: double.infinity,
          height: context.responsive.borderRadiusXs / 4,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.0)],
            ),
          ),
        ),
        
        context.vSpaceSm,
        
        // Content
        Container(
          width: double.infinity,
          padding: context.paddingMd,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(context.responsive.borderRadiusMd),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: content.isEmpty
              ? Text(
                  'Keine Informationen verfügbar',
                  style: context.textStyles.bodySmall.copyWith(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                )
              : SelectableText(
                  content,
                  style: context.textStyles.bodyMedium.copyWith(
                    height: 1.6,
                  ),
                ),
        ),
      ],
    );
  }

  /// 🆕 v5.7: QUELLEN-SECTION MIT BEWERTUNGSSYSTEM
  Widget _buildQuellenSectionMitBewertung(
    BuildContext context,
    Map<String, dynamic>? structured,
  ) {
    // Quellen extrahieren
    final List<String> quellenListe = [];
    
    if (structured != null) {
      // Offizielle Quellen
      if (structured.containsKey('sichtweise1_offiziell')) {
        final view1 = structured['sichtweise1_offiziell'] as Map<String, dynamic>?;
        if (view1 != null && view1.containsKey('quellen')) {
          final quellen = view1['quellen'] as List<dynamic>?;
          if (quellen != null) {
            quellenListe.addAll(quellen.map((q) => q.toString()));
          }
        }
      }
      
      // Alternative Quellen
      if (structured.containsKey('sichtweise2_alternativ')) {
        final view2 = structured['sichtweise2_alternativ'] as Map<String, dynamic>?;
        if (view2 != null && view2.containsKey('quellen')) {
          final quellen = view2['quellen'] as List<dynamic>?;
          if (quellen != null) {
            quellenListe.addAll(quellen.map((q) => q.toString()));
          }
        }
      }
    }
    
    // 🆕 v5.8: Keine Quellen → KI-Fallback-Hinweis
    if (quellenListe.isEmpty) {
      return _buildKeinQuellenHinweis(context);
    }
    
    // Quellen analysieren
    final bewertungen = QuellenAnalyzer.analyseQuellen(quellenListe);
    
    // 🆕 v5.7.2: SORTIERUNG nach Vertrauensscore (höchste zuerst)
    // 🆕 v5.8: Score niemals blockierend - sortiere nur bewertete Quellen
    bewertungen.sort((a, b) {
      // Nicht bewertete Quellen ans Ende
      if (!a.istBewertet && !b.istBewertet) return 0;
      if (!a.istBewertet) return 1;
      if (!b.istBewertet) return -1;
      // Bewertete Quellen nach Score sortieren
      return b.vertrauensScore.compareTo(a.vertrauensScore);
    });
    
    final avgScore = QuellenAnalyzer.durchschnittlicherScore(bewertungen);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section-Header
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: context.responsive.spacingSm,
            vertical: context.responsive.spacingXs,
          ),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            border: Border(
              left: BorderSide(
                color: Colors.green,
                width: context.responsive.borderRadiusXs / 2,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.link,
                color: Colors.green,
                size: context.responsive.iconSizeMd,
              ),
              context.hSpaceXs,
              Text(
                'QUELLEN',
                style: context.textStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              // Durchschnitts-Score
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsive.spacingXs,
                  vertical: context.responsive.spacingXs / 2,
                ),
                decoration: BoxDecoration(
                  color: _getScoreColor(avgScore).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(context.responsive.borderRadiusXs),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.assessment,
                      size: context.responsive.iconSizeSm,
                      color: _getScoreColor(avgScore),
                    ),
                    SizedBox(width: context.responsive.spacingXs / 2),
                    Text(
                      'Ø ${avgScore.toStringAsFixed(0)}/100',
                      style: context.textStyles.labelSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getScoreColor(avgScore),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Dekorative Linie
        Container(
          width: double.infinity,
          height: context.responsive.borderRadiusXs / 4,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green, Colors.green.withValues(alpha: 0.0)],
            ),
          ),
        ),
        
        context.vSpaceSm,
        
        // Quellen mit Bewertungen
        ...bewertungen.map((bewertung) => QuellenBewertungsCard(
          bewertung: bewertung,
          showDetails: true,
        )),
      ],
    );
  }
  
  /// 🆕 v5.8: Hinweis wenn keine Quellen vorhanden
  Widget _buildKeinQuellenHinweis(BuildContext context) {
    final responsive = context.responsive;
    final textStyles = context.textStyles;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: responsive.spacingSm,
            vertical: responsive.spacingXs,
          ),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            border: Border(
              left: BorderSide(
                color: Colors.orange,
                width: responsive.borderRadiusXs / 2,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: responsive.iconSizeMd,
              ),
              context.hSpaceXs,
              Text(
                'QUELLEN',
                style: textStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.spacingXs,
                  vertical: responsive.spacingXs / 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(responsive.borderRadiusXs),
                ),
                child: Text(
                  'KI-FALLBACK',
                  style: textStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          height: responsive.borderRadiusXs / 4,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange, Colors.orange.withValues(alpha: 0.0)],
            ),
          ),
        ),
        context.vSpaceSm,
        Container(
          width: double.infinity,
          padding: context.paddingMd,
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(responsive.borderRadiusMd),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange[700],
                    size: responsive.iconSizeSm,
                  ),
                  context.hSpaceXs,
                  Expanded(
                    child: Text(
                      'Keine externen Quellen verfügbar',
                      style: textStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[900],
                      ),
                    ),
                  ),
                ],
              ),
              context.vSpaceXs,
              Text(
                'Diese Analyse basiert auf KI-generiertem Inhalt ohne externe Quellenverifikation. '
                'Die Informationen sollten mit Vorsicht betrachtet und durch unabhängige Recherche '
                'überprüft werden.',
                style: textStyles.bodySmall.copyWith(
                  color: Colors.orange[800],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  /// Helper: Score-basierte Farbe
  Color _getScoreColor(double score) {
    if (score >= 75) return Colors.green;
    if (score >= 50) return Colors.orange;
    if (score >= 25) return Colors.deepOrange;
    return Colors.red;
  }
  
  /// 🆕 v5.12: INTERNATIONALER VERGLEICH
  // DEAKTIVIERT - Feature wird nicht genutzt (context-Fehler)
  /* Widget _buildInternationalComparison(dynamic perspectivesData) {
    try {
      // Validierung: prüfe ob es eine Map ist
      if (perspectivesData is! Map<String, dynamic>) {
        throw ArgumentError('perspectivesData muss eine Map<String, dynamic> sein');
      }
      
      // Für Demo-Zwecke zeigen wir nur eine Info-Message
      // Backend-Integration folgt später
      return Card(
        elevation: context.responsive.elevationSm,
        margin: EdgeInsets.only(top: context.responsive.spacingXs),
        child: Container(
          padding: context.paddingSm,
          decoration: BoxDecoration(
            color: Colors.indigo[50],
            borderRadius: BorderRadius.circular(context.responsive.borderRadiusMd),
            border: Border.all(color: Colors.indigo[200]!),
          ),
          child: Row(
            children: [
              Icon(
                Icons.public,
                color: Colors.indigo[700],
                size: context.responsive.iconSizeSm,
              ),
              context.hSpaceXs,
              Expanded(
                child: Text(
                  'Internationale Perspektiven verfügbar - Feature wird vom Backend integriert',
                  style: context.textStyles.labelSmall?.copyWith(
                    color: Colors.indigo[900],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      // Fallback falls Konvertierung fehlschlägt
      return Card(
        elevation: context.responsive.elevationSm,
        margin: EdgeInsets.only(top: context.responsive.spacingXs),
        child: Container(
          padding: context.paddingSm,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(context.responsive.borderRadiusMd),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.grey[600],
                size: context.responsive.iconSizeSm,
              ),
              context.hSpaceXs,
              Expanded(
                child: Text(
                  'Internationale Perspektiven konnten nicht geladen werden',
                  style: context.textStyles.labelSmall?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  } */

  /// FAKTEN EXTRAHIEREN
  String _extractFakten(Map<String, dynamic>? structured, String inhalt) {
    if (structured != null && structured.containsKey('faktenbasis')) {
      final fb = structured['faktenbasis'] as Map<String, dynamic>?;
      if (fb != null) {
        final buffer = StringBuffer();
        
        // Fakten
        if (fb.containsKey('facts')) {
          final facts = fb['facts'] as List<dynamic>?;
          if (facts != null && facts.isNotEmpty) {
            buffer.writeln('📌 BELEGBARE FAKTEN:\n');
            for (var fact in facts) {
              buffer.writeln('• $fact');
            }
            buffer.writeln();
          }
        }
        
        // Akteure
        if (fb.containsKey('actors')) {
          final actors = fb['actors'] as List<dynamic>?;
          if (actors != null && actors.isNotEmpty) {
            buffer.writeln('👤 BETEILIGTE AKTEURE:\n');
            for (var actor in actors) {
              buffer.writeln('• $actor');
            }
            buffer.writeln();
          }
        }
        
        // Organisationen
        if (fb.containsKey('organizations')) {
          final orgs = fb['organizations'] as List<dynamic>?;
          if (orgs != null && orgs.isNotEmpty) {
            buffer.writeln('🏛️ ORGANISATIONEN:\n');
            for (var org in orgs) {
              buffer.writeln('• $org');
            }
            buffer.writeln();
          }
        }
        
        // Geldflüsse
        if (fb.containsKey('financial_flows')) {
          final flows = fb['financial_flows'] as List<dynamic>?;
          if (flows != null && flows.isNotEmpty) {
            buffer.writeln('💰 GELDFLÜSSE:\n');
            for (var flow in flows) {
              buffer.writeln('• $flow');
            }
            buffer.writeln();
          }
        }
        
        if (buffer.isNotEmpty) return buffer.toString().trim();
      }
    }
    
    // Fallback: Aus Inhalt extrahieren
    return _extractFromInhalt(inhalt, [
      'FAKT',
      'BETEILIGTE',
      'ORGANISATIONEN',
      'GELDFLÜSSE',
    ]);
  }

  /// QUELLEN EXTRAHIEREN
  String _extractQuellen(Map<String, dynamic>? structured, String inhalt) {
    if (structured != null) {
      final buffer = StringBuffer();
      
      // Offizielle Quellen
      if (structured.containsKey('sichtweise1_offiziell')) {
        final view1 = structured['sichtweise1_offiziell'] as Map<String, dynamic>?;
        if (view1 != null && view1.containsKey('quellen')) {
          final quellen = view1['quellen'] as List<dynamic>?;
          if (quellen != null && quellen.isNotEmpty) {
            buffer.writeln('📚 OFFIZIELLE QUELLEN:\n');
            for (var quelle in quellen) {
              buffer.writeln('• $quelle');
            }
            buffer.writeln();
          }
        }
      }
      
      // Alternative Quellen
      if (structured.containsKey('sichtweise2_alternativ')) {
        final view2 = structured['sichtweise2_alternativ'] as Map<String, dynamic>?;
        if (view2 != null && view2.containsKey('quellen')) {
          final quellen = view2['quellen'] as List<dynamic>?;
          if (quellen != null && quellen.isNotEmpty) {
            buffer.writeln('🔍 ALTERNATIVE QUELLEN:\n');
            for (var quelle in quellen) {
              buffer.writeln('• $quelle');
            }
            buffer.writeln();
          }
        }
      }
      
      if (buffer.isNotEmpty) return buffer.toString().trim();
    }
    
    // Fallback: Aus Inhalt extrahieren
    return _extractFromInhalt(inhalt, ['QUELLEN', 'Quelle:']);
  }

  /// ANALYSE EXTRAHIEREN (Offizielle Sicht)
  String _extractAnalyse(Map<String, dynamic>? structured, String inhalt) {
    if (structured != null && structured.containsKey('sichtweise1_offiziell')) {
      final view1 = structured['sichtweise1_offiziell'] as Map<String, dynamic>?;
      if (view1 != null) {
        final buffer = StringBuffer();
        
        // Interpretation
        if (view1.containsKey('interpretation')) {
          buffer.writeln(view1['interpretation']);
          buffer.writeln();
        }
        
        // Argumentation
        if (view1.containsKey('argumentation')) {
          final args = view1['argumentation'] as List<dynamic>?;
          if (args != null && args.isNotEmpty) {
            buffer.writeln('📊 HAUPTARGUMENTE:\n');
            for (var arg in args) {
              buffer.writeln('• $arg');
            }
          }
        }
        
        if (buffer.isNotEmpty) return buffer.toString().trim();
      }
    }
    
    // Fallback: Aus Inhalt extrahieren
    return _extractFromInhalt(inhalt, ['ANALYSE', 'INTERPRETATION', 'Offiziell']);
  }

  /// ALTERNATIVE SICHT EXTRAHIEREN
  String _extractAlternativeSicht(Map<String, dynamic>? structured, String inhalt) {
    if (structured != null && structured.containsKey('sichtweise2_alternativ')) {
      final view2 = structured['sichtweise2_alternativ'] as Map<String, dynamic>?;
      if (view2 != null) {
        final buffer = StringBuffer();
        
        // Interpretation
        if (view2.containsKey('interpretation')) {
          buffer.writeln(view2['interpretation']);
          buffer.writeln();
        }
        
        // Argumentation
        if (view2.containsKey('argumentation')) {
          final args = view2['argumentation'] as List<dynamic>?;
          if (args != null && args.isNotEmpty) {
            buffer.writeln('🔍 HAUPTARGUMENTE:\n');
            for (var arg in args) {
              buffer.writeln('• $arg');
            }
          }
        }
        
        if (buffer.isNotEmpty) return buffer.toString().trim();
      }
    }
    
    // Fallback: Aus Inhalt extrahieren
    return _extractFromInhalt(inhalt, ['ALTERNATIVE', 'KRITISCH', 'Systemkritisch']);
  }

  /// VERGLEICH EXTRAHIEREN (nur wenn beide Sichtweisen existieren)
  String _extractVergleich(Map<String, dynamic> structured) {
    if (!structured.containsKey('vergleich')) return '';
    
    final vergleich = structured['vergleich'] as Map<String, dynamic>?;
    if (vergleich == null) return '';
    
    final buffer = StringBuffer();
    
    // Gemeinsame Punkte
    if (vergleich.containsKey('gemeinsame_punkte')) {
      final gemeinsam = vergleich['gemeinsame_punkte'] as List<dynamic>?;
      if (gemeinsam != null && gemeinsam.isNotEmpty) {
        buffer.writeln('✅ GEMEINSAME PUNKTE:\n');
        for (var punkt in gemeinsam) {
          buffer.writeln('• $punkt');
        }
        buffer.writeln();
      }
    }
    
    // Unterschiede
    if (vergleich.containsKey('unterschiede')) {
      final unterschiede = vergleich['unterschiede'] as List<dynamic>?;
      if (unterschiede != null && unterschiede.isNotEmpty) {
        buffer.writeln('⚖️ ZENTRALE UNTERSCHIEDE:\n');
        for (var diff in unterschiede) {
          buffer.writeln('• $diff');
        }
        buffer.writeln();
      }
    }
    
    // Offene Fragen
    if (vergleich.containsKey('offene_punkte')) {
      final offen = vergleich['offene_punkte'] as List<dynamic>?;
      if (offen != null && offen.isNotEmpty) {
        buffer.writeln('❓ OFFENE FRAGEN:\n');
        for (var frage in offen) {
          buffer.writeln('• $frage');
        }
      }
    }
    
    return buffer.toString().trim();
  }

  /// HELPER: Aus Inhalt extrahieren
  String _extractFromInhalt(String inhalt, List<String> keywords) {
    if (inhalt.isEmpty) return '';
    
    final lines = inhalt.split('\n');
    final buffer = StringBuffer();
    bool inRelevantSection = false;
    
    for (var line in lines) {
      // Check if line contains any keyword
      final lineUpper = line.toUpperCase();
      if (keywords.any((kw) => lineUpper.contains(kw.toUpperCase()))) {
        inRelevantSection = true;
        continue;
      }
      
      // Check if new section starts (uppercase header)
      if (line.trim().isNotEmpty && 
          line.trim() == line.trim().toUpperCase() && 
          line.trim().length > 5 &&
          !keywords.any((kw) => lineUpper.contains(kw.toUpperCase()))) {
        if (inRelevantSection && buffer.isNotEmpty) {
          break; // End of relevant section
        }
      }
      
      // Add line if in relevant section
      if (inRelevantSection && line.trim().isNotEmpty) {
        buffer.writeln(line);
      }
    }
    
    return buffer.toString().trim();
  }
}
