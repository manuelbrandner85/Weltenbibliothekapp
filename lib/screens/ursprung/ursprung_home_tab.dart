import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/mentor_service.dart';
import '../../widgets/mentor_hero_card.dart';
import '../shared/mentor_chat_screen.dart';

import '../../widgets/daily_path_widget.dart';
import '../../widgets/world_xp_header.dart';
import '../../widgets/daily_revelation_card.dart';

import 'ursprung_modules_screen.dart';
import 'tools/gateway_room_screen.dart';
import 'tools/frequency_generator_screen.dart';
import 'tools/breathmaster_screen.dart';
import 'tools/reality_architect_screen.dart';
import 'tools/rv_trainer_screen.dart';

/// 🌀 URSPRUNG Home Tab — CIA Quanten-Code (25 Module, 5 Tools)
///
/// Hero · 5 Branch-Cards · 5 Tool-Cards · Alchemist · CIA-Footer.
class UrsprungHomeTab extends StatelessWidget {
  final ValueChanged<int>? onSwitchTab;

  const UrsprungHomeTab({super.key, this.onSwitchTab});

  // URSPRUNG Farben
  static const _cyan = Color(0xFF00D4AA);
  static const _cyanAccent = Color(0xFF00FFD4);
  static const _bgDeep = Color(0xFF050510);
  static const _surface = Color(0xFF080818);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bgDeep,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroSection(),
            const SizedBox(height: 12),

            // FEATURE (U1): Level + XP + Streak sichtbar.
            const WorldXpHeader(world: 'ursprung', accent: Color(0xFF00D4AA)),
            const SizedBox(height: 12),

            // FEATURE (V2-analog): Täglicher Bewusstseins-Impuls.
            DailyRevelationCard(
              accent: const Color(0xFF00D4AA),
              emoji: '🌌',
              label: 'IMPULS DES TAGES',
              principles: DailyRevelationCard.ursprungInsights,
            ),
            const SizedBox(height: 16),

            // ── Mentor: Der Alchemist ──
            _buildMentorButton(context),
            const SizedBox(height: 28),

            // ── Ambient Tagespfad ──
            const DailyPathWidget(),
            const SizedBox(height: 28),

            // ── 5 Branches ──
            _sectionLabel('5 ZWEIGE · 25 MODULE'),
            const SizedBox(height: 12),
            _buildBranchCard(
              context: context,
              emoji: '🌀',
              title: 'Gateway Foundation',
              subtitle: '5 Module · CIA Gateway Process · Hemi-Sync',
              moduleCodes: [
                'U-QC-01',
                'U-QC-02',
                'U-QC-03',
                'U-QC-04',
                'U-QC-05'
              ],
              color: const Color(0xFF8A2BE2),
            ),
            const SizedBox(height: 10),
            _buildBranchCard(
              context: context,
              emoji: '🧠',
              title: 'Focus Levels',
              subtitle: '5 Module · F10/F12/F15/F21-27/F34-49',
              moduleCodes: [
                'U-QC-06',
                'U-QC-07',
                'U-QC-08',
                'U-QC-09',
                'U-QC-10'
              ],
              color: _cyan,
            ),
            const SizedBox(height: 10),
            _buildBranchCard(
              context: context,
              emoji: '⚡',
              title: 'Energiewerkzeuge',
              subtitle: '5 Module · Energy Bar, REBAL, Resonant Tuning',
              moduleCodes: [
                'U-QC-11',
                'U-QC-12',
                'U-QC-13',
                'U-QC-14',
                'U-QC-15'
              ],
              color: const Color(0xFFFFD700),
            ),
            const SizedBox(height: 10),
            _buildBranchCard(
              context: context,
              emoji: '✨',
              title: 'Patterning & Manifestation',
              subtitle: '5 Module · Realitätserschaffung nach McDonnell',
              moduleCodes: [
                'U-QC-16',
                'U-QC-17',
                'U-QC-18',
                'U-QC-19',
                'U-QC-20'
              ],
              color: const Color(0xFFFF4081),
            ),
            const SizedBox(height: 10),
            _buildBranchCard(
              context: context,
              emoji: '👁️',
              title: 'Remote Viewing',
              subtitle: '5 Module · CRV 6-Stage · Project Stargate',
              moduleCodes: [
                'U-QC-21',
                'U-QC-22',
                'U-QC-23',
                'U-QC-24',
                'U-QC-25'
              ],
              color: const Color(0xFF00BCD4),
            ),

            const SizedBox(height: 32),

            // ── 5 Tools ──
            _sectionLabel('INTERAKTIVE WERKZEUGE'),
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

            const SizedBox(height: 32),
            _buildCiaFooter(),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _surface,
            _cyan.withValues(alpha: 0.08),
            _bgDeep,
          ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _cyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _cyan.withValues(alpha: 0.5)),
                ),
                child: Text(
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
              Icon(Icons.bolt, color: _cyanAccent, size: 18),
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
        ],
      ),
    );
  }

  Widget _buildMentorButton(BuildContext context) {
    return MentorHeroCard(
      world: 'ursprung',
      mentorName: 'Alchemist',
      tagline: 'Bewusstsein · Quanten · Realität',
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
    );
  }

  Widget _buildBranchCard({
    required BuildContext context,
    required String emoji,
    required String title,
    required String subtitle,
    required List<String> moduleCodes,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const UrsprungModulesScreen(),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: _surface.withValues(alpha: 0.85),
          border: Border.all(color: color.withValues(alpha: 0.30)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withValues(alpha: 0.30),
                    color.withValues(alpha: 0.08),
                  ],
                ),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
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
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 11.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    moduleCodes.join(' · '),
                    style: TextStyle(
                      color: color.withValues(alpha: 0.85),
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: color.withValues(alpha: 0.6), size: 14),
          ],
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
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: builder)),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: _surface.withValues(alpha: 0.7),
          border: Border.all(color: _cyan.withValues(alpha: 0.25)),
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
              Icon(Icons.shield_outlined,
                  color: _cyan.withValues(alpha: 0.7), size: 16),
              const SizedBox(width: 8),
              Text(
                'BASIEREND AUF DEKLASSIFIZIERTEN CIA-DOKUMENTEN',
                style: TextStyle(
                  color: _cyan.withValues(alpha: 0.7),
                  fontSize: 9,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w700,
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

  Widget _sectionLabel(String s) => Text(
        s,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 4.0,
          color: _cyan.withValues(alpha: 0.8),
        ),
      );
}
