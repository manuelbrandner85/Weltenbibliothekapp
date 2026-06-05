import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/wb_cinematic_tokens.dart';
import '../../widgets/cinematic/wb_world_orb.dart';
import '../../widgets/cinematic/wb_stagger_reveal.dart';

import '../../services/mentor_service.dart';
import '../../widgets/mentor_hero_card.dart';
import '../../services/vorhang_service.dart';
import '../shared/mentor_chat_screen.dart';
import '../../widgets/daily_path_widget.dart';
import '../../widgets/world_xp_header.dart';
import '../../widgets/daily_revelation_card.dart';
import '../../widgets/daily_practice_card.dart';
import 'vorhang_community_tab.dart';
import 'vorhang_lesson_screen.dart';
import 'vorhang_live_chat_screen.dart';
import 'vorhang_modules_screen.dart';
import 'vorhang_symbol_decoder_screen.dart';
import 'tools/power_tools.dart';

/// 🎭 VORHANG Home Tab — Dunkle Psychologie & Elite-Strategien
///
/// Live-Daten-driven Home Tab:
/// - Hero Section (Welt-Branding)
/// - 🧠 KI-Mentor Button (Stratege)
/// - Branch-Progress Horizontal-Scroll-Cards (6 Branches)
/// - "Nächstes Modul"-Karte (prominent, gold)
/// - "Zuletzt abgeschlossen"-Liste
class VorhangHomeTab extends StatefulWidget {
  final ValueChanged<int>? onSwitchTab;

  const VorhangHomeTab({super.key, this.onSwitchTab});

  @override
  State<VorhangHomeTab> createState() => _VorhangHomeTabState();
}

class _VorhangHomeTabState extends State<VorhangHomeTab> {
  // Vorhang Farben
  static const _gold = Color(0xFFC9A84C);
  static const _bgBlack = Color(0xFF000000);
  static const _surface = Color(0xFF0D0B00);

  static const List<String> _branchOrder = [
    'Machtpsychologie',
    'Manipulationserkennung',
    'Verhandlung & Überzeugung',
    'Körpersprache & Nonverbales',
    'Strategisches Denken',
    'Schattenarbeit',
  ];

  static const Map<String, IconData> _branchIcons = {
    'Machtpsychologie': Icons.psychology,
    'Manipulationserkennung': Icons.shield,
    'Verhandlung & Überzeugung': Icons.handshake,
    'Körpersprache & Nonverbales': Icons.accessibility_new,
    'Strategisches Denken': Icons.military_tech,
    'Schattenarbeit': Icons.dark_mode,
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
      final user = Supabase.instance.client.auth.currentUser;
      // Direct-Supabase Pfad (Worker-Bypass) — funktioniert auch bei
      // Cloudflare-Worker-Quota-Outage.
      final data = await VorhangService.fetchModules(userId: user?.id);
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

  /// Find next unlocked, not-yet-completed module
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
    // Last 3 by branch_order desc / module_code desc
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
          builder: (_) => VorhangLessonScreen(moduleCode: moduleCode)),
    ).then((_) => _fetch());
  }

  void _openAllModules() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VorhangModulesScreen()),
    ).then((_) => _fetch());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bgBlack,
      child: RefreshIndicator(
        color: _gold,
        backgroundColor: _surface,
        onRefresh: _fetch,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          // Bottom-Inset (Gesten-Leiste) zur Floating-Nav-Hoehe addieren,
          // damit der "ALLE 30 MODULE"-Button auf Geraeten mit hoher
          // Navigationsleiste nicht hinter der Nav verschwindet.
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, 100 + MediaQuery.paddingOf(context).bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero Section (PRESERVED, lines 78-165 original) ──
              _buildHeroSection(),
              const SizedBox(height: 12),

              // FEATURE (V1): Level + XP + Streak sichtbar.
              const WorldXpHeader(world: 'vorhang', accent: Color(0xFFC9A84C)),
              const SizedBox(height: 12),

              // FEATURE (V2): Tägliche Enthüllung -- Macht-Prinzip des Tages.
              const DailyRevelationCard(accent: Color(0xFFC9A84C)),
              const SizedBox(height: 12),

              // V5: Tägliche Praxis-Challenge -- konkrete Mikro-Übung.
              const DailyPracticeCard(
                accent: Color(0xFFC9A84C),
                practices: DailyPracticeCard.vorhangPractices,
              ),
              const SizedBox(height: 20),

              // ── 🧠 KI-Mentor Button (PRESERVED, lines 167-239 original) ──
              Text(
                'MENTOR',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4.0,
                  color: _gold.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 12),
              _buildMentorButton(context),
              const SizedBox(height: 28),

              // ── COMMUNITY: Beiträge-Feed (vom Community-Tab ausgelagert) ──
              _sectionLabel('COMMUNITY'),
              const SizedBox(height: 12),
              _buildToolTile(
                context,
                emoji: '📝',
                title: 'Beiträge',
                subtitle: 'Community-Feed - Erkenntnisse teilen & lesen.',
                builder: (_) => const VorhangPostsScreen(),
              ),
              const SizedBox(height: 28),

              // ── KERN-TOOL: Symbol- & Logo-Decoder (Vorhang-exklusiv) ──
              _sectionLabel('KERN-TOOL'),
              const SizedBox(height: 12),
              _buildSymbolDecoderCard(context),
              const SizedBox(height: 28),

              // ── INTERAKTIVE WERKZEUGE (key-frei) ──
              _sectionLabel('WERKZEUGE'),
              const SizedBox(height: 12),
              _buildToolTile(
                context,
                emoji: '🎙️',
                title: 'Livestream',
                subtitle: 'Live-Chat & Sprachraeume',
                builder: (_) => const VorhangLiveChatScreen(),
              ),
              const SizedBox(height: 10),
              _buildToolTile(
                context,
                emoji: '🏛️',
                title: 'Lobby-Radar',
                subtitle: 'Konzern-Einfluss auf Politik - Live-Medien.',
                builder: (_) => const LobbyRadarScreen(),
              ),
              const SizedBox(height: 10),
              _buildToolTile(
                context,
                emoji: '🔓',
                title: 'Leaks-Suche',
                subtitle: 'Enthuellungen & Whistleblower weltweit.',
                builder: (_) => const LeaksSearchScreen(),
              ),
              const SizedBox(height: 10),
              _buildToolTile(
                context,
                emoji: '🕸️',
                title: 'Macht-Netzwerke',
                subtitle: 'Einflussreiche Netzwerke - Wissens-Datenbank.',
                builder: (_) => const PowerNetworksScreen(),
              ),
              const SizedBox(height: 10),
              _buildToolTile(
                context,
                emoji: '🔺',
                title: 'Symbol-Datenbank',
                subtitle: 'Historische Symbole & ihre Bedeutung.',
                builder: (_) => const SymbolDatabaseScreen(),
              ),
              const SizedBox(height: 28),

              // ── Ambient Tagespfad ──
              const DailyPathWidget(),
              const SizedBox(height: 28),

              // ── NEW: Branch Progress horizontal scroll ──
              _buildBranchProgressSection(),
              const SizedBox(height: 28),

              // ── NEW: Next Module prominent card ──
              _buildNextModuleSection(),
              const SizedBox(height: 28),

              // ── NEW: Last completed list ──
              _buildLastCompletedSection(),
              const SizedBox(height: 16),

              // ── See all modules button ──
              Center(
                child: OutlinedButton.icon(
                  onPressed: _openAllModules,
                  icon: const Icon(Icons.menu_book, color: _gold),
                  label: const Text(
                    'ALLE 30 MODULE',
                    style: TextStyle(
                      color: _gold,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _gold.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
              ),
            ]
                .asMap()
                .entries
                .map((e) => WBStaggerReveal(
                      index: e.key,
                      staggerStep: const Duration(milliseconds: 40),
                      child: e.value,
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }

  // ── PRESERVED: Hero Section ──
  /// Section-Label mit Gold-Accent-Bar (premium Rhythmus, wie Materie/Energie).
  Widget _sectionLabel(String s, {String? trailing}) => Row(
        children: [
          Container(
            width: 3,
            height: 13,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE0C872), Color(0x33C9A84C)],
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
              color: _gold.withValues(alpha: 0.85),
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
          colors: [
            _surface,
            _gold.withValues(alpha: 0.08),
            _bgBlack,
          ],
        ),
        border: Border.all(
          color: _gold.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _gold.withValues(alpha: 0.15),
            blurRadius: 40,
            offset: const Offset(0, 12),
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
                  opacity: 0.40,
                  child: WBWorldOrb(world: WBWorld.vorhang, size: 130),
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
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: _gold.withValues(alpha: 0.4)),
                        ),
                        child: const Text(
                          'WELT VI',
                          style: TextStyle(
                            fontSize: 9,
                            letterSpacing: 3.0,
                            color: _gold,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (!_loading)
                        Text(
                          '$_completedCount / $_totalCount',
                          style: const TextStyle(
                            color: _gold,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'VORHANG',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w200,
                      fontSize: 32,
                      letterSpacing: 8.0,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dunkle Psychologie & Elite-Strategien',
                    style: TextStyle(
                      fontSize: 14,
                      color: _gold.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w300,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Hinter dem Vorhang verbirgt sich das Wissen über Macht, '
                    'Manipulation und die psychologischen Werkzeuge der Eliten. '
                    'Lerne sie zu erkennen — und dich zu schützen.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.55),
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
                        backgroundColor: _gold.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation(_gold),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${(percent * 100).round()}% des Vorhangs gelüftet',
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

  // ── PRESERVED: Mentor Button ──
  Widget _buildMentorButton(BuildContext context) {
    return MentorHeroCard(
      world: 'vorhang',
      mentorName: 'Stratege',
      tagline: 'KI-Mentor für Machtstrategien',
      icon: Icons.psychology_rounded,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const MentorChatScreen(
            personality: MentorPersonality.stratege,
            world: 'vorhang',
          ),
        ),
      ),
    );
  }

  // ── KERN-TOOL: Symbol- & Logo-Decoder ──
  /// Vorhang-exclusive entry point: decode symbols/logos into possible
  /// meanings, origin and cross-world references.
  /// Kompakte Tool-Kachel fuer die WERKZEUGE-Sektion.
  Widget _buildToolTile(
    BuildContext context, {
    required String emoji,
    required String title,
    required String subtitle,
    required WidgetBuilder builder,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: builder)),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: _surface,
            border: Border.all(color: _gold.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _gold.withValues(alpha: 0.12),
                  border: Border.all(color: _gold.withValues(alpha: 0.4)),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 12,
                            height: 1.3)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: _gold.withValues(alpha: 0.7), size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSymbolDecoderCard(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const VorhangSymbolDecoderScreen(),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _gold.withValues(alpha: 0.18),
                _gold.withValues(alpha: 0.05),
                _surface,
              ],
            ),
            border:
                Border.all(color: _gold.withValues(alpha: 0.45), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: _gold.withValues(alpha: 0.15),
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
                  color: _gold.withValues(alpha: 0.15),
                  border: Border.all(color: _gold.withValues(alpha: 0.5)),
                ),
                child: const Text('👁️', style: TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Symbol- & Logo-Decoder',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Symbole entschluesseln: Bedeutung, Herkunft & '
                      'Querverweise in die anderen Welten.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: _gold.withValues(alpha: 0.7), size: 22),
            ],
          ),
        ),
      ),
    );
  }

  // ── NEW: Branch progress horizontal scroll ──
  Widget _buildBranchProgressSection() {
    if (_loading) return _buildSkeletonRow();
    if (_error != null) return _buildErrorCard(_error!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('BRANCHEN', trailing: '6 Pfade · 30 Module'),
        const SizedBox(height: 14),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _branchOrder.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final name = _branchOrder[i];
              final modules = _branches[name] ?? const [];
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
                        Color.lerp(_surface, _gold, 0.07)!
                            .withValues(alpha: 0.9),
                      ],
                    ),
                    border: Border.all(
                      color: allDone
                          ? _gold.withValues(alpha: 0.55)
                          : _gold.withValues(alpha: 0.18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: _gold.withValues(alpha: allDone ? 0.22 : 0.10),
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
                              color: _gold.withValues(alpha: 0.15),
                              border: Border.all(
                                  color: _gold.withValues(alpha: 0.4)),
                            ),
                            child: Icon(
                              _branchIcons[name] ?? Icons.folder,
                              color: _gold,
                              size: 16,
                            ),
                          ),
                          const Spacer(),
                          if (allDone)
                            const Icon(Icons.verified, color: _gold, size: 18),
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
                          backgroundColor: _gold.withValues(alpha: 0.1),
                          valueColor: const AlwaysStoppedAnimation(_gold),
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

  // ── NEW: Next module card ──
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
    final branch = (next['branch'] as String?) ?? '';
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
                  _gold.withValues(alpha: 0.22),
                  _gold.withValues(alpha: 0.06),
                  _surface,
                ],
              ),
              border:
                  Border.all(color: _gold.withValues(alpha: 0.55), width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: _gold.withValues(alpha: 0.18),
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
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _gold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        code,
                        style: const TextStyle(
                          color: _gold,
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
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_gold, Color(0xFFFFD700)],
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
                    const Icon(Icons.play_circle_fill, color: _gold, size: 26),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  branch,
                  style: TextStyle(
                    color: _gold.withValues(alpha: 0.85),
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
                    Icon(Icons.bolt,
                        color: _gold.withValues(alpha: 0.85), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '+$xp XP',
                      style: const TextStyle(
                        color: _gold,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Jetzt beginnen →',
                      style: TextStyle(
                        color: _gold.withValues(alpha: 0.9),
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

  // ── NEW: Last completed ──
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
    final branch = (m['branch'] as String?) ?? '';
    final icon = _branchIcons[branch] ?? Icons.school;

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
            border: Border.all(color: _gold.withValues(alpha: 0.2)),
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
                      color: Colors.greenAccent.withValues(alpha: 0.5)),
                ),
                child: Icon(icon,
                    color: Colors.greenAccent.withValues(alpha: 0.9), size: 18),
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
                            color: _gold.withValues(alpha: 0.85),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.check_circle,
                            color: Colors.greenAccent, size: 14),
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
              Icon(Icons.chevron_right,
                  color: _gold.withValues(alpha: 0.5), size: 18),
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
        gradient: const LinearGradient(
          colors: [_gold, Color(0xFFFFD700)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.black, size: 28),
              SizedBox(width: 10),
              Text(
                'VORHANG GELÜFTET',
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
            'Du hast alle 30 Module von Welt 6 gemeistert. Willkommen in der Reife.',
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
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => Container(
          width: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: _surface.withValues(alpha: 0.4),
            border: Border.all(color: _gold.withValues(alpha: 0.1)),
          ),
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _gold.withValues(alpha: 0.4),
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
                  color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: _fetch,
            child: const Text('Erneut', style: TextStyle(color: _gold)),
          ),
        ],
      ),
    );
  }
}
