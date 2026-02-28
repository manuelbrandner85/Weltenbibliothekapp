/// 🧪 RESULT SUMMARY CARD TEST SCREEN
/// 
/// Test screen to preview ResultSummaryCard widget with mock data
library;

import 'package:flutter/material.dart';
import '../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import '../models/recherche_view_state.dart';
import '../widgets/recherche/result_summary_card.dart';
import '../widgets/recherche/mode_selector.dart';

class ResultSummaryCardTestScreen extends StatefulWidget {
  const ResultSummaryCardTestScreen({super.key});

  @override
  State<ResultSummaryCardTestScreen> createState() => _ResultSummaryCardTestScreenState();
}

class _ResultSummaryCardTestScreenState extends State<ResultSummaryCardTestScreen> {
  RechercheMode _selectedMode = RechercheMode.simple;
  double _confidenceLevel = 0.85;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📋 Result Summary Card Test'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Mode Selector
          ModeSelector(
            selectedMode: _selectedMode,
            onModeSelected: (mode) {
              setState(() {
                _selectedMode = mode;
              });
            },
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Result Summary Card
                  ResultSummaryCard(
                    result: _createMockResult(_selectedMode, _confidenceLevel),
                    onShare: () {
                      _showFeedback(context, '📤 Teilen-Funktion');
                    },
                    onSave: () {
                      _showFeedback(context, '💾 Speichern-Funktion');
                    },
                    onViewDetails: () {
                      _showFeedback(context, '👁️ Details anzeigen');
                    },
                  ),
                  
                  // Controls
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🎛️ Steuerung',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Confidence slider
                        Text(
                          'Confidence Level: ${(_confidenceLevel * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        Slider(
                          value: _confidenceLevel,
                          min: 0.0,
                          max: 1.0,
                          divisions: 20,
                          label: '${(_confidenceLevel * 100).toInt()}%',
                          onChanged: (value) {
                            setState(() {
                              _confidenceLevel = value;
                            });
                          },
                        ),
                        
                        // Confidence indicators
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildConfidenceBadge('Niedrig', 0.5, Colors.red),
                            _buildConfidenceBadge('Mittel', 0.7, Colors.orange),
                            _buildConfidenceBadge('Hoch', 0.9, Colors.green),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Info
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Wähle einen Modus und passe die Confidence an',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceBadge(String label, double value, Color color) {
    final isActive = (_confidenceLevel - value).abs() < 0.15;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _confidenceLevel = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.2) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? color : Colors.grey[300]!,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? color : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  RechercheResult _createMockResult(RechercheMode mode, double confidence) {
    final modeData = _getModeData(mode);
    
    return RechercheResult(
      query: modeData['query'] as String,
      mode: mode,
      sources: _createMockSources(mode),
      summary: modeData['summary'] as String,
      keyFindings: modeData['keyFindings'] as List<String>,
      facts: const [],
      rabbitLayers: const [],
      perspectives: const [],
      confidence: confidence,
      metadata: {
        'research_type': mode.name,
        'source_count': _getSourceCount(mode),
      },
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    );
  }

  List<RechercheSource> _createMockSources(RechercheMode mode) {
    final count = _getSourceCount(mode);
    return List.generate(count, (index) {
      return RechercheSource(
        title: 'Quelle ${index + 1}',
        url: 'https://example.com/source${index + 1}',
        excerpt: 'Excerpt from source ${index + 1}',
        relevance: 0.8 - (index * 0.1),
        sourceType: 'article',
        publishDate: DateTime.now().subtract(Duration(days: index + 1)),
      );
    });
  }

  int _getSourceCount(RechercheMode mode) {
    switch (mode) {
      case RechercheMode.simple:
        return 3;
      case RechercheMode.advanced:
        return 6;
      case RechercheMode.deep:
        return 10;
      case RechercheMode.conspiracy:
        return 8;
      case RechercheMode.historical:
        return 7;
      case RechercheMode.scientific:
        return 9;
    }
  }

  Map<String, dynamic> _getModeData(RechercheMode mode) {
    switch (mode) {
      case RechercheMode.simple:
        return {
          'query': 'Was ist künstliche Intelligenz?',
          'summary': 'Künstliche Intelligenz (KI) ist ein Teilgebiet der Informatik, '
              'das sich mit der Automatisierung intelligenten Verhaltens befasst. '
              'Moderne KI-Systeme verwenden maschinelles Lernen und neuronale Netze, '
              'um aus Daten zu lernen und komplexe Aufgaben zu lösen.',
          'keyFindings': [
            'KI umfasst verschiedene Technologien wie maschinelles Lernen und Deep Learning',
            'Moderne KI-Systeme können komplexe Muster in großen Datenmengen erkennen',
            'KI findet Anwendung in vielen Bereichen wie Medizin, Verkehr und Kommunikation',
          ],
        };
        
      case RechercheMode.advanced:
        return {
          'query': 'Klimawandel und erneuerbare Energien',
          'summary': 'Der Klimawandel ist eine der größten Herausforderungen unserer Zeit. '
              'Erneuerbare Energien wie Solar- und Windkraft spielen eine zentrale Rolle '
              'bei der Reduktion von CO2-Emissionen. Aktuelle Studien zeigen, dass ein '
              'vollständiger Umstieg auf erneuerbare Energien bis 2050 technisch und '
              'wirtschaftlich machbar ist, erfordert aber massive Investitionen in Infrastruktur.',
          'keyFindings': [
            'Solarenergie ist die am schnellsten wachsende Energiequelle weltweit',
            'Windkraft kann bis zu 30% des globalen Energiebedarfs decken',
            'Speichertechnologien sind der Schlüssel für stabile Energieversorgung',
            'Kostenparität mit fossilen Brennstoffen wurde bereits erreicht',
            'Politik und Wirtschaft müssen enger zusammenarbeiten',
          ],
        };
        
      case RechercheMode.deep:
        return {
          'query': 'Quantencomputing und Kryptographie',
          'summary': 'Quantencomputing verspricht revolutionäre Fortschritte in der '
              'Rechenleistung, stellt aber gleichzeitig aktuelle Verschlüsselungsmethoden '
              'in Frage. RSA und andere Public-Key-Verfahren könnten durch Quantenalgorithmen '
              'wie Shor\'s Algorithmus gebrochen werden. Die Entwicklung quantensicherer '
              'Kryptographie ist daher von höchster Priorität. Post-Quantum-Kryptographie '
              'entwickelt neue Verfahren, die auch gegen Quantenangriffe resistent sind.',
          'keyFindings': [
            'Quantencomputer könnten aktuelle Verschlüsselung in wenigen Stunden brechen',
            'NIST standardisiert bereits Post-Quantum-Kryptographie-Verfahren',
            'Lattice-basierte Kryptographie gilt als vielversprechendster Ansatz',
            'Hybride Systeme kombinieren klassische und Quanten-Methoden',
            'Migration zu neuen Standards wird Jahre dauern',
            'Harvest-Now-Decrypt-Later-Bedrohung ist akut',
          ],
        };
        
      case RechercheMode.conspiracy:
        return {
          'query': 'Überwachungskapitalismus und Datenschutz',
          'summary': 'Der Begriff "Überwachungskapitalismus" beschreibt ein Wirtschaftsmodell, '
              'bei dem persönliche Daten systematisch gesammelt und kommerziell ausgewertet werden. '
              'Tech-Konzerne wie Google und Facebook haben umfassende Profile von Milliarden Nutzern '
              'erstellt. Kritiker warnen vor einer Erosion der Privatsphäre und Manipulation durch '
              'gezielte Werbung und Inhalte. Alternative Perspektiven argumentieren, dass dies '
              'notwendig für kostenlose Services sei.',
          'keyFindings': [
            'Persönliche Daten werden ohne explizite Zustimmung gesammelt',
            'Algorithmen können Verhalten vorhersagen und beeinflussen',
            'Regulierung wie GDPR zeigt erste Wirkung',
            'Dezentrale Alternativen gewinnen an Bedeutung',
            'Verbindungen zwischen Tech-Firmen und Geheimdiensten existieren',
          ],
        };
        
      case RechercheMode.historical:
        return {
          'query': 'Industrielle Revolution und soziale Auswirkungen',
          'summary': 'Die Industrielle Revolution (1760-1840) markierte einen fundamentalen '
              'Wandel von agrarischen zu industriellen Gesellschaften. Neue Technologien wie '
              'die Dampfmaschine revolutionierten Produktion und Transport. Dies führte zu '
              'massiver Urbanisierung und grundlegenden Veränderungen in Arbeits- und Lebensbedingungen. '
              'Während Wohlstand entstand, waren Arbeitsbedingungen oft unmenschlich.',
          'keyFindings': [
            'Dampfmaschine ermöglichte Mechanisierung der Produktion',
            'Urbanisierung führte zu Entstehung von Arbeiterstädten',
            'Kinderarbeit war weit verbreitet',
            'Gewerkschaften bildeten sich als Reaktion',
            'Grundlage für moderne Wirtschaftssysteme wurde gelegt',
          ],
        };
        
      case RechercheMode.scientific:
        return {
          'query': 'mRNA-Impfstoffe: Wirkungsweise und Effektivität',
          'summary': 'mRNA-Impfstoffe repräsentieren einen innovativen Ansatz in der Immunologie. '
              'Statt abgeschwächte Viren zu verwenden, enthalten sie messenger-RNA, die Körperzellen '
              'anweist, ein virales Protein zu produzieren. Das Immunsystem erkennt dieses Protein '
              'und entwickelt eine Immunantwort. Klinische Studien zeigen eine Effektivität von '
              'über 90% bei COVID-19-Impfstoffen mit milden Nebenwirkungen.',
          'keyFindings': [
            'Phase-3-Studien zeigen hohe Wirksamkeit (>90%)',
            'Technologie ermöglicht schnelle Entwicklung neuer Impfstoffe',
            'Nebenwirkungen sind meist mild und vorübergehend',
            'Langzeitdaten bestätigen Sicherheitsprofil',
            'Anwendung auf andere Krankheiten wird erforscht',
          ],
        };
    }
  }

  void _showFeedback(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
