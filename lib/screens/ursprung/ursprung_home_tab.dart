import 'package:flutter/material.dart';
import '../../theme/wb_cinematic_tokens.dart';
import '../../widgets/cinematic/wb_vignette.dart';
import '../../services/mentor_service.dart';
import '../shared/mentor_chat_screen.dart';

/// 🌀 URSPRUNG Home Tab — Realitätserschaffung & CIA-Bewusstseins-Codes
///
/// Placeholder mit Hero-Section und gesperrten Modul-Karten.
class UrsprungHomeTab extends StatelessWidget {
  final ValueChanged<int>? onSwitchTab;

  const UrsprungHomeTab({super.key, this.onSwitchTab});

  // Ursprung Farben
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
                color: _cyan.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            // ── 🧠 KI-Mentor Button ──
            _buildMentorButton(context),
            const SizedBox(height: 24),

            _buildLockedModule(
              icon: Icons.auto_awesome,
              title: 'Realitätserschaffung',
              subtitle: '15 Lektionen · Manifestation & Bewusstsein',
            ),
            const SizedBox(height: 12),
            _buildLockedModule(
              icon: Icons.remove_red_eye,
              title: 'CIA Gateway Process',
              subtitle: '12 Lektionen · Hemisync & Bewusstseins-Codes',
            ),
            const SizedBox(height: 12),
            _buildLockedModule(
              icon: Icons.waves,
              title: 'Frequenz-Programmierung',
              subtitle: '10 Lektionen · Theta, Delta & Gamma',
            ),
            const SizedBox(height: 12),
            _buildLockedModule(
              icon: Icons.psychology_alt,
              title: 'Remote Viewing',
              subtitle: '8 Lektionen · Fernwahrnehmung nach CIA-Protokoll',
            ),
            const SizedBox(height: 12),
            _buildLockedModule(
              icon: Icons.all_inclusive,
              title: 'Quantenbewusstsein',
              subtitle: '10 Lektionen · Verschränkung & Nichtlokalität',
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
            _cyan.withValues(alpha: 0.06),
            _bgDeep,
          ],
        ),
        border: Border.all(
          color: _cyan.withValues(alpha: 0.20),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _cyan.withValues(alpha: 0.12),
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
                  color: _cyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _cyan.withValues(alpha: 0.35)),
                ),
                child: Text(
                  'WELT IV',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 3.0,
                    color: _cyan,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.lock_outline, color: _cyan.withValues(alpha: 0.5), size: 18),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'URSPRUNG',
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
            'Realitätserschaffung & CIA-Bewusstseins-Codes',
            style: TextStyle(
              fontSize: 14,
              color: _cyan.withValues(alpha: 0.7),
              fontWeight: FontWeight.w300,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Am Ursprung allen Seins liegt das Bewusstsein. '
            'Entdecke die geheimen Forschungsprogramme der CIA, '
            'das Gateway-Projekt und die Wissenschaft der Realitätserschaffung.',
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

  Widget _buildMentorButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const MentorChatScreen(
            personality: MentorPersonality.alchemist,
            world: 'ursprung',
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              _cyan.withValues(alpha: 0.12),
              _cyan.withValues(alpha: 0.04),
            ],
          ),
          border: Border.all(color: _cyan.withValues(alpha: 0.30)),
          boxShadow: [
            BoxShadow(
              color: _cyan.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [_cyan.withValues(alpha: 0.25), _cyan.withValues(alpha: 0.08)],
                ),
                border: Border.all(color: _cyan.withValues(alpha: 0.4)),
              ),
              child: Icon(Icons.all_inclusive, color: _cyan, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sprich mit dem Alchemisten',
                    style: TextStyle(
                      color: _cyan,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dein KI-Mentor für Bewusstsein',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: _cyan.withValues(alpha: 0.5), size: 16),
          ],
        ),
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
        border: Border.all(color: _cyan.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _cyan.withValues(alpha: 0.08),
              border: Border.all(color: _cyan.withValues(alpha: 0.20)),
            ),
            child: Icon(icon, color: _cyan.withValues(alpha: 0.6), size: 22),
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
              color: _cyan.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _cyan.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock, size: 12, color: _cyan.withValues(alpha: 0.7)),
                const SizedBox(width: 4),
                Text(
                  'BALD',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                    color: _cyan.withValues(alpha: 0.7),
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
