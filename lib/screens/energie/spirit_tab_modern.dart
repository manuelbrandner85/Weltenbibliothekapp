import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import '../../widgets/favorite_button.dart';
import '../../models/favorite.dart';
import '../../models/energie_profile.dart';
import 'calculators/numerology_calculator_screen.dart';
import 'calculators/everyday_numerology_screen.dart';
import 'calculators/numerology_quiz_screen.dart';
import 'calculators/archetype_calculator_screen.dart';
import 'calculators/chakra_calculator_screen.dart';
import 'calculators/kabbalah_calculator_screen.dart';
import 'calculators/hermetic_calculator_screen.dart';
import 'calculators/gematria_calculator_screen.dart';
import 'calculators/spirit_profile_screen.dart'; // 🌟 Konsolidiert die 10 Universal-Tools
import 'calculators/epigenetik_coach_screen.dart'; // 🧬 Echte Epigenetik statt 12-Strang-DNA
import 'calculators/sacred_symbols_screen.dart'; // 🔱 Heilige Symbole multikulturell
import 'calculators/lernreihen_index_screen.dart'; // 📚 Tagesweise Lernpfade (17 Reihen)
import 'calculators/hermetic_reality_check_screen.dart'; // ✨ Reality-Check
import 'calculators/aura_quiz_screen.dart'; // 🌈 12-Fragen-Aura-Quiz
import 'calculators/archetype_quiz_screen.dart'; // 🧠 Pearson-Archetypen-Quiz
import 'calculators/relationship_numerology_screen.dart'; // 💕 Synastrie
import 'calculators/biorhythm_compatibility_screen.dart'; // 📊 Bio-Kompat
import 'calculators/god_oracle_chat_screen.dart'; // 🏛️ Götter-KI-Dialog
import 'calculators/dream_pattern_analysis_screen.dart'; // 💭 Traum-Muster
import 'calculators/family_tree_screen.dart'; // 🌳 Stammbaum
import 'calculators/tarot_spreads_screen.dart'; // 🔮 Tarot-Legesysteme (alt)
import 'calculators/tarot_oracle_screen.dart'; // 🔮 Cinematic mit AI-Lesung
import 'calculators/tarot_lexicon_screen.dart'; // 📚 78-Karten-Lexikon
import 'calculators/runes_oracle_screen.dart'; // ᚱ Elder Futhark Cinematic
import 'calculators/galdr_meditation_screen.dart'; // ᚠ Galdr-Gesang
import 'calculators/synastry_chart_screen.dart'; // 💞 Astrologie-Synastrie
import 'calculators/akasha_chronicle_screen.dart'; // 🌌 Cinematic Journal + AI
import 'calculators/birth_chart_360_screen.dart'; // ♓ 360° Visual Geburts-Chart
import 'calculators/biorhythm_chart_screen.dart'; // 📊 90-Tage Bio + Critical Days
import 'calculators/transformation_journey_screen.dart'; // 🦋 5-Dim Tracker
import 'calculators/human_design_bodygraph_screen.dart'; // 🌀 HD Body-Graph cinematic
import 'calculators/animated_sacred_geometry_screen.dart'; // 🔯 Animierte SVG
import 'calculators/sacred_geometry_constructor_screen.dart'; // 🔯 Interaktiver Konstruktor
import 'calculators/affirmations_studio_screen.dart'; // 🌟 Cinematic AI-Studio
import 'calculators/audio_body_scan_screen.dart'; // 🧘 TTS-Körperscan
import 'calculators/audio_meditation_screen.dart'; // 🧘 TTS-Meditationen
import 'calculators/photo_progress_screen.dart'; // 📸 Vor/Nach
import 'calculators/crystal_photo_id_screen.dart'; // 💎 KI-Foto-ID
import 'calculators/voice_affirmation_screen.dart'; // 💫 Voice-Recording
import 'calculators/mantra_practice_screen.dart'; // 🕉️ Mantra-Praxis cinematic
import 'calculators/iching_oracle_screen.dart'; // ☯ I-Ging cinematic
import 'calculators/new_spirit_tool_screens.dart';
import 'meditation_timer_screen.dart'; // MeditationTimerScreen (canonical, deduplicated)
import 'calculators/moon_calendar_tool_screen.dart'; // 🌕 v19 Mondkalender
import 'calculators/dream_interpretation_tool_screen.dart'; // 💭 v20 Traumdeutung
import 'calculators/body_scan_tool_screen.dart'; // 🧘 v21 Körperscan
import 'calculators/ancestral_work_tool_screen.dart'; // 🕯️ v23 Ahnenarbeit
import 'calculators/shamanic_journey_tool_screen.dart'; // 🥁 v24 Schamanische Reise (Timer)
import 'calculators/shamanic_guided_journey_screen.dart'; // 🥁 AI-Guided cinematic
import 'calculators/natal_chart_tool_screen.dart'; // ♓ v25 Geburtshoroskop
import 'calculators/human_design_tool_screen.dart'; // 🌀 v26 Human Design
import 'frequency_generator_screen.dart';  // 🎵 FREQUENCY GENERATOR
import '../spirit/spirit_tools_mega_screen.dart'; // 🆕 V115 MEGA UPDATE TOOLS
import 'planetary_transit_screen.dart'; // 🪐 Planeten & Transite
import 'energie_recherche_screen.dart'; // 🔮 Spirituelle Recherche

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
      // 🎓 Numerologie-Quiz -- Wissens-Check mit Gamification
      {
        'icon': Icons.school_rounded,
        'iconEmoji': '🎓',
        'title': 'Numerologie-Quiz',
        'subtitle': '30 Fragen, 3 Levels',
        'color': const Color(0xFFCE93D8),
        'category': 'core',
        'screen': const NumerologyQuizScreen(),
      },
      // 🏠 Alltags-Numerologie -- Adresse, Telefon, Kennzeichen
      {
        'icon': Icons.home_rounded,
        'iconEmoji': '🏠',
        'title': 'Alltags-Numerologie',
        'subtitle': 'Adresse, Telefon, Kennzeichen',
        'color': const Color(0xFF7C4DFF),
        'category': 'core',
        'screen': const EverydayNumerologyScreen(),
      },
      // 💕 Beziehungs-Numerologie — Synastrie aus zwei Profilen
      {
        'icon': Icons.favorite,
        'iconEmoji': '💕',
        'title': 'Beziehungs-Numerologie',
        'subtitle': 'Synastrie zweier Lebenszahlen',
        'color': const Color(0xFFE91E63),
        'category': 'core',
        'screen': const RelationshipNumerologyScreen(),
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
      // 🧠 Archetypen-Quiz — Pearson-12-Test mit Szenario-Fragen
      {
        'icon': Icons.quiz,
        'iconEmoji': '🎭',
        'title': 'Archetypen-Quiz',
        'subtitle': '12 Szenario-Fragen → dein Archetyp',
        'color': const Color(0xFF673AB7),
        'category': 'core',
        'screen': const ArchetypeQuizScreen(),
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
      // ✨ Reality-Check — Erweiterung zu Hermetik: aktuelle Lebenssituation
      // gegen die 7 Prinzipien prüfen, top-2-Hinweise + Praxis-Vorschlag.
      {
        'icon': Icons.psychology_outlined,
        'iconEmoji': '🔍',
        'title': 'Reality-Check',
        'subtitle': '7 hermetische Prinzipien auf deine Situation',
        'color': const Color(0xFFFF9800),
        'category': 'core',
        'screen': const HermeticRealityCheckScreen(),
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
      
      // 📚 LERNREIHEN — Zentraler Einstieg in 17 tagesweise Lernpfade
      // (Chakren 7d, Hermetik 7d, Schamanen 7d, Ahnen 7d, Numerologie 9d,
      //  Earthing 10d, Archetypen 12d, Olymp 12d, Geometrie 12d, Kabbala 22d
      //  + Phase-2: Meditation/Mantras/Affirmationen/Tarot/Runen/Yoga/I-Ging)
      {
        'icon': Icons.menu_book,
        'iconEmoji': '📚',
        'title': 'Lernreihen',
        'subtitle': 'Tagesweise Lernpfade · 17 Reihen aktiv',
        'color': const Color(0xFF4DB6AC),
        'category': 'core',
        'screen': const LernreihenIndexScreen(),
      },

      // === KONSOLIDIERT: 10 frühere Universal-Tools zu 1 Spirit-Profil ===
      // Energiefeld + Polaritäten + Transformation + Unterbewusstsein +
      // Innere Karten + Zyklen + Orientierung + Meta-Spiegel + Wahrnehmung +
      // Selbstbeobachtung — jetzt als 10 Tabs in einem Bericht.
      {
        'icon': Icons.auto_graph,
        'iconEmoji': '🌟',
        'title': 'Spirit-Profil',
        'subtitle': '10 Analysen in einem Bericht',
        'color': const Color(0xFF9C27B0),
        'category': 'core',
        'screen': const SpiritProfileScreen(),
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
      // 💎 Kristall-Foto-Erkennung — Cloudflare Workers AI Vision
      {
        'icon': Icons.camera,
        'iconEmoji': '🔍',
        'title': 'Kristall-Foto-KI',
        'subtitle': 'KI identifiziert deinen Stein',
        'color': const Color(0xFF1976D2),
        'category': 'new',
        'screen': const CrystalPhotoIdScreen(),
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
      // 🧘 Audio-Meditationen — 5 TTS-geleitete Sessions (5-10 Min)
      {
        'icon': Icons.headphones,
        'iconEmoji': '🎧',
        'title': 'Audio-Meditation',
        'subtitle': '5 geführte Sessions (Atem · Metta · Berg · Vergebung · Dank)',
        'color': const Color(0xFF4527A0),
        'category': 'new',
        'screen': const AudioMeditationScreen(),
      },
      
      // 🌈 Aura-Quiz (12 Fragen → dominante Aura-Farbe via Farbpsychologie)
      {
        'icon': Icons.color_lens,
        'iconEmoji': '🌈',
        'title': 'Aura-Quiz',
        'subtitle': '12 Fragen → deine Aura-Farbe',
        'color': const Color(0xFFAD1457),
        'category': 'new',
        'screen': const AuraQuizScreen(),
      },
      
      // 🧬 Epigenetik & Gen-Expression (ersetzt 12-Strang-DNA, evidenzbasiert)
      {
        'icon': Icons.biotech,
        'iconEmoji': '🧬',
        'title': 'Epigenetik',
        'subtitle': '12 Praktiken für Gen-Expression',
        'color': const Color(0xFF00695C),
        'category': 'new',
        'screen': const EpigenetikCoachScreen(),
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
      
      // 🌌 Akasha-Chronik cinematic — Journal + AI-Reflexion + Mood-Tracker
      {
        'icon': Icons.menu_book,
        'iconEmoji': '🌌',
        'title': 'Akasha-Chronik',
        'subtitle': 'Journal · AI-Reflexion · 30-Tage-Mood · Streak',
        'color': const Color(0xFF7C4DFF),
        'category': 'new',
        'screen': const AkashaChronicleScreen(),
      },
      
      // 🕉️ Mantra-Bibliothek (Original)
      {
        'icon': Icons.record_voice_over,
        'iconEmoji': '🕉️',
        'title': 'Mantras',
        'subtitle': '30+ Sanskrit-Mantras',
        'color': const Color(0xFFE65100),
        'category': 'new',
        'screen': const MantraLibraryScreen(),
      },
      // 🕉️ Mantra-Praxis (cinematic) — Audio + 108-Mala + Tagesmantra
      {
        'icon': Icons.spa,
        'iconEmoji': '📿',
        'title': 'Mantra-Praxis',
        'subtitle': 'Aussprache · 108-Mala · Tagesmantra',
        'color': const Color(0xFFFFB300),
        'category': 'new',
        'screen': const MantraPracticeScreen(),
      },
      
      // 🔯 Heilige Geometrie · Interaktiver Konstruktor (cinematic)
      {
        'icon': Icons.hexagon_outlined,
        'iconEmoji': '🔯',
        'title': 'Heilige Geometrie',
        'subtitle': '6 Stufen · Touch-Konstruktor',
        'color': const Color(0xFF00838F),
        'category': 'new',
        'screen': const SacredGeometryConstructorScreen(),
      },
      // 🌀 Animierte Geometrie — Live-Stroke-Animation der 8 Hauptformen
      {
        'icon': Icons.architecture,
        'iconEmoji': '🌀',
        'title': 'Animierte Geometrie',
        'subtitle': '8 Formen · Live-Stroke-Animation',
        'color': const Color(0xFF00ACC1),
        'category': 'new',
        'screen': const AnimatedSacredGeometryScreen(),
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
      
      // 🦋 Transformation-Journey cinematic — 5-Dim + Streak + Korrelationen
      {
        'icon': Icons.trending_up,
        'iconEmoji': '🦋',
        'title': 'Transformation',
        'subtitle': '5 Dimensionen · Chart · Streak · Korrelationen',
        'color': const Color(0xFFFF7043),
        'category': 'new',
        'screen': const TransformationJourneyScreen(),
      },
      // 📸 Vor/Nach-Foto — Body/Mind/Soul Timeline mit Vergleich
      {
        'icon': Icons.photo_camera,
        'iconEmoji': '📸',
        'title': 'Vor/Nach-Foto',
        'subtitle': 'Foto-Timeline · Side-by-Side-Vergleich',
        'color': const Color(0xFFF57C00),
        'category': 'new',
        'screen': const PhotoProgressScreen(),
      },
      
      // 🔱 Heilige Symbole multikulturell (ersetzt esoterische Lichtsprache,
      // mit echten etymologischen/historischen Bedeutungen via Wikipedia-API)
      {
        'icon': Icons.brightness_high,
        'iconEmoji': '🔱',
        'title': 'Heilige Symbole',
        'subtitle': 'Multikulturelle Sakralsymbole',
        'color': const Color(0xFFFDD835),
        'category': 'new',
        'screen': const SacredSymbolsScreen(),
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
      // 🏛️ Götter-KI-Dialog — chatte mit der Persona eines gewählten Gottes
      {
        'icon': Icons.forum,
        'iconEmoji': '🏛️',
        'title': 'Götter-Dialog',
        'subtitle': 'KI-Chat mit 17 Pantheons',
        'color': const Color(0xFF6A1B9A),
        'category': 'new',
        'screen': const GodOracleChatScreen(),
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
      // 💭 Traum-Muster — KI-Jungianische Analyse über die letzten 60 Träume
      {
        'icon': Icons.analytics,
        'iconEmoji': '🔮',
        'title': 'Traum-Muster KI',
        'subtitle': 'Jung-Analyse aller Träume',
        'color': const Color(0xFF1A237E),
        'category': 'new',
        'screen': const DreamPatternAnalysisScreen(),
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
      // 🧘 Audio-Körperscan — 10 Min TTS-geführte Vipassana
      {
        'icon': Icons.spatial_audio,
        'iconEmoji': '🎙️',
        'title': 'Audio-Körperscan',
        'subtitle': '10 Min · 20 Regionen · deutsche TTS',
        'color': const Color(0xFFE91E63),
        'category': 'new',
        'screen': const AudioBodyScanScreen(),
      },

      // 🌳 Stammbaum-Generator — 3 Generationen Ahnenarbeit
      {
        'icon': Icons.account_tree,
        'iconEmoji': '🌳',
        'title': 'Stammbaum',
        'subtitle': '3 Generationen · lokal',
        'color': const Color(0xFFD4A24C),
        'category': 'new',
        'screen': const FamilyTreeScreen(),
      },

      // 🔮 Tarot-Legesysteme — 1/3/5/10-Karten-Spreads
      {
        'icon': Icons.style,
        'iconEmoji': '🃏',
        'title': 'Tarot-Orakel',
        'subtitle': 'Shuffle-Animation · 3 Spreads · AI-Lesung · Verlauf',
        'color': const Color(0xFF8E5AE2),
        'category': 'new',
        'screen': const TarotOracleScreen(),
      },
      // 📚 Tarot-Lexikon -- alle 78 Karten browsebar (v95)
      {
        'icon': Icons.menu_book_rounded,
        'iconEmoji': '📚',
        'title': 'Tarot-Lexikon',
        'subtitle': '78 Karten · Filter · Suche · Detail-Lesungen',
        'color': const Color(0xFFCE93D8),
        'category': 'core',
        'screen': const TarotLexiconScreen(),
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

      // 🥁 Schamanische Reise · AI-Guided 5-Phasen cinematic
      {
        'icon': Icons.nightlight_round,
        'iconEmoji': '🥁',
        'title': 'Schamanen-Reise',
        'subtitle': '3 Welten · AI-Narration · Theta-Pulse · Safety',
        'color': const Color(0xFF6D4C41),
        'category': 'new',
        'screen': const ShamanicGuidedJourneyScreen(),
      },
      // 🥁 Klassische Trommel-Reise (Timer + Manuelles Journal)
      {
        'icon': Icons.timer_rounded,
        'iconEmoji': '🥁',
        'title': 'Trommel-Timer',
        'subtitle': 'Trommel-BPM-Library · Manuelles Journal',
        'color': const Color(0xFF8E5AE2),
        'category': 'new',
        'screen': const ShamanicJourneyToolScreen(),
      },

      // ♓ Geburtshoroskop 360° — Cinematic Visual-Chart
      {
        'icon': Icons.brightness_2,
        'iconEmoji': '♓',
        'title': 'Geburtshoroskop 360°',
        'subtitle': 'Zodiac-Rad · 10 Planeten · 5 Aspekte · Transits',
        'color': const Color(0xFF7E57C2),
        'category': 'new',
        'screen': const BirthChart360Screen(),
      },
      // ♓ Geburtshoroskop klassisch (v25 – Meeus-Astrologie + Lexikon)
      {
        'icon': Icons.auto_awesome,
        'iconEmoji': '♓',
        'title': 'Horoskop-Lexikon',
        'subtitle': 'Verlauf · Planeten · Zeichen-Lexikon',
        'color': const Color(0xFF6C63FF),
        'category': 'new',
        'screen': const NatalChartToolScreen(),
      },

      // 🌀 Human Design — cinematic Body-Graph mit Visual-Zentren
      {
        'icon': Icons.bubble_chart_rounded,
        'iconEmoji': '🌀',
        'title': 'Human Design',
        'subtitle': '9 Zentren · Visual · 5 Typen · Strategie',
        'color': const Color(0xFF00ACC1),
        'category': 'new',
        'screen': const HumanDesignBodyGraphScreen(),
      },
      // 🌀 Human Design klassisch (Tabs mit Tor-Liste + Lexikon)
      {
        'icon': Icons.hub,
        'iconEmoji': '🌀',
        'title': 'HD-Lexikon',
        'subtitle': 'Tor-Listen · Profil-Lexikon · Channels',
        'color': const Color(0xFF26C6DA),
        'category': 'new',
        'screen': const HumanDesignToolScreen(),
      },

      // ᚱ Runen-Orakel cinematic — Cast-Animation, 3 Spreads, AI, Bind-Rune
      {
        'icon': Icons.auto_stories,
        'iconEmoji': 'ᚱ',
        'title': 'Runen-Orakel',
        'subtitle': '24 Elder Futhark · Cast · AI · Bind-Rune',
        'color': const Color(0xFF1B5E20),
        'category': 'new',
        'screen': const RunesOracleScreen(),
      },
      // ᚠ Galdr-Meditation -- Runen-Gesang (v95)
      {
        'icon': Icons.self_improvement_rounded,
        'iconEmoji': 'ᚠ',
        'title': 'Galdr-Meditation',
        'subtitle': '24 Runen-Gesaenge · Atem · 3/5/9 min',
        'color': const Color(0xFFC9A84C),
        'category': 'core',
        'screen': const GaldrMeditationScreen(),
      },
      // 💞 Synastrie -- Astrologie Partner-Vergleich (v95)
      {
        'icon': Icons.favorite_border_rounded,
        'iconEmoji': '💞',
        'title': 'Synastrie-Chart',
        'subtitle': 'Astrologie Partner-Vergleich · 5 Aspekte',
        'color': const Color(0xFFEC407A),
        'category': 'core',
        'screen': const SynastryChartScreen(),
      },

      // 💫 Affirmationen · Cinematic AI-Studio
      {
        'icon': Icons.format_quote,
        'iconEmoji': '💫',
        'title': 'Affirmationen',
        'subtitle': 'AI · 9 Kategorien · TTS · Sets',
        'color': const Color(0xFFE91E63),
        'category': 'new',
        'screen': const AffirmationsStudioScreen(),
      },
      // 💫 Voice-Affirmationen — eigene Stimme aufnehmen + loopen
      {
        'icon': Icons.mic_external_on,
        'iconEmoji': '🎤',
        'title': 'Voice-Affirmation',
        'subtitle': 'Selbstsuggestion mit eigener Stimme (Coué)',
        'color': const Color(0xFFE91E63),
        'category': 'new',
        'screen': const VoiceAffirmationScreen(),
      },
      
      // 📊 Biorhythmus cinematic — 6 Zyklen, 90-Tage-Chart, Critical Days
      {
        'icon': Icons.show_chart,
        'iconEmoji': '📊',
        'title': 'Biorhythmus',
        'subtitle': '6 Zyklen · 90-Tage-Chart · Critical Days · Mondphase',
        'color': const Color(0xFF26C6DA),
        'category': 'new',
        'screen': const BiorhythmChartScreen(),
      },
      // 📊 Biorhythmus-Kompatibilität — zwei Geburtsdaten vergleichen
      {
        'icon': Icons.compare_arrows,
        'iconEmoji': '🔗',
        'title': 'Biorhythmus-Kompat',
        'subtitle': 'Zwei Personen heute vergleichen',
        'color': const Color(0xFF00897B),
        'category': 'new',
        'screen': const BiorhythmCompatibilityScreen(),
      },
      
      // ☯ I-Ging Münzwurf-Orakel (cinematic) · Wandlung + AI + Verlauf
      // (Simple I-Ging entfernt v5.43.1 - Muenzwurf ist die bessere Variante)
      {
        'icon': Icons.casino,
        'iconEmoji': '🪙',
        'title': 'I-Ging Münzwurf',
        'subtitle': 'Wandlungs-Lesung mit AI · Verlauf',
        'color': const Color(0xFF7C4DFF),
        'category': 'new',
        'screen': const IChingOracleScreen(),
      },

      // ═══════════════════════════════════════════════════════════
      // 🌌 KOSMOS-TOOLS — Planeten & Recherche
      // ═══════════════════════════════════════════════════════════

      // 🪐 Planeten & Transite
      {
        'icon': Icons.public,
        'iconEmoji': '🪐',
        'title': 'Planeten & Transite',
        'subtitle': 'Kosmische Einflüsse heute',
        'color': const Color(0xFF1A237E),
        'category': 'cosmos',
        'screen': const PlanetaryTransitScreen(),
      },

      // 🔮 Spirituelle Recherche
      {
        'icon': Icons.search,
        'iconEmoji': '🔮',
        'title': 'Spirituelle Recherche',
        'subtitle': 'Bücher, Studien & Wissen',
        'color': const Color(0xFF4A148C),
        'category': 'cosmos',
        'screen': const EnergieRechercheScreen(),
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
                for (final cat in const [
                  ['all',      '✨ Alle'],
                  ['core',     '⭐ Kern'],
                  ['advanced', '🚀 Erweitert'],
                  ['meta',     '🌌 Meta'],
                  ['new',      '🆕 Neu'],
                  ['cosmos',   '🌌 Kosmos'],
                ])
                  if (_getCategoryCount(cat[0]) > 0) ...[
                    _buildCategoryChip(cat[0], cat[1], _chipColor(cat[0]), _getCategoryCount(cat[0])),
                    const SizedBox(width: 10),
                  ],
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Color _chipColor(String cat) => switch (cat) {
        'all'      => _purple,
        'core'     => _teal,
        'advanced' => _pink,
        'meta'     => _gold,
        'new'      => _green,
        'cosmos'   => const Color(0xFF1A237E),
        _          => _purple,
      };

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
