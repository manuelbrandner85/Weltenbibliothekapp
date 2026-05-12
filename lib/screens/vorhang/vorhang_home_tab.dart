import 'package:flutter/material.dart';
import '../../theme/wb_cinematic_tokens.dart';
import '../../widgets/cinematic/wb_vignette.dart';

/// 🎭 VORHANG Home Tab — Dunkle Psychologie & Elite-Strategien
///
/// Placeholder mit Hero-Section und gesperrten Modul-Karten.
class VorhangHomeTab extends StatelessWidget {
  final ValueChanged<int>? onSwitchTab;

  const VorhangHomeTab({super.key, this.onSwitchTab});

  // Vorhang Farben
  static const _gold = Color(0xFFC9A84C);
  static const _goldAccent = Color(0xFFFFD700);
  static const _bgBlack = Color(0xFF000000);
  static const _surface = Color(0xFF0D0B00);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bgBlack,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero Section ──
            _buildHeroSection(),
            const SizedBox(height: 32),

            // ── Module (gesperrt) ──
            Text(
              'MODULE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 4.0,
                color: _gold.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            _buildLockedModule(
              icon: Icons.psychology,
              title: 'Dunkle Psychologie',
              subtitle: '12 Lektionen · Manipulation erkennen',
            ),
            const SizedBox(height: 12),
            _buildLockedModule(
              icon: Icons.account_balance,
              title: 'Elite-Strategien',
              subtitle: '8 Lektionen · Machtstrukturen verstehen',
            ),
            const SizedBox(height: 12),
            _buildLockedModule(
              icon: Icons.visibility,
              title: 'Massenpsychologie',
              subtitle: '10 Lektionen · Propaganda & Einfluss',
            ),
            const SizedBox(height: 12),
            _buildLockedModule(
              icon: Icons.shield,
              title: 'Schutzstrategien',
              subtitle: '6 Lektionen · Mentale Abwehr',
            ),
          ],
        ),
      ),
    );
  }

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _gold.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'WELT III',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 3.0,
                    color: _gold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.lock_outline, color: _gold.withValues(alpha: 0.5), size: 18),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'VORHANG',
            style: TextStyle(
              fontFamily: 'Inter',
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
        ],
      ),
    );
  }

  Widget _buildLockedModule({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: _surface.withValues(alpha: 0.6),
        border: Border.all(color: _gold.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _gold.withValues(alpha: 0.1),
              border: Border.all(color: _gold.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, color: _gold.withValues(alpha: 0.6), size: 22),
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
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _gold.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock, size: 12, color: _gold.withValues(alpha: 0.7)),
                const SizedBox(width: 4),
                Text(
                  'BALD',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                    color: _gold.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
