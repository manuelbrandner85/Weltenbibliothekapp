// 🌀 HUMAN DESIGN BODY-GRAPH · Cinematic Visual Type + 9 Centers + Aspects
//
// Klassischer HD-Körpergraph mit 9 Energie-Zentren an konventionellen Positionen,
// definierte vs undefinierte Zentren visuell unterschieden.
// Type/Authority/Strategy/Profile prominent + Erklärungstexte.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/storage/unified_storage_service.dart';
import '../../../services/human_design_service.dart';
import '../../../services/spirit_reading_service.dart';
import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/cinematic/wb_ambient_particles.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/cinematic/wb_vignette.dart';

class HumanDesignBodyGraphScreen extends StatefulWidget {
  const HumanDesignBodyGraphScreen({super.key});

  @override
  State<HumanDesignBodyGraphScreen> createState() =>
      _HumanDesignBodyGraphScreenState();
}

class _HumanDesignBodyGraphScreenState extends State<HumanDesignBodyGraphScreen>
    with TickerProviderStateMixin {
  static const Color _bgDark = Color(0xFF050414);

  /// Theme-aware background. Light-Mode liefert helle `context.wb.bgVoid`,
  /// Dark-Mode behält den Original-Ton.
  Color _bg(BuildContext context) {
    final wb = Theme.of(context).extension<WBCinematic>();
    return wb?.bgVoid ?? _bgDark;
  }

  static const Color _primary = Color(0xFF00ACC1);
  static const Color _accent = Color(0xFFFFB300);
  static const Color _gold = Color(0xFFFFD54F);

  DateTime _birthDate = DateTime(1990, 6, 21, 12, 0);
  bool _hasTime = true;
  HumanDesignResult? _hd;

  late final AnimationController _revealCtrl;
  late final AnimationController _ambientCtrl;

  @override
  void initState() {
    super.initState();
    _revealCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));
    _ambientCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 11))
          ..repeat();
  }

  @override
  void dispose() {
    _revealCtrl.dispose();
    _ambientCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    HapticFeedback.selectionClick();
    final d = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
              primary: _primary, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (d == null) return;
    if (_hasTime) {
      final t = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_birthDate),
      );
      _birthDate =
          DateTime(d.year, d.month, d.day, t?.hour ?? 12, t?.minute ?? 0);
    } else {
      _birthDate = DateTime(d.year, d.month, d.day, 12, 0);
    }
    setState(() {});
  }

  // v95: Tap auf ein Center oeffnet ein Info-Sheet mit der Deutung
  // (definiert vs. offen). Position-Lookup matched die _BodyGraphPainter-
  // Konstanten so gut wie moeglich.
  void _handleCenterTap(Offset local) {
    if (_hd == null) return;
    final ctx = context;
    final size = (ctx.findRenderObject() as RenderBox?)?.size;
    final w = size?.width ?? 360;
    final h = w / 0.78;
    final positions = <String, Offset>{
      'crown': Offset(w * 0.5, h * 0.08),
      'ajna': Offset(w * 0.5, h * 0.22),
      'throat': Offset(w * 0.5, h * 0.37),
      'g': Offset(w * 0.5, h * 0.55),
      'heart': Offset(w * 0.75, h * 0.55),
      'spleen': Offset(w * 0.18, h * 0.65),
      'solar_plexus': Offset(w * 0.82, h * 0.65),
      'sacral': Offset(w * 0.5, h * 0.75),
      'root': Offset(w * 0.5, h * 0.92),
    };
    String? hit;
    double bestDist = 40;
    positions.forEach((key, pos) {
      final d = (pos - local).distance;
      if (d < bestDist) {
        bestDist = d;
        hit = key;
      }
    });
    if (hit == null) return;
    HapticFeedback.lightImpact();
    final isDefined = _hd!.definedCenters.contains(hit);
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => _CenterInfoSheet(
          centerKey: hit!, isDefined: isDefined, accent: _gold),
    );
  }

  void _compute() {
    HapticFeedback.mediumImpact();
    final result = HumanDesign.compute(birthDateUtc: _birthDate.toUtc());
    setState(() => _hd = result);
    _revealCtrl.forward(from: 0);
  }

  Future<void> _save() async {
    if (_hd == null) return;
    final username = UnifiedStorageService().getUsername('energie');
    final userId = await UnifiedStorageService().getCurrentUserId() ?? 'anonym';
    final saved = await SpiritReadingService.instance.save(
      userId: userId,
      username: username,
      tool: 'human_design',
      summary: '🌀 ${_hd!.type} · ${_hd!.profile} · ${_hd!.authority}',
      result: {
        'birth_date': _birthDate.toIso8601String(),
        'type': _hd!.type,
        'authority': _hd!.authority,
        'strategy': _hd!.strategy,
        'profile': _hd!.profile,
        'defined_centers': _hd!.definedCenters.toList(),
        'defined_gates': _hd!.definedGates.toList(),
      },
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(saved != null
          ? '🌀 Body-Graph gespeichert'
          : '⚠️ Speichern fehlgeschlagen'),
      backgroundColor: _primary,
    ));
  }

  String _typeEmoji(String type) {
    switch (type) {
      case 'Manifestor':
        return '⚡';
      case 'Generator':
        return '🔥';
      case 'Manifesting Generator':
        return '⚡🔥';
      case 'Projector':
        return '👁️';
      case 'Reflector':
        return '🌙';
      default:
        return '🌀';
    }
  }

  String _typeDescription(String type) {
    switch (type) {
      case 'Manifestor':
        return 'Du bist hier um zu initiieren — neue Welten zu eröffnen. ~9% der Menschheit. Strategie: Informieren bevor du handelst.';
      case 'Generator':
        return 'Du bist die Lebenskraft des Planeten — gebaut um zu reagieren auf das was dich anzieht. ~37%. Strategie: Reagiere mit deiner Sakral-Antwort.';
      case 'Manifesting Generator':
        return 'Hybrid aus Initiieren + Reagieren. Schnelle Multi-Passion-Wesen. ~33%. Strategie: Reagiere, dann informiere.';
      case 'Projector':
        return 'Du bist der Lenker und Berater — wartest auf Einladung zum Lenken anderer. ~21%. Strategie: Warte auf die Einladung.';
      case 'Reflector':
        return 'Du bist der Spiegel der Gemeinschaft — sehr selten. ~1%. Strategie: Warte einen lunaren Zyklus (29.5 Tage) vor wichtigen Entscheidungen.';
      default:
        return '';
    }
  }

  String _fmtDate(DateTime dt) {
    final d = dt.toLocal();
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg(context),
      extendBodyBehindAppBar: true,
      appBar: WBGlassAppBar(
        world: WBWorld.energie,
        titleWidget: ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            colors: [_gold, _primary, _accent],
          ).createShader(r),
          child: const Text('HUMAN DESIGN',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3)),
        ),
        actions: [
          if (_hd != null)
            IconButton(
              icon: const Icon(Icons.bookmark_added_rounded, color: _gold),
              tooltip: 'Body-Graph speichern',
              onPressed: _save,
            ),
        ],
      ),
      body: Stack(fit: StackFit.expand, children: [
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.3),
              radius: 1.5,
              colors: [Color(0x4400796B), Color(0x33041A1F), _bgDark],
            ),
          ),
        ),
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _ambientCtrl,
            builder: (_, __) => CustomPaint(
              painter: _HdOrbsPainter(_ambientCtrl.value),
              size: Size.infinite,
            ),
          ),
        ),
        const IgnorePointer(
            child: WBAmbientParticles(world: WBWorld.energie, count: 38)),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
            child: Column(children: [
              _birthCard(),
              const SizedBox(height: 12),
              if (_hd != null) ...[
                _typeCard(),
                const SizedBox(height: 12),
                _bodyGraphCard(),
                const SizedBox(height: 12),
                _detailsCard(),
              ] else
                _empty(),
            ]),
          ),
        ),
        const IgnorePointer(child: WBVignette()),
      ]),
    );
  }

  Widget _birthCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('GEBURTSZEITPUNKT',
                style: TextStyle(
                    color: _gold,
                    fontSize: 10,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _primary.withValues(alpha: 0.4)),
                ),
                child: Row(children: [
                  Icon(Icons.calendar_month_rounded, color: _gold, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_fmtDate(_birthDate),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ),
                  Icon(Icons.edit_rounded, color: _primary, size: 16),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              const Text('Genaue Geburtszeit?',
                  style: TextStyle(color: Colors.white70, fontSize: 11)),
              const Spacer(),
              Switch(
                value: _hasTime,
                onChanged: (v) => setState(() {
                  _hasTime = v;
                  if (!v)
                    _birthDate = DateTime(_birthDate.year, _birthDate.month,
                        _birthDate.day, 12, 0);
                }),
                activeColor: _primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ]),
            const Text(
                'Wichtig für HD! Profil + Linie können sich um 1 Stunde verschieben.',
                style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontStyle: FontStyle.italic)),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _compute,
                icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                label: const Text('BODY-GRAPH BERECHNEN',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _empty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(children: [
        Icon(Icons.bubble_chart_rounded,
            color: _primary.withValues(alpha: 0.4), size: 80),
        const SizedBox(height: 16),
        const Text('Wähle Geburtszeit + Berechnen',
            style: TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center),
        const SizedBox(height: 4),
        const Text('für deinen einzigartigen Body-Graph',
            style: TextStyle(
                color: Colors.white38,
                fontSize: 12,
                fontStyle: FontStyle.italic),
            textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _typeCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _primary.withValues(alpha: 0.3),
                _accent.withValues(alpha: 0.1)
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _primary.withValues(alpha: 0.4)),
          ),
          child: Column(children: [
            Text(_typeEmoji(_hd!.type), style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 6),
            ShaderMask(
              shaderCallback: (r) =>
                  const LinearGradient(colors: [_gold, _primary])
                      .createShader(r),
              child: Text(_hd!.type.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3)),
            ),
            const SizedBox(height: 6),
            Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  _chip(_hd!.profile, _accent),
                  _chip(_hd!.authority, _gold),
                  _chip('${_hd!.definedCenters.length} Zentren', _primary),
                  _chip('${_hd!.definedGates.length} Tore', Colors.greenAccent),
                ]),
            const SizedBox(height: 12),
            Text(_typeDescription(_hd!.type),
                style: const TextStyle(
                    color: Colors.white, fontSize: 13, height: 1.6),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _gold.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                Icon(Icons.flag_rounded, color: _gold, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Strategie: ${_hd!.strategy}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      );

  Widget _bodyGraphCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(children: [
            const Text('BODY-GRAPH · 9 ZENTREN',
                style: TextStyle(
                    color: _gold,
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            AspectRatio(
              aspectRatio: 0.78,
              child: AnimatedBuilder(
                animation: _revealCtrl,
                builder: (_, __) => GestureDetector(
                  onTapDown: (d) => _handleCenterTap(d.localPosition),
                  child: CustomPaint(
                    painter: _BodyGraphPainter(
                      defined: _hd!.definedCenters,
                      definedGates: _hd!.definedGates,
                      definedChannels: _hd!.definedChannels,
                      reveal: _revealCtrl.value,
                      gold: _gold,
                      accent: _accent,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gefüllt = definiert (konsistente Energie) · Hohl = undefiniert (offen für Einflüsse)',
              style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      ),
    );
  }

  Widget _detailsCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('DEINE DEFINITION',
                style: TextStyle(
                    color: _gold,
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _detailRow('Definierte Zentren',
                _hd!.definedCenters.map((c) => _centerLabel(c)).join(' · ')),
            const SizedBox(height: 6),
            _detailRow('Aktive Tore', _hd!.definedGates.toList()..sort()),
            const SizedBox(height: 6),
            _detailRow('Aktive Kanäle',
                _hd!.definedChannels.map((c) => '${c[0]}↔${c[1]}').join(' · ')),
          ]),
        ),
      ),
    );
  }

  Widget _detailRow(String label, dynamic value) {
    final str = value is List
        ? (value.isEmpty ? '—' : value.join(', '))
        : value.toString();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              color: Colors.white60, fontSize: 10, letterSpacing: 1.5)),
      const SizedBox(height: 2),
      Text(str.isEmpty ? '—' : str,
          style:
              const TextStyle(color: Colors.white, fontSize: 12, height: 1.5)),
    ]);
  }

  String _centerLabel(String code) =>
      const {
        'crown': 'Krone',
        'ajna': 'Ajna',
        'throat': 'Kehle',
        'g': 'G-Zentrum',
        'heart': 'Herz/Ego',
        'spleen': 'Milz',
        'solar_plexus': 'Solar-Plexus',
        'sacral': 'Sakral',
        'root': 'Wurzel',
      }[code] ??
      code;
}

// ── PAINTER: Body-Graph ──────────────────────────────────────────────────────
class _BodyGraphPainter extends CustomPainter {
  final Set<String> defined;
  final Set<int> definedGates;
  final Set<List<int>> definedChannels;
  final double reveal;
  final Color gold;
  final Color accent;

  _BodyGraphPainter({
    required this.defined,
    this.definedGates = const {},
    this.definedChannels = const {},
    required this.reveal,
    required this.gold,
    required this.accent,
  });

  static const _centerColors = {
    'crown': Color(0xFFFFD54F),
    'ajna': Color(0xFF66BB6A),
    'throat': Color(0xFF8D6E63),
    'g': Color(0xFFFFA000),
    'heart': Color(0xFFE53935),
    'spleen': Color(0xFF9CCC65),
    'solar_plexus': Color(0xFFEC407A),
    'sacral': Color(0xFFE53935),
    'root': Color(0xFF8D6E63),
  };

  static const _centerLabels = {
    'crown': 'Krone',
    'ajna': 'Ajna',
    'throat': 'Kehle',
    'g': 'G',
    'heart': 'Ego',
    'spleen': 'Milz',
    'solar_plexus': 'Plexus',
    'sacral': 'Sakral',
    'root': 'Wurzel',
  };

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Standard-Positionen (in 0..1 normalisiert auf 0.78 aspect ratio)
    final positions = <String, Offset>{
      'crown': Offset(w * 0.5, h * 0.08),
      'ajna': Offset(w * 0.5, h * 0.22),
      'throat': Offset(w * 0.5, h * 0.37),
      'g': Offset(w * 0.5, h * 0.55),
      'heart': Offset(w * 0.75, h * 0.55),
      'spleen': Offset(w * 0.18, h * 0.65),
      'solar_plexus': Offset(w * 0.82, h * 0.65),
      'sacral': Offset(w * 0.5, h * 0.75),
      'root': Offset(w * 0.5, h * 0.92),
    };
    final sizes = <String, double>{
      'crown': 50,
      'ajna': 50,
      'throat': 60,
      'g': 56,
      'heart': 44,
      'spleen': 44,
      'solar_plexus': 44,
      'sacral': 60,
      'root': 60,
    };

    // Verbindungs-Linien zwischen Centern (klassische HD-Verbindungen)
    final connections = [
      ['crown', 'ajna'],
      ['ajna', 'throat'],
      ['throat', 'g'],
      ['throat', 'heart'],
      ['throat', 'spleen'],
      ['throat', 'solar_plexus'],
      ['g', 'sacral'],
      ['g', 'heart'],
      ['heart', 'sacral'],
      ['heart', 'solar_plexus'],
      ['spleen', 'sacral'],
      ['spleen', 'root'],
      ['solar_plexus', 'sacral'],
      ['solar_plexus', 'root'],
      ['sacral', 'root'],
    ];
    for (final c in connections) {
      final p1 = positions[c[0]]!;
      final p2 = positions[c[1]]!;
      final bothDefined = defined.contains(c[0]) && defined.contains(c[1]);
      // v95: pruefe ob ein aktiver Channel diese beiden Center verbindet.
      final channelActive = _hasActiveChannelBetween(c[0], c[1]);
      Color col;
      double sw;
      double alpha;
      if (channelActive) {
        col = gold;
        sw = 3.0;
        alpha = 0.95;
      } else if (bothDefined) {
        col = gold;
        sw = 1.8;
        alpha = 0.6;
      } else {
        col = Colors.white.withValues(alpha: 0.08);
        sw = 0.8;
        alpha = 0.3;
      }
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = col.withValues(alpha: alpha * reveal)
          ..strokeWidth = sw,
      );
      // Glow auf aktive Channels.
      if (channelActive) {
        canvas.drawLine(
          p1,
          p2,
          Paint()
            ..color = gold.withValues(alpha: 0.4 * reveal)
            ..strokeWidth = 8
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
      }
    }

    // v95 Gate-Dots: kleine Punkte fuer aktive Gates pro Center.
    // Vereinfacht: wir verteilen aktive Gates radial um das Center.
    for (final centerKey in _centerLabels.keys) {
      final gates = _gatesForCenter(centerKey);
      final active = gates.where(definedGates.contains).toList();
      if (active.isEmpty) continue;
      final centerPos = positions[centerKey]!;
      final radius = (sizes[centerKey] ?? 50) / 2 + 10;
      for (int i = 0; i < active.length; i++) {
        final angle = (2 * math.pi * i / active.length) - math.pi / 2;
        final dotPos = Offset(
          centerPos.dx + math.cos(angle) * radius,
          centerPos.dy + math.sin(angle) * radius,
        );
        canvas.drawCircle(
          dotPos,
          3.2,
          Paint()
            ..color = gold.withValues(alpha: reveal)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
        );
        // Kleine Gate-Nummer
        final tp = TextPainter(
          text: TextSpan(
              text: '${active[i]}',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95 * reveal),
                  fontSize: 7,
                  fontWeight: FontWeight.w800)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, dotPos.translate(-tp.width / 2, -tp.height / 2));
      }
    }

    // Zentren
    final centerOrder = [
      'crown',
      'ajna',
      'throat',
      'heart',
      'g',
      'spleen',
      'solar_plexus',
      'sacral',
      'root'
    ];
    final visibleCount = (centerOrder.length * reveal).ceil();

    for (int i = 0; i < visibleCount && i < centerOrder.length; i++) {
      final key = centerOrder[i];
      final pos = positions[key]!;
      final s = sizes[key]!;
      final isDefined = defined.contains(key);
      final color = _centerColors[key] ?? Colors.white;

      _drawCenter(canvas, pos, s, key, isDefined, color);

      // Label
      final tp = TextPainter(
        text: TextSpan(
          text: _centerLabels[key] ?? key,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9 * reveal),
            fontSize: 9,
            fontWeight: FontWeight.w600,
            shadows: [Shadow(color: Colors.black, blurRadius: 2)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
    }
  }

  void _drawCenter(Canvas canvas, Offset pos, double s, String key,
      bool isDefined, Color color) {
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = isDefined
          ? color.withValues(alpha: 0.7 * reveal)
          : Colors.black.withValues(alpha: 0.4 * reveal);
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isDefined ? 2 : 1.5
      ..color = color.withValues(alpha: reveal);
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..color = color.withValues(alpha: (isDefined ? 0.4 : 0.15) * reveal);

    // Form je nach Center
    if (key == 'crown' || key == 'ajna') {
      // Dreieck nach oben
      final path = _triangle(pos, s, up: true);
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, strokePaint);
    } else if (key == 'heart' || key == 'spleen' || key == 'solar_plexus') {
      // Dreieck nach unten
      final path = _triangle(pos, s, up: false);
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, strokePaint);
    } else if (key == 'g') {
      // Raute
      final path = _diamond(pos, s);
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, strokePaint);
    } else {
      // Quadrat (throat, sacral, root)
      final rect = Rect.fromCenter(center: pos, width: s, height: s * 0.65);
      canvas.drawRect(rect, glowPaint);
      canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, strokePaint);
    }
  }

  Path _triangle(Offset pos, double s, {required bool up}) {
    final half = s / 2;
    final height = s * 0.85;
    if (up) {
      return Path()
        ..moveTo(pos.dx, pos.dy - height / 2)
        ..lineTo(pos.dx - half, pos.dy + height / 2)
        ..lineTo(pos.dx + half, pos.dy + height / 2)
        ..close();
    } else {
      return Path()
        ..moveTo(pos.dx, pos.dy + height / 2)
        ..lineTo(pos.dx - half, pos.dy - height / 2)
        ..lineTo(pos.dx + half, pos.dy - height / 2)
        ..close();
    }
  }

  Path _diamond(Offset pos, double s) {
    final r = s / 2;
    return Path()
      ..moveTo(pos.dx, pos.dy - r)
      ..lineTo(pos.dx + r, pos.dy)
      ..lineTo(pos.dx, pos.dy + r)
      ..lineTo(pos.dx - r, pos.dy)
      ..close();
  }

  // v95: Lookup-Tabelle Gate -> Center (HD-Standard).
  static const Map<int, String> _gateToCenter = {
    // Crown
    61: 'crown', 63: 'crown', 64: 'crown',
    // Ajna
    47: 'ajna', 24: 'ajna', 4: 'ajna', 17: 'ajna', 43: 'ajna', 11: 'ajna',
    // Throat
    62: 'throat', 23: 'throat', 56: 'throat', 35: 'throat', 12: 'throat',
    45: 'throat', 33: 'throat', 8: 'throat', 31: 'throat',
    16: 'throat', 20: 'throat',
    // G
    1: 'g', 2: 'g', 7: 'g', 10: 'g', 13: 'g', 15: 'g', 25: 'g', 46: 'g',
    // Heart/Ego
    21: 'heart', 26: 'heart', 40: 'heart', 51: 'heart',
    // Spleen
    18: 'spleen', 28: 'spleen', 32: 'spleen', 44: 'spleen',
    48: 'spleen', 50: 'spleen', 57: 'spleen',
    // Solar Plexus
    6: 'solar_plexus', 22: 'solar_plexus', 30: 'solar_plexus',
    36: 'solar_plexus', 37: 'solar_plexus', 49: 'solar_plexus',
    55: 'solar_plexus',
    // Sacral
    3: 'sacral', 5: 'sacral', 9: 'sacral', 14: 'sacral', 27: 'sacral',
    29: 'sacral', 34: 'sacral', 42: 'sacral', 59: 'sacral',
    // Root
    19: 'root', 38: 'root', 39: 'root', 41: 'root', 52: 'root', 53: 'root',
    54: 'root', 58: 'root', 60: 'root',
  };

  List<int> _gatesForCenter(String center) {
    return _gateToCenter.entries
        .where((e) => e.value == center)
        .map((e) => e.key)
        .toList();
  }

  /// Prueft ob ein aktiver Channel zwischen zwei Centern verlaeuft.
  /// Channel = beide Gates definiert. definedChannels enthaelt
  /// List<int> mit 2 Gate-Nummern pro Eintrag.
  bool _hasActiveChannelBetween(String a, String b) {
    for (final channel in definedChannels) {
      if (channel.length < 2) continue;
      final ca = _gateToCenter[channel[0]];
      final cb = _gateToCenter[channel[1]];
      if ((ca == a && cb == b) || (ca == b && cb == a)) return true;
    }
    return false;
  }

  @override
  bool shouldRepaint(_BodyGraphPainter old) =>
      old.defined.length != defined.length ||
      old.definedGates.length != definedGates.length ||
      old.definedChannels.length != definedChannels.length ||
      old.reveal != reveal;
}

class _HdOrbsPainter extends CustomPainter {
  final double t;
  _HdOrbsPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    _draw(
        canvas,
        Offset(size.width * 0.18,
            size.height * (0.3 + math.sin(t * 2 * math.pi) * 0.05)),
        110,
        const Color(0xFF00ACC1));
    _draw(
        canvas,
        Offset(size.width * 0.85,
            size.height * (0.55 + math.cos(t * 2 * math.pi) * 0.04)),
        90,
        const Color(0xFFFFB300));
    _draw(
        canvas,
        Offset(size.width * 0.5,
            size.height * (0.92 + math.sin(t * math.pi) * 0.03)),
        70,
        const Color(0xFFFFD54F));
  }

  void _draw(Canvas canvas, Offset c, double r, Color color) {
    final p = Paint()
      ..color = color.withValues(alpha: 0.10)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.5);
    canvas.drawCircle(c, r, p);
  }

  @override
  bool shouldRepaint(_HdOrbsPainter old) => old.t != t;
}

class _CenterInfoSheet extends StatelessWidget {
  final String centerKey;
  final bool isDefined;
  final Color accent;
  const _CenterInfoSheet({
    required this.centerKey,
    required this.isDefined,
    required this.accent,
  });

  static const _info = <String, Map<String, String>>{
    'crown': {
      'name': 'Krone',
      'defined':
          'Konstante Inspiration und mentaler Druck. Du hast feste Fragen.',
      'open':
          'Du nimmst die Fragen anderer auf. Unterscheide eigene von fremden Gedanken.',
    },
    'ajna': {
      'name': 'Ajna',
      'defined': 'Feste Art zu denken und Konzepte zu verarbeiten.',
      'open': 'Flexibles Denken. Viele Perspektiven moeglich.',
    },
    'throat': {
      'name': 'Kehle',
      'defined': 'Konsistente Manifestation und Ausdruck.',
      'open': 'Sprich nur wenn eingeladen. Dein Timing ist entscheidend.',
    },
    'g': {
      'name': 'Selbst/G',
      'defined': 'Feste Identitaet und Lebensrichtung.',
      'open': 'Chamaeleon. Identitaet variiert je nach Umgebung.',
    },
    'heart': {
      'name': 'Herz/Ego',
      'defined': 'Konsistente Willenskraft. Halte Versprechen.',
      'open': 'Beweise niemandem deinen Wert. Du bist genug.',
    },
    'sacral': {
      'name': 'Sakral',
      'defined': 'Generator-Energie. Reagiere mit Bauchgefuehl (uh-huh/uh-uh).',
      'open': 'Nicht zum Marathon-Arbeiten gemacht. Kenne dein Limit.',
    },
    'spleen': {
      'name': 'Milz',
      'defined': 'Spontane Intuition. Vertraue dem ersten Impuls.',
      'open': 'Festhalte-Tendenz. Lass los was nicht gut ist.',
    },
    'solar_plexus': {
      'name': 'Solar Plexus',
      'defined':
          'Emotionale Autoritaet. Warte auf Klarheit, keine spontanen Entscheidungen.',
      'open': 'Empathie-Schwamm. Unterscheide eigene von fremden Emotionen.',
    },
    'root': {
      'name': 'Wurzel',
      'defined': 'Konstanter Antriebsdruck. Lass dich nicht hetzen.',
      'open': 'Stress-anfaellig durch aeusseren Druck. Setze Grenzen.',
    },
  };

  @override
  Widget build(BuildContext context) {
    final info =
        _info[centerKey] ?? const {'name': 'Center', 'defined': '', 'open': ''};
    final body = isDefined ? info['defined']! : info['open']!;
    final status = isDefined ? 'DEFINIERT' : 'OFFEN';
    final statusColor =
        isDefined ? const Color(0xFFFFD54F) : const Color(0xFF4FC3F7);
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
          decoration: BoxDecoration(
            color: const Color(0xFF0B0716).withValues(alpha: 0.96),
            border: Border(
                top: BorderSide(
                    color: accent.withValues(alpha: 0.4), width: 1.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(children: [
                Text(info['name']!,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900)),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: statusColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(status,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5)),
                ),
              ]),
              const SizedBox(height: 14),
              Text(body,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14, height: 1.55)),
            ],
          ),
        ),
      ),
    );
  }
}
