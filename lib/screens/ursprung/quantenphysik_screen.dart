import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/quantenphysik_model.dart';
import '../../services/quantenphysik_service.dart';
import '../../theme/wb_cinematic_tokens.dart';
import '../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../widgets/responsive_web_container.dart';

/// Interactive quantum physics simulator with 4 phenomena:
/// - Doppelspalt (double-slit interference)
/// - Wellenfunktion (wave function in infinite potential well)
/// - Tunneling (quantum tunneling through a barrier)
/// - Unschaerfe (Heisenberg uncertainty principle)
///
/// User-friendly shell (Issue #410): each phenomenon offers ready-made
/// presets (DropdownButton), a one-tap reset, a global play/pause control for
/// the time animation and a built-in usage guide. The layout adapts to the
/// screen size — on wide screens (tablet/desktop) the canvas and the controls
/// sit side by side, on phones they stack vertically.
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

  // Width at and above which the canvas and the controls are shown in two
  // columns instead of stacking. Tuned to tablet landscape / desktop.
  static const double _twoColumnBreakpoint = 720;

  // ── Per-phenomenon default parameters (used by the reset button) ────────────
  static const double _defWavelength = 0.25;
  static const double _defSlitSeparation = 0.5;
  static const double _defSlitWidth = 0.15;
  static const int _defEnergyLevel = 1;
  static const double _defBarrierHeight = 2.0;
  static const double _defParticleEnergy = 1.0;
  static const double _defBarrierWidth = 0.5;
  static const double _defSigmaX = 0.5;

  late final TabController _tabCtrl;
  late final AnimationController _timeCtrl;

  /// Whether the time animation (wave evolution) is currently running.
  bool _isPlaying = true;

  // ── Doppelspalt parameters ─────────────────────────────────────────────────
  double _wavelength = _defWavelength;
  double _slitSeparation = _defSlitSeparation;
  double _slitWidth = _defSlitWidth;

  // ── Wellenfunktion parameters ──────────────────────────────────────────────
  int _energyLevel = _defEnergyLevel;
  bool _showProbability = false;

  // ── Tunneling parameters ───────────────────────────────────────────────────
  double _barrierHeight = _defBarrierHeight;
  double _particleEnergy = _defParticleEnergy;
  double _barrierWidth = _defBarrierWidth;

  // ── Heisenberg parameters ──────────────────────────────────────────────────
  double _sigmaX = _defSigmaX;

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

  /// Start/stop the time evolution without rebuilding the whole tree pointlessly.
  void _togglePlayback() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _timeCtrl.repeat();
      } else {
        _timeCtrl.stop();
      }
    });
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
            Flexible(
              child: Text(
                'Quantenphysik-Simulator',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _isPlaying ? 'Animation pausieren' : 'Animation starten',
            icon: Icon(
              _isPlaying
                  ? Icons.pause_circle_outline
                  : Icons.play_circle_outline,
              color: _cyan,
            ),
            onPressed: _togglePlayback,
          ),
          IconButton(
            tooltip: 'Bedienungshilfe',
            icon: const Icon(Icons.help_outline, color: _cyan),
            onPressed: _showHelpSheet,
          ),
        ],
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
    return _tabScaffold(
      title: phenom.title,
      description: phenom.description,
      formula: phenom.formula,
      canvas: _buildCanvas(
        _DoppelspaltPainter(
          wavelength: _wavelength,
          slitSeparation: _slitSeparation,
          slitWidth: _slitWidth,
        ),
      ),
      presets: <_QuantumPreset>[
        _QuantumPreset(
          'Rotes Licht (grosse Wellenlaenge)',
          () => setState(() {
            _wavelength = 0.45;
            _slitSeparation = 0.5;
            _slitWidth = 0.15;
          }),
        ),
        _QuantumPreset(
          'Blaues Licht (kleine Wellenlaenge)',
          () => setState(() {
            _wavelength = 0.1;
            _slitSeparation = 0.5;
            _slitWidth = 0.12;
          }),
        ),
        _QuantumPreset(
          'Weite Spalte, scharfe Streifen',
          () => setState(() {
            _wavelength = 0.25;
            _slitSeparation = 1.2;
            _slitWidth = 0.05;
          }),
        ),
        _QuantumPreset(
          'Breite Spalte, weiche Streifen',
          () => setState(() {
            _wavelength = 0.25;
            _slitSeparation = 0.3;
            _slitWidth = 0.35;
          }),
        ),
      ],
      onReset: () => setState(() {
        _wavelength = _defWavelength;
        _slitSeparation = _defSlitSeparation;
        _slitWidth = _defSlitWidth;
      }),
      controls: [
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
      ],
    );
  }

  // ─── Tab 1: Wellenfunktion ────────────────────────────────────────────────

  Widget _buildWellenfunktionTab() {
    final phenom = kQuantumPhenomena[1];
    return _tabScaffold(
      title: phenom.title,
      description: phenom.description,
      formula: phenom.formula,
      // AnimatedBuilder wraps only the canvas to avoid rebuilding controls each frame
      canvas: AnimatedBuilder(
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
      presets: <_QuantumPreset>[
        _QuantumPreset(
          'Grundzustand n = 1',
          () => setState(() {
            _energyLevel = 1;
            _showProbability = false;
          }),
        ),
        _QuantumPreset(
          'Erste Anregung n = 2',
          () => setState(() {
            _energyLevel = 2;
            _showProbability = false;
          }),
        ),
        _QuantumPreset(
          'Hohe Energie n = 5',
          () => setState(() {
            _energyLevel = 5;
            _showProbability = false;
          }),
        ),
        _QuantumPreset(
          'Wahrscheinlichkeit |psi|^2',
          () => setState(() {
            _energyLevel = 3;
            _showProbability = true;
          }),
        ),
      ],
      onReset: () => setState(() {
        _energyLevel = _defEnergyLevel;
        _showProbability = false;
      }),
      controls: [
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
              'psi(x)',
              !_showProbability,
              () => setState(() => _showProbability = false),
            ),
            const SizedBox(width: 8),
            _chipToggle(
              '|psi|^2',
              _showProbability,
              () => setState(() => _showProbability = true),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Tab 2: Tunneling ─────────────────────────────────────────────────────

  Widget _buildTunnelingTab() {
    final phenom = kQuantumPhenomena[2];
    final t = QuantenphysikService.tunnelingProbability(
      barrierHeight: _barrierHeight,
      particleEnergy: _particleEnergy,
      barrierWidth: _barrierWidth,
    );

    return _tabScaffold(
      title: phenom.title,
      description: phenom.description,
      formula: phenom.formula,
      badge: _badgeBox(
        icon: Icons.show_chart,
        text: 'Tunnelwahrscheinlichkeit: ${(t * 100).toStringAsFixed(2)} %',
      ),
      canvas: AnimatedBuilder(
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
      presets: <_QuantumPreset>[
        _QuantumPreset(
          'Dicke Barriere (kaum Tunneln)',
          () => setState(() {
            _barrierHeight = 2.5;
            _particleEnergy = 1.0;
            _barrierWidth = 1.2;
          }),
        ),
        _QuantumPreset(
          'Duenne Barriere (starkes Tunneln)',
          () => setState(() {
            _barrierHeight = 2.5;
            _particleEnergy = 1.0;
            _barrierWidth = 0.2;
          }),
        ),
        _QuantumPreset(
          'Energie nahe Barriere',
          () => setState(() {
            _barrierHeight = 3.0;
            _particleEnergy = 2.5;
            _barrierWidth = 0.5;
          }),
        ),
        _QuantumPreset(
          'Niedrige Energie',
          () => setState(() {
            _barrierHeight = 3.0;
            _particleEnergy = 0.4;
            _barrierWidth = 0.5;
          }),
        ),
      ],
      onReset: () => setState(() {
        _barrierHeight = _defBarrierHeight;
        _particleEnergy = _defParticleEnergy;
        _barrierWidth = _defBarrierWidth;
      }),
      controls: [
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
      ],
    );
  }

  // ─── Tab 3: Heisenberg Unschaerfe ─────────────────────────────────────────

  Widget _buildUnschaerfeTab() {
    final phenom = kQuantumPhenomena[3];
    final sigmaP = 0.5 / _sigmaX;
    final product = _sigmaX * sigmaP;

    return _tabScaffold(
      title: phenom.title,
      description: phenom.description,
      formula: phenom.formula,
      badge: Container(
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
              'Delta_x = ${_sigmaX.toStringAsFixed(3)}   '
              'Delta_p = ${sigmaP.toStringAsFixed(3)}   '
              'Produkt = ${product.toStringAsFixed(3)}',
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
                  : 'Produkt liegt ueber der Unschaerfegrenze hbar/2',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      canvas: _buildCanvas(_UnschaerfePainter(sigmaX: _sigmaX)),
      presets: <_QuantumPreset>[
        _QuantumPreset(
          'Scharfer Ort, breiter Impuls',
          () => setState(() => _sigmaX = 0.2),
        ),
        _QuantumPreset('Ausgewogen', () => setState(() => _sigmaX = 0.5)),
        _QuantumPreset(
          'Breiter Ort, scharfer Impuls',
          () => setState(() => _sigmaX = 1.3),
        ),
      ],
      onReset: () => setState(() => _sigmaX = _defSigmaX),
      controls: [
        _sliderRow(
          'Ortsunschaerfe Delta_x',
          _sigmaX,
          0.1,
          1.5,
          (v) => setState(() => _sigmaX = v),
        ),
      ],
    );
  }

  // ─── Shared tab scaffold (responsive) ─────────────────────────────────────

  /// Builds the common structure for every phenomenon tab:
  /// title + description + optional result badge + canvas on one side, and the
  /// preset selector, reset button, parameter controls and formula on the
  /// other. On phones everything stacks; from [_twoColumnBreakpoint] upward the
  /// canvas and the controls sit side by side. Wrapped in a
  /// [ResponsiveWebContainer] so the content stays a comfortable reading width
  /// on large desktop viewports.
  Widget _tabScaffold({
    required String title,
    required String description,
    required String formula,
    required Widget canvas,
    required List<_QuantumPreset> presets,
    required VoidCallback onReset,
    required List<Widget> controls,
    Widget? badge,
  }) {
    return ResponsiveWebContainer(
      variant: WebContainerVariant.wide,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final twoColumn = constraints.maxWidth >= _twoColumnBreakpoint;

            final visual = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _phenomTitle(title),
                const SizedBox(height: 8),
                _infoBox(description),
                if (badge != null) ...[const SizedBox(height: 12), badge],
                const SizedBox(height: 16),
                canvas,
              ],
            );

            final panel = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _presetBar(presets, onReset),
                const SizedBox(height: 16),
                ...controls,
                const SizedBox(height: 12),
                _formulaBox(formula),
              ],
            );

            if (twoColumn) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: visual),
                  const SizedBox(width: 24),
                  Expanded(flex: 4, child: panel),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [visual, const SizedBox(height: 20), panel],
            );
          },
        ),
      ),
    );
  }

  /// Preset dropdown + reset button row. Picking a preset applies a ready-made
  /// parameter set; the dropdown keeps no persistent selection because the
  /// sliders can be moved freely afterwards.
  Widget _presetBar(List<_QuantumPreset> presets, VoidCallback onReset) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: _surface,
              border: Border.all(color: _cyan.withValues(alpha: 0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                isExpanded: true,
                value: null,
                dropdownColor: _surface,
                iconEnabledColor: _cyan,
                borderRadius: BorderRadius.circular(12),
                hint: Row(
                  children: [
                    const Icon(Icons.tune, color: _cyan, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Voreinstellung waehlen',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                items: [
                  for (var i = 0; i < presets.length; i++)
                    DropdownMenuItem<int>(
                      value: i,
                      child: Text(
                        presets[i].label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
                onChanged: (i) {
                  if (i != null) presets[i].apply();
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: onReset,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Zuruecksetzen'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _cyan.withValues(alpha: 0.15),
            foregroundColor: _cyan,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: _cyan.withValues(alpha: 0.4)),
            ),
          ),
        ),
      ],
    );
  }

  /// Usage guide opened from the app bar — explains the controls in German.
  void _showHelpSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'So bedienst du den Simulator',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                _helpRow(
                  Icons.tab,
                  'Reiter oben',
                  'Wechsle zwischen den vier Quantenphaenomenen.',
                ),
                _helpRow(
                  Icons.tune,
                  'Voreinstellung',
                  'Waehle ein fertiges Experiment - die Regler springen auf '
                      'sinnvolle Werte.',
                ),
                _helpRow(
                  Icons.drag_handle,
                  'Regler',
                  'Veraendere einzelne Parameter und beobachte die Wirkung '
                      'sofort im Diagramm.',
                ),
                _helpRow(
                  Icons.play_circle_outline,
                  'Play / Pause',
                  'Halte die zeitliche Animation an, um einen Moment genau zu '
                      'betrachten.',
                ),
                _helpRow(
                  Icons.refresh,
                  'Zuruecksetzen',
                  'Stellt die Standardwerte des aktuellen Reiters wieder her.',
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(foregroundColor: _cyan),
                    child: const Text('Verstanden'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _helpRow(IconData icon, String title, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _cyan, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

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

  /// Highlighted result chip shown above a canvas (e.g. tunneling probability).
  Widget _badgeBox({required IconData icon, required String text}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: _cyan.withValues(alpha: 0.12),
      border: Border.all(color: _cyan.withValues(alpha: 0.4)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _cyan, size: 18),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              color: _cyan,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ],
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
    final clamped = value.clamp(min, max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              clamped.toStringAsFixed(2),
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
            valueIndicatorColor: _cyan,
            valueIndicatorTextStyle: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: Slider(
            value: clamped,
            min: min,
            max: max,
            divisions: 60,
            label: clamped.toStringAsFixed(2),
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

/// A named, ready-to-use parameter set for one phenomenon. Plain class instead
/// of a Dart 3 named record (records crash dart2js — see CLAUDE.md Kernregel 8).
class _QuantumPreset {
  final String label;
  final VoidCallback apply;
  const _QuantumPreset(this.label, this.apply);
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
        ? '|psi|^2 (Wahrscheinlichkeit)'
        : 'psi(x,t)  n = $energyLevel';
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
