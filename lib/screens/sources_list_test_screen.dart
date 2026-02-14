/// 🧪 SOURCES LIST TEST SCREEN
/// 
/// Test screen to preview SourcesList widget with mock data
library;

import 'package:flutter/material.dart';
import '../models/recherche_view_state.dart';
import '../widgets/recherche/sources_list.dart';
import '../widgets/recherche/mode_selector.dart';

class SourcesListTestScreen extends StatefulWidget {
  const SourcesListTestScreen({super.key});

  @override
  State<SourcesListTestScreen> createState() => _SourcesListTestScreenState();
}

class _SourcesListTestScreenState extends State<SourcesListTestScreen> {
  RechercheMode _selectedMode = RechercheMode.advanced;
  bool _showSearch = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📚 Sources List Test'),
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
                  // Sources List Widget
                  SourcesList(
                    sources: _getMockSources(_selectedMode),
                    title: 'Quellen - ${_getModeDisplayName(_selectedMode)}',
                    showSearch: _showSearch,
                    onSourceOpened: () {
                      // Analytics tracking
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 20,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Tippe auf eine Quelle zum Öffnen',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '• URL kopieren: Klicke "URL kopieren"\n'
                                '• Quelle öffnen: Klicke "Öffnen" oder auf die Karte\n'
                                '• Suchen: Nutze die Suchleiste (bei > 3 Quellen)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  height: 1.5,
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

  List<RechercheSource> _getMockSources(RechercheMode mode) {
    switch (mode) {
      case RechercheMode.simple:
        return [
          RechercheSource(
            title: 'Was ist Künstliche Intelligenz? - Definition und Grundlagen',
            url: 'https://de.wikipedia.org/wiki/Künstliche_Intelligenz',
            excerpt: 'Künstliche Intelligenz ist ein Teilgebiet der Informatik, das sich mit der Automatisierung intelligenten Verhaltens befasst.',
            relevance: 0.95,
            sourceType: 'website',
            publishDate: DateTime(2023, 11, 15),
          ),
          RechercheSource(
            title: 'Machine Learning Grundlagen - Einführung',
            url: 'https://www.example.com/ml-basics',
            excerpt: 'Machine Learning ermöglicht es Computern, aus Daten zu lernen und Entscheidungen zu treffen.',
            relevance: 0.88,
            sourceType: 'article',
            publishDate: DateTime(2024, 1, 10),
          ),
          RechercheSource(
            title: 'Deep Learning: A Comprehensive Guide',
            url: 'https://www.example.com/deep-learning',
            excerpt: 'Deep Learning nutzt neuronale Netze mit mehreren Schichten zur Mustererkennung.',
            relevance: 0.82,
            sourceType: 'article',
            publishDate: DateTime(2023, 9, 5),
          ),
        ];
        
      case RechercheMode.advanced:
        return [
          RechercheSource(
            title: 'Renewable Energy Statistics 2024 - International Energy Agency',
            url: 'https://www.iea.org/reports/renewable-energy-statistics-2024',
            excerpt: 'Comprehensive report on global renewable energy deployment, capacity factors, and cost trends.',
            relevance: 0.97,
            sourceType: 'document',
            publishDate: DateTime(2024, 3, 20),
          ),
          RechercheSource(
            title: 'Solar Energy Growth: Breaking Records in 2023',
            url: 'https://www.solarpowereurope.org/insights/market-outlooks',
            excerpt: 'Solar power installations grew by 35% in 2023, breaking all previous records with 400 GW added globally.',
            relevance: 0.94,
            sourceType: 'article',
            publishDate: DateTime(2024, 2, 15),
          ),
          RechercheSource(
            title: 'Wind Energy Potential and Capacity Analysis',
            url: 'https://www.windpowermonthly.com/article/wind-capacity-2023',
            excerpt: 'Analysis shows wind energy could supply 30% of global electricity demand by 2030.',
            relevance: 0.91,
            sourceType: 'article',
            publishDate: DateTime(2023, 12, 8),
          ),
          RechercheSource(
            title: 'Energy Storage Technologies Review',
            url: 'https://www.energy-storage.news/technologies/battery-storage',
            excerpt: 'Overview of battery storage technologies including lithium-ion, flow batteries, and emerging solutions.',
            relevance: 0.89,
            sourceType: 'article',
            publishDate: DateTime(2024, 1, 25),
          ),
          RechercheSource(
            title: 'Grid Parity: Renewables vs Fossil Fuels Cost Comparison',
            url: 'https://www.lazard.com/perspective/levelized-cost-of-energy',
            excerpt: 'LCOE analysis shows renewable energy has achieved cost parity with fossil fuels in most markets.',
            relevance: 0.86,
            sourceType: 'document',
            publishDate: DateTime(2023, 11, 30),
          ),
          RechercheSource(
            title: 'Smart Grid Technologies and Implementation',
            url: 'https://www.smartgrid.gov/the-smart-grid',
            excerpt: 'Smart grids use digital technology to improve reliability, efficiency, and sustainability.',
            relevance: 0.83,
            sourceType: 'website',
            publishDate: DateTime(2023, 10, 12),
          ),
        ];
        
      case RechercheMode.deep:
        return [
          RechercheSource(
            title: 'Shor\'s Algorithm and the Threat to RSA Encryption',
            url: 'https://arxiv.org/abs/quant-ph/9508027',
            excerpt: 'Polynomial-time algorithm for integer factorization on a quantum computer.',
            relevance: 0.98,
            sourceType: 'article',
            publishDate: DateTime(1995, 8, 15),
          ),
          RechercheSource(
            title: 'NIST Post-Quantum Cryptography Standards (2022)',
            url: 'https://csrc.nist.gov/projects/post-quantum-cryptography',
            excerpt: 'NIST announces first four quantum-resistant cryptographic algorithms.',
            relevance: 0.96,
            sourceType: 'document',
            publishDate: DateTime(2022, 7, 5),
          ),
          RechercheSource(
            title: 'Lattice-Based Cryptography: A Practical Guide',
            url: 'https://eprint.iacr.org/2015/939',
            excerpt: 'Comprehensive overview of lattice-based cryptographic schemes resistant to quantum attacks.',
            relevance: 0.94,
            sourceType: 'article',
            publishDate: DateTime(2015, 9, 28),
          ),
          RechercheSource(
            title: 'Quantum Computing: Progress and Prospects',
            url: 'https://www.nap.edu/catalog/25196/quantum-computing-progress-and-prospects',
            excerpt: 'National Academies report on the state of quantum computing and its implications.',
            relevance: 0.92,
            sourceType: 'book',
            publishDate: DateTime(2019, 12, 4),
          ),
          RechercheSource(
            title: 'Google Achieves Quantum Supremacy (2019)',
            url: 'https://www.nature.com/articles/s41586-019-1666-5',
            excerpt: 'Quantum processor performs calculation impossible for classical computers.',
            relevance: 0.90,
            sourceType: 'article',
            publishDate: DateTime(2019, 10, 23),
          ),
        ];
        
      case RechercheMode.conspiracy:
        return [
          RechercheSource(
            title: 'The Age of Surveillance Capitalism - Shoshana Zuboff',
            url: 'https://www.publicaffairsbooks.com/titles/shoshana-zuboff/the-age-of-surveillance-capitalism',
            excerpt: 'Examination of how tech companies monetize personal data through behavioral prediction.',
            relevance: 0.96,
            sourceType: 'book',
            publishDate: DateTime(2019, 1, 15),
          ),
          RechercheSource(
            title: 'NSA PRISM Program: What We Know',
            url: 'https://www.theguardian.com/world/2013/jun/06/us-tech-giants-nsa-data',
            excerpt: 'Documents reveal NSA direct access to servers of major tech companies.',
            relevance: 0.93,
            sourceType: 'article',
            publishDate: DateTime(2013, 6, 6),
          ),
          RechercheSource(
            title: 'Cambridge Analytica Data Scandal: Complete Timeline',
            url: 'https://www.bbc.com/news/technology-43465968',
            excerpt: '87 million Facebook users had their data harvested without consent.',
            relevance: 0.91,
            sourceType: 'article',
            publishDate: DateTime(2018, 3, 20),
          ),
        ];
        
      case RechercheMode.historical:
        return [
          RechercheSource(
            title: 'The Industrial Revolution - A New History',
            url: 'https://yalebooks.yale.edu/book/9780300189513/industrial-revolution',
            excerpt: 'Comprehensive examination of the economic and social transformations 1760-1840.',
            relevance: 0.95,
            sourceType: 'book',
            publishDate: DateTime(2014, 4, 8),
          ),
          RechercheSource(
            title: 'Working Conditions in Industrial Britain',
            url: 'https://www.parliament.uk/about/living-heritage/transformingsociety/livinglearning/19thcentury',
            excerpt: 'Parliamentary archives document harsh working conditions and reform movements.',
            relevance: 0.92,
            sourceType: 'document',
            publishDate: DateTime(1840, 1, 1),
          ),
          RechercheSource(
            title: 'The History of Trade Unions in Britain',
            url: 'https://www.bl.uk/romantics-and-victorians/articles/the-rise-of-the-trade-unions',
            excerpt: 'Development of workers\' organizations from illegal societies to legal unions.',
            relevance: 0.88,
            sourceType: 'article',
            publishDate: DateTime(2019, 5, 15),
          ),
        ];
        
      case RechercheMode.scientific:
        return [
          RechercheSource(
            title: 'Safety and Efficacy of BNT162b2 mRNA Covid-19 Vaccine',
            url: 'https://www.nejm.org/doi/full/10.1056/nejmoa2034577',
            excerpt: 'Phase 3 trial results showing 95% efficacy in preventing COVID-19 (N=43,548).',
            relevance: 0.98,
            sourceType: 'article',
            publishDate: DateTime(2020, 12, 31),
          ),
          RechercheSource(
            title: 'Efficacy and Safety of the mRNA-1273 SARS-CoV-2 Vaccine',
            url: 'https://www.nejm.org/doi/full/10.1056/nejmoa2035389',
            excerpt: 'Moderna vaccine demonstrates 94.1% efficacy in phase 3 clinical trial.',
            relevance: 0.97,
            sourceType: 'article',
            publishDate: DateTime(2021, 2, 4),
          ),
          RechercheSource(
            title: 'mRNA Vaccines: A New Era in Vaccinology',
            url: 'https://www.nature.com/articles/nrd.2017.243',
            excerpt: 'Review of mRNA vaccine technology development since the 1990s.',
            relevance: 0.94,
            sourceType: 'article',
            publishDate: DateTime(2018, 1, 12),
          ),
          RechercheSource(
            title: 'Long-term Safety Data of mRNA COVID-19 Vaccines',
            url: 'https://www.thelancet.com/journals/lancet/article/PIIS0140-6736(22)00089-7',
            excerpt: 'Two-year follow-up study confirms safety profile of mRNA vaccines.',
            relevance: 0.92,
            sourceType: 'article',
            publishDate: DateTime(2022, 3, 15),
          ),
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
