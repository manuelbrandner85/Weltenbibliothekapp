import 'package:flutter/material.dart';
import '../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0

class EventPredictorScreen extends StatefulWidget {
  const EventPredictorScreen({super.key});

  @override
  State<EventPredictorScreen> createState() => _EventPredictorScreenState();
}

class _EventPredictorScreenState extends State<EventPredictorScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'all';
  List<Map<String, dynamic>>? _predictions;
  List<Map<String, dynamic>>? _filteredPredictions;
  bool _isLoading = false;

  final Map<String, List<Map<String, dynamic>>> _predictionDatabase = {
    'economy': [
      {
        'title': 'Globale Wirtschaftskrise 2025',
        'probability': 68,
        'timeframe': '2025-Q2',
        'category': 'economy',
        'patterns': ['Ähnlich 2008', 'Schuldenblase', 'Zinszyklen', 'Inflation 1970er'],
        'indicators': [
          'Inflation >7% in Industrieländern',
          'Zentralbanken heben Zinsen auf 5%+',
          'Aktienmarkt volatil (-20% Korrekturen)',
          'Immobilienpreise fallen in USA/EU'
        ],
        'description': 'Historische Schuldenblasen führen zu Finanzkrisen. Aktuelle Zinspolitik verschärft wirtschaftliche Spannungen.',
        'alternativePerspektive': 'Mainstream verschweigt: Fiat-Geldsystem am Ende. Alternative: Bitcoin & Edelmetalle als Schutz.',
      },
      {
        'title': 'Euro-Krise 2.0',
        'probability': 55,
        'timeframe': '2025-2026',
        'category': 'economy',
        'patterns': ['Euro-Krise 2011-2013', 'Staatsschuldenkrise', 'Währungsreformen'],
        'indicators': [
          'Italien Schuldenquote >150%',
          'EZB Bondaufkäufe steigen',
          'Süd-Nord-Spreads ausweiten',
          'Politische Fragmentierung EU'
        ],
        'description': 'Strukturprobleme der Eurozone ungelöst. Südländer-Schulden nicht tragfähig.',
        'alternativePerspektive': 'Medien verschweigen: EU-Zentralisierung gescheitert. Dezentrale Lösungen nötig.',
      },
      {
        'title': 'BRICS-Währung Launch',
        'probability': 42,
        'timeframe': '2024-2025',
        'category': 'economy',
        'patterns': ['Petrodollar Ende', 'Goldrückdeckung', 'Bretton Woods'],
        'indicators': [
          'Russland/China Handel in Yuan',
          'Goldreserven BRICS steigen',
          'De-Dollarisierung beschleunigt',
          'Saudi-Arabien Ölverkauf auch Yuan'
        ],
        'description': 'BRICS-Staaten arbeiten an Dollar-Alternative. Gold-gedeckte Währung geplant.',
        'alternativePerspektive': 'Mainstream ignoriert: Multipolare Weltordnung entsteht. Dollar-Hegemonie endet.',
      },
    ],
    'politics': [
      {
        'title': 'Geopolitische Eskalation Europa',
        'probability': 72,
        'timeframe': '2024-2025',
        'category': 'politics',
        'patterns': ['Kalter Krieg', 'Balkan 1990er', 'Weltkriege Vorspiel'],
        'indicators': [
          'NATO-Russland Spannungen maximal',
          'Militärausgaben steigen EU >2%',
          'Wehrpflicht-Diskussionen',
          'Propaganda auf allen Seiten'
        ],
        'description': 'Historisch: Militarisierung führt zu Konflikten. Rhetorik verschärft sich.',
        'alternativePerspektive': 'Medien heizen an: Waffenlobby profitiert. Friedensbewegung totgeschwiegen.',
      },
      {
        'title': 'EU-Fragmentierung',
        'probability': 58,
        'timeframe': '2025-2027',
        'category': 'politics',
        'patterns': ['Brexit 2016', 'Sowjetunion Zerfall', 'Jugoslawien'],
        'indicators': [
          'Rechtspopulisten stärker',
          'EU-Kritik steigt',
          'Nationale Souveränität Thema',
          'Brüssel-Distanz wächst'
        ],
        'description': 'Zentrifugale Kräfte in EU stärker. Mitgliedstaaten wollen Souveränität zurück.',
        'alternativePerspektive': 'Elite verschweigt: Demokratiedefizit EU nicht lösbar. Dezentralisierung ist Zukunft.',
      },
      {
        'title': 'Globale Zensur-Infrastruktur',
        'probability': 75,
        'timeframe': '2024-2026',
        'category': 'politics',
        'patterns': ['Patriot Act 2001', 'Notstandsgesetze', 'Ermächtigungsgesetze'],
        'indicators': [
          'Digital Services Act EU',
          'Online Safety Bill UK',
          'AI-Content-Moderation',
          'Deplatforming steigt'
        ],
        'description': 'Regierungen bauen digitale Kontrollsysteme aus. Meinungsfreiheit bedroht.',
        'alternativePerspektive': 'Mainstream verschweigt: Orwellsche Überwachung kommt. Dezentrale Plattformen Widerstand.',
      },
    ],
    'technology': [
      {
        'title': 'KI-Superintelligenz Durchbruch',
        'probability': 45,
        'timeframe': '2025-2027',
        'category': 'technology',
        'patterns': ['Industrielle Revolution', 'Internet 1990er', 'Atomenergie'],
        'indicators': [
          'GPT-5+ Fähigkeiten exponentiell',
          'AGI-Forschung beschleunigt',
          'KI-Investment >100 Mrd/Jahr',
          'Regulierungsdebatte intensiv'
        ],
        'description': 'KI-Entwicklung exponentiell. Superintelligenz könnte Arbeitsmärkte revolutionieren.',
        'alternativePerspektive': 'Tech-Konzerne verschweigen: Jobverlust massiv. Bedingungsloses Einkommen nötig.',
      },
      {
        'title': 'Quantencomputer-Revolution',
        'probability': 38,
        'timeframe': '2026-2028',
        'category': 'technology',
        'patterns': ['Manhattan Project', 'Moores Law Ende', 'Kryptographie-Brüche'],
        'indicators': [
          'Qubit-Zahlen steigen',
          'Fehlerkorrektur verbessert',
          'Krypto-Migration startet',
          'Nationale Quanten-Programme'
        ],
        'description': 'Quantencomputer bedrohen aktuelle Verschlüsselung. Umstellung notwendig.',
        'alternativePerspektive': 'Sicherheitsbehörden verschweigen: Totale Überwachung möglich. Bitcoin gefährdet.',
      },
      {
        'title': 'Dezentrales Internet (Web3)',
        'probability': 52,
        'timeframe': '2024-2026',
        'category': 'technology',
        'patterns': ['Internet Anfänge', 'Open-Source Bewegung', 'Punk-Ethos'],
        'indicators': [
          'Blockchain-Adoption steigt',
          'Dezentrale Apps wachsen',
          'Zensurresistenz Thema',
          'Big Tech Kontrollverlust'
        ],
        'description': 'Web3-Technologien ermöglichen zensurresistente Infrastruktur.',
        'alternativePerspektive': 'Mainstream bekämpft: Dezentralisierung bedroht Kontrollstrukturen.',
      },
    ],
    'society': [
      {
        'title': 'Massenmigration Europa',
        'probability': 66,
        'timeframe': '2024-2026',
        'category': 'society',
        'patterns': ['Völkerwanderung', 'Fluchtbewegungen 2015', 'Klimamigration'],
        'indicators': [
          'Klimakrise verschärft',
          'Konflikte Nahost/Afrika',
          'Grenzsicherung Thema',
          'Soziale Spannungen steigen'
        ],
        'description': 'Klimawandel und Konflikte treiben Migrationsströme. Europa unvorbereitet.',
        'alternativePerspektive': 'Politik verschweigt: Ursachen (Kriege, Ausbeutung) nicht angegangen.',
      },
      {
        'title': 'Gesellschaftliche Polarisierung',
        'probability': 78,
        'timeframe': '2024-2025',
        'category': 'society',
        'patterns': ['Weimarer Republik', 'USA 1960er', 'Klassenkämpfe'],
        'indicators': [
          'Echo-Kammern Social Media',
          'Vertrauen Institutionen sinkt',
          'Extremismus links/rechts',
          'Dialog bricht ab'
        ],
        'description': 'Gesellschaft zerfällt in unversöhnliche Lager. Dialog unmöglich.',
        'alternativePerspektive': 'Medien spalten bewusst: Teile-und-Herrsche-Strategie der Elite.',
      },
      {
        'title': 'Digitale Überwachungsgesellschaft',
        'probability': 82,
        'timeframe': '2024-2026',
        'category': 'society',
        'patterns': ['China Social Credit', '1984 Orwell', 'Stasi DDR'],
        'indicators': [
          'Gesichtserkennung flächendeckend',
          'Digitaler Euro mit Tracking',
          'Bewegungsprofile Standard',
          'Private Datensammlung'
        ],
        'description': 'Technologie ermöglicht totalitäre Überwachung. Privatsphäre verschwindet.',
        'alternativePerspektive': 'Regierungen verschweigen: Social-Credit-System nach chinesischem Vorbild geplant.',
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadAllPredictions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadAllPredictions() {
    setState(() {
      _isLoading = true;
    });

    // Simuliere API-Call
    Future.delayed(const Duration(milliseconds: 500), () {
      final allPredictions = <Map<String, dynamic>>[];
      _predictionDatabase.forEach((category, predictions) {
        allPredictions.addAll(predictions);
      });
      
      // Sortiere nach Wahrscheinlichkeit
      allPredictions.sort((a, b) => (b['probability'] as int).compareTo(a['probability'] as int));
      
      setState(() {
        _predictions = allPredictions;
        _filteredPredictions = allPredictions;
        _isLoading = false;
      });
    });
  }

  void _searchPredictions(String query) {
    if (_predictions == null) return;
    
    setState(() {
      if (query.isEmpty) {
        _filteredPredictions = _predictions;
      } else {
        _filteredPredictions = _predictions!.where((pred) {
          final title = (pred['title'] as String).toLowerCase();
          final description = (pred['description'] as String).toLowerCase();
          final searchLower = query.toLowerCase();
          return title.contains(searchLower) || description.contains(searchLower);
        }).toList();
      }
      
      // Filter nach Kategorie
      if (_selectedCategory != 'all') {
        _filteredPredictions = _filteredPredictions!
            .where((pred) => pred['category'] == _selectedCategory)
            .toList();
      }
    });
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _searchPredictions(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF1A1A1A), Color(0xFF000000)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EVENT PREDICTOR',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Alternative Vorhersagen',
                            style: TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE91E63),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'PRO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Thema suchen... (z.B. "Euro", "KI", "Migration")',
                      hintStyle: TextStyle(color: Colors.white38),
                      prefixIcon: Icon(Icons.search, color: Colors.white54),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                    onChanged: _searchPredictions,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Category Filter
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildCategoryChip('all', 'Alle', Icons.grid_view),
                    _buildCategoryChip('economy', 'Wirtschaft', Icons.attach_money),
                    _buildCategoryChip('politics', 'Politik', Icons.gavel),
                    _buildCategoryChip('technology', 'Technologie', Icons.computer),
                    _buildCategoryChip('society', 'Gesellschaft', Icons.groups),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Results Count
              if (_filteredPredictions != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.white.withValues(alpha: 0.6),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_filteredPredictions!.length} Vorhersagen gefunden',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Predictions List
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF2196F3),
                        ),
                      )
                    : _filteredPredictions == null || _filteredPredictions!.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Keine Vorhersagen gefunden',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredPredictions!.length,
                            itemBuilder: (context, index) {
                              final pred = _filteredPredictions![index];
                              return _buildPredictionCard(pred);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category, String label, IconData icon) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.white70),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
        onSelected: (_) => _filterByCategory(category),
        backgroundColor: Colors.white.withValues(alpha: 0.05),
        selectedColor: const Color(0xFF2196F3),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected 
            ? const Color(0xFF2196F3) 
            : Colors.white.withValues(alpha: 0.2),
        ),
      ),
    );
  }

  Widget _buildPredictionCard(Map<String, dynamic> pred) {
    final probability = pred['probability'] as int;
    final Color color;
    
    if (probability > 70) {
      color = const Color(0xFFF44336);
    } else if (probability > 50) {
      color = const Color(0xFFFF9800);
    } else if (probability > 30) {
      color = const Color(0xFFFFC107);
    } else {
      color = const Color(0xFF4CAF50);
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.3),
            color.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  pred['title'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$probability%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Timeframe & Category
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                pred['timeframe'],
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getCategoryLabel(pred['category']),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Description
          Text(
            pred['description'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Alternative Perspective
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE91E63).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFE91E63).withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.remove_red_eye,
                  color: Color(0xFFE91E63),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ALTERNATIVE PERSPEKTIVE',
                        style: TextStyle(
                          color: Color(0xFFE91E63),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        pred['alternativePerspektive'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Patterns
          const Text(
            'HISTORISCHE MUSTER:',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (pred['patterns'] as List<String>).map((p) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                p,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            )).toList(),
          ),
          
          const SizedBox(height: 16),
          
          // Indicators
          const Text(
            'INDIKATOREN:',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          ...(pred['indicators'] as List<String>).map((i) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.trending_up, color: color, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    i,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'economy': return 'WIRTSCHAFT';
      case 'politics': return 'POLITIK';
      case 'technology': return 'TECHNOLOGIE';
      case 'society': return 'GESELLSCHAFT';
      default: return 'SONSTIGES';
    }
  }
}
