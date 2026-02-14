import 'package:flutter/material.dart';
import '../widgets/recherche/rabbit_hole_view.dart';
import '../models/recherche_view_state.dart';

/// 🧪 TEST SCREEN: RabbitHoleView Widget
/// 
/// Test-Szenarien:
/// 1. Multi-Layer Rabbit Hole (4 Ebenen)
/// 2. Single Layer
/// 3. Empty State
/// 4. Layer Navigation Test

class RabbitHoleViewTestScreen extends StatefulWidget {
  const RabbitHoleViewTestScreen({super.key});

  @override
  State<RabbitHoleViewTestScreen> createState() => _RabbitHoleViewTestScreenState();
}

class _RabbitHoleViewTestScreenState extends State<RabbitHoleViewTestScreen> {
  String _selectedScenario = 'multi';
  String? _lastTappedSource;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🐰🕳️ RabbitHoleView Test'),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Szenario-Auswahl
          _buildScenarioSelector(),
          const Divider(height: 1),

          // Test Widget
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RabbitHoleView(
                    layers: _getLayers(),
                    onSourceTap: (url) {
                      setState(() => _lastTappedSource = url);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Quelle angeklickt: $url'),
                          backgroundColor: Colors.purple,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Debug Panel
          if (_lastTappedSource != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.purple[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🔍 Letzte Aktion:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Quelle: $_lastTappedSource',
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScenarioSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📋 Test-Szenario:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildScenarioChip('multi', 'Multi-Layer (4 Ebenen)'),
              _buildScenarioChip('single', 'Single Layer'),
              _buildScenarioChip('empty', 'Empty State'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioChip(String value, String label) {
    final isSelected = _selectedScenario == value;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedScenario = value;
            _lastTappedSource = null;
          });
        }
      },
      selectedColor: Colors.purple[100],
      backgroundColor: Colors.white,
    );
  }

  List<RabbitLayer> _getLayers() {
    switch (_selectedScenario) {
      case 'empty':
        return [];

      case 'single':
        return [
          RabbitLayer(
            layerNumber: 1,
            layerName: 'Oberflächenanalyse',
            description: 'Die ersten offensichtlichen Zusammenhänge und öffentlich zugänglichen Informationen.',
            sources: [
              RechercheSource(
                title: 'Wikipedia Artikel',
                url: 'https://wikipedia.org/article',
                excerpt: 'Basic information',
                relevance: 0.85,
                sourceType: 'website',
              ),
              RechercheSource(
                title: 'News Report',
                url: 'https://news.com/report',
                excerpt: 'Latest news',
                relevance: 0.78,
                sourceType: 'article',
              ),
            ],
            connections: [
              'Verbindung zu öffentlichen Datenbanken',
              'Referenzen in Mainstream-Medien',
            ],
            depth: 0.25,
          ),
        ];

      case 'multi':
      default:
        return [
          RabbitLayer(
            layerNumber: 1,
            layerName: 'Oberflächenanalyse',
            description: 'Die ersten offensichtlichen Zusammenhänge. Öffentlich zugängliche Informationen aus Mainstream-Quellen zeigen das offizielle Narrativ und die allgemein akzeptierten Fakten.',
            sources: [
              RechercheSource(
                title: 'Wikipedia - Grundlagen',
                url: 'https://wikipedia.org/topic-basics',
                excerpt: 'Comprehensive overview',
                relevance: 0.92,
                sourceType: 'website',
              ),
              RechercheSource(
                title: 'BBC News Coverage',
                url: 'https://bbc.com/news/topic',
                excerpt: 'Mainstream news coverage',
                relevance: 0.88,
                sourceType: 'article',
              ),
              RechercheSource(
                title: 'Government Official Statement',
                url: 'https://gov.uk/statement',
                excerpt: 'Official position',
                relevance: 0.85,
                sourceType: 'document',
              ),
            ],
            connections: [
              'Verweise auf offizielle Regierungsdokumente',
              'Zitate von etablierten Experten',
              'Querverweise zu akademischen Grundlagentexten',
            ],
            depth: 0.20,
          ),
          RabbitLayer(
            layerNumber: 2,
            layerName: 'Versteckte Verbindungen',
            description: 'Tiefere Analyse offenbart weniger offensichtliche Zusammenhänge. Finanzielle Verflechtungen, historische Kontexte und beteiligte Akteure werden sichtbar. Die offiziellen Narrative beginnen, Risse zu zeigen.',
            sources: [
              RechercheSource(
                title: 'Follow The Money Database',
                url: 'https://followmoney.org/connections',
                excerpt: 'Financial connections',
                relevance: 0.82,
                sourceType: 'database',
              ),
              RechercheSource(
                title: 'Investigative Journalism Report',
                url: 'https://propublica.org/investigation',
                excerpt: 'Deep dive investigation',
                relevance: 0.78,
                sourceType: 'article',
              ),
              RechercheSource(
                title: 'Academic Critical Analysis',
                url: 'https://jstor.org/critical-paper',
                excerpt: 'Scholarly critique',
                relevance: 0.75,
                sourceType: 'document',
              ),
              RechercheSource(
                title: 'Leaked Internal Documents',
                url: 'https://wikileaks.org/docs',
                excerpt: 'Internal communications',
                relevance: 0.88,
                sourceType: 'document',
              ),
            ],
            connections: [
              'Finanzielle Verbindungen zwischen Schlüsselakteuren',
              'Historische Präzedenzfälle mit ähnlichen Mustern',
              'Think Tanks und ihre Einflüsse auf Policy',
              'Lobbyist-Register zeigt versteckte Interessengruppen',
            ],
            depth: 0.45,
          ),
          RabbitLayer(
            layerNumber: 3,
            layerName: 'Systemische Muster',
            description: 'Wiederkehrende Strukturen werden erkennbar. Das große Bild formt sich: Machtverhältnisse, systematische Vorgehensweisen und langfristige Strategien offenbaren sich. Wir verlassen den Bereich gesicherter Fakten und betreten den Raum fundierter Theorien.',
            sources: [
              RechercheSource(
                title: 'Systems Theory Analysis',
                url: 'https://systemstheory.org/analysis',
                excerpt: 'Pattern recognition',
                relevance: 0.72,
                sourceType: 'article',
              ),
              RechercheSource(
                title: 'Historical Pattern Comparison',
                url: 'https://historypatterns.org/comparison',
                excerpt: 'Historical parallels',
                relevance: 0.68,
                sourceType: 'document',
              ),
              RechercheSource(
                title: 'Power Structure Research',
                url: 'https://powerresearch.org/structures',
                excerpt: 'Elite network analysis',
                relevance: 0.70,
                sourceType: 'article',
              ),
              RechercheSource(
                title: 'Alternative Media Investigation',
                url: 'https://altmedia.org/deep-investigation',
                excerpt: 'Independent research',
                relevance: 0.65,
                sourceType: 'website',
              ),
              RechercheSource(
                title: 'Whistleblower Testimonies',
                url: 'https://whistleblowers.org/testimonies',
                excerpt: 'Insider accounts',
                relevance: 0.75,
                sourceType: 'document',
              ),
            ],
            connections: [
              'Verbindungen zu historischen Operationen (Operation Mockingbird, etc.)',
              'Netzwerk-Analyse zeigt Elite-Verbindungen (Council on Foreign Relations, etc.)',
              'Wiederkehrende Muster in scheinbar unabhängigen Events',
              'Think Tank Papiere aus den 1970ern beschreiben heutige Strategien',
              'Geopolitische Langzeitstrategien (Brzezinski, Kissinger)',
            ],
            depth: 0.70,
          ),
          RabbitLayer(
            layerNumber: 4,
            layerName: 'Fundamentale Strukturen',
            description: 'Die tiefsten Ebenen der Analyse. Hier treffen wir auf philosophische Fragen über Macht, Kontrolle und gesellschaftliche Organisation. Die Grenze zwischen nachweisbaren Fakten und spekulativen Theorien verschwimmt. Vorsicht: Ab hier wird es hochgradig interpretativ.',
            sources: [
              RechercheSource(
                title: 'Deep Politics Framework',
                url: 'https://deeppolitics.org/framework',
                excerpt: 'Structural analysis',
                relevance: 0.58,
                sourceType: 'article',
              ),
              RechercheSource(
                title: 'Shadow Government Research',
                url: 'https://shadowgov.org/research',
                excerpt: 'Hidden structures',
                relevance: 0.55,
                sourceType: 'document',
              ),
              RechercheSource(
                title: 'Ancient Power Structures',
                url: 'https://ancientpower.org/structures',
                excerpt: 'Historical continuity',
                relevance: 0.52,
                sourceType: 'article',
              ),
              RechercheSource(
                title: 'Occult Symbolism Analysis',
                url: 'https://symbolanalysis.org/occult',
                excerpt: 'Symbolic communication',
                relevance: 0.48,
                sourceType: 'website',
              ),
              RechercheSource(
                title: 'Alternative History Archives',
                url: 'https://althistory.org/archives',
                excerpt: 'Suppressed information',
                relevance: 0.50,
                sourceType: 'database',
              ),
              RechercheSource(
                title: 'Conspiracy Research Compendium',
                url: 'https://conspiracyresearch.org/compendium',
                excerpt: 'Comprehensive theories',
                relevance: 0.45,
                sourceType: 'document',
              ),
            ],
            connections: [
              'Verbindungen zu geheimen Gesellschaften (Skull & Bones, etc.)',
              'Familienlinien der Macht über Jahrhunderte',
              'Okkultismus in Eliten-Kreisen (Bohemian Grove, etc.)',
              'Transhumanismus-Agenda und technokratische Zukunftsvisionen',
              'Verbindungen zu alten Mystery Schools und Esoterik',
              'NWO-Blueprint Dokumente (UN Agenda 2030, etc.)',
              'Predictive Programming in Medien',
            ],
            depth: 0.95,
          ),
        ];
    }
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ℹ️ RabbitHoleView Info'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '📋 Features:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Layer-Karten mit Ebenen-Nummer', style: TextStyle(fontSize: 12)),
              Text('• Depth Indicator (0-100%)', style: TextStyle(fontSize: 12)),
              Text('• Depth Color-Coding', style: TextStyle(fontSize: 12)),
              Text('• Expandierbarer Layer', style: TextStyle(fontSize: 12)),
              Text('• Sources als Chips', style: TextStyle(fontSize: 12)),
              Text('• Connections Liste', style: TextStyle(fontSize: 12)),
              Text('• Layer Navigation (>1 Layer)', style: TextStyle(fontSize: 12)),
              Text('• Overall Depth Progress', style: TextStyle(fontSize: 12)),
              SizedBox(height: 12),
              Text(
                '🎨 Depth Color-Coding:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• 0-30%: Grün (Oberflächlich)', style: TextStyle(fontSize: 12)),
              Text('• 30-60%: Orange (Mittel)', style: TextStyle(fontSize: 12)),
              Text('• 60-100%: Rot (Tief)', style: TextStyle(fontSize: 12)),
              SizedBox(height: 12),
              Text(
                '🧪 Test-Szenarien:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Multi-Layer: 4 Ebenen, Navigation aktiv', style: TextStyle(fontSize: 12)),
              Text('• Single Layer: 1 Ebene', style: TextStyle(fontSize: 12)),
              Text('• Empty: Empty State', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }
}
