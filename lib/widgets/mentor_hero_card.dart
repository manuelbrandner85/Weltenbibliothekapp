// Cinematic Mentor-Karte fuer den oberen Bereich jeder Welt:
// - Pulsierende Welt-Akzent-Aura hinter Avatar
// - 56x56 Mentor-Avatar (Welt-spezifisches Icon)
// - 2-Zeilen-Headline: "Dein Mentor - <Name>" + Tageszeit-Anrede
// - "NEU - Frag mich" Pulse-Pille (verschwindet nach erstem Tap pro Welt)

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Welt-Identifier: 'materie' | 'energie' | 'vorhang' | 'ursprung'
class MentorHeroCard extends StatefulWidget {
  final String world;
  final String
      mentorName; // "Forscher", "Heiler", "Wahrheitssucher", "Alchemist"
  final String tagline; // 1-Zeilen-Beschreibung
  final IconData icon;
  final VoidCallback onTap;
  final String? userFirstName;

  const MentorHeroCard({
    super.key,
    required this.world,
    required this.mentorName,
    required this.tagline,
    required this.icon,
    required this.onTap,
    this.userFirstName,
  });

  @override
  State<MentorHeroCard> createState() => _MentorHeroCardState();
}

class _MentorHeroCardState extends State<MentorHeroCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  bool _isNew = true;

  Color get _accent => switch (widget.world) {
        'materie' => const Color(0xFF2979FF),
        'energie' => const Color(0xFF7C4DFF),
        'vorhang' => const Color(0xFFC9A84C),
        'ursprung' => const Color(0xFF00D4AA),
        _ => const Color(0xFF7C4DFF),
      };

  Color get _accentBright => switch (widget.world) {
        'materie' => const Color(0xFF82B1FF),
        'energie' => const Color(0xFFCE93D8),
        'vorhang' => const Color(0xFFFFE08A),
        'ursprung' => const Color(0xFF80FFE0),
        _ => Colors.white,
      };

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 5) return 'Gute Nacht';
    if (h < 12) return 'Guten Morgen';
    if (h < 17) return 'Guten Tag';
    if (h < 21) return 'Guten Abend';
    return 'Gute Nacht';
  }

  String get _personalGreeting {
    final name = widget.userFirstName?.trim() ?? '';
    if (name.isEmpty) return _greeting;
    return '$_greeting, $name';
  }

  String get _prefKey => 'mentor_pulse_seen_${widget.world}';

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _loadSeen();
  }

  Future<void> _loadSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool(_prefKey) ?? false;
      if (mounted && seen) setState(() => _isNew = false);
    } catch (_) {
      // ignore
    }
  }

  Future<void> _markSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, true);
    } catch (_) {
      // ignore
    }
  }

  void _handleTap() {
    if (_isNew) {
      setState(() => _isNew = false);
      _markSeen();
    }
    widget.onTap();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final t = Curves.easeInOut.transform(_pulse.value);
          final glow = 0.18 + t * 0.22;
          final auraScale = 1.0 + t * 0.12;
          return Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _accent.withValues(alpha: 0.22),
                  _accent.withValues(alpha: 0.06),
                ],
              ),
              border: Border.all(
                color: _accent.withValues(alpha: 0.5 + t * 0.2),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _accent.withValues(alpha: glow),
                  blurRadius: 28,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                // Avatar mit Pulse-Aura
                SizedBox(
                  width: 64,
                  height: 64,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.scale(
                        scale: auraScale,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                _accent.withValues(alpha: 0.45 * (1 - t)),
                                _accent.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              _accent.withValues(alpha: 0.55),
                              _accent.withValues(alpha: 0.15),
                            ],
                          ),
                          border: Border.all(
                            color: _accentBright.withValues(alpha: 0.7),
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _accent.withValues(alpha: 0.4 + t * 0.2),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                        child: Icon(widget.icon, color: Colors.white, size: 26),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // Headline + Tagline + NEU-Pille
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Dein Mentor · ${widget.mentorName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _accentBright,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          if (_isNew) ...[
                            const SizedBox(width: 6),
                            _PulsingNewBadge(t: t, color: _accentBright),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _personalGreeting,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.tagline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 11.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _accent.withValues(alpha: 0.18),
                    border: Border.all(
                      color: _accent.withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: _accentBright,
                    size: 16,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PulsingNewBadge extends StatelessWidget {
  final double t;
  final Color color;
  const _PulsingNewBadge({required this.t, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18 + t * 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.5 + t * 0.4),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3 * t),
            blurRadius: 6,
          ),
        ],
      ),
      child: Text(
        'NEU · Frag mich',
        style: TextStyle(
          color: color,
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
