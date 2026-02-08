/// Spirit Tool Cards - 15 neue spirituelle Werkzeuge
/// Weltenbibliothek v43 - Alle Tools als eigenständige Cards
library;

import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Spirit Tool Cards - 15 neue Werkzeuge
class SpiritToolCards {
  
  // ═══════════════════════════════════════════════════════════
  // 1. 🌙 MONDPHASEN-TRACKER
  // ═══════════════════════════════════════════════════════════
  
  Widget buildMoonPhaseTrackerCard(BuildContext context) {
    final moonPhase = _getCurrentMoonPhase();
    
    return _buildToolCard(
      context: context,
      icon: Icons.nightlight_round,
      title: 'Mondphasen-Tracker',
      subtitle: moonPhase['name']!,
      gradient: [Color(0xFF1A237E), Color(0xFF283593)],
      onTap: () => _showMoonPhaseDetail(context, moonPhase),
      child: Column(
        children: [
          SizedBox(height: 16),
          // Mond-Visualisierung
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
            ),
            child: CustomPaint(
              painter: MoonPhasePainter(moonPhase['phase'] as int),
            ),
          ),
          SizedBox(height: 12),
          Text(
            moonPhase['ritual']!,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 2. 🔮 TAROT-TAGESZIEHUNG
  // ═══════════════════════════════════════════════════════════
  
  Widget buildTarotDailyDrawCard(BuildContext context) {
    return _buildToolCard(
      context: context,
      icon: Icons.auto_awesome,
      title: 'Tarot-Tagesziehung',
      subtitle: 'Ziehe deine Tageskarte',
      gradient: [Color(0xFF4A148C), Color(0xFF6A1B9A)],
      onTap: () => _showTarotDrawDialog(context),
      child: Column(
        children: [
          SizedBox(height: 16),
          Icon(
            Icons.style,
            size: 60,
            color: Colors.amber,
          ),
          SizedBox(height: 12),
          Text(
            '78 Tarot-Karten',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 3. 🧬 DNA-AKTIVIERUNG TRACKER
  // ═══════════════════════════════════════════════════════════
  
  Widget buildDnaActivationTrackerCard(BuildContext context) {
    return _buildToolCard(
      context: context,
      icon: Icons.biotech,
      title: 'DNA-Aktivierung',
      subtitle: '12-Strang Aktivierung',
      gradient: [Color(0xFF00695C), Color(0xFF00897B)],
      onTap: () => _showDnaActivationDetail(context),
      child: Column(
        children: [
          SizedBox(height: 16),
          // DNA-Helix Visualisierung
          SizedBox(
            width: 80,
            height: 80,
            child: CustomPaint(
              painter: DnaHelixPainter(),
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Aktivierungslevel: 7/12',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 4. 🎵 FREQUENZ-GENERATOR
  // ═══════════════════════════════════════════════════════════
  
  Widget buildFrequencyGeneratorCard(BuildContext context) {
    return _buildToolCard(
      context: context,
      icon: Icons.graphic_eq,
      title: 'Frequenz-Generator',
      subtitle: 'Solfeggio & Binaural Beats',
      gradient: [Color(0xFFD32F2F), Color(0xFFF44336)],
      onTap: () => _showFrequencyGeneratorDialog(context),
      child: Column(
        children: [
          SizedBox(height: 16),
          Icon(
            Icons.graphic_eq,
            size: 60,
            color: Colors.lightBlue,
          ),
          SizedBox(height: 12),
          Text(
            '9 Heilfrequenzen',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 5. 🌌 AKASHA-CHRONIK JOURNAL
  // ═══════════════════════════════════════════════════════════
  
  Widget buildAkashaChronicleCard(BuildContext context) {
    return _buildToolCard(
      context: context,
      icon: Icons.menu_book,
      title: 'Akasha-Chronik',
      subtitle: 'Seelen-Erinnerungen',
      gradient: [Color(0xFF311B92), Color(0xFF512DA8)],
      onTap: () => _showAkashaChronicleDialog(context),
      child: Column(
        children: [
          SizedBox(height: 16),
          Icon(
            Icons.auto_stories,
            size: 60,
            color: Colors.purple[200],
          ),
          SizedBox(height: 12),
          Text(
            '5 Einträge gespeichert',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 6. 💎 KRISTALL-DATENBANK
  // ═══════════════════════════════════════════════════════════
  
  Widget buildCrystalDatabaseCard(BuildContext context) {
    return _buildToolCard(
      context: context,
      icon: Icons.diamond,
      title: 'Kristall-Datenbank',
      subtitle: '50+ Heilsteine',
      gradient: [Color(0xFF1976D2), Color(0xFF2196F3)],
      onTap: () => _showCrystalDatabaseDialog(context),
      child: Column(
        children: [
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.diamond, size: 30, color: Colors.pink[300]),
              SizedBox(width: 8),
              Icon(Icons.diamond, size: 30, color: Colors.blue[300]),
              SizedBox(width: 8),
              Icon(Icons.diamond, size: 30, color: Colors.purple[300]),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Wirkung & Zuordnung',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 7. 🕉️ MANTRA-BIBLIOTHEK
  // ═══════════════════════════════════════════════════════════
  
  Widget buildMantraLibraryCard(BuildContext context) {
    return _buildToolCard(
      context: context,
      icon: Icons.record_voice_over,
      title: 'Mantra-Bibliothek',
      subtitle: '30+ kraftvolle Mantras',
      gradient: [Color(0xFFE65100), Color(0xFFFF6F00)],
      onTap: () => _showMantraLibraryDialog(context),
      child: Column(
        children: [
          SizedBox(height: 16),
          Text(
            'ॐ',
            style: TextStyle(
              fontSize: 60,
              color: Colors.orange[200],
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Sanskrit-Mantras',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 8. 🌈 AURA-FARBEN READER
  // ═══════════════════════════════════════════════════════════
  
  Widget buildAuraColorReaderCard(BuildContext context) {
    return _buildToolCard(
      context: context,
      icon: Icons.color_lens,
      title: 'Aura-Farben Reader',
      subtitle: 'Bestimme deine Aura',
      gradient: [Color(0xFFAD1457), Color(0xFFE91E63)],
      onTap: () => _showAuraColorReaderDialog(context),
      child: Column(
        children: [
          SizedBox(height: 16),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.yellow,
                  Colors.orange,
                  Colors.pink.withValues(alpha: 0.5),
                ],
              ),
            ),
          ),
          SizedBox(height: 12),
          Text(
            '12 Aura-Farben',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 9. 📿 MEDITATION-TIMER
  // ═══════════════════════════════════════════════════════════
  
  Widget buildMeditationTimerCard(BuildContext context) {
    return _buildToolCard(
      context: context,
      icon: Icons.timer,
      title: 'Meditation-Timer',
      subtitle: 'Strukturierte Praxis',
      gradient: [Color(0xFF4527A0), Color(0xFF5E35B1)],
      onTap: () => _showMeditationTimerDialog(context),
      child: Column(
        children: [
          SizedBox(height: 16),
          Icon(
            Icons.self_improvement,
            size: 60,
            color: Colors.purple[200],
          ),
          SizedBox(height: 12),
          Text(
            '5 - 60 Minuten',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 10. 🔯 HEILIGE GEOMETRIE GENERATOR
  // ═══════════════════════════════════════════════════════════
  
  Widget buildSacredGeometryCard(BuildContext context) {
    return _buildToolCard(
      context: context,
      icon: Icons.hexagon_outlined,
      title: 'Heilige Geometrie',
      subtitle: '12 Muster',
      gradient: [Color(0xFF00838F), Color(0xFF00ACC1)],
      onTap: () => _showSacredGeometryDialog(context),
      child: Column(
        children: [
          SizedBox(height: 16),
          SizedBox(
            width: 80,
            height: 80,
            child: CustomPaint(
              painter: FlowerOfLifePainter(),
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Blume des Lebens',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 11. 🌍 ERDUNG-ÜBUNGEN
  // ═══════════════════════════════════════════════════════════
  
  Widget buildGroundingExercisesCard(BuildContext context) {
    return _buildToolCard(
      context: context,
      icon: Icons.nature_people,
      title: 'Erdung-Übungen',
      subtitle: '10 geführte Praktiken',
      gradient: [Color(0xFF558B2F), Color(0xFF689F38)],
      onTap: () => _showGroundingExercisesDialog(context),
      child: Column(
        children: [
          SizedBox(height: 16),
          Icon(
            Icons.park,
            size: 60,
            color: Colors.green[200],
          ),
          SizedBox(height: 12),
          Text(
            'Grounding & Balance',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 12. 🦋 TRANSFORMATION-TRACKER
  // ═══════════════════════════════════════════════════════════
  
  Widget buildTransformationTrackerCard(BuildContext context) {
    return _buildToolCard(
      context: context,
      icon: Icons.trending_up,
      title: 'Transformation-Tracker',
      subtitle: 'Deine spirituelle Reise',
      gradient: [Color(0xFFF57C00), Color(0xFFFF9800)],
      onTap: () => _showTransformationTrackerDialog(context),
      child: Column(
        children: [
          SizedBox(height: 16),
          Icon(
            Icons.auto_graph,
            size: 60,
            color: Colors.orange[200],
          ),
          SizedBox(height: 12),
          Text(
            'Meilensteine & Durchbrüche',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 13. 🌟 LICHTSPRACHE DECODER
  // ═══════════════════════════════════════════════════════════
  
  Widget buildLightLanguageDecoderCard(BuildContext context) {
    return _buildToolCard(
      context: context,
      icon: Icons.language,
      title: 'Lichtsprache Decoder',
      subtitle: '30+ Lichtcodes',
      gradient: [Color(0xFFFDD835), Color(0xFFFBC02D)],
      onTap: () => _showLightLanguageDecoderDialog(context),
      child: Column(
        children: [
          SizedBox(height: 16),
          Icon(
            Icons.flare,
            size: 60,
            color: Colors.yellow[100],
          ),
          SizedBox(height: 12),
          Text(
            'Downloads & Symbole',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 14. 🧘‍♀️ YOGA ASANA GUIDE
  // ═══════════════════════════════════════════════════════════
  
  Widget buildYogaAsanaGuideCard(BuildContext context) {
    return _buildToolCard(
      context: context,
      icon: Icons.self_improvement,
      title: 'Yoga Asana Guide',
      subtitle: '50+ Asanas',
      gradient: [Color(0xFF00695C), Color(0xFF00897B)],
      onTap: () => _showYogaAsanaGuideDialog(context),
      child: Column(
        children: [
          SizedBox(height: 16),
          Icon(
            Icons.accessibility_new,
            size: 60,
            color: Colors.teal[200],
          ),
          SizedBox(height: 12),
          Text(
            'Illustrationen & Sequenzen',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 15. 🌺 GÖTTINNEN & GÖTTER ORAKEL
  // ═══════════════════════════════════════════════════════════
  
  Widget buildDeityOracleCard(BuildContext context) {
    return _buildToolCard(
      context: context,
      icon: Icons.auto_awesome,
      title: 'Göttinnen & Götter Orakel',
      subtitle: '30+ Archetypen',
      gradient: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
      onTap: () => _showDeityOracleDialog(context),
      child: Column(
        children: [
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('✨', style: TextStyle(fontSize: 30)),
              SizedBox(width: 8),
              Text('🌸', style: TextStyle(fontSize: 30)),
              SizedBox(width: 8),
              Text('⚡', style: TextStyle(fontSize: 30)),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Tägliche Botschaft',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HELPER: TOOL CARD BUILDER
  // ═══════════════════════════════════════════════════════════
  
  Widget _buildToolCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
    Widget? child,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 20,
                ),
              ],
            ),
            if (child != null) child,
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════
  
  Map<String, dynamic> _getCurrentMoonPhase() {
    final now = DateTime.now();
    final moonPhaseIndex = (now.day % 8);
    
    final phases = [
      {'name': 'Neumond', 'ritual': 'Zeit für Neuanfänge', 'phase': 0},
      {'name': 'Zunehmender Mond', 'ritual': 'Manifestation & Wachstum', 'phase': 1},
      {'name': 'Erstes Viertel', 'ritual': 'Entscheidungen treffen', 'phase': 2},
      {'name': 'Zunehmender Dreiviertelmond', 'ritual': 'Verfeinern & Optimieren', 'phase': 3},
      {'name': 'Vollmond', 'ritual': 'Kraft & Manifestation', 'phase': 4},
      {'name': 'Abnehmender Dreiviertelmond', 'ritual': 'Dankbarkeit & Loslassen', 'phase': 5},
      {'name': 'Letztes Viertel', 'ritual': 'Reflexion & Heilung', 'phase': 6},
      {'name': 'Abnehmender Mond', 'ritual': 'Vorbereitung auf Neues', 'phase': 7},
    ];
    
    return phases[moonPhaseIndex];
  }

  // Dialog-Platzhalter (werden erweitert)
  void _showMoonPhaseDetail(BuildContext context, Map<String, dynamic> phase) {
    _showComingSoonDialog(context, 'Mondphasen-Tracker');
  }

  void _showTarotDrawDialog(BuildContext context) {
    _showComingSoonDialog(context, 'Tarot-Tagesziehung');
  }

  void _showDnaActivationDetail(BuildContext context) {
    _showComingSoonDialog(context, 'DNA-Aktivierung Tracker');
  }

  void _showFrequencyGeneratorDialog(BuildContext context) {
    _showComingSoonDialog(context, 'Frequenz-Generator');
  }

  void _showAkashaChronicleDialog(BuildContext context) {
    _showComingSoonDialog(context, 'Akasha-Chronik Journal');
  }

  void _showCrystalDatabaseDialog(BuildContext context) {
    _showComingSoonDialog(context, 'Kristall-Datenbank');
  }

  void _showMantraLibraryDialog(BuildContext context) {
    _showComingSoonDialog(context, 'Mantra-Bibliothek');
  }

  void _showAuraColorReaderDialog(BuildContext context) {
    _showComingSoonDialog(context, 'Aura-Farben Reader');
  }

  void _showMeditationTimerDialog(BuildContext context) {
    _showComingSoonDialog(context, 'Meditation-Timer');
  }

  void _showSacredGeometryDialog(BuildContext context) {
    _showComingSoonDialog(context, 'Heilige Geometrie Generator');
  }

  void _showGroundingExercisesDialog(BuildContext context) {
    _showComingSoonDialog(context, 'Erdung-Übungen');
  }

  void _showTransformationTrackerDialog(BuildContext context) {
    _showComingSoonDialog(context, 'Transformation-Tracker');
  }

  void _showLightLanguageDecoderDialog(BuildContext context) {
    _showComingSoonDialog(context, 'Lichtsprache Decoder');
  }

  void _showYogaAsanaGuideDialog(BuildContext context) {
    _showComingSoonDialog(context, 'Yoga Asana Guide');
  }

  void _showDeityOracleDialog(BuildContext context) {
    _showComingSoonDialog(context, 'Göttinnen & Götter Orakel');
  }

  void _showComingSoonDialog(BuildContext context, String toolName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.construction, color: Colors.amber),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                toolName,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: Text(
          'Dieses Tool ist in Entwicklung!\n\nEs wird bald mit vollen Features verfügbar sein. 🚀',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// CUSTOM PAINTERS
// ═══════════════════════════════════════════════════════════

class MoonPhasePainter extends CustomPainter {
  final int phase;
  
  MoonPhasePainter(this.phase);
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Mond-Hintergrund
    final moonPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius, moonPaint);
    
    // Schatten basierend auf Phase
    if (phase > 0 && phase < 8) {
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.7)
        ..style = PaintingStyle.fill;
      
      final shadowPath = Path();
      
      if (phase <= 4) {
        // Zunehmender Mond
        shadowPath.addArc(
          Rect.fromCircle(center: center, radius: radius),
          -math.pi / 2,
          math.pi,
        );
        shadowPath.close();
      } else {
        // Abnehmender Mond
        shadowPath.addArc(
          Rect.fromCircle(center: center, radius: radius),
          math.pi / 2,
          math.pi,
        );
        shadowPath.close();
      }
      
      canvas.drawPath(shadowPath, shadowPaint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DnaHelixPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    final path1 = Path();
    final path2 = Path();
    
    for (double i = 0; i < size.height; i++) {
      final x1 = size.width / 2 + math.sin(i * 0.1) * 20;
      final x2 = size.width / 2 - math.sin(i * 0.1) * 20;
      
      if (i == 0) {
        path1.moveTo(x1, i);
        path2.moveTo(x2, i);
      } else {
        path1.lineTo(x1, i);
        path2.lineTo(x2, i);
      }
    }
    
    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FlowerOfLifePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyan.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 4;
    
    // Zentraler Kreis
    canvas.drawCircle(center, radius, paint);
    
    // 6 umgebende Kreise
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60) * math.pi / 180;
      final offset = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawCircle(offset, radius, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
