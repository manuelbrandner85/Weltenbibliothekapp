import 'package:flutter/material.dart';

/// 🎨 Thematische Chat-Hintergr\u00fcnde f\u00fcr die Weltenbibliothek
///
/// Jeder Chat-Raum erh\u00e4lt einen einzigartigen, eleganten Hintergrund,
/// der die Atmosph\u00e4re und das Thema der Diskussion unterstreicht.
class ThemedChatBackground extends StatelessWidget {
  final String theme;
  final Widget child;

  const ThemedChatBackground({
    super.key,
    required this.theme,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Thematischer Gradient-Hintergrund
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(gradient: _getThemeGradient(theme)),
          ),
        ),

        // Subtiles Muster-Overlay
        Positioned.fill(child: _buildPatternOverlay(theme)),

        // Dunkles Overlay f\u00fcr Lesbarkeit
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0F0F1E).withValues(alpha: 0.85),
                  const Color(0xFF0F0F1E).withValues(alpha: 0.92),
                  const Color(0xFF0F0F1E).withValues(alpha: 0.88),
                ],
              ),
            ),
          ),
        ),

        // Chat-Inhalt
        child,
      ],
    );
  }

  /// Gibt den passenden Gradient f\u00fcr das Thema zur\u00fcck
  LinearGradient _getThemeGradient(String theme) {
    switch (theme) {
      case 'mystery':
        // 🔮 Mysterien & R\u00e4tsel - Tieflila mit magischen Violett-T\u00f6nen
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2C1654), // Dunkel-Violett
            const Color(0xFF4A148C), // K\u00f6nigs-Violett
            const Color(0xFF6A1B9A), // Mystik-Lila
            const Color(0xFF4A148C), // K\u00f6nigs-Violett
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        );

      case 'wisdom':
        // 📚 Weisheit & Philosophie - Warme Gold-Braun-T\u00f6ne
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3E2723), // Dunkel-Braun
            const Color(0xFF5D4037), // Holz-Braun
            const Color(0xFF6D4C41), // Warmes Braun
            const Color(0xFF8D6E63), // Helles Braun
          ],
          stops: const [0.0, 0.3, 0.6, 1.0],
        );

      case 'alchemy':
        // ⚗️ Alchemie & Transformation - Smaragdgr\u00fcn mit Gold
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF004D40), // Tiefes Gr\u00fcn
            const Color(0xFF00695C), // Smaragd
            const Color(0xFF00796B), // T\u00fcrkis-Gr\u00fcn
            const Color(0xFF26A69A), // Helles T\u00fcrkis
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        );

      case 'cosmos':
        // 🌌 Kosmos & Sterne - Tiefblau mit kosmischen Violett-Akzenten
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0D1B2A), // Weltraum-Dunkelblau
            const Color(0xFF1B263B), // Nacht-Blau
            const Color(0xFF2C3E63), // Tiefes Blau
            const Color(0xFF3A506B), // Cosmic-Blau
          ],
          stops: const [0.0, 0.3, 0.6, 1.0],
        );

      case 'nature':
        // 🌿 Natur & Elemente - Erdgr\u00fcn mit Wald-T\u00f6nen
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1B5E20), // Dunkel-Gr\u00fcn
            const Color(0xFF2E7D32), // Wald-Gr\u00fcn
            const Color(0xFF388E3C), // Natur-Gr\u00fcn
            const Color(0xFF43A047), // Frisches Gr\u00fcn
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        );

      case 'ancient':
        // 🏛️ Antike Zivilisationen - Warme Sandstein-T\u00f6ne mit Gold
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF4E342E), // Antike-Braun
            const Color(0xFF5D4037), // Sandstein
            const Color(0xFF6D4C41), // Terrakotta
            const Color(0xFF795548), // Warmer Stein
          ],
          stops: const [0.0, 0.3, 0.6, 1.0],
        );

      case 'energy':
        // ⚡ Energie & Frequenzen - Elektrisches Blau mit Cyan-Akzenten
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF01579B), // Tiefer Ozean
            const Color(0xFF0277BD), // Energie-Blau
            const Color(0xFF0288D1), // Elektrisches Blau
            const Color(0xFF039BE5), // Helles Cyan
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        );

      case 'art':
        // 🎨 Kunst & Kreativit\u00e4t - Lebendige Regenbogen-T\u00f6ne
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6A1B9A), // K\u00fcnstler-Lila
            const Color(0xFF8E24AA), // Kreativ-Violett
            const Color(0xFFAB47BC), // Magenta
            const Color(0xFFBA68C8), // Helles Lila
          ],
          stops: const [0.0, 0.3, 0.6, 1.0],
        );

      case 'music':
        // 🎵 Musik - Harmonische Violett-Rosa-T\u00f6ne
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF4A148C), // Tiefes Musik-Violett
            const Color(0xFF6A1B9A), // Melodie-Lila
            const Color(0xFF8E24AA), // Harmonie-Violett
            const Color(0xFFAB47BC), // Rhythmus-Magenta
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        );

      case 'library':
      default:
        // 🌍 Bibliothek (Standard) - Elegante Blau-Lila-T\u00f6ne
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A237E), // Bibliothek-Blau
            const Color(0xFF283593), // B\u00fccher-Blau
            const Color(0xFF303F9F), // Wissens-Blau
            const Color(0xFF3949AB), // Elegantes Blau
          ],
          stops: const [0.0, 0.3, 0.6, 1.0],
        );
    }
  }

  /// Erstellt ein subtiles Muster-Overlay f\u00fcr mehr Tiefe
  Widget _buildPatternOverlay(String theme) {
    return CustomPaint(
      painter: _PatternPainter(theme: theme),
      child: Container(),
    );
  }
}

/// Custom Painter f\u00fcr thematische Muster
class _PatternPainter extends CustomPainter {
  final String theme;

  _PatternPainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    switch (theme) {
      case 'mystery':
        // Mystische Kreise und Symbole
        paint.color = Colors.white.withValues(alpha: 0.03);
        _drawMysteryPattern(canvas, size, paint);
        break;

      case 'cosmos':
        // Sterne und Konstellationen
        paint.color = Colors.white.withValues(alpha: 0.05);
        _drawStarPattern(canvas, size, paint);
        break;

      case 'nature':
        // Organische Linien und Bl\u00e4tter
        paint.color = Colors.white.withValues(alpha: 0.04);
        _drawNaturePattern(canvas, size, paint);
        break;

      case 'ancient':
        // Antike geometrische Muster
        paint.color = Colors.white.withValues(alpha: 0.04);
        _drawAncientPattern(canvas, size, paint);
        break;

      case 'energy':
        // Wellenf\u00f6rmige Energielinien
        paint.color = Colors.white.withValues(alpha: 0.05);
        _drawEnergyPattern(canvas, size, paint);
        break;

      default:
        // Subtiles Gitter-Muster
        paint.color = Colors.white.withValues(alpha: 0.02);
        _drawGridPattern(canvas, size, paint);
    }
  }

  void _drawMysteryPattern(Canvas canvas, Size size, Paint paint) {
    // Mystische konzentrische Kreise
    for (int i = 0; i < 8; i++) {
      final x = (i % 3) * size.width / 3 + size.width / 6;
      final y = (i ~/ 3) * size.height / 3 + size.height / 6;

      for (int j = 0; j < 3; j++) {
        canvas.drawCircle(Offset(x, y), 20.0 + j * 15.0, paint);
      }
    }
  }

  void _drawStarPattern(Canvas canvas, Size size, Paint paint) {
    // Sterne-Muster
    for (int i = 0; i < 30; i++) {
      final x = (i * 137.508) % size.width; // Goldener Winkel
      final y = (i * 83.7) % size.height;

      _drawStar(canvas, Offset(x, y), 3.0, paint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * 3.14159 / 5) - 3.14159 / 2;
      final x = center.dx + radius * 2 * (i % 2 == 0 ? 1 : 0.5) * cos(angle);
      final y = center.dy + radius * 2 * (i % 2 == 0 ? 1 : 0.5) * sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawNaturePattern(Canvas canvas, Size size, Paint paint) {
    // Organische wellenf\u00f6rmige Linien
    for (int i = 0; i < 10; i++) {
      final path = Path();
      final y = i * size.height / 10;
      path.moveTo(0, y);

      for (double x = 0; x <= size.width; x += 20) {
        final offset = 10 * sin(x / 30 + i);
        path.lineTo(x, y + offset);
      }

      canvas.drawPath(path, paint);
    }
  }

  void _drawAncientPattern(Canvas canvas, Size size, Paint paint) {
    // Geometrische antike Muster
    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < 5; j++) {
        final x = i * size.width / 5 + size.width / 10;
        final y = j * size.height / 5 + size.height / 10;

        canvas.drawRect(
          Rect.fromCenter(center: Offset(x, y), width: 30, height: 30),
          paint,
        );
      }
    }
  }

  void _drawEnergyPattern(Canvas canvas, Size size, Paint paint) {
    // Wellenf\u00f6rmige Energielinien
    for (int i = 0; i < 15; i++) {
      final path = Path();
      final startY = i * size.height / 15;
      path.moveTo(0, startY);

      for (double x = 0; x <= size.width; x += 10) {
        final y = startY + 20 * sin(x / 40 + i * 0.5);
        path.lineTo(x, y);
      }

      canvas.drawPath(path, paint);
    }
  }

  void _drawGridPattern(Canvas canvas, Size size, Paint paint) {
    // Subtiles Gitter
    for (double i = 0; i < size.width; i += 50) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 50) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  double cos(double angle) => (angle).cos();
  double sin(double angle) => (angle).sin();

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Erweiterungen f\u00fcr mathematische Funktionen
extension MathExtensions on double {
  double cos() {
    return (this * 180 / 3.14159).cosineValue();
  }

  double sin() {
    return (this * 180 / 3.14159).sineValue();
  }

  double cosineValue() {
    // Approximation mit Taylor-Reihe
    double x = this * 3.14159 / 180; // Grad zu Radiant
    double result = 1.0;
    double term = 1.0;

    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i - 1) * (2 * i));
      result += term;
    }

    return result;
  }

  double sineValue() {
    // Approximation mit Taylor-Reihe
    double x = this * 3.14159 / 180; // Grad zu Radiant
    double result = x;
    double term = x;

    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }

    return result;
  }
}
