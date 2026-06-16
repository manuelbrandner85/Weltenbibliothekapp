import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/quantenphysik_model.dart';
import '../../services/quantenphysik_service.dart';
import '../../theme/wb_cinematic_tokens.dart';
import '../../widgets/cinematic/wb_glass_app_bar.dart';

/// Interactive quantum physics simulator with 4 phenomena:
/// - Doppelspalt (double-slit interference)
/// - Wellenfunktion (wave function in infinite potential well)
/// - Tunneling (quantum tunneling through a barrier)
/// - Unschaerfe (Heisenberg uncertainty principle)
class QuantenphysikScreen extends StatefulWidget {
  const QuantenphysikScreen({super.key});

  @override
  State<QuantenphysikScreen> createState() => _QuantenphysikScreenState();
}

class _QuantenphysikScreenState extends State<QuantenphysikScreen>
    with TickerProviderStateMixin {
  static const _cyan = Color(0xFF00D4AA);
  static const _cyanAccent = Color(0xFF00FFD4);
  static const _bgDeep = Color(0xFF050510);
  static const _surface = Color(0xFF080818);

  late final TabController _tabCtrl;
  late final AnimationController _timeCtrl;

  // ── Doppelspalt parameters ─────────────────────────────────────────────────
  double _wavelength = 0.25;
  double _slitSeparation = 0.5;
  double _slitWidth = 0.15;

  // ── Wellenfunktion parameters ──────────────────────────────────────────────
  int _energyLevel = 1;
  bool _showProbability = false;

  // ── Tunneling parameters ───────────────────────────────────────────────────
  double _barrierHeight = 2.0;
  double _particleEnergy = 1.0;
  double _barrierWidth = 0.5;

  // ── Heisenberg parameters ──────────────────────────────────────────────────
  double _sigmaX = 0.5;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: kQuantumPhenomena.length, vsync: this);
    _timeCtrl = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDeep,
      appBar: WBGlassAppBar(
        world: WBWorld.ursprung,
        titleWidget: const Row(
          children: [
            Icon(Icons.science_rounded, color: _cyan, size: 20),
            SizedBox(width: 8),
            Text(
              'Quantenphysik-Simulator',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: _cyan,
          labelColor: _cyan,
          unselectedLabelColor: Colors.white38,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            for (final phenom in kQuantumPhenomena) Tab(text: phenom.tabLabel),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildDoppelspaltTab(),
          _buildWellenfunktionTab(),
          _buildTunnelingTab(),
          _buildUnschaerfeTab(),
        ],
      ),
    );
  }

  // ─── Tab 0: Doppelspalt ───────────────────────────────────────────────────

  Widget _buildDoppelspaltTab() {
    final phenom = kQuantumPhenomena[0];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _phenomTitle(phenom.title),
          const SizedBox(height: 8),
          _infoBox(phenom.description),
          const SizedBox(height: 16),
          _buildCanvas(
            _DoppelspaltPainter(
              wavelength: _wavelength,
              slitSeparation: _slitSeparation,
              slitWidth: _slitWidth,
            ),
          ),
          const SizedBox(height: 20),
          _sliderRow(
            'Wellenlaenge lambda',
            _wavelength,
            0.05,
            0.5,
            (v) => setState(() => _wavelength = v),
          ),
          _sliderRow(
            'Spaltabstand d',
            _slitSeparation,
            0.1,
            1.5,
            (v) => setState(() => _slitSeparation = v),
          ),
          _sliderRow(
            'Spaltbreite a',
            _slitWidth,
            0.02,
            0.4,
            (v) => setState(() => _slitWidth = v),
          ),
          const SizedBox(height: 12),
          _formulaBox(phenom.formula),
        ],
      ),
    );
  }

  // ─── Tab 1: Wellenfunktion ────────────────────────────────────────────────

  Widget _buildWellenfunktionTab() {
    final phenom = kQuantumPhenomena[1];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _phenomTitle(phenom.title),
          const SizedBox(height: 8),
          _infoBox(phenom.description),
          const SizedBox(height: 16),
          // AnimatedBuilder wraps only the canvas to avoid rebuilding sliders each frame
          AnimatedBuilder(
            animation: _timeCtrl,
            builder: (context, _) {
              final time = _timeCtrl.value * 2.0 * math.pi;
              return _buildCanvas(
                _WellenfunktionPainter(
                  energyLevel: _energyLevel,
                  time: time,
                  showProbability: _showProbability,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Energieniveau  n = $_energyLevel',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: _cyan),
                onPressed: _energyLevel > 1
                    ? () => setState(() => _energyLevel--)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: _cyan),
                onPressed: _energyLevel < 6
                    ? () => setState(() => _energyLevel++)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Anzeige:',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 12),
              _chipToggle(
                'ψ(x)',
                !_showProbability,
                () => setState(() => _showProbability = false),
              ),
              const SizedBox(width: 8),
              _chipToggle(
                '|ψ|²',
                _showProbability,
                () => setState(() => _showProbability = true),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _formulaBox(phenom.formula),
        ],
      ),
    );
  }

  // ─── Tab 2: Tunneling ─────────────────────────────────────────────────────

  Widget _buildTunnelingTab() {
    final phenom = kQuantumPhenomena[2];
    final T = QuantenphysikService.tunnelingProbability(
      barrierHeight: _barrierHeight,
      particleEnergy: _particleEnergy,
      barrierWidth: _barrierWidth,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _phenomTitle(phenom.title),
          const SizedBox(height: 8),
          _infoBox(phenom.description),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: _cyan.withValues(alpha: 0.12),
              border: Border.all(color: _cyan.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.show_chart, color: _cyan, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Tunnelwahrscheinlichkeit: ${(T * 100).toStringAsFixed(2)} %',
                  style: const TextStyle(
                    color: _cyan,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _timeCtrl,
            builder: (context, _) {
              final time = _timeCtrl.value * 2.0 * math.pi;
              return _buildCanvas(
                _TunnelingPainter(
                  barrierHeight: _barrierHeight,
                  particleEnergy: _particleEnergy,
                  barrierWidth: _barrierWidth,
                  time: time,
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          _sliderRow(
            'Barrierenhoehe V',
            _barrierHeight,
            0.5,
            4.0,
            (v) => setState(() {
              _barrierHeight = v;
              // Keep particle energy below barrier
              if (_particleEnergy >= _barrierHeight - 0.05) {
                _particleEnergy = (_barrierHeight - 0.15).clamp(0.1, 3.9);
              }
            }),
          ),
          _sliderRow(
            'Teilchenenergie E  (< V)',
            _particleEnergy,
            0.1,
            (_barrierHeight - 0.1).clamp(0.1, 3.9),
            (v) => setState(() => _particleEnergy = v),
          ),
          _sliderRow(
            'Barrierenbreite L',
            _barrierWidth,
            0.1,
            1.5,
            (v) => setState(() => _barrierWidth = v),
          ),
          const SizedBox(height: 12),
          _formulaBox(phenom.formula),
        ],
      ),
    );
  }

  // ─── Tab 3: Heisenberg Unschaerfe ─────────────────────────────────────────

  Widget _buildUnschaerfeTab() {
    final phenom = kQuantumPhenomena[3];
    final sigmaP = 0.5 / _sigmaX;
    final product = _sigmaX * sigmaP;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _phenomTitle(phenom.title),
          const SizedBox(height: 8),
          _infoBox(phenom.description),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: _cyan.withValues(alpha: 0.12),
              border: Border.all(color: _cyan.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Δx = ${_sigmaX.toStringAsFixed(3)}   '
                  'Δp = ${sigmaP.toStringAsFixed(3)}   '
                  'Δx·Δp = ${product.toStringAsFixed(3)}',
                  style: const TextStyle(
                    color: _cyan,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product <= 0.501
                      ? 'Minimal-Unschaerfe (Grundzustand eines harmonischen Oszillators)'
                      : 'Produkt liegt ueber der Unschaerfegrenze ℏ/2',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildCanvas(_UnschaerfePainter(sigmaX: _sigmaX)),
          const SizedBox(height: 20),
          _sliderRow(
            'Ortsunschaerfe Δx',
            _sigmaX,
            0.1,
            1.5,
            (v) => setState(() => _sigmaX = v),
          ),
          const SizedBox(height: 12),
          _formulaBox(phenom.formula),
        ],
      ),
    );
  }

  // ─── Shared UI helpers ────────────────────────────────────────────────────

  Widget _phenomTitle(String title) => Text(
    title,
    style: const TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.w700,
    ),
  );

  Widget _infoBox(String text) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: _surface,
      border: Border.all(color: _cyan.withValues(alpha: 0.2)),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.7),
        fontSize: 12,
        height: 1.5,
      ),
    ),
  );

  Widget _buildCanvas(CustomPainter painter) => Container(
    height: 200,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: const Color(0xFF03030D),
      border: Border.all(color: _cyan.withValues(alpha: 0.3)),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: CustomPaint(painter: painter, child: const SizedBox.expand()),
    ),
  );

  Widget _sliderRow(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
            const Spacer(),
            Text(
              value.toStringAsFixed(2),
              style: const TextStyle(
                color: _cyan,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: _cyan,
            thumbColor: _cyanAccent,
            inactiveTrackColor: _cyan.withValues(alpha: 0.2),
            overlayColor: _cyan.withValues(alpha: 0.1),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _formulaBox(String formula) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: _cyan.withValues(alpha: 0.07),
      border: Border.all(color: _cyan.withValues(alpha: 0.3)),
    ),
    child: Text(
      formula,
      style: const TextStyle(
        color: _cyan,
        fontSize: 13,
        fontFamily: 'monospace',
        height: 1.6,
      ),
    ),
  );

  Widget _chipToggle(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected ? _cyan.withValues(alpha: 0.2) : Colors.transparent,
          border: Border.all(color: selected ? _cyan : Colors.white24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? _cyan : Colors.white38,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ─── CustomPainters ────────────────────────────────────────────────────────────

/// Draws the double-slit interference intensity pattern I(x).
class _DoppelspaltPainter extends CustomPainter {
  final double wavelength;
  final double slitSeparation;
  final double slitWidth;

  _DoppelspaltPainter({
    required this.wavelength,
    required this.slitSeparation,
    required this.slitWidth,
  });

  static const _cyan = Color(0xFF00D4AA);

  @override
  void paint(Canvas canvas, Size size) {
    final points = QuantenphysikService.doubleSlit(
      wavelength: wavelength,
      slitSeparation: slitSeparation,
      slitWidth: slitWidth,
    );
    if (points.isEmpty) return;

    _drawAxes(canvas, size);

    // Coordinate mapping: x in [-2,2] -> canvas 20..size.width-10
    // y in [0,1] -> canvas size.height-20..10
    final xMin = points.first.x;
    final xMax = points.last.x;
    final xRange = xMax - xMin;

    double cx(double x) => 20 + (x - xMin) / xRange * (size.width - 30);
    double cy(double y) => (size.height - 20) - y * (size.height - 30);

    final path = Path();
    bool first = true;
    for (final p in points) {
      if (first) {
        path.moveTo(cx(p.x), cy(p.y));
        first = false;
      } else {
        path.lineTo(cx(p.x), cy(p.y));
      }
    }

    // Fill area under the curve
    final fill = Path.from(path)
      ..lineTo(cx(xMax), cy(0))
      ..lineTo(cx(xMin), cy(0))
      ..close();
    canvas.drawPath(fill, Paint()..color = _cyan.withValues(alpha: 0.15));

    // Curve stroke
    canvas.drawPath(
      path,
      Paint()
        ..color = _cyan
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );

    _drawLabel(canvas, 'Intensitaet vs. Schirmposition', _cyan);
  }

  void _drawAxes(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 0.5;
    // Baseline (bottom)
    canvas.drawLine(
      Offset(20, size.height - 20),
      Offset(size.width - 10, size.height - 20),
      axisPaint,
    );
    // Y-axis
    canvas.drawLine(
      const Offset(20, 10),
      Offset(20, size.height - 10),
      axisPaint,
    );
  }

  void _drawLabel(Canvas canvas, String text, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color.withValues(alpha: 0.6), fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, const Offset(26, 6));
  }

  @override
  bool shouldRepaint(_DoppelspaltPainter old) =>
      old.wavelength != wavelength ||
      old.slitSeparation != slitSeparation ||
      old.slitWidth != slitWidth;
}

/// Draws psi(x, t) or |psi(x)|^2 for a particle in an infinite potential well.
class _WellenfunktionPainter extends CustomPainter {
  final int energyLevel;
  final double time;
  final bool showProbability;

  _WellenfunktionPainter({
    required this.energyLevel,
    required this.time,
    required this.showProbability,
  });

  static const _cyan = Color(0xFF00D4AA);
  static const _cyanAccent = Color(0xFF00FFD4);

  @override
  void paint(Canvas canvas, Size size) {
    final points = showProbability
        ? QuantenphysikService.probabilityDensity(energyLevel)
        : QuantenphysikService.waveFunction(energyLevel, time);
    if (points.isEmpty) return;

    // Box walls
    final wallPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(10, 10), Offset(10, size.height - 10), wallPaint);
    canvas.drawLine(
      Offset(size.width - 10, 10),
      Offset(size.width - 10, size.height - 10),
      wallPaint,
    );

    final midY = size.height * 0.5;

    // X-axis (midline for psi; baseline for prob. density)
    canvas.drawLine(
      Offset(10, midY),
      Offset(size.width - 10, midY),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..strokeWidth = 0.5,
    );

    // Determine max for normalization
    double maxY = 0;
    for (final p in points) {
      if (p.y.abs() > maxY) maxY = p.y.abs();
    }
    if (maxY < 1e-6) return;

    // Coordinate mapping
    double cx(double x) => 10 + x * (size.width - 20); // x in [0,1]
    double cyProb(double y) =>
        (size.height - 20) - (y / maxY) * (size.height - 30);
    double cyPsi(double y) => midY - (y / maxY) * (midY - 15);

    final path = Path();
    bool first = true;
    for (final p in points) {
      final canX = cx(p.x);
      final canY = showProbability ? cyProb(p.y) : cyPsi(p.y);
      if (first) {
        path.moveTo(canX, canY);
        first = false;
      } else {
        path.lineTo(canX, canY);
      }
    }

    // Fill under curve
    final baselineY = showProbability ? size.height - 20.0 : midY;
    final fill = Path.from(path)
      ..lineTo(cx(1.0), baselineY)
      ..lineTo(cx(0.0), baselineY)
      ..close();
    final curveColor = showProbability ? _cyanAccent : _cyan;
    canvas.drawPath(fill, Paint()..color = curveColor.withValues(alpha: 0.15));

    // Curve stroke
    canvas.drawPath(
      path,
      Paint()
        ..color = curveColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );

    // Energy-level label (n)
    final labelTxt = showProbability
        ? '|ψ|² (Wahrscheinlichkeit)'
        : 'ψ(x,t)  n = $energyLevel';
    final tp = TextPainter(
      text: TextSpan(
        text: labelTxt,
        style: TextStyle(
          color: curveColor.withValues(alpha: 0.6),
          fontSize: 10,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, const Offset(16, 5));
  }

  @override
  bool shouldRepaint(_WellenfunktionPainter old) =>
      old.energyLevel != energyLevel ||
      old.time != time ||
      old.showProbability != showProbability;
}

/// Draws the wave function for quantum tunneling through a rectangular barrier.
class _TunnelingPainter extends CustomPainter {
  final double barrierHeight;
  final double particleEnergy;
  final double barrierWidth;
  final double time;

  _TunnelingPainter({
    required this.barrierHeight,
    required this.particleEnergy,
    required this.barrierWidth,
    required this.time,
  });

  static const _cyan = Color(0xFF00D4AA);

  @override
  void paint(Canvas canvas, Size size) {
    final wavePoints = QuantenphysikService.tunnelingWave(
      barrierHeight: barrierHeight,
      particleEnergy: particleEnergy,
      barrierWidth: barrierWidth,
      time: time,
    );
    if (wavePoints.isEmpty) return;

    // x range: -1 to 2 (total 3 units)
    double cx(double x) => 10 + (x + 1) / 3.0 * (size.width - 20);
    final midY = size.height * 0.5;
    final maxAmp = size.height * 0.38;

    // X-axis
    canvas.drawLine(
      Offset(10, midY),
      Offset(size.width - 10, midY),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..strokeWidth = 0.5,
    );

    // Barrier region
    final bLeft = cx(0);
    final bRight = cx(barrierWidth);
    final vFrac = (barrierHeight / 4.0).clamp(0.0, 1.0);
    final barrierTop = midY - vFrac * maxAmp;

    canvas.drawRect(
      Rect.fromLTRB(bLeft, barrierTop, bRight, midY),
      Paint()..color = Colors.red.withValues(alpha: 0.14),
    );
    canvas.drawRect(
      Rect.fromLTRB(bLeft, barrierTop, bRight, midY),
      Paint()
        ..color = Colors.redAccent.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Particle energy line
    final eFrac = (particleEnergy / 4.0).clamp(0.0, 1.0);
    final energyY = midY - eFrac * maxAmp;
    canvas.drawLine(
      Offset(10, energyY),
      Offset(size.width - 10, energyY),
      Paint()
        ..color = Colors.yellowAccent.withValues(alpha: 0.55)
        ..strokeWidth = 1.0,
    );

    // Wave function
    double maxWave = 0;
    for (final p in wavePoints) {
      if (p.y.abs() > maxWave) maxWave = p.y.abs();
    }
    if (maxWave < 1e-6) return;

    final path = Path();
    bool first = true;
    for (final p in wavePoints) {
      final canX = cx(p.x);
      final canY = midY - (p.y / maxWave) * maxAmp * 0.72;
      if (first) {
        path.moveTo(canX, canY);
        first = false;
      } else {
        path.lineTo(canX, canY);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = _cyan
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );

    // Labels V / E
    _paintSmallText(
      canvas,
      'V',
      Colors.redAccent.withValues(alpha: 0.9),
      Offset((bLeft + bRight) / 2 - 4, barrierTop - 14),
    );
    _paintSmallText(
      canvas,
      'E',
      Colors.yellowAccent.withValues(alpha: 0.85),
      Offset(12, energyY - 13),
    );
    _paintSmallText(
      canvas,
      'Quanten-Tunneling',
      _cyan.withValues(alpha: 0.6),
      const Offset(16, 5),
    );
  }

  void _paintSmallText(Canvas canvas, String text, Color color, Offset offset) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_TunnelingPainter old) =>
      old.barrierHeight != barrierHeight ||
      old.particleEnergy != particleEnergy ||
      old.barrierWidth != barrierWidth ||
      old.time != time;
}

/// Draws Gaussian wave packets in position and momentum space side by side.
/// Illustrates the Heisenberg uncertainty principle.
class _UnschaerfePainter extends CustomPainter {
  final double sigmaX;

  _UnschaerfePainter({required this.sigmaX});

  static const _posCyan = Color(0xFF00D4AA);
  static const _momOrange = Color(0xFFFF7043);

  @override
  void paint(Canvas canvas, Size size) {
    final posPoints = QuantenphysikService.gaussianPacket(sigmaX);
    final momPoints = QuantenphysikService.momentumDistribution(sigmaX);

    final halfW = size.width / 2;

    // Divider
    canvas.drawLine(
      Offset(halfW, 8),
      Offset(halfW, size.height - 8),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..strokeWidth = 0.5,
    );

    _drawGaussian(
      canvas,
      Offset.zero,
      Size(halfW, size.height),
      posPoints,
      _posCyan,
      'Ort x',
    );
    _drawGaussian(
      canvas,
      Offset(halfW, 0),
      Size(halfW, size.height),
      momPoints,
      _momOrange,
      'Impuls p',
    );
  }

  void _drawGaussian(
    Canvas canvas,
    Offset origin,
    Size area,
    List<QuantumPoint> points,
    Color color,
    String label,
  ) {
    if (points.isEmpty) return;
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.clipRect(Rect.fromLTWH(0, 0, area.width, area.height));

    final baseY = area.height - 18.0;

    // Baseline
    canvas.drawLine(
      Offset(8, baseY),
      Offset(area.width - 8, baseY),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..strokeWidth = 0.5,
    );

    // Gaussian curve — x in [-3,3] mapped to canvas
    double cx(double x) => 8 + (x + 3) / 6.0 * (area.width - 16);
    double cy(double y) => baseY - y * (area.height - 28);

    final path = Path();
    bool first = true;
    for (final p in points) {
      if (first) {
        path.moveTo(cx(p.x), cy(p.y));
        first = false;
      } else {
        path.lineTo(cx(p.x), cy(p.y));
      }
    }

    // Fill
    final fill = Path.from(path)
      ..lineTo(cx(3.0), baseY)
      ..lineTo(cx(-3.0), baseY)
      ..close();
    canvas.drawPath(fill, Paint()..color = color.withValues(alpha: 0.18));

    // Stroke
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );

    // Label
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, const Offset(12, 5));

    canvas.restore();
  }

  @override
  bool shouldRepaint(_UnschaerfePainter old) => old.sigmaX != sigmaX;
}
