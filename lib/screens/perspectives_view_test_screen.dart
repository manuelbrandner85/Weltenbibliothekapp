import 'package:flutter/material.dart';
import 'package:weltenbibliothek/services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import '../widgets/recherche/perspectives_view.dart';
import '../models/recherche_view_state.dart';

/// 🧪 TEST SCREEN: PerspectivesView Widget
/// 
/// Test-Szenarien:
/// 1. Mehrere Perspektiven (alle Typen)
/// 2. Filter-Funktionalität
/// 3. Expand/Collapse
/// 4. Credibility Scores
/// 5. Arguments & Sources
/// 6. Empty State

class PerspectivesViewTestScreen extends StatefulWidget {
  const PerspectivesViewTestScreen({super.key});

  @override
  State<PerspectivesViewTestScreen> createState() => _PerspectivesViewTestScreenState();
}

class _PerspectivesViewTestScreenState extends State<PerspectivesViewTestScreen> {
  String _selectedScenario = 'full';
  String? _lastTappedSource;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔮 PerspectivesView Test'),
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
                  PerspectivesView(
                    perspectives: _getPerspectives(),
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
              _buildScenarioChip('full', 'Vollständig (4 Perspektiven)'),
              _buildScenarioChip('minimal', 'Minimal (2 Perspektiven)'),
              _buildScenarioChip('empty', 'Leer (0 Perspektiven)'),
              _buildScenarioChip('single', 'Einzeln (1 Perspektive)'),
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

  List<Perspective> _getPerspectives() {
    switch (_selectedScenario) {
      case 'empty':
        return [];

      case 'single':
        return [
          Perspective(
            perspectiveName: 'Wissenschaftliche Sicht',
            viewpoint: 'Eine evidenzbasierte Analyse zeigt klare Zusammenhänge zwischen den beobachteten Phänomenen.',
            arguments: [
              'Peer-reviewed Studien bestätigen die Hypothese',
              'Empirische Daten zeigen signifikante Korrelationen',
              'Reproduzierbare Experimente unterstützen die Theorie',
            ],
            supportingSources: [
              RechercheSource(
                title: 'Nature Journal 2023',
                url: 'https://nature.com/article-123',
                excerpt: 'Peer-reviewed study',
                relevance: 0.95,
                sourceType: 'article',
              ),
              RechercheSource(
                title: 'Science Daily Report',
                url: 'https://sciencedaily.com/report-456',
                excerpt: 'Daily science news',
                relevance: 0.88,
                sourceType: 'article',
              ),
              RechercheSource(
                title: 'MIT Research Paper',
                url: 'https://mit.edu/research/789',
                excerpt: 'Research paper',
                relevance: 0.92,
                sourceType: 'document',
              ),
            ],
            credibility: 9.2,
            type: PerspectiveType.supporting,
          ),
        ];

      case 'minimal':
        return [
          Perspective(
            perspectiveName: 'Befürwortende Position',
            viewpoint: 'Diese Sichtweise unterstützt die Hauptthese.',
            arguments: ['Argument 1', 'Argument 2'],
            supportingSources: [
              RechercheSource(
                title: 'Quelle A',
                url: 'https://example.com/source-a',
                excerpt: 'Supporting source',
                relevance: 0.85,
                sourceType: 'article',
              ),
            ],
            credibility: 8.0,
            type: PerspectiveType.supporting,
          ),
          Perspective(
            perspectiveName: 'Kritische Perspektive',
            viewpoint: 'Es gibt berechtigte Zweifel an dieser Interpretation.',
            arguments: ['Gegenargument 1', 'Gegenargument 2'],
            supportingSources: [
              RechercheSource(
                title: 'Quelle B',
                url: 'https://example.com/source-b',
                excerpt: 'Critical source',
                relevance: 0.78,
                sourceType: 'article',
              ),
            ],
            credibility: 7.5,
            type: PerspectiveType.opposing,
          ),
        ];

      case 'full':
      default:
        return [
          Perspective(
            perspectiveName: 'Wissenschaftliche Mainstream-Sicht',
            viewpoint: 'Die etablierte wissenschaftliche Gemeinschaft sieht überwältigende Beweise für den anthropogenen Klimawandel. Klimamodelle, Temperaturdaten und Eiskernbohrungen zeigen eindeutige Trends, die auf menschliche Aktivitäten zurückzuführen sind.',
            arguments: [
              'CO2-Konzentration ist seit 1950 um 50% gestiegen',
              'Globale Durchschnittstemperatur steigt messbar an',
              'Extreme Wetterereignisse nehmen signifikant zu',
              '97% aller Klimaforscher stimmen überein',
              'Arktisches Eis schmilzt in Rekordgeschwindigkeit',
            ],
            supportingSources: [
              RechercheSource(
                title: 'IPCC Climate Report 2023',
                url: 'https://ipcc.ch/report-2023',
                excerpt: 'Climate change assessment',
                relevance: 0.98,
                sourceType: 'document',
              ),
              RechercheSource(
                title: 'NASA Climate Data',
                url: 'https://nasa.gov/climate-data',
                excerpt: 'Climate monitoring data',
                relevance: 0.96,
                sourceType: 'website',
              ),
              RechercheSource(
                title: 'Nature Climate Journal',
                url: 'https://nature.com/climate',
                excerpt: 'Climate research journal',
                relevance: 0.94,
                sourceType: 'article',
              ),
              RechercheSource(
                title: 'World Meteorological Organization',
                url: 'https://wmo.int',
                excerpt: 'Weather and climate organization',
                relevance: 0.92,
                sourceType: 'website',
              ),
            ],
            credibility: 9.5,
            type: PerspectiveType.supporting,
          ),
          Perspective(
            perspectiveName: 'Klimaskeptische Position',
            viewpoint: 'Kritiker argumentieren, dass natürliche Klimaschwankungen unterschätzt werden. Sie verweisen auf historische Warmperioden und stellen die Genauigkeit von Klimamodellen in Frage.',
            arguments: [
              'Klimawandel gab es schon immer in der Erdgeschichte',
              'Mittelalterliche Warmzeit war ohne CO2-Anstieg',
              'Sonnenaktivität wird als Faktor unterschätzt',
              'Klimamodelle haben in der Vergangenheit versagt',
              'Messdaten sind teilweise unzuverlässig',
            ],
            supportingSources: [
              RechercheSource(
                title: 'Climate Change Reconsidered',
                url: 'https://climatechangereconsidered.org',
                excerpt: 'Alternative climate analysis',
                relevance: 0.42,
                sourceType: 'website',
              ),
              RechercheSource(
                title: 'Heartland Institute Papers',
                url: 'https://heartland.org/papers',
                excerpt: 'Climate skepticism research',
                relevance: 0.38,
                sourceType: 'document',
              ),
              RechercheSource(
                title: 'Alternative Climate Research',
                url: 'https://altclimate.org',
                excerpt: 'Alternative climate perspectives',
                relevance: 0.35,
                sourceType: 'website',
              ),
            ],
            credibility: 3.8,
            type: PerspectiveType.opposing,
          ),
          Perspective(
            perspectiveName: 'Neutrale Vermittlungsposition',
            viewpoint: 'Eine vermittelnde Sicht erkennt sowohl die Evidenz für menschengemachten Klimawandel als auch Unsicherheiten in Prognosen an. Der Fokus liegt auf pragmatischen Lösungen statt ideologischen Grabenkämpfen.',
            arguments: [
              'Klimawandel ist real, aber Ausmaß ist unsicher',
              'Sowohl natürliche als auch anthropogene Faktoren spielen eine Rolle',
              'Technologische Innovation wichtiger als Panikmache',
              'Wirtschaftliche Folgen müssen berücksichtigt werden',
            ],
            supportingSources: [
              RechercheSource(
                title: 'Pragmatic Climate Policy Journal',
                url: 'https://pragmaticclimate.org/journal',
                excerpt: 'Balanced climate policy research',
                relevance: 0.72,
                sourceType: 'article',
              ),
              RechercheSource(
                title: 'Economic Impact Studies',
                url: 'https://economics.org/climate-impact',
                excerpt: 'Economic analysis of climate policy',
                relevance: 0.68,
                sourceType: 'document',
              ),
              RechercheSource(
                title: 'Technology Review Articles',
                url: 'https://techreview.com/climate',
                excerpt: 'Technology and climate solutions',
                relevance: 0.70,
                sourceType: 'article',
              ),
            ],
            credibility: 7.2,
            type: PerspectiveType.neutral,
          ),
          Perspective(
            perspectiveName: 'Alternative Systemkritik',
            viewpoint: 'Diese Perspektive sieht den Klimawandel als Symptom eines tieferliegenden Problems: das kapitalistische Wachstumsparadigma. Echte Lösungen erfordern einen radikalen Systemwandel, nicht nur technische Anpassungen.',
            arguments: [
              'Grüner Kapitalismus ist ein Widerspruch in sich',
              'Endloses Wachstum ist auf endlichem Planeten unmöglich',
              'Konzerne nutzen Klimaschutz für Greenwashing',
              'Echte Lösung erfordert Postwachstumsökonomie',
            ],
            supportingSources: [
              RechercheSource(
                title: 'Degrowth Movement Papers',
                url: 'https://degrowth.org/papers',
                excerpt: 'Post-growth economic theory',
                relevance: 0.65,
                sourceType: 'document',
              ),
              RechercheSource(
                title: 'System Change Publications',
                url: 'https://systemchange.org/publications',
                excerpt: 'Systemic change research',
                relevance: 0.62,
                sourceType: 'document',
              ),
              RechercheSource(
                title: 'Alternative Economics Journal',
                url: 'https://alteconomics.org/journal',
                excerpt: 'Alternative economic models',
                relevance: 0.60,
                sourceType: 'article',
              ),
            ],
            credibility: 6.5,
            type: PerspectiveType.alternative,
          ),
        ];
    }
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ℹ️ PerspectivesView Info'),
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
              Text('• Perspektiven-Karten mit Typ-Badge', style: TextStyle(fontSize: 12)),
              Text('• Credibility Score (Sterne 0-5)', style: TextStyle(fontSize: 12)),
              Text('• Expandierbarer Viewpoint', style: TextStyle(fontSize: 12)),
              Text('• Nummerierte Arguments', style: TextStyle(fontSize: 12)),
              Text('• Supporting Sources als Chips', style: TextStyle(fontSize: 12)),
              Text('• Filter nach Typ (>3 Perspektiven)', style: TextStyle(fontSize: 12)),
              Text('• Typ-spezifische Farben', style: TextStyle(fontSize: 12)),
              SizedBox(height: 12),
              Text(
                '🎨 Typ-Farben:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Supporting: Grün', style: TextStyle(fontSize: 12)),
              Text('• Opposing: Rot', style: TextStyle(fontSize: 12)),
              Text('• Neutral: Grau', style: TextStyle(fontSize: 12)),
              Text('• Alternative: Blau', style: TextStyle(fontSize: 12)),
              SizedBox(height: 12),
              Text(
                '🧪 Test-Szenarien:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Vollständig: 4 Perspektiven, Filter aktiv', style: TextStyle(fontSize: 12)),
              Text('• Minimal: 2 Perspektiven', style: TextStyle(fontSize: 12)),
              Text('• Einzeln: 1 Perspektive', style: TextStyle(fontSize: 12)),
              Text('• Leer: Empty State', style: TextStyle(fontSize: 12)),
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
