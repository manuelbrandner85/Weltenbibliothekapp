/// 🧪 FACTS LIST TEST SCREEN
/// 
/// Test screen to preview FactsList widget with mock data
library;

import 'package:flutter/material.dart';
import '../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import '../models/recherche_view_state.dart';
import '../widgets/recherche/facts_list.dart';
import '../widgets/recherche/mode_selector.dart';

class FactsListTestScreen extends StatefulWidget {
  const FactsListTestScreen({super.key});

  @override
  State<FactsListTestScreen> createState() => _FactsListTestScreenState();
}

class _FactsListTestScreenState extends State<FactsListTestScreen> {
  RechercheMode _selectedMode = RechercheMode.advanced;
  bool _showSearch = true;
  int _factCount = 10;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📝 Facts List Test'),
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
                  // Facts List Widget
                  FactsList(
                    facts: _getMockFacts(_selectedMode, _factCount),
                    title: 'Fakten - ${_getModeDisplayName(_selectedMode)}',
                    showSearch: _showSearch,
                    onFactCopied: () {
                      // Callback when fact is copied
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
                        
                        // Show search toggle
                        SwitchListTile(
                          title: const Text('Suchfunktion anzeigen'),
                          subtitle: Text(
                            _showSearch ? 'Aktiviert' : 'Deaktiviert',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          value: _showSearch,
                          onChanged: (value) {
                            setState(() {
                              _showSearch = value;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Fact count slider
                        Text(
                          'Anzahl Fakten: $_factCount',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        Slider(
                          value: _factCount.toDouble(),
                          min: 0,
                          max: 15,
                          divisions: 15,
                          label: '$_factCount',
                          onChanged: (value) {
                            setState(() {
                              _factCount = value.toInt();
                            });
                          },
                        ),
                        
                        // Quick select buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildQuickButton('0', 0),
                            _buildQuickButton('5', 5),
                            _buildQuickButton('10', 10),
                            _buildQuickButton('15', 15),
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
                                  'Halte einen Fakt gedrückt oder klicke das Kopier-Icon',
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

  Widget _buildQuickButton(String label, int count) {
    final isActive = _factCount == count;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _factCount = count;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).primaryColor
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? Theme.of(context).primaryColor
                : Colors.grey[300]!,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  List<String> _getMockFacts(RechercheMode mode, int count) {
    if (count == 0) return [];
    
    final allFacts = _getAllFactsForMode(mode);
    return allFacts.take(count).toList();
  }

  List<String> _getAllFactsForMode(RechercheMode mode) {
    switch (mode) {
      case RechercheMode.simple:
        return [
          'Künstliche Intelligenz umfasst maschinelles Lernen und Deep Learning Technologien',
          'KI-Systeme können Muster in großen Datenmengen erkennen und analysieren',
          'Machine Learning ermöglicht Computern, aus Erfahrungen zu lernen',
          'Neuronale Netze sind von biologischen Gehirnstrukturen inspiriert',
          'KI findet Anwendung in Medizin, Verkehr, Kommunikation und vielen anderen Bereichen',
        ];
        
      case RechercheMode.advanced:
        return [
          'Solarenergie ist mit über 30% Wachstum die am schnellsten expandierende Energiequelle weltweit',
          'Windkraft kann theoretisch bis zu 30% des globalen Energiebedarfs decken',
          'Kostenparität zwischen erneuerbaren und fossilen Energien wurde 2019 erreicht',
          'Speichertechnologien sind der Schlüsselfaktor für stabile Energieversorgung',
          'Lithium-Ionen-Batterien dominieren mit 85% Marktanteil den Speichermarkt',
          'Power-to-Gas Technologie ermöglicht langfristige Energiespeicherung',
          'Smart Grids reduzieren Energieverluste um bis zu 20%',
          'Offshore-Windparks erzielen Kapazitätsfaktoren von über 50%',
          'Floating Solar-Anlagen sparen 70% Landfläche im Vergleich zu traditionellen Parks',
          'Grüner Wasserstoff wird als Schlüsseltechnologie für Dekarbonisierung gesehen',
        ];
        
      case RechercheMode.deep:
        return [
          'Shor\'s Algorithmus kann RSA-2048 Verschlüsselung in wenigen Stunden brechen',
          'NIST hat 2022 erste Post-Quantum-Kryptographie Standards veröffentlicht',
          'Lattice-basierte Kryptographie gilt als resistentester Ansatz gegen Quantenangriffe',
          'Quantencomputer mit 4000 logischen Qubits könnten RSA knacken',
          'Google erreichte 2019 Quantum Supremacy mit 53 Qubits',
          'Harvest-Now-Decrypt-Later Angriffe sind bereits im Gange',
          'Hybride Kryptosysteme kombinieren klassische und Post-Quantum-Verfahren',
          'CRYSTALS-Kyber wurde als Standard für Key-Encapsulation ausgewählt',
          'Migration zu Post-Quantum-Krypto dauert geschätzt 10-15 Jahre',
          'IBM erreichte 2023 über 1000 Qubits mit Eagle Processor',
          'Fehlerkorrektur bleibt größte Herausforderung für praktische Quantencomputer',
          'Topologische Qubits versprechen höhere Stabilität und Fehlerresistenz',
        ];
        
      case RechercheMode.conspiracy:
        return [
          'Facebook sammelt Daten über 52.000 Datenpunkte pro Nutzer',
          'PRISM-Programm der NSA überwachte 9 große Tech-Unternehmen direkt',
          'Cambridge Analytica sammelte Daten von 87 Millionen Facebook-Nutzern',
          'Google trackt Standortdaten auch bei deaktivierter Ortungsfunktion',
          'Behaviorale Vorhersagemodelle erreichen 95% Genauigkeit',
          'Tech-Firmen teilen Daten mit über 1000 Drittanbietern',
          'Dark Patterns manipulieren 70% der Nutzer zu ungewollten Entscheidungen',
          'Personalisierte Werbung generiert 70% mehr Revenue als generische Ads',
        ];
        
      case RechercheMode.historical:
        return [
          'James Watt patentierte die Dampfmaschine 1769 und revolutionierte die Produktion',
          'Manchester wuchs von 25.000 (1772) auf 303.000 (1850) Einwohner',
          'Kinderarbeit betraf 1840 über 50% der Textilarbeiter in England',
          'Arbeitszeiten von 14-16 Stunden täglich waren Standard in Fabriken',
          'Trade Unions Act 1871 legalisierte Gewerkschaften in Großbritannien',
          'Industrielle Revolution steigerte BIP pro Kopf um 300% in 100 Jahren',
          'Lebenserwartung in Industriestädten sank zunächst um 10 Jahre',
          'Eisenbahn-Netz wuchs in GB von 0 (1825) auf 10.000 km (1850)',
        ];
        
      case RechercheMode.scientific:
        return [
          'Pfizer/BioNTech Phase-3-Studie zeigte 95% Wirksamkeit (N=43.548)',
          'Moderna Studie erreichte 94.1% Effektivität (N=30.000)',
          'mRNA-Technologie entwickelt seit 1990, erste Humanstudien 2013',
          'Nebenwirkungen meist mild: Schmerzen (84%), Müdigkeit (62%), Kopfschmerz (55%)',
          'Schutz vor schwerer Erkrankung über 90% auch nach 6 Monaten',
          'Booster erhöht Antikörperspiegel um das 15-fache',
          'Technologie anwendbar auf Krebs, HIV, Malaria und andere Krankheiten',
          'Produktionszeit von 6-12 Monate auf 2-3 Monate reduziert',
          'Langzeitdaten über 2 Jahre zeigen kein erhöhtes Risiko',
        ];
    }
  }

  String _getModeDisplayName(RechercheMode mode) {
    switch (mode) {
      case RechercheMode.simple:
        return 'Simple';
      case RechercheMode.advanced:
        return 'Advanced';
      case RechercheMode.deep:
        return 'Deep Dive';
      case RechercheMode.conspiracy:
        return 'Conspiracy';
      case RechercheMode.historical:
        return 'Historical';
      case RechercheMode.scientific:
        return 'Scientific';
    }
  }
}
