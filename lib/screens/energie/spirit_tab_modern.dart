import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import '../../widgets/favorite_button.dart';
import '../../models/favorite.dart';
import '../../models/energie_profile.dart';
import 'calculators/numerology_calculator_screen.dart';
import 'calculators/archetype_calculator_screen.dart';
import 'calculators/chakra_calculator_screen.dart';
import 'calculators/kabbalah_calculator_screen.dart';
import 'calculators/hermetic_calculator_screen.dart';
import 'calculators/gematria_calculator_screen.dart';
import 'calculators/spirit_universal_tool_screen.dart';
import 'calculators/new_spirit_tool_screens.dart';
import 'calculators/moon_calendar_tool_screen.dart'; // 🌕 v19 Mondkalender
import 'calculators/dream_interpretation_tool_screen.dart'; // 💭 v20 Traumdeutung
import 'calculators/body_scan_tool_screen.dart'; // 🧘 v21 Körperscan
import 'calculators/soul_contract_tool_screen.dart'; // 📜 v22 Seelenvertrag
import 'calculators/ancestral_work_tool_screen.dart'; // 🕯️ v23 Ahnenarbeit
import 'calculators/shamanic_journey_tool_screen.dart'; // 🥁 v24 Schamanische Reise
import 'calculators/natal_chart_tool_screen.dart'; // ♓ v25 Geburtshoroskop
import 'calculators/human_design_tool_screen.dart'; // 🌀 v26 Human Design
import 'frequency_generator_screen.dart';  // 🎵 FREQUENCY GENERATOR
import '../spirit/spirit_tools_mega_screen.dart'; // 🆕 V115 MEGA UPDATE TOOLS

/// Moderner Spirit-Tab mit ALLEN 16 originalen Tools
class SpiritTabModern extends StatefulWidget {
  const SpiritTabModern({super.key});

  @override
  State<SpiritTabModern> createState() => _SpiritTabModernState();
}

class _SpiritTabModernState extends State<SpiritTabModern>
    with TickerProviderStateMixin {

  // ── Animations ─────────────────────────────────────────────────────────
  late AnimationController _auraCtrl;
  late AnimationController _entryCtrl;
  late AnimationController _orbitCtrl;
  late Animation<double> _entryAnim;

  // ── Colors (identical to home dashboard) ───────────────────────────────
  static const _bg      = Color(0xFF06040F);
  static const _card    = Color(0xFF100B1E);
  static const _cardB   = Color(0xFF150E25);
  static const _purple  = Color(0xFFAB47BC);
  static const _purpleD = Color(0xFF4A148C);
  static const _purpleL = Color(0xFFCE93D8);
  static const _gold    = Color(0xFFFFD54F);
  static const _teal    = Color(0xFF26C6DA);
  static const _pink    = Color(0xFFEC407A);
  static const _green   = Color(0xFF66BB6A);

  // ── State ──────────────────────────────────────────────────────────────
  final _storage = StorageService();
  EnergieProfile? _profile;
  bool _isLoading = true;
  String? _error;
  String _selectedCategory = 'all';

  late final List<Map<String, dynamic>> _allTools;

  @override
  void initState() {
    super.initState();
    _auraCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 3))..repeat(reverse: true);
    _entryCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 900));
    _orbitCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 12))..repeat();
    _entryAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic);
    _entryCtrl.forward();
    _initializeTools();
    _loadProfile();
  }

  @override
  void dispose() {
    _auraCtrl.dispose();
    _entryCtrl.dispose();
    _orbitCtrl.dispose();
    super.dispose();
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
      
      // 🌕 Mondkalender (v19 – echte Ephemeriden + Rituale + Tagebuch)
      {
        'icon': Icons.nightlight_round,
        'iconEmoji': '🌕',
        'title': 'Mondkalender',
        'subtitle': 'Lebe im Einklang mit dem Mond',
        'color': const Color(0xFF37474F),
        'category': 'new',
        'screen': const MoonCalendarToolScreen(),
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
      
      // 💭 Traumdeutung (v20 – Symbol-Lexikon + Auto-Tagging)
      {
        'icon': Icons.bedtime,
        'iconEmoji': '💭',
        'title': 'Traumdeutung',
        'subtitle': 'Symbole deuten & Muster erkennen',
        'color': const Color(0xFF1A237E),
        'category': 'new',
        'screen': const DreamInterpretationToolScreen(),
      },

      // 🧘 Körperscan (v21 – Chakra-Symptom-Scanner)
      {
        'icon': Icons.sensors,
        'iconEmoji': '🧘',
        'title': 'Körperscan',
        'subtitle': 'Symptome → Chakra-Blockaden',
        'color': const Color(0xFFE91E63),
        'category': 'new',
        'screen': const BodyScanToolScreen(),
      },

      // 📜 Seelenvertrag (v22 – Numerologie aus Name + Geburtsdatum)
      {
        'icon': Icons.auto_stories,
        'iconEmoji': '📜',
        'title': 'Seelenvertrag',
        'subtitle': 'Numerologie deiner Lebensaufgabe',
        'color': const Color(0xFFFFB300),
        'category': 'new',
        'screen': const SoulContractToolScreen(),
      },

      // 🕯️ Ahnenarbeit (v23 – Ahnen, Muster, Rituale)
      {
        'icon': Icons.family_restroom,
        'iconEmoji': '🕯️',
        'title': 'Ahnenarbeit',
        'subtitle': 'Ahnen, Muster & Heil-Rituale',
        'color': const Color(0xFFD4A24C),
        'category': 'new',
        'screen': const AncestralWorkToolScreen(),
      },

      // 🥁 Schamanische Reise (v24 – Timer + Journal + Krafttiere + Guides)
      {
        'icon': Icons.nightlight_round,
        'iconEmoji': '🥁',
        'title': 'Schamanische Reise',
        'subtitle': 'Trommel-Reise mit Journal',
        'color': const Color(0xFF8E5AE2),
        'category': 'new',
        'screen': const ShamanicJourneyToolScreen(),
      },

      // ♓ Geburtshoroskop (v25 – Meeus-Astrologie + Lexikon)
      {
        'icon': Icons.auto_awesome,
        'iconEmoji': '♓',
        'title': 'Geburtshoroskop',
        'subtitle': 'Natal-Chart mit echter Ephemeride',
        'color': const Color(0xFF6C63FF),
        'category': 'new',
        'screen': const NatalChartToolScreen(),
      },

      // 🌀 Human Design (v26 – Type/Profile/Authority/64 Gates)
      {
        'icon': Icons.hub,
        'iconEmoji': '🌀',
        'title': 'Human Design',
        'subtitle': 'Typ, Strategie, Autorität & Tore',
        'color': const Color(0xFF26C6DA),
        'category': 'new',
        'screen': const HumanDesignToolScreen(),
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
    return DefaultTextStyle.merge(
      style: const TextStyle(
        decoration: TextDecoration.none,
        decorationColor: Colors.transparent,
        fontFamily: 'Roboto',
        letterSpacing: 0.1,
        height: 1.25,
      ),
      child: Scaffold(
        backgroundColor: _bg,
        body: _isLoading
            ? _buildLoadingState()
            : _error != null
                ? _buildErrorState()
                : RefreshIndicator(
                    onRefresh: _loadProfile,
                    color: _purple,
                    backgroundColor: _cardB,
                    displacement: 60,
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics()),
                      slivers: [
                        _buildHeroHeader(),
                        _buildCategoryFilterSliver(),
                        _buildDailyInspirationSliver(),
                        _buildToolsGrid(),
                        const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
                      ],
                    ),
                  ),
      ),
    );
  }

  // ── HERO HEADER ────────────────────────────────────────────────────────
  Widget _buildHeroHeader() {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _entryAnim,
        child: SizedBox(
          height: 200,
          child: Stack(
            children: [
              // Animated aura background
              AnimatedBuilder(
                animation: _orbitCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _SpiritAuraPainter(
                    orbitProgress: _orbitCtrl.value,
                    auraProgress: _auraCtrl.value,
                    color: _purple,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              // Fade to bg
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, _bg],
                    stops: const [0.45, 1.0],
                  ),
                ),
              ),
              // Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildAuraOrb(),
                          const SizedBox(width: 14),
                          Expanded(child: _buildHeaderText()),
                          _buildToolCount(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuraOrb() {
    return AnimatedBuilder(
      animation: _auraCtrl,
      builder: (_, __) => Container(
        width: 54, height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              _purple.withValues(alpha: 0.45 + _auraCtrl.value * 0.2),
              _purpleD.withValues(alpha: 0.1),
            ],
          ),
          border: Border.all(
              color: _purpleL.withValues(alpha: 0.4 + _auraCtrl.value * 0.3),
              width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _purple.withValues(alpha: 0.25 + _auraCtrl.value * 0.2),
              blurRadius: 18, spreadRadius: 3,
            ),
          ],
        ),
        child: Center(
          child: Text(
            _profile?.avatarEmoji ?? '🔮',
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderText() {
    final name = (_profile?.firstName.isNotEmpty == true)
        ? _profile!.firstName
        : _profile?.username ?? 'Suchende/r';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('✨ Spirit Tools',
            style: TextStyle(color: Colors.white54, fontSize: 12,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(name,
            style: const TextStyle(color: Colors.white, fontSize: 20,
                fontWeight: FontWeight.bold, letterSpacing: -0.3),
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 3),
        Row(children: [
          AnimatedBuilder(
            animation: _auraCtrl,
            builder: (_, __) => Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                color: _purple.withValues(alpha: 0.5 + _auraCtrl.value * 0.5),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: _purple.withValues(alpha: 0.5), blurRadius: 4)],
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Text('Welt der ENERGIE',
              style: TextStyle(color: Colors.white38, fontSize: 11)),
        ]),
      ],
    );
  }

  Widget _buildToolCount() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('${_allTools.length}',
            style: const TextStyle(color: _purpleL, fontSize: 18,
                fontWeight: FontWeight.bold)),
        const Text('Tools',
            style: TextStyle(color: Colors.white38, fontSize: 9,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: _bg,
      child: const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_purple)),
          SizedBox(height: 20),
          Text('Lade Spirit-Tools…',
              style: TextStyle(fontSize: 15, color: Colors.white54)),
        ]),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      color: _bg,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.error_outline, size: 56,
                color: _pink.withValues(alpha: 0.7)),
            const SizedBox(height: 16),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.white54)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _loadProfile,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF6A1B9A), _purple]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text('Erneut versuchen',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ),
    );
  }


  Widget _buildCategoryFilterSliver() {
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
            .animate(_entryAnim),
        child: FadeTransition(
          opacity: _entryAnim,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(children: [
                _buildCategoryChip('all',      '✨ Alle',      _purple, _getCategoryCount('all')),
                const SizedBox(width: 10),
                _buildCategoryChip('core',     '⭐ Kern',      _teal,   _getCategoryCount('core')),
                const SizedBox(width: 10),
                _buildCategoryChip('advanced', '🚀 Erweitert', _pink,   _getCategoryCount('advanced')),
                const SizedBox(width: 10),
                _buildCategoryChip('meta',     '🌌 Meta',      _gold,   _getCategoryCount('meta')),
                const SizedBox(width: 10),
                _buildCategoryChip('new',      '🆕 Neu',       _green,  _getCategoryCount('new')),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category, String label, Color color, int count) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [
                  color.withValues(alpha: 0.7),
                  color.withValues(alpha: 0.3),
                ])
              : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.15),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.3),
                  blurRadius: 12, offset: const Offset(0, 4))]
              : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label,
              style: TextStyle(color: Colors.white, fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count',
                style: TextStyle(color: isSelected ? Colors.white : Colors.white54,
                    fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ]),
      ),
    );
  }

  Widget _buildDailyInspirationSliver() {
    final quotes = [
      '"Deine Energie zieht an, was du ausstrahlst."',
      '"Stille ist die Sprache Gottes, alles andere ist schlechte Übersetzung."',
      '"Du bist nicht ein Mensch auf einer spirituellen Reise, sondern ein Geist auf einer menschlichen Erfahrung."',
      '"Wahres Erwachen beginnt mit der Stille in dir."',
      '"Dein Licht kann die Dunkelheit der Welt erhellen."',
    ];
    final quote = quotes[DateTime.now().day % quotes.length];

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
        child: AnimatedBuilder(
          animation: _auraCtrl,
          builder: (_, __) => Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _purpleD.withValues(alpha: 0.8),
                  _purple.withValues(alpha: 0.3 + _auraCtrl.value * 0.1),
                  _gold.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: _purpleL.withValues(alpha: 0.2 + _auraCtrl.value * 0.1)),
              boxShadow: [
                BoxShadow(
                  color: _purple.withValues(alpha: 0.12 + _auraCtrl.value * 0.08),
                  blurRadius: 20, offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(children: [
              AnimatedBuilder(
                animation: _orbitCtrl,
                builder: (_, __) => Transform.rotate(
                  angle: _orbitCtrl.value * math.pi * 2 * 0.08,
                  child: Text('💫',
                      style: TextStyle(fontSize: 32 + _auraCtrl.value * 3)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Tägliche Inspiration',
                      style: TextStyle(color: Colors.white, fontSize: 13,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(quote,
                      style: TextStyle(color: _purpleL.withValues(alpha: 0.85),
                          fontSize: 11, fontStyle: FontStyle.italic, height: 1.4)),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildToolsGrid() {
    final tools = _filteredTools;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.82,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildToolCard(tools[index]),
          childCount: tools.length,
        ),
      ),
    );
  }

  Widget _buildToolCard(Map<String, dynamic> tool) {
    final color = tool['color'] as Color;
    return GestureDetector(
      onTap: () {
        final screen = tool['screen'] as Widget?;
        final builder = tool['screenBuilder'] as Widget Function()?;
        if (screen != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        } else if (builder != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => builder()));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: _card,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.18),
              _card,
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.15),
                blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(children: [
            // Decorative circle (like home action tiles)
            Positioned(
              right: -18, bottom: -18,
              child: Container(
                width: 70, height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: icon orb + favorite
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            color.withValues(alpha: 0.45),
                            color.withValues(alpha: 0.1),
                          ]),
                          border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
                        ),
                        child: Center(
                          child: Text(tool['iconEmoji'] as String,
                              style: const TextStyle(fontSize: 24)),
                        ),
                      ),
                      FavoriteButton(
                        itemId: 'spirit_tool_${tool['title']}',
                        itemType: FavoriteType.narrative,
                        itemTitle: tool['title'] as String,
                        itemDescription: tool['subtitle'] as String?,
                        size: 20,
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Title
                  Text(tool['title'] as String,
                      style: const TextStyle(color: Colors.white, fontSize: 15,
                          fontWeight: FontWeight.bold),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  // Subtitle
                  Text(tool['subtitle'] as String,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 10),
                  // Open button (matching home tile style)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [color.withValues(alpha: 0.55),
                                   color.withValues(alpha: 0.25)]),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withValues(alpha: 0.5)),
                    ),
                    child: const Center(
                      child: Text('Öffnen',
                          style: TextStyle(color: Colors.white, fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SPIRIT AURA PAINTER (simplified version of home dashboard painter)
// ═══════════════════════════════════════════════════════════════════════════
class _SpiritAuraPainter extends CustomPainter {
  final double orbitProgress;
  final double auraProgress;
  final Color color;

  _SpiritAuraPainter({
    required this.orbitProgress,
    required this.auraProgress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.45;

    // Pulsing aura
    for (int i = 3; i >= 0; i--) {
      final radius = 60.0 + i * 28 + auraProgress * 14;
      final alpha = (0.06 - i * 0.012) + auraProgress * 0.02;
      canvas.drawCircle(
        Offset(cx, cy),
        radius,
        Paint()..color = color.withValues(alpha: alpha.clamp(0.0, 1.0)),
      );
    }

    // Orbiting particles
    for (int i = 0; i < 5; i++) {
      final angle = orbitProgress * math.pi * 2 + i * math.pi * 2 / 5;
      final r = 80.0 + i * 6.0;
      final px = cx + math.cos(angle) * r;
      final py = cy + math.sin(angle) * r * 0.4;
      canvas.drawCircle(
        Offset(px, py),
        2.5,
        Paint()..color = color.withValues(alpha: 0.25 + auraProgress * 0.15),
      );
    }
  }

  @override
  bool shouldRepaint(_SpiritAuraPainter old) => true;
}
