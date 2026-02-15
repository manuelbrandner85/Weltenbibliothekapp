import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import '../../widgets/favorite_button.dart';
import '../../models/favorite.dart';  // 🆕 For FavoriteType
import '../../models/energie_profile.dart';
import 'calculators/numerology_calculator_screen.dart';
import 'calculators/archetype_calculator_screen.dart';
import 'calculators/chakra_calculator_screen.dart';
import 'calculators/kabbalah_calculator_screen.dart';
import 'calculators/hermetic_calculator_screen.dart';
import 'calculators/gematria_calculator_screen.dart';
import 'calculators/spirit_universal_tool_screen.dart';
import 'calculators/new_spirit_tool_screens.dart';
import 'frequency_generator_screen.dart';  // 🎵 FREQUENCY GENERATOR
import '../spirit/spirit_tools_mega_screen.dart'; // 🆕 V115 MEGA UPDATE TOOLS

/// Moderner Spirit-Tab mit ALLEN 16 originalen Tools
class SpiritTabModern extends StatefulWidget {
  const SpiritTabModern({super.key});

  @override
  State<SpiritTabModern> createState() => _SpiritTabModernState();
}

class _SpiritTabModernState extends State<SpiritTabModern> {
  final _storage = StorageService();
  EnergieProfile? _profile;
  bool _isLoading = true;
  String? _error;
  String _selectedCategory = 'all'; // 'all', 'core', 'advanced', 'meta', 'new'
  
  // 16 ORIGINAL + 15 NEUE = 31 SPIRIT-TOOLS
  late final List<Map<String, dynamic>> _allTools;

  @override
  void initState() {
    super.initState();
    _initializeTools();
    _loadProfile();
  }

  void _initializeTools() {
    _allTools = [
      // === KERN-TOOLS (6 Original-Calculators) ===
      {
        'icon': Icons.calculate,
        'iconEmoji': '🔢',
        'title': 'Numerologie',
        'subtitle': 'Zahlen deines Lebens',
        'color': const Color(0xFF9C27B0),
        'category': 'core',
        'screen': const NumerologyCalculatorScreen(),
      },
      {
        'icon': Icons.psychology,
        'iconEmoji': '🧠',
        'title': 'Archetypen',
        'subtitle': 'Deine inneren Muster',
        'color': const Color(0xFF673AB7),
        'category': 'core',
        'screen': const ArchetypeCalculatorScreen(),
      },
      {
        'icon': Icons.spa,
        'iconEmoji': '🔮',
        'title': 'Chakren',
        'subtitle': 'Energiezentren',
        'color': const Color(0xFFE91E63),
        'category': 'core',
        'screen': const ChakraCalculatorScreen(),
      },
      {
        'icon': Icons.account_tree,
        'iconEmoji': '🌳',
        'title': 'Kabbala',
        'subtitle': 'Lebensbaum-Analyse',
        'color': const Color(0xFF00BCD4),
        'category': 'core',
        'screen': const KabbalahCalculatorScreen(),
      },
      {
        'icon': Icons.auto_awesome,
        'iconEmoji': '✨',
        'title': 'Hermetik',
        'subtitle': 'Hermetische Gesetze',
        'color': const Color(0xFFFF9800),
        'category': 'core',
        'screen': const HermeticCalculatorScreen(),
      },
      {
        'icon': Icons.translate,
        'iconEmoji': '📖',
        'title': 'Gematria',
        'subtitle': 'Zahlen-Buchstaben',
        'color': const Color(0xFF4CAF50),
        'category': 'core',
        'screen': const GematriaCalculatorScreen(),
      },
      
      // === ERWEITERTE TOOLS (10 Universal-Tools) ===
      {
        'icon': Icons.bolt,
        'iconEmoji': '⚡',
        'title': 'Energiefeld',
        'subtitle': 'Biofield-Analyse',
        'color': const Color(0xFF00BCD4),
        'category': 'advanced',
        'screen': const SpiritUniversalToolScreen(
          toolName: 'Energiefeld-Analyse',
          toolIcon: Icons.bolt,
          toolColor: Color(0xFF00BCD4),
          toolType: 'energy_field',
        ),
      },
      {
        'icon': Icons.balance,
        'iconEmoji': '☯️',
        'title': 'Polaritäten',
        'subtitle': 'Yin-Yang Balance',
        'color': const Color(0xFFE91E63),
        'category': 'advanced',
        'screen': const SpiritUniversalToolScreen(
          toolName: 'Polaritäts-Analyse',
          toolIcon: Icons.balance,
          toolColor: Color(0xFFE91E63),
          toolType: 'polarity',
        ),
      },
      {
        'icon': Icons.transform,
        'iconEmoji': '🦋',
        'title': 'Transformation',
        'subtitle': 'Spirituelle Stufen',
        'color': const Color(0xFF9C27B0),
        'category': 'advanced',
        'screen': const SpiritUniversalToolScreen(
          toolName: 'Transformations-Analyse',
          toolIcon: Icons.transform,
          toolColor: Color(0xFF9C27B0),
          toolType: 'transformation',
        ),
      },
      {
        'icon': Icons.psychology_outlined,
        'iconEmoji': '🌑',
        'title': 'Unterbewusstsein',
        'subtitle': 'Shadow Work',
        'color': const Color(0xFF4CAF50),
        'category': 'advanced',
        'screen': const SpiritUniversalToolScreen(
          toolName: 'Unterbewusstseins-Analyse',
          toolIcon: Icons.psychology_outlined,
          toolColor: Color(0xFF4CAF50),
          toolType: 'unconscious',
        ),
      },
      {
        'icon': Icons.explore,
        'iconEmoji': '🧭',
        'title': 'Innere Karten',
        'subtitle': 'Prozessnavigation',
        'color': const Color(0xFFFF9800),
        'category': 'advanced',
        'screen': const SpiritUniversalToolScreen(
          toolName: 'Innere-Karten-Analyse',
          toolIcon: Icons.explore,
          toolColor: Color(0xFFFF9800),
          toolType: 'inner_maps',
        ),
      },
      {
        'icon': Icons.refresh,
        'iconEmoji': '🔄',
        'title': 'Zyklen',
        'subtitle': 'Saturn Return',
        'color': const Color(0xFF673AB7),
        'category': 'advanced',
        'screen': const SpiritUniversalToolScreen(
          toolName: 'Zyklen-Analyse',
          toolIcon: Icons.refresh,
          toolColor: Color(0xFF673AB7),
          toolType: 'cycles',
        ),
      },
      {
        'icon': Icons.stacked_line_chart,
        'iconEmoji': '🌀',
        'title': 'Orientierung',
        'subtitle': 'Spiral Dynamics',
        'color': const Color(0xFF2196F3),
        'category': 'meta',
        'screen': const SpiritUniversalToolScreen(
          toolName: 'Orientierungs-Analyse',
          toolIcon: Icons.stacked_line_chart,
          toolColor: Color(0xFF2196F3),
          toolType: 'orientation',
        ),
      },
      {
        'icon': Icons.sync,
        'iconEmoji': '🔗',
        'title': 'Meta-Spiegel',
        'subtitle': 'Synchronizität',
        'color': const Color(0xFFFFD700),
        'category': 'meta',
        'screen': const SpiritUniversalToolScreen(
          toolName: 'Meta-Spiegel-Analyse',
          toolIcon: Icons.sync,
          toolColor: Color(0xFFFFD700),
          toolType: 'meta_mirror',
        ),
      },
      {
        'icon': Icons.visibility,
        'iconEmoji': '👁️',
        'title': 'Wahrnehmung',
        'subtitle': 'Bewusstseins-Filter',
        'color': const Color(0xFF00BCD4),
        'category': 'meta',
        'screen': const SpiritUniversalToolScreen(
          toolName: 'Wahrnehmungs-Analyse',
          toolIcon: Icons.visibility,
          toolColor: Color(0xFF00BCD4),
          toolType: 'perception',
        ),
      },
      {
        'icon': Icons.self_improvement,
        'iconEmoji': '🪞',
        'title': 'Selbstbeobachtung',
        'subtitle': 'Meta-Kognition',
        'color': const Color(0xFF9C27B0),
        'category': 'meta',
        'screen': const SpiritUniversalToolScreen(
          toolName: 'Selbstbeobachtungs-Analyse',
          toolIcon: Icons.self_improvement,
          toolColor: Color(0xFF9C27B0),
          toolType: 'self_observation',
        ),
      },
      
      // ═══════════════════════════════════════════════════════════
      // 🆕 15 NEUE SPIRIT-TOOLS (v44) - IM GRID WIE ORIGINAL-TOOLS
      // ═══════════════════════════════════════════════════════════
      
      // 🌙 Mondphasen-Tracker
      {
        'icon': Icons.nightlight_round,
        'iconEmoji': '🌙',
        'title': 'Mondphasen',
        'subtitle': 'Mond-Zyklus & Rituale',
        'color': const Color(0xFF1A237E),
        'category': 'new',
        'screen': const MoonPhaseTrackerScreen(),
      },
      
      // 🔮 Tarot-Tagesziehung
      {
        'icon': Icons.auto_awesome,
        'iconEmoji': '🔮',
        'title': 'Tarot',
        'subtitle': 'Tägliche Kartenziehung',
        'color': const Color(0xFF4A148C),
        'category': 'new',
        'screen': const TarotDailyDrawScreen(),
      },
      
      // 💎 Kristall-Datenbank
      {
        'icon': Icons.diamond,
        'iconEmoji': '💎',
        'title': 'Kristalle',
        'subtitle': '50+ Heilsteine',
        'color': const Color(0xFF1976D2),
        'category': 'new',
        'screen': const CrystalDatabaseScreen(),
      },
      
      // 📿 Meditation-Timer
      {
        'icon': Icons.timer,
        'iconEmoji': '📿',
        'title': 'Meditation',
        'subtitle': 'Timer & Gongs',
        'color': const Color(0xFF4527A0),
        'category': 'new',
        'screen': const MeditationTimerScreen(),
      },
      
      // 🌈 Aura-Farben Reader
      {
        'icon': Icons.color_lens,
        'iconEmoji': '🌈',
        'title': 'Aura-Reader',
        'subtitle': 'Aura-Farb-Analyse',
        'color': const Color(0xFFAD1457),
        'category': 'new',
        'screen': const AuraColorReaderScreen(),
      },
      
      // 🧬 DNA-Aktivierung
      {
        'icon': Icons.biotech,
        'iconEmoji': '🧬',
        'title': 'DNA-Aktivierung',
        'subtitle': '12-Strang Tracker',
        'color': const Color(0xFF00695C),
        'category': 'new',
        'screen': const DnaActivationTrackerScreen(),
      },
      
      // 🎵 Frequenz-Generator
      {
        'icon': Icons.graphic_eq,
        'iconEmoji': '🎵',
        'title': 'Frequenzen',
        'subtitle': 'Solfeggio & Binaural',
        'color': const Color(0xFFD32F2F),
        'category': 'new',
        'screen': null,  // Create on tap (not const-constructable)
        'screenBuilder': () => const FrequencyGeneratorScreen(),
      },
      
      // 🌌 Akasha-Chronik
      {
        'icon': Icons.menu_book,
        'iconEmoji': '🌌',
        'title': 'Akasha-Chronik',
        'subtitle': 'Seelen-Journal',
        'color': const Color(0xFF311B92),
        'category': 'new',
        'screen': const AkashaChronicleJournalScreen(),
      },
      
      // 🕉️ Mantra-Bibliothek
      {
        'icon': Icons.record_voice_over,
        'iconEmoji': '🕉️',
        'title': 'Mantras',
        'subtitle': '30+ Sanskrit-Mantras',
        'color': const Color(0xFFE65100),
        'category': 'new',
        'screen': const MantraLibraryScreen(),
      },
      
      // 🔯 Heilige Geometrie
      {
        'icon': Icons.hexagon_outlined,
        'iconEmoji': '🔯',
        'title': 'Heilige Geometrie',
        'subtitle': '12 Muster',
        'color': const Color(0xFF00838F),
        'category': 'new',
        'screen': const SacredGeometryScreen(),
      },
      
      // 🌍 Erdung-Übungen
      {
        'icon': Icons.nature_people,
        'iconEmoji': '🌍',
        'title': 'Erdung',
        'subtitle': '10 Grounding-Übungen',
        'color': const Color(0xFF558B2F),
        'category': 'new',
        'screen': const GroundingExercisesScreen(),
      },
      
      // 🦋 Transformation-Tracker
      {
        'icon': Icons.trending_up,
        'iconEmoji': '🦋',
        'title': 'Transformation',
        'subtitle': 'Wachstums-Tracking',
        'color': const Color(0xFFF57C00),
        'category': 'new',
        'screen': const TransformationTrackerScreen(),
      },
      
      // 🌟 Lichtsprache
      {
        'icon': Icons.language,
        'iconEmoji': '🌟',
        'title': 'Lichtsprache',
        'subtitle': '30+ Lichtcodes',
        'color': const Color(0xFFFDD835),
        'category': 'new',
        'screen': const LightLanguageDecoderScreen(),
      },
      
      // 🧘‍♀️ Yoga Asana
      {
        'icon': Icons.self_improvement,
        'iconEmoji': '🧘‍♀️',
        'title': 'Yoga Asanas',
        'subtitle': '50+ Übungen',
        'color': const Color(0xFF00695C),
        'category': 'new',
        'screen': const YogaAsanaGuideScreen(),
      },
      
      // 🌺 Göttinnen & Götter Orakel
      {
        'icon': Icons.auto_awesome,
        'iconEmoji': '🌺',
        'title': 'Götter-Orakel',
        'subtitle': '30+ Archetypen',
        'color': const Color(0xFF6A1B9A),
        'category': 'new',
        'screen': const GoddessOracleScreen(),
      },
      
      // ═══════════════════════════════════════════════════════════
      // 🆕 V115 MEGA UPDATE - NEUE SPIRIT-TOOLS
      // ═══════════════════════════════════════════════════════════
      
      // 💭 Traumtagebuch (V115 Feature #16)
      {
        'icon': Icons.bedtime,
        'iconEmoji': '💭',
        'title': 'Traumtagebuch',
        'subtitle': 'Träume & Symbole',
        'color': const Color(0xFF1A237E),
        'category': 'new',
        'screen': const DreamJournalScreen(),
      },
      
      // ᚱ Runen-Orakel (V115 Feature #20)
      {
        'icon': Icons.auto_stories,
        'iconEmoji': 'ᚱ',
        'title': 'Runen-Orakel',
        'subtitle': 'Elder Futhark 24',
        'color': const Color(0xFF795548),
        'category': 'new',
        'screen': const RuneOracleScreen(),
      },
      
      // 💫 Affirmationen (V115 Feature #17)
      {
        'icon': Icons.format_quote,
        'iconEmoji': '💫',
        'title': 'Affirmationen',
        'subtitle': 'Tägliche Kraft',
        'color': const Color(0xFFE91E63),
        'category': 'new',
        'screen': const AffirmationsScreen(),
      },
      
      // 📊 Biorhythmus (V115 Feature #18)
      {
        'icon': Icons.show_chart,
        'iconEmoji': '📊',
        'title': 'Biorhythmus',
        'subtitle': 'Körper-Geist-Seele',
        'color': const Color(0xFF00897B),
        'category': 'new',
        'screen': const BiorhythmScreen(),
      },
      
      // ☯ I-Ging Orakel (V115 Feature #19)
      {
        'icon': Icons.circle_outlined,
        'iconEmoji': '☯',
        'title': 'I-Ging',
        'subtitle': '64 Hexagramme',
        'color': const Color(0xFF424242),
        'category': 'new',
        'screen': const IChingScreen(),
      },
    ];
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await _storage.loadEnergieProfile();
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Fehler beim Laden: $e';
        _isLoading = false;
      });
      if (kDebugMode) {
        debugPrint('❌ Fehler beim Laden des Profils: $e');
      }
    }
  }

  List<Map<String, dynamic>> get _filteredTools {
    if (_selectedCategory == 'all') return _allTools;
    return _allTools.where((tool) => tool['category'] == _selectedCategory).toList();
  }

  int _getCategoryCount(String category) {
    if (category == 'all') return _allTools.length;
    return _allTools.where((tool) => tool['category'] == category).length;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF4A148C).withValues(alpha: 0.1),
            Colors.black,
          ],
        ),
      ),
      child: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : CustomScrollView(
                  slivers: [
                    // Header
                    SliverToBoxAdapter(
                      child: _buildHeader(),
                    ),
                    
                    // Kategorien-Filter
                    SliverToBoxAdapter(
                      child: _buildCategoryFilter(),
                    ),
                    
                    // Tägliche Inspiration
                    SliverToBoxAdapter(
                      child: _buildDailyInspiration(),
                    ),
                    
                    // Tools-Grid (31 TOOLS: 16 ORIGINAL + 15 NEUE)
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildToolCard(_filteredTools[index]),
                          childCount: _filteredTools.length,
                        ),
                      ),
                    ),
                    
                    // Bottom-Padding
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 100),
                    ),
                  ],
                ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9C27B0)),
          ),
          SizedBox(height: 20),
          Text(
            'Lade Spirit-Tools...',
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 20),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9C27B0),
            ),
            child: const Text('Erneut versuchen'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '🔮',
                style: TextStyle(fontSize: 40),
              ),
              const SizedBox(width: 12),
              const Text(
                'Spirit Tools',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_profile != null)
            Text(
              'Für ${_profile!.firstName} ${_profile!.lastName}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            '${_allTools.length} Spirituelle Werkzeuge',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildCategoryChip(
              'all',
              '✨ Alle (${_getCategoryCount('all')})',
              Colors.purple,
            ),
            const SizedBox(width: 12),
            _buildCategoryChip(
              'core',
              '⭐ Kern (${_getCategoryCount('core')})',
              Colors.blue,
            ),
            const SizedBox(width: 12),
            _buildCategoryChip(
              'advanced',
              '🚀 Erweitert (${_getCategoryCount('advanced')})',
              Colors.cyan,
            ),
            const SizedBox(width: 12),
            _buildCategoryChip(
              'meta',
              '🌌 Meta (${_getCategoryCount('meta')})',
              Colors.pink,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category, String label, Color color) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.7),
                    color.withValues(alpha: 0.3),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildDailyInspiration() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepPurple.withValues(alpha: 0.3),
            Colors.purple.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.purple.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '💫',
                style: TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              const Text(
                'Tägliche Inspiration',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"Deine Energie zieht an, was du ausstrahlst. Nutze diese Tools, um deine spirituelle Reise zu vertiefen."',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '— Spirit-Weisheit',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.purple.withValues(alpha: 0.8, red: 0.8, green: 0.5, blue: 0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard(Map<String, dynamic> tool) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (tool['color'] as Color).withValues(alpha: 0.2),
            (tool['color'] as Color).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (tool['color'] as Color).withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (tool['color'] as Color).withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            final screen = tool['screen'] as Widget?;
            final screenBuilder = tool['screenBuilder'] as Widget Function()?;
            
            if (screen != null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => screen),
              );
            } else if (screenBuilder != null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => screenBuilder()),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon, Favorite-Button und Emoji
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            (tool['color'] as Color).withValues(alpha: 0.4),
                            (tool['color'] as Color).withValues(alpha: 0.1),
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: (tool['color'] as Color).withValues(alpha: 0.6),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          tool['iconEmoji'] as String,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                    // Favorite-Button für Spirit-Tool
                    FavoriteButton(
                      itemId: 'spirit_tool_${tool['title']}',
                      itemType: FavoriteType.narrative,
                      itemTitle: tool['title'] as String,
                      itemDescription: tool['description'] as String?,
                      size: 22,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Tool-Name
                Text(
                  tool['title'] as String,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                
                // Beschreibung
                Expanded(
                  child: Text(
                    tool['subtitle'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.7),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Start-Button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (tool['color'] as Color).withValues(alpha: 0.6),
                        (tool['color'] as Color).withValues(alpha: 0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (tool['color'] as Color).withValues(alpha: 0.7),
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'Öffnen',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 🆕 15 NEUE SPIRIT-TOOLS SECTION
  // ═══════════════════════════════════════════════════════════
  
}
