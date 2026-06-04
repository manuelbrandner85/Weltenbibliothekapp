// Erweiterung 2 "Vier Linsen": shows a single topic through all four worlds.
// Pure presentation -- one colored panel per world with its perspective.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/cross_world_topics_service.dart';

class VierLinsenScreen extends StatelessWidget {
  final CrossWorldTopic topic;
  const VierLinsenScreen({super.key, required this.topic});

  // World order + colors + labels (same identity as the rest of the app).
  static const List<String> _worldOrder = [
    'materie',
    'energie',
    'vorhang',
    'ursprung',
  ];
  static const Map<String, Color> _worldColors = {
    'materie': Color(0xFF3B82F6),
    'energie': Color(0xFFA855F7),
    'vorhang': Color(0xFFC9A84C),
    'ursprung': Color(0xFF00D4AA),
  };
  static const Map<String, String> _worldLabels = {
    'materie': 'MATERIE',
    'energie': 'ENERGIE',
    'vorhang': 'VORHANG',
    'ursprung': 'URSPRUNG',
  };
  static const Map<String, String> _worldTaglines = {
    'materie': 'Das Sichtbare & Belegbare',
    'energie': 'Das Spirituelle & Energetische',
    'vorhang': 'Das Verborgene & Symbolische',
    'ursprung': 'Das Urspruengliche & Mythische',
  };

  @override
  Widget build(BuildContext context) {
    final entries = _worldOrder.where((w) => topic.lenses[w] != null).toList();
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050505),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'VIER LINSEN',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w300,
            fontSize: 16,
            letterSpacing: 3.0,
            color: Colors.white,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          for (final w in entries) ...[
            _buildLensPanel(w, topic.lenses[w]!),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(topic.emoji ?? '🔆', style: const TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text(
          topic.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (topic.subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            topic.subtitle!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'Dasselbe Thema -- vier Perspektiven.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 11,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLensPanel(String world, String text) {
    final color = _worldColors[world] ?? Colors.white;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.14),
            color.withValues(alpha: 0.04),
            const Color(0xFF0A0A0A),
          ],
        ),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [BoxShadow(color: color, blurRadius: 8)],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _worldLabels[world] ?? world.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 13),
            child: Text(
              _worldTaglines[world] ?? '',
              style: TextStyle(
                color: color.withValues(alpha: 0.7),
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
