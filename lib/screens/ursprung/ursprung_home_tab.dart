import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/animations/wb_tap_scale.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/wb_cinematic_tokens.dart';
import '../../widgets/cinematic/wb_world_orb.dart';
import '../../widgets/cinematic/wb_stagger_reveal.dart';
import '../../services/mentor_service.dart';
import '../../widgets/mentor_hero_card.dart';
import '../../services/unified_profile_service.dart';
import '../../services/ursprung_service.dart';
import '../shared/mentor_chat_screen.dart';
import 'mentor_session_screen.dart';

import '../../widgets/daily_path_widget.dart';
import '../../widgets/world_xp_header.dart';
import '../../widgets/daily_revelation_card.dart';
import '../../widgets/daily_practice_card.dart';

import 'ursprung_community_tab.dart';
import 'ursprung_lesson_screen.dart';
import 'ursprung_live_chat_screen.dart';
import 'ursprung_modules_screen.dart';
import 'ursprung_timeline_screen.dart';
import 'tools/gateway_room_screen.dart';
import 'tools/frequency_generator_screen.dart';
import 'tools/breathmaster_screen.dart';
import 'tools/breath_hold_timer_screen.dart';
import 'tools/reality_architect_screen.dart';
import 'tools/rv_trainer_screen.dart';
import 'tools/origin_tools.dart';

/// 🌀 URSPRUNG Home Tab — CIA Quanten-Code (deklassifiziert)
///
/// Live-Daten-driven Home Tab (konsistent zu Vorhang):
/// - Hero Section mit Fortschritts-Balken
/// - 🧠 KI-Mentor Button (Alchemist)
/// - Kern-Tool (Zeitleiste) · Werkzeuge · Lebendiger Planet
/// - Branch-Progress Horizontal-Scroll-Cards (5 Zweige, dynamisch)
/// - "Nächstes Modul"-Karte (prominent) + "Zuletzt abgeschlossen"-Liste
/// - CIA-Footer (Ursprung-exklusiv)
class UrsprungHomeTab extends StatefulWidget {
  final ValueChanged<int>? onSwitchTab;

  const UrsprungHomeTab({super.key, this.onSwitchTab});

  @override
  State<UrsprungHomeTab> createState() => _UrsprungHomeTabState();
}

class _UrsprungHomeTabState extends State<UrsprungHomeTab> {
  // URSPRUNG Farben
  static const _cyan = Color(0xFF00D4AA);
  static const _cyanAccent = Color(0xFF00FFD4);
  static const _bgDeep = Color(0xFF050510);
  static const _surface = Color(0xFF080818);

  // Branch-Keys wie in ursprung_modules (snake_case) -> Anzeige + Icon.
  static const List<String> _branchOrder = [
    'gateway_foundation',
    'focus_levels',
    'energy_tools',
    'patterning_manifestation',
    'remote_viewing',
  ];

  static const Map<String, String> _branchTitles = {
    'gateway_foundation': 'Gateway Foundation',
    'focus_levels': 'Focus Levels',
    'energy_tools': 'Energiewerkzeuge',
    'patterning_manifestation': 'Patterning & Manifestation',
    'remote_viewing': 'Remote Viewing',
  };

  static const Map<String, IconData> _branchIcons = {
    'gateway_foundation': Icons.door_sliding_outlined,
    'focus_levels': Icons.psychology,
    'energy_tools': Icons.bolt,
    'patterning_manifestation': Icons.auto_awesome,
    'remote_viewing': Icons.visibility,
  };

  bool _loading = true;
  String? _error;
  Map<String, List<Map<String, dynamic>>> _branches = {};
  int _totalCount = 0;
  int _completedCount = 0;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Fall back to UnifiedProfileService.userId when no Supabase Auth
      // session exists (InvisibleAuth users) -- otherwise admin module
      // overrides never load for app-only profiles.
      final user = Supabase.instance.client.auth.currentUser;
      final userId = user?.id ?? UnifiedProfileService.instance.userId;
      final data = await UrsprungService.fetchModules(userId: userId);
      final rawBranches = (data['branches'] as Map?) ?? {};
      final mapped = <String, List<Map<String, dynamic>>>{};
      for (final b in _branchOrder) {
        final list = (rawBranches[b] as List?) ?? const [];
        mapped[b] = list
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
      }
      setState(() {
        _branches = mapped;
        _totalCount = (data['total'] as num?)?.toInt() ?? 0;
        _completedCount = (data['completed'] as num?)?.toInt() ?? 0;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// Find next unlocked, not-yet-completed module.
  Map<String, dynamic>? get _nextModule {
    for (final branch in _branchOrder) {
      final modules = _branches[branch] ?? const [];
      for (final m in modules) {
        if (m['is_unlocked'] == true && m['is_completed'] != true) {
          return m;
        }
      }
    }
    return null;
  }

  List<Map<String, dynamic>> get _lastCompleted {
    final all = <Map<String, dynamic>>[];
    for (final branch in _branchOrder) {
      final list = _branches[branch] ?? const <Map<String, dynamic>>[];
      for (final m in list) {
        if (m['is_completed'] == true) all.add(m);
      }
    }
    all.sort((a, b) {
      final ac = (a['module_code'] as String?) ?? '';
      final bc = (b['module_code'] as String?) ?? '';
      return bc.compareTo(ac);
    });
    return all.take(3).toList();
  }

  void _openLesson(String moduleCode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UrsprungLessonScreen(moduleCode: moduleCode),
      ),
    ).then((_) => _fetch());
  }

  void _openAllModules() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UrsprungModulesScreen()),
    ).then((_) => _fetch());
  }

  @override
  Widget build(BuildContext context) {
    final moduleCount = _totalCount > 0 ? _totalCount : 25;
    return Container(
      color: _bgDeep,
      child: RefreshIndicator(
        color: _cyan,
        backgroundColor: _surface,
        onRefresh: _fetch,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          // Bottom-Inset (Gesten-Leiste) zur Floating-Nav-Hoehe addieren,
          // damit der CIA-Footer auf Geraeten mit hoher Navigationsleiste
          // nicht hinter der Nav verschwindet.
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            100 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero Section (mit Fortschritts-Balken) ──
              _buildHeroSection(),
              const SizedBox(height: 12),

              // FEATURE (U1): Level + XP + Streak sichtbar.
              const WorldXpHeader(world: 'ursprung', accent: _cyan),
              const SizedBox(height: 12),

              // Täglicher Bewusstseins-Impuls.
              DailyRevelationCard(
                accent: _cyan,
                emoji: '🌌',
                label: 'IMPULS DES TAGES',
                principles: DailyRevelationCard.ursprungInsights,
              ),
              const SizedBox(height: 12),

              // Tägliche Praxis-Challenge -- konkrete Mikro-Übung.
              const DailyPracticeCard(
                accent: _cyan,
                practices: DailyPracticeCard.ursprungPractices,
              ),
              const SizedBox(height: 20),

              // ── 🧠 KI-Mentor (Alchemist) ──
              Text(
                'MENTOR',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4.0,
                  color: _cyan.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 12),
              _buildMentorButton(context),
              const SizedBox(height: 28),

              // ── COMMUNITY: Beiträge-Feed ──
              _sectionLabel('COMMUNITY'),
              const SizedBox(height: 12),
              _buildToolCard(
                context: context,
                emoji: '📝',
                title: 'Beiträge',
                subtitle: 'Community-Feed - Erfahrungen teilen & lesen.',
                builder: (_) => const UrsprungPostsScreen(),
              ),
              const SizedBox(height: 28),

              // ── KERN-TOOL: Zeitleiste der Menschheitsursprünge ──
              _sectionLabel('KERN-TOOL'),
              const SizedBox(height: 12),
              _buildTimelineCard(context),
              const SizedBox(height: 28),

              // ── INTERAKTIVE WERKZEUGE ──
              _sectionLabel('WERKZEUGE'),
              const SizedBox(height: 12),
              _buildToolCard(
                context: context,
                emoji: '🚪',
                title: 'Gateway-Kammer',
                subtitle: 'Hemi-Sync Meditation · F10/F12/F15/F21',
                builder: (_) => const GatewayRoomScreen(),
              ),
              const SizedBox(height: 10),
              _buildToolCard(
                context: context,
                emoji: '🎵',
                title: 'Frequenz-Generator',
                subtitle: '1–40 Hz Slider · 7 Presets (Schumann 7.83 Hz)',
                builder: (_) => const FrequencyGeneratorScreen(),
              ),
              const SizedBox(height: 10),
              _buildToolCard(
                context: context,
                emoji: '🌬️',
                title: 'Atemmeister',
                subtitle: 'Resonant Tuning · Coherent · Energy · Click-Out',
                builder: (_) => const BreathmasterScreen(),
              ),
              const SizedBox(height: 10),
              _buildToolCard(
                context: context,
                emoji: '🫁',
                title: 'CO2-Toleranz-Timer',
                subtitle: 'Atemhalte-Training · Bestzeit · Verlauf',
                builder: (_) => const BreathHoldTimerScreen(),
              ),
              const SizedBox(height: 10),
              _buildToolCard(
                context: context,
                emoji: '🏗️',
                title: 'Realitäts-Architekt',
                subtitle: '6-Schritt Patterning · CIA McDonnell-Protokoll',
                builder: (_) => const RealityArchitectScreen(),
              ),
              const SizedBox(height: 10),
              _buildToolCard(
                context: context,
                emoji: '👁️',
                title: 'RV Trainer',
                subtitle: '50 Targets · CRV 3-Stage · Ingo Swann',
                builder: (_) => const RvTrainerScreen(),
              ),
              const SizedBox(height: 28),

              // ── LEBENDIGER PLANET (Ursprung-exklusiv) ──
              _sectionLabel('LEBENDIGER PLANET'),
              const SizedBox(height: 12),
              _buildToolCard(
                context: context,
                emoji: '🎙️',
                title: 'Livestream',
                subtitle: 'Live-Chat & Sprachraeume',
                builder: (_) => const UrsprungLiveChatScreen(),
              ),
              const SizedBox(height: 10),
              _buildToolCard(
                context: context,
                emoji: '🐾',
                title: 'Artenvielfalt',
                subtitle: 'Biodiversität weltweit · GBIF Live-Daten',
                builder: (_) => const BiodiversityScreen(),
              ),
              const SizedBox(height: 10),
              _buildToolCard(
                context: context,
                emoji: '✨',
                title: 'Sternenhimmel heute',
                subtitle: 'Sichtbare Planeten · Himmelskalender',
                builder: (_) => const NightSkyScreen(),
              ),
              const SizedBox(height: 10),
              _buildToolCard(
                context: context,
                emoji: '🌍',
                title: 'Naturphänomene',
                subtitle: 'Stürme, Eis, Dürre weltweit · NASA EONET',
                builder: (_) => const NaturePhenomenaScreen(),
              ),
              const SizedBox(height: 10),
              _buildToolCard(
                context: context,
                emoji: '🗣️',
                title: 'Indigene Sprachen',
                subtitle: 'Naturvölker & ihr Wissen · Datenbank',
                builder: (_) => const IndigenousLanguagesScreen(),
              ),
              const SizedBox(height: 28),

              // ── Ambient Tagespfad ──
              const DailyPathWidget(),
              const SizedBox(height: 28),

              // ── Branch Progress horizontal scroll (dynamisch) ──
              _buildBranchProgressSection(),
              const SizedBox(height: 28),

              // ── Next Module prominent card ──
              _buildNextModuleSection(),
              const SizedBox(height: 28),

              // ── Last completed list ──
              _buildLastCompletedSection(),
              const SizedBox(height: 16),

              // ── See all modules button ──
              Center(
                child: OutlinedButton.icon(
                  onPressed: _openAllModules,
                  icon: const Icon(Icons.menu_book, color: _cyan),
                  label: Text(
                    'ALLE $moduleCount MODULE',
                    style: const TextStyle(
                      color: _cyan,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: _cyan.withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── CIA-Footer (Ursprung-exklusiv) ──
              _buildCiaFooter(),
            ]
                .asMap()
                .entries
                .map(
                  (e) => WBStaggerReveal(
                    index: e.key,
                    staggerStep: const Duration(milliseconds: 40),
                    child: e.value,
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  // ── Section-Label mit Cyan-Accent-Bar ──
  Widget _sectionLabel(String s, {String? trailing}) => Row(
        children: [
          Container(
            width: 3,
            height: 13,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_cyanAccent, Color(0x3300D4AA)],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            s,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 4.0,
              color: _cyan.withValues(alpha: 0.9),
            ),
          ),
          if (trailing != null) ...[
            const Spacer(),
            Text(
              trailing,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 11,
              ),
            ),
          ],
        ],
      );

  Widget _buildHeroSection() {
    final percent = _totalCount > 0 ? _completedCount / _totalCount : 0.0;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_surface, _cyan.withValues(alpha: 0.08), _bgDeep],
        ),
        border: Border.all(color: _cyan.withValues(alpha: 0.30)),
        boxShadow: [
          BoxShadow(
            color: _cyan.withValues(alpha: 0.20),
            blurRadius: 50,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Ambient Welt-Orb als Lichtanker (hinter dem Content).
            Positioned(
              top: -34,
              right: -24,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.42,
                  child: WBWorldOrb(world: WBWorld.ursprung, size: 130),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _cyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _cyan.withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Text(
                          'WELT IV · CIA QUANTEN-CODE',
                          style: TextStyle(
                            fontSize: 9,
                            letterSpacing: 3.0,
                            color: _cyan,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (!_loading)
                        Text(
                          '$_completedCount / $_totalCount',
                          style: const TextStyle(
                            color: _cyan,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      else
                        const Icon(Icons.bolt, color: _cyanAccent, size: 18),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'URSPRUNG',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w200,
                      fontSize: 36,
                      letterSpacing: 10.0,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kehre zum Ursprung zurück',
                    style: TextStyle(
                      fontSize: 14,
                      color: _cyan,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bewusstsein ist der Ursprung der Realität. '
                    'Entdecke die deklassifizierten CIA-Programme — '
                    'Gateway Process, Project Stargate, Remote Viewing — '
                    'und werde Architekt deiner eigenen Wirklichkeit.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.65),
                      height: 1.6,
                    ),
                  ),
                  if (!_loading && _totalCount > 0) ...[
                    const SizedBox(height: 18),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: percent,
                        minHeight: 6,
                        backgroundColor: _cyan.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation(_cyan),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${(percent * 100).round()}% zum Ursprung erwacht',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMentorButton(BuildContext context) {
    return Column(
      children: [
        MentorHeroCard(
          world: 'ursprung',
          mentorName: 'Alchemist',
          tagline: 'Bewusstsein - Quanten - Realitaet',
          icon: Icons.all_inclusive_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const MentorChatScreen(
                personality: MentorPersonality.alchemist,
                world: 'ursprung',
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Avatar-Modus: immersive 3D-Session direkt starten
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MentorSessionScreen(
                  personality: MentorPersonality.alchemist,
                  world: 'ursprung',
                ),
              ),
            ),
            icon: const Icon(Icons.face_retouching_natural, size: 16),
            label: const Text('Avatar-Modus'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _cyan,
              side: BorderSide(color: _cyan.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 10),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── KERN-TOOL: Zeitleiste der Menschheitsursprünge ──
  Widget _buildTimelineCard(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UrsprungTimelineScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _cyan.withValues(alpha: 0.18),
                _cyan.withValues(alpha: 0.05),
                _surface,
              ],
            ),
            border: Border.all(
              color: _cyan.withValues(alpha: 0.45),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: _cyan.withValues(alpha: 0.15),
                blurRadius: 26,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _cyan.withValues(alpha: 0.15),
                  border: Border.all(color: _cyan.withValues(alpha: 0.5)),
                ),
                child: const Text('🕰️', style: TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Zeitleiste der Menschheitsursprünge',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Schoepfungsmythen, Urkulturen & offene Fragen -- '
                      'interaktiv von den Anfaengen bis heute.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: _cyan.withValues(alpha: 0.7),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolCard({
    required BuildContext context,
    required String emoji,
    required String title,
    required String subtitle,
    required WidgetBuilder builder,
  }) {
    // WbTapScale: Scale-on-Press + Haptik (reduce-motion-bewusst).
    return WbTapScale(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: builder)),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _surface.withValues(alpha: 0.9),
              Color.lerp(_surface, _cyan, 0.06)!.withValues(alpha: 0.85),
            ],
          ),
          border: Border.all(color: _cyan.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: _cyan.withValues(alpha: 0.12),
              blurRadius: 20,
              spreadRadius: -2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: _cyan.withValues(alpha: 0.10),
                border: Border.all(color: _cyan.withValues(alpha: 0.30)),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _cyan.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _cyan.withValues(alpha: 0.40)),
              ),
              child: Text(
                'ÖFFNEN',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: _cyanAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Branch progress horizontal scroll (dynamisch) ──
  Widget _buildBranchProgressSection() {
    if (_loading) return _buildSkeletonRow();
    if (_error != null) return _buildErrorCard(_error!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('ZWEIGE', trailing: '5 Pfade · 25 Module'),
        const SizedBox(height: 14),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _branchOrder.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final key = _branchOrder[i];
              final name = _branchTitles[key] ?? key;
              final modules = _branches[key] ?? const [];
              final completed =
                  modules.where((m) => m['is_completed'] == true).length;
              final total = modules.length;
              final percent = total > 0 ? completed / total : 0.0;
              final allDone = total > 0 && completed == total;
              return GestureDetector(
                onTap: _openAllModules,
                child: Container(
                  width: 150,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _surface.withValues(alpha: 0.95),
                        Color.lerp(
                          _surface,
                          _cyan,
                          0.07,
                        )!
                            .withValues(alpha: 0.9),
                      ],
                    ),
                    border: Border.all(
                      color: allDone
                          ? _cyan.withValues(alpha: 0.55)
                          : _cyan.withValues(alpha: 0.18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: _cyan.withValues(alpha: allDone ? 0.22 : 0.10),
                        blurRadius: 22,
                        spreadRadius: -2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _cyan.withValues(alpha: 0.15),
                              border: Border.all(
                                color: _cyan.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Icon(
                              _branchIcons[key] ?? Icons.folder,
                              color: _cyan,
                              size: 16,
                            ),
                          ),
                          const Spacer(),
                          if (allDone)
                            const Icon(Icons.verified, color: _cyan, size: 18),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                      const Spacer(),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percent,
                          minHeight: 4,
                          backgroundColor: _cyan.withValues(alpha: 0.1),
                          valueColor: const AlwaysStoppedAnimation(_cyan),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$completed / $total',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Next module card ──
  Widget _buildNextModuleSection() {
    if (_loading) return const SizedBox.shrink();
    final next = _nextModule;
    if (next == null) {
      if (_totalCount > 0 && _completedCount == _totalCount) {
        return _buildCompletionCard();
      }
      return const SizedBox.shrink();
    }
    final code = (next['module_code'] as String?) ?? '';
    final title = (next['title'] as String?) ?? '';
    final branchKey = (next['branch'] as String?) ?? '';
    final branch = _branchTitles[branchKey] ?? branchKey;
    final subtitle = (next['subtitle'] as String?) ?? '';
    final isBoss = next['is_boss_module'] == true;
    final xp = (next['xp_reward'] as num?)?.toInt() ?? 50;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('NÄCHSTES MODUL'),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => _openLesson(code),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _cyan.withValues(alpha: 0.22),
                  _cyan.withValues(alpha: 0.06),
                  _surface,
                ],
              ),
              border: Border.all(
                color: _cyan.withValues(alpha: 0.55),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: _cyan.withValues(alpha: 0.18),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _cyan.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        code,
                        style: const TextStyle(
                          color: _cyan,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    if (isBoss) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_cyan, _cyanAccent],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'BOSS',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    const Icon(Icons.play_circle_fill, color: _cyan, size: 26),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  branch,
                  style: TextStyle(
                    color: _cyan.withValues(alpha: 0.85),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      Icons.bolt,
                      color: _cyan.withValues(alpha: 0.85),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+$xp XP',
                      style: const TextStyle(
                        color: _cyan,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Jetzt beginnen →',
                      style: TextStyle(
                        color: _cyan.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Last completed ──
  Widget _buildLastCompletedSection() {
    if (_loading) return const SizedBox.shrink();
    final list = _lastCompleted;
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('ZULETZT ABGESCHLOSSEN'),
        const SizedBox(height: 14),
        for (final m in list)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildCompletedTile(m),
          ),
      ],
    );
  }

  Widget _buildCompletedTile(Map<String, dynamic> m) {
    final code = (m['module_code'] as String?) ?? '';
    final title = (m['title'] as String?) ?? '';
    final branchKey = (m['branch'] as String?) ?? '';
    final icon = _branchIcons[branchKey] ?? Icons.school;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openLesson(code),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: _surface.withValues(alpha: 0.5),
            border: Border.all(color: _cyan.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1B5E20).withValues(alpha: 0.4),
                  border: Border.all(
                    color: Colors.greenAccent.withValues(alpha: 0.5),
                  ),
                ),
                child: Icon(
                  icon,
                  color: Colors.greenAccent.withValues(alpha: 0.9),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          code,
                          style: TextStyle(
                            color: _cyan.withValues(alpha: 0.85),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.check_circle,
                          color: Colors.greenAccent,
                          size: 14,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: _cyan.withValues(alpha: 0.5),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(colors: [_cyan, _cyanAccent]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.black, size: 28),
              SizedBox(width: 10),
              Text(
                'URSPRUNG ERWACHT',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Du hast alle 25 Module des CIA-Quanten-Codes gemeistert. '
            'Du bist Architekt deiner eigenen Wirklichkeit.',
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonRow() {
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => Container(
          width: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: _surface.withValues(alpha: 0.4),
            border: Border.all(color: _cyan.withValues(alpha: 0.1)),
          ),
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _cyan.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String err) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.red.withValues(alpha: 0.1),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Module konnten nicht geladen werden.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            onPressed: _fetch,
            child: const Text('Erneut', style: TextStyle(color: _cyan)),
          ),
        ],
      ),
    );
  }

  Widget _buildCiaFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: _surface.withValues(alpha: 0.5),
        border: Border.all(color: _cyan.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                color: _cyan.withValues(alpha: 0.7),
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'BASIEREND AUF DEKLASSIFIZIERTEN CIA-DOKUMENTEN',
                  style: TextStyle(
                    color: _cyan.withValues(alpha: 0.7),
                    fontSize: 9,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '• Gateway Process Report — Lt. Col. Wayne McDonnell, 1983\n'
            '• Project Stargate / SCANATE / GRILL FLAME / STAR GATE\n'
            '• Coordinate Remote Viewing — Ingo Swann (1971-1995)\n'
            '• Hemi-Sync Research — Monroe Institute',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Volltexte: cia.gov/readingroom (FOIA-freigegeben)',
            style: TextStyle(
              color: _cyanAccent.withValues(alpha: 0.6),
              fontSize: 10.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
