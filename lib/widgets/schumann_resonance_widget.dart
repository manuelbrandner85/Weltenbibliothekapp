import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Schumann-Resonanz Anzeige Widget
/// Zeigt die aktuelle Erdresonanzfrequenz (normalerweise 7.83 Hz)
class SchumannResonanceWidget extends StatefulWidget {
  const SchumannResonanceWidget({super.key});

  @override
  State<SchumannResonanceWidget> createState() =>
      _SchumannResonanceWidgetState();
}

class _SchumannResonanceWidgetState extends State<SchumannResonanceWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _currentFrequency = 7.83;
  double _qualityFactor = 4.3;
  double _amplitude = 0.80;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Simuliere leichte Schwankungen der Schumann-Resonanz
    _simulateResonanceFluctuations();
  }

  void _simulateResonanceFluctuations() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          // Realistische Schwankungen: 7.83 Hz ± 0.5 Hz
          _currentFrequency = 7.83 + (math.Random().nextDouble() - 0.5) * 1.0;
          _qualityFactor = 4.0 + math.Random().nextDouble() * 1.0;
          _amplitude = 0.70 + math.Random().nextDouble() * 0.20;
        });
        _simulateResonanceFluctuations();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.withValues(alpha: 0.3),
            Colors.green.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.waves, color: Colors.green[300], size: 24),
              const SizedBox(width: 8),
              Text(
                'Schumann-Resonanz',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[300],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Hauptfrequenz-Anzeige
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Text(
                '${_currentFrequency.toStringAsFixed(2)} Hz',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[400],
                  shadows: [
                    Shadow(
                      color: Colors.green.withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          // Status-Text
          Text(
            _getResonanceStatus(),
            style: TextStyle(fontSize: 14, color: Colors.green[200]),
          ),
          const SizedBox(height: 12),

          // Qualitätsfaktor und Amplitude
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetric('Q:', _qualityFactor.toStringAsFixed(1)),
              _buildMetric('A:', _amplitude.toStringAsFixed(2)),
            ],
          ),
          const SizedBox(height: 12),

          // Wellenform-Visualisierung
          CustomPaint(
            size: const Size(double.infinity, 60),
            painter: WaveformPainter(
              frequency: _currentFrequency,
              amplitude: _amplitude,
              animation: _controller,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Row(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.green[300])),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.green[400],
          ),
        ),
      ],
    );
  }

  String _getResonanceStatus() {
    if (_currentFrequency >= 7.5 && _currentFrequency <= 8.2) {
      return 'Normale Aktivität - Stabile Resonanz';
    } else if (_currentFrequency < 7.5) {
      return 'Niedrige Aktivität - Schwache Resonanz';
    } else {
      return 'Erhöhte Aktivität - Starke Resonanz';
    }
  }
}

/// Custom Painter für Wellenform-Visualisierung
class WaveformPainter extends CustomPainter {
  final double frequency;
  final double amplitude;
  final Animation<double> animation;
  final Color color;

  WaveformPainter({
    required this.frequency,
    required this.amplitude,
    required this.animation,
    required this.color,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final double waveHeight = size.height / 2;
    final double waveWidth = size.width;
    final double animationValue = animation.value;

    path.moveTo(0, waveHeight);

    for (double x = 0; x <= waveWidth; x += 1) {
      final double normalizedX = x / waveWidth;
      final double y =
          waveHeight +
          math.sin(
                (normalizedX * frequency * 2 * math.pi) +
                    (animationValue * 2 * math.pi),
              ) *
              waveHeight *
              amplitude;
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);

    // Zweite Welle mit Phasenverschiebung
    final paint2 = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path2 = Path();
    path2.moveTo(0, waveHeight);

    for (double x = 0; x <= waveWidth; x += 1) {
      final double normalizedX = x / waveWidth;
      final double y =
          waveHeight +
          math.sin(
                (normalizedX * frequency * 2 * math.pi) +
                    (animationValue * 2 * math.pi) +
                    (math.pi / 4),
              ) *
              waveHeight *
              amplitude *
              0.7;
      path2.lineTo(x, y);
    }

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.frequency != frequency ||
        oldDelegate.amplitude != amplitude ||
        oldDelegate.animation != animation;
  }
}
