/// Detaillierter Behauptungs-Analyse-Screen
/// Professionelle Darstellung mit Statistiken und Beweismitteln
/// Version: 2.0.0
library;

import 'package:flutter/material.dart';
import '../../models/enhanced_research_models.dart';
import '../../widgets/research_statistics_card.dart';
import '../../widgets/universal_edit_wrapper.dart';
import '../../services/universal_content_service.dart';

class BehauptungDetailScreen extends StatelessWidget {
  final DetaillierteBehauptung behauptung;
  
  const BehauptungDetailScreen({
    super.key,
    required this.behauptung,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D47A1),
              Color(0xFF1A1A1A),
              Color(0xFF000000),
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              pinned: true,
              expandedHeight: 120,
              backgroundColor: const Color(0xFF0D47A1),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'BEHAUPTUNGS-ANALYSE',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF0D47A1),
                        const Color(0xFF1565C0).withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Haupt-Behauptung
                  _buildHauptbehauptung(),
                  const SizedBox(height: 20),
                  
                  // Statistik-Übersicht
                  _buildStatistikUebersicht(),
                  const SizedBox(height: 20),
                  
                  // Kontext
                  _buildKontextSection(),
                  const SizedBox(height: 20),
                  
                  // Beweise
                  _buildBeweiseSection(),
                  const SizedBox(height: 20),
                  
                  // Gegenbeweise
                  if (behauptung.gegenbeweise.isNotEmpty)
                    _buildGegenbeweiseSection(),
                  if (behauptung.gegenbeweise.isNotEmpty)
                    const SizedBox(height: 20),
                  
                  // Verbindungen
                  _buildVerbindungenSection(),
                  const SizedBox(height: 20),
                  
                  // Metadaten
                  _buildMetadatenSection(),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHauptbehauptung() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E3A8A).withValues(alpha: 0.3),
            const Color(0xFF1A1A1A),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2196F3).withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kategorie-Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFF2196F3).withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              behauptung.kategorie.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2196F3),
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Behauptung
          Text(
            behauptung.behauptung,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          
          // Schnell-Metriken
          Row(
            children: [
              _buildQuickMetric(
                'Plausibilität',
                '${(behauptung.plausibilitaet * 100).toInt()}%',
                _getPlausibilitaetColor(behauptung.plausibilitaet),
              ),
              const SizedBox(width: 16),
              _buildQuickMetric(
                'Relevanz',
                '${(behauptung.relevanz * 100).toInt()}%',
                Colors.blue,
              ),
              const SizedBox(width: 16),
              _buildQuickMetric(
                'Beweiskraft',
                '${(behauptung.gesamtBeweiskraft * 100).toInt()}%',
                _getBeweiskraftColor(behauptung.gesamtBeweiskraft),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMetric(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white60,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistikUebersicht() {
    return ForschungsStatistikKarte(
      titel: 'ANALYSE-METRIKEN',
      untertitel: 'Detaillierte Bewertung',
      icon: Icons.analytics,
      farbe: const Color(0xFF2196F3),
      elemente: [
        StatistikElement(
          bezeichnung: 'Plausibilität',
          wert: '${(behauptung.plausibilitaet * 100).toInt()}%',
          prozent: behauptung.plausibilitaet,
          farbeWert: _getPlausibilitaetColor(behauptung.plausibilitaet),
        ),
        StatistikElement(
          bezeichnung: 'Relevanz',
          wert: '${(behauptung.relevanz * 100).toInt()}%',
          prozent: behauptung.relevanz,
          farbeWert: Colors.blue,
        ),
        StatistikElement(
          bezeichnung: 'Beweiskraft (Durchschnitt)',
          wert: '${(behauptung.gesamtBeweiskraft * 100).toInt()}%',
          prozent: behauptung.gesamtBeweiskraft,
          farbeWert: _getBeweiskraftColor(behauptung.gesamtBeweiskraft),
        ),
        StatistikElement(
          bezeichnung: 'Kontroversität',
          wert: '${(behauptung.kontroversitaet * 100).toInt()}%',
          prozent: behauptung.kontroversitaet,
          farbeWert: Colors.orange,
        ),
        StatistikElement(
          bezeichnung: 'Anzahl Beweise',
          wert: '${behauptung.beweise.length}',
        ),
        StatistikElement(
          bezeichnung: 'Anzahl Gegenbeweise',
          wert: '${behauptung.gegenbeweise.length}',
        ),
      ],
    );
  }

  Widget _buildKontextSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.public, color: Colors.blue, size: 24),
              const SizedBox(width: 12),
              const Text(
                'KONTEXT',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Beteiligte
          _buildKontextItem('Beteiligte Akteure', behauptung.beteiligte, Icons.people),
          const SizedBox(height: 16),
          
          // Motive
          _buildKontextItem('Motive', behauptung.motive, Icons.psychology),
          const SizedBox(height: 16),
          
          // Zeitlicher Kontext
          if (behauptung.zeitlicherKontext.isNotEmpty)
            _buildKontextItem('Zeitlicher Kontext', behauptung.zeitlicherKontext, Icons.timeline),
          if (behauptung.zeitlicherKontext.isNotEmpty)
            const SizedBox(height: 16),
          
          // Geografischer Kontext
          if (behauptung.geografischerKontext.isNotEmpty)
            _buildKontextItem('Geografischer Kontext', behauptung.geografischerKontext, Icons.location_on),
        ],
      ),
    );
  }

  Widget _buildKontextItem(String titel, List<String> items, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.white60),
            const SizedBox(width: 8),
            Text(
              titel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) => Chip(
            label: Text(
              item,
              style: const TextStyle(fontSize: 11, color: Colors.white),
            ),
            backgroundColor: Colors.white10,
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildBeweiseSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified, color: const Color(0xFF4CAF50), size: 24),
              const SizedBox(width: 12),
              const Text(
                'BEWEISE',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${behauptung.beweise.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          ...behauptung.beweise.map((beweis) => _buildBeweisKarte(beweis, true)),
        ],
      ),
    );
  }

  Widget _buildGegenbeweiseSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF44336).withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: const Color(0xFFF44336), size: 24),
              const SizedBox(width: 12),
              const Text(
                'GEGENBEWEISE',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF44336).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${behauptung.gegenbeweise.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF44336),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          ...behauptung.gegenbeweise.map((beweis) => _buildBeweisKarte(beweis, false)),
        ],
      ),
    );
  }

  Widget _buildBeweisKarte(Beweismittel beweis, bool isBeweis) {
    final color = isBeweis ? const Color(0xFF4CAF50) : const Color(0xFFF44336);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getBeweisTypBezeichnung(beweis.typ),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (beweis.verifiziert)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 12, color: Colors.blue),
                      const SizedBox(width: 4),
                      const Text(
                        'VERIFIZIERT',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              Text(
                _formatDatum(beweis.datierung),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Text(
            beweis.beschreibung,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          
          // Beweiskraft-Anzeige
          Row(
            children: [
              const Text(
                'Beweiskraft:',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white60,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: beweis.staerke,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(beweis.staerke * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          
          if (beweis.quellenIds.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white10),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: beweis.quellenIds.map((quelle) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.link, size: 10, color: Colors.white60),
                    const SizedBox(width: 4),
                    Text(
                      quelle,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVerbindungenSection() {
    if (behauptung.verbindungenZuAnderenFaellen.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_tree, color: Colors.purple, size: 24),
              const SizedBox(width: 12),
              const Text(
                'VERBINDUNGEN ZU ANDEREN FÄLLEN',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: behauptung.verbindungenZuAnderenFaellen.map((fall) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.withValues(alpha: 0.2),
                    Colors.purple.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.link, size: 14, color: Colors.purple),
                  const SizedBox(width: 6),
                  Text(
                    fall,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadatenSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'METADATEN',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildMetadatenZeile('ID', behauptung.id),
          _buildMetadatenZeile('Erst erwähnt', _formatDatum(behauptung.erstErwaehnt)),
          _buildMetadatenZeile('Letzte Aktualisierung', _formatDatum(behauptung.letztAktualisiert)),
        ],
      ),
    );
  }

  Widget _buildMetadatenZeile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white60,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPlausibilitaetColor(double wert) {
    if (wert >= 0.8) return const Color(0xFF4CAF50);
    if (wert >= 0.5) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  Color _getBeweiskraftColor(double wert) {
    if (wert >= 0.7) return const Color(0xFF4CAF50);
    if (wert >= 0.4) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  String _getBeweisTypBezeichnung(BeweisTyp typ) {
    switch (typ) {
      case BeweisTyp.dokumentiert:
        return 'DOKUMENTIERT';
      case BeweisTyp.zeugnis:
        return 'ZEUGNIS';
      case BeweisTyp.statistisch:
        return 'STATISTISCH';
      case BeweisTyp.logischAbleitung:
        return 'LOGISCH';
      case BeweisTyp.indizienbeweis:
        return 'INDIZIEN';
      case BeweisTyp.anekdotisch:
        return 'ANEKDOTISCH';
    }
  }

  String _formatDatum(DateTime datum) {
    final monate = [
      'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
      'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'
    ];
    return '${datum.day}. ${monate[datum.month - 1]} ${datum.year}';
  }
}
