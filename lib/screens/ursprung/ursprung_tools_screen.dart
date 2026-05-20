import 'package:flutter/material.dart';
import '../../theme/wb_cinematic_tokens.dart';
import '../../widgets/cinematic/wb_glass_app_bar.dart';

/// 🌀 URSPRUNG Tools Screen — Placeholder
///
/// Enthält Werkzeuge wie Remote-Viewing-Protokolle, Frequenz-Generator,
/// Gateway-Meditation-Timer, etc.
class UrsprungToolsScreen extends StatelessWidget {
  const UrsprungToolsScreen({super.key});

  static const _cyan = Color(0xFF00D4AA);
  static const _bgDeep = Color(0xFF050510);
  static const _surface = Color(0xFF080818);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: _bgDeep,
      appBar: WBGlassAppBar(
        world: WBWorld.ursprung,
        title: 'URSPRUNG TOOLS',
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _cyan),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 60, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WERKZEUGE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 4.0,
                color: _cyan.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            _buildToolCard(
              icon: Icons.remove_red_eye,
              title: 'Remote Viewing Protokoll',
              subtitle: 'CRV nach CIA-Standard',
            ),
            const SizedBox(height: 12),
            _buildToolCard(
              icon: Icons.graphic_eq,
              title: 'Frequenz-Generator',
              subtitle: 'Binaurale Beats & Isochronic Tones',
            ),
            const SizedBox(height: 12),
            _buildToolCard(
              icon: Icons.timer,
              title: 'Gateway Meditation Timer',
              subtitle: 'Hemisync-basierte Sitzungen',
            ),
            const SizedBox(height: 12),
            _buildToolCard(
              icon: Icons.auto_graph,
              title: 'Bewusstseins-Tracker',
              subtitle: 'Fortschritt & Erfahrungsprotokoll',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard({
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
