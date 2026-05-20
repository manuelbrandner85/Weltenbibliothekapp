import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/gamification_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// AVATAR SCREEN — AUFGABE 8A
// Zeigt den evolvierenden Avatar mit CustomPainter (5 Stufen),
// Weltbalance-Balken, ausgerüstete Artefakte und bearbeitbaren Titel.
// ═══════════════════════════════════════════════════════════════════════════

// ── WELTFARBEN ───────────────────────────────────────────────────────────

const Color _kMaterie = Color(0xFFE53935);
const Color _kEnergie = Color(0xFF7C4DFF);
const Color _kVorhang = Color(0xFFC9A84C);
const Color _kUrsprung = Color(0xFF00D4AA);
const Color _kBg = Color(0xFF0D0D1A);
const Color _kSurface = Color(0xFF1A1A2E);
const Color _kTextMuted = Color(0xFF6B7280);

// ── EVOLUTIONSSTUFE ──────────────────────────────────────────────────────

/// Berechnet die Evolutionsstufe aus Gesamt-XP über alle Welten.
int _stageFromXp(int totalXp) {
  if (totalXp < 500) return 1;
  if (totalXp < 1500) return 2;
  if (totalXp < 3000) return 3;
  if (totalXp < 5000) return 4;
  return 5;
}

String _stageName(int stage) {
  switch (stage) {
    case 1:
      return 'Suchender';
    case 2:
      return 'Erwachender';
    case 3:
      return 'Wissender';
    case 4:
      return 'Meister';
    default:
      return 'Erleuchteter';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// AVATAR SCREEN
// ═══════════════════════════════════════════════════════════════════════════

class AvatarScreen extends StatefulWidget {
  const AvatarScreen({super.key});

  @override
  State<AvatarScreen> createState() => _AvatarScreenState();
}

class _AvatarScreenState extends State<AvatarScreen>
    with SingleTickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────
  late final AnimationController _animController;
  final GamificationService _gamification = GamificationService();

  bool _loading = true;
  int _totalXp = 0;
  Map<String, double> _worldBalances = {
    'materie': 0,
    'energie': 0,
    'vorhang': 0,
    'ursprung': 0,
  };
  List<String> _equippedArtifacts = [];
  String _customTitle = '';
  final TextEditingController _titleController = TextEditingController();
  bool _editingTitle = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  // ── Daten laden ─────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    try {
      // XP aus GamificationService (synchron aus Cache)
      final int matXp = _gamification.getProgress('materie').totalXp;
      final int engXp = _gamification.getProgress('energie').totalXp;
      final int noirXp = _gamification.getProgress('noir').totalXp;
      final int genesisXp = _gamification.getProgress('genesis').totalXp;
      final int total = matXp + engXp + noirXp + genesisXp;

      // Normierte Weltbalance (Anteil 0.0–1.0 relativ zum Maximum)
      final int maxWorld =
          [matXp, engXp, noirXp, genesisXp].fold(1, (a, b) => a > b ? a : b);
      final Map<String, double> balances = {
        'materie': matXp / maxWorld,
        'energie': engXp / maxWorld,
        'vorhang': noirXp / maxWorld,
        'ursprung': genesisXp / maxWorld,
      };

      // Artefakte aus GamificationService
      final List<UserArtifact> artifacts =
          await _gamification.getUserArtifacts();
      final List<String> equipped = artifacts
          .where((a) => a.isEquipped)
          .map((a) => '${a.artifact.iconEmoji} ${a.artifact.nameDe}')
          .toList();

      // user_avatar aus Supabase
      String customTitle = '';
      try {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          final row = await Supabase.instance.client
              .from('user_avatar')
              .select('custom_title')
              .eq('user_id', userId)
              .maybeSingle();
          if (row != null) {
            customTitle = (row['custom_title'] as String?) ?? '';
          }
        }
      } catch (_) {
        // Tabelle existiert ggf. noch nicht — graceful degradation
      }

      if (!mounted) return;
      setState(() {
        _totalXp = total;
        _worldBalances = balances;
        _equippedArtifacts = equipped;
        _customTitle = customTitle;
        _titleController.text = customTitle;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  // ── Titel speichern ──────────────────────────────────────────────────────

  Future<void> _saveTitle(String newTitle) async {
    setState(() {
      _customTitle = newTitle;
      _editingTitle = false;
    });
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      await Supabase.instance.client.from('user_avatar').upsert({
        'user_id': userId,
        'custom_title': newTitle,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');
    } catch (_) {
      // Silent — lokaler State ist bereits aktualisiert
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final int stage = _stageFromXp(_totalXp);
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: Colors.white,
        title: const Text(
          'Mein Avatar',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kEnergie))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: _kEnergie,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  children: [
                    // ── Avatar Widget ──────────────────────────────────────
                    _AvatarDisplay(
                      stage: stage,
                      animController: _animController,
                      worldBalances: _worldBalances,
                    ),
                    const SizedBox(height: 16),

                    // ── Evolutionsstufe ────────────────────────────────────
                    _StageIndicator(stage: stage, totalXp: _totalXp),
                    const SizedBox(height: 20),

                    // ── Benutzerdefinierter Titel ──────────────────────────
                    _CustomTitleField(
                      customTitle: _customTitle,
                      editing: _editingTitle,
                      controller: _titleController,
                      onEdit: () => setState(() => _editingTitle = true),
                      onSave: _saveTitle,
                      onCancel: () {
                        _titleController.text = _customTitle;
                        setState(() => _editingTitle = false);
                      },
                    ),
                    const SizedBox(height: 20),

                    // ── Weltbalance-Balken ─────────────────────────────────
                    _WorldBalanceBars(balances: _worldBalances),
                    const SizedBox(height: 20),

                    // ── Ausgerüstete Artefakte ─────────────────────────────
                    _EquippedArtifacts(artifacts: _equippedArtifacts),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// AVATAR DISPLAY (CustomPainter + AnimationController)
// ═══════════════════════════════════════════════════════════════════════════

class _AvatarDisplay extends StatelessWidget {
  const _AvatarDisplay({
    required this.stage,
    required this.animController,
    required this.worldBalances,
  });

  final int stage;
  final AnimationController animController;
  final Map<String, double> worldBalances;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _stageAccentColor(stage).withAlpha(77),
          width: 1.5,
        ),
      ),
      child: AnimatedBuilder(
        animation: animController,
        builder: (context, _) {
          return CustomPaint(
            painter: AvatarPainter(
              stage: stage,
              animValue: animController.value,
              worldBalances: worldBalances,
            ),
          );
        },
      ),
    );
  }

  static Color _stageAccentColor(int stage) {
    switch (stage) {
      case 1:
        return Colors.grey;
      case 2:
        return _kMaterie;
      case 3:
        return _kEnergie;
      case 4:
        return _kVorhang;
      default:
        return _kUrsprung;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// AVATAR PAINTER — alle 5 Evolutionsstufen
// ═══════════════════════════════════════════════════════════════════════════

class AvatarPainter extends CustomPainter {
  final int stage;
  final double animValue; // 0.0–1.0 (AnimationController.value)
  final Map<String, double> worldBalances;

  const AvatarPainter({
    required this.stage,
    required this.animValue,
    required this.worldBalances,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (stage) {
      case 1:
        _paintStage1(canvas, size);
      case 2:
        _paintStage2(canvas, size);
      case 3:
        _paintStage3(canvas, size);
      case 4:
        _paintStage4(canvas, size);
      default:
        _paintStage5(canvas, size);
    }
  }

  // ── Stufe 1: Suchender ─────────────────────────────────────────────────
  // Einfache dunkelgraue Silhouette, einzelner Lichtpunkt in der Mitte

  void _paintStage1(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final paint = Paint();

    // Dunkle Silhouette (menschliche Form approximiert durch Ovale)
    paint.color = const Color(0xFF2D2D3A);
    // Rumpf
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 30), width: 80, height: 120),
      paint,
    );
    // Kopf
    canvas.drawCircle(Offset(cx, cy - 50), 32, paint);

    // Einzelner Lichtpunkt (pulsiert leicht mit animValue)
    final pulse = 0.5 + 0.5 * sin(animValue * 2 * pi);
    paint
      ..color = Colors.white.withAlpha((180 + (75 * pulse)).round())
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 + 4 * pulse);
    canvas.drawCircle(Offset(cx, cy), 4 + 2 * pulse, paint);
    paint.maskFilter = null;
  }

  // ── Stufe 2: Erwachender ───────────────────────────────────────────────
  // Klare Umrisslinie, 4 Weltfarb-Punkte, schwacher Aura-Ring

  void _paintStage2(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final paint = Paint();

    // Schwacher Aura-Ring
    final auraPulse = 0.3 + 0.7 * (0.5 + 0.5 * sin(animValue * 2 * pi));
    paint
      ..color = _kMaterie.withAlpha((30 * auraPulse).round())
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 30)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 90, paint);
    paint.maskFilter = null;

    // Silhouette mit Umrisslinie
    paint
      ..color = const Color(0xFF3A3A4E)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 30), width: 80, height: 120),
      paint,
    );
    canvas.drawCircle(Offset(cx, cy - 50), 32, paint);

    // Umrisslinie
    paint
      ..color = Colors.white.withAlpha(120)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 30), width: 80, height: 120),
      paint,
    );
    canvas.drawCircle(Offset(cx, cy - 50), 32, paint);
    paint.style = PaintingStyle.fill;

    // 4 Weltfarb-Punkte
    final List<MapEntry<Offset, Color>> dots = [
      MapEntry(Offset(cx - 60, cy - 30), _kMaterie),
      MapEntry(Offset(cx + 60, cy - 30), _kEnergie),
      MapEntry(Offset(cx - 60, cy + 50), _kVorhang),
      MapEntry(Offset(cx + 60, cy + 50), _kUrsprung),
    ];
    for (final d in dots) {
      paint
        ..color = d.value.withAlpha(200)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(d.key, 5, paint);
      paint.maskFilter = null;
      paint.color = d.value;
      canvas.drawCircle(d.key, 3, paint);
    }
  }

  // ── Stufe 3: Wissender ─────────────────────────────────────────────────
  // 7 Chakra-Punkte entlang der Wirbelsäule, Energielinien, sichtbare Aura

  void _paintStage3(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final paint = Paint();

    // Aura (stärker als Stufe 2)
    final auraPulse = 0.5 + 0.5 * sin(animValue * 2 * pi);
    paint
      ..color = _kEnergie.withAlpha((40 + (20 * auraPulse).round()))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 40)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 110, paint);
    paint.maskFilter = null;

    // Silhouette
    paint
      ..color = const Color(0xFF2A2A3E)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 30), width: 80, height: 120),
      paint,
    );
    canvas.drawCircle(Offset(cx, cy - 50), 32, paint);

    // 7 Chakra-Farben entlang der Wirbelsäule (root → crown)
    const List<Color> chakraColors = [
      Color(0xFFE53935), // Wurzel — Rot
      Color(0xFFFF7043), // Sakral — Orange
      Color(0xFFFFEE58), // Solarplexus — Gelb
      Color(0xFF66BB6A), // Herz — Grün
      Color(0xFF42A5F5), // Hals — Blau
      Color(0xFF7E57C2), // Stirn — Indigo
      Color(0xFFCE93D8), // Krone — Violett
    ];

    // Y-Positionen: Wurzel (cy+90) bis Krone (cy-90)
    const double chakraSpacing = 180.0 / 6;
    final List<Offset> chakraPositions = List.generate(
      7,
      (i) => Offset(cx, cy + 90 - i * chakraSpacing),
    );

    // Energielinien zwischen Chakra-Punkten
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < chakraPositions.length - 1; i++) {
      final progress = (animValue + i / chakraPositions.length) % 1.0;
      linePaint.color =
          chakraColors[i].withAlpha((120 + (80 * progress).round()));
      canvas.drawLine(chakraPositions[i], chakraPositions[i + 1], linePaint);
    }

    // Chakra-Punkte
    for (int i = 0; i < chakraPositions.length; i++) {
      final pulse = 0.7 + 0.3 * sin(animValue * 2 * pi + i * pi / 3.5);
      paint
        ..color = chakraColors[i].withAlpha(120)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * pulse);
      canvas.drawCircle(chakraPositions[i], 7 * pulse, paint);
      paint.maskFilter = null;
      paint.color = chakraColors[i];
      canvas.drawCircle(chakraPositions[i], 4, paint);
    }
  }

  // ── Stufe 4: Meister ───────────────────────────────────────────────────
  // Vollständig leuchtend, REBAL-Pulsing-Ring, 3 orbitierende Artefakt-Punkte

  void _paintStage4(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final paint = Paint();

    // Expandierender REBAL-Ring (pulsierend vom Zentrum)
    final ringPhase = animValue;
    for (int ring = 0; ring < 3; ring++) {
      final phase = (ringPhase + ring / 3) % 1.0;
      final ringRadius = 40 + phase * 80;
      final ringAlpha = (1.0 - phase);
      paint
        ..color = _kVorhang.withAlpha((ringAlpha * 120).round())
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(Offset(cx, cy), ringRadius, paint);
    }
    paint
      ..style = PaintingStyle.fill
      ..maskFilter = null;

    // Äußere Aura
    paint
      ..color = _kVorhang.withAlpha(30)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 50);
    canvas.drawCircle(Offset(cx, cy), 120, paint);
    paint.maskFilter = null;

    // Leuchtende Silhouette
    paint
      ..color = const Color(0xFF3A2E50)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 30), width: 80, height: 120),
      paint,
    );
    canvas.drawCircle(Offset(cx, cy - 50), 32, paint);

    // Goldener Glow über Silhouette
    paint
      ..color = _kVorhang.withAlpha(60)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 30), width: 84, height: 124),
      paint,
    );
    canvas.drawCircle(Offset(cx, cy - 50), 34, paint);
    paint.maskFilter = null;

    // 3 orbitierende Artefakt-Punkte
    const List<Color> orbitColors = [_kMaterie, _kEnergie, _kUrsprung];
    for (int i = 0; i < 3; i++) {
      final angle = animValue * 2 * pi + i * (2 * pi / 3);
      const orbitRadius = 100.0;
      final orbitX = cx + orbitRadius * cos(angle);
      final orbitY = cy + orbitRadius * sin(angle) * 0.5; // elliptisch
      paint
        ..color = orbitColors[i].withAlpha(160)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(orbitX, orbitY), 6, paint);
      paint.maskFilter = null;
      paint.color = orbitColors[i];
      canvas.drawCircle(Offset(orbitX, orbitY), 4, paint);
    }
  }

  // ── Stufe 5: Erleuchteter ──────────────────────────────────────────────
  // Torus-Energiefeld, 20 Partikel, Sternfeld-Hintergrund

  void _paintStage5(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final paint = Paint();

    // Sternfeld (statische Punkte aus seeded random)
    final rng = Random(42);
    paint
      ..color = Colors.white
      ..maskFilter = null
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 60; i++) {
      final sx = rng.nextDouble() * size.width;
      final sy = rng.nextDouble() * size.height;
      final sr = rng.nextDouble() * 1.2 + 0.3;
      final starPulse =
          0.4 + 0.6 * (0.5 + 0.5 * sin(animValue * 2 * pi + i * 0.7));
      paint.color = Colors.white.withAlpha((starPulse * 160).round());
      canvas.drawCircle(Offset(sx, sy), sr, paint);
    }

    // Äußere Torus-Ringe (ovale Ellipsen, verschieden geneigt)
    final torusPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const List<double> torusAngles = [0, 30, 60, 90, 120, 150];
    for (int i = 0; i < torusAngles.length; i++) {
      final angle = torusAngles[i] * pi / 180 + animValue * 2 * pi * 0.1;
      final alpha = 0.5 + 0.5 * sin(animValue * 2 * pi + i * pi / 3);
      torusPaint.color = _kUrsprung.withAlpha((80 * alpha).round());
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(angle);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 180, height: 90),
        torusPaint,
      );
      canvas.restore();
    }

    // Innere Aura
    paint
      ..color = _kUrsprung.withAlpha(50)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 40)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 100, paint);
    paint.maskFilter = null;

    // Leuchtende Silhouette (cyan getönt)
    paint
      ..color = const Color(0xFF003344)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 30), width: 80, height: 120),
      paint,
    );
    canvas.drawCircle(Offset(cx, cy - 50), 32, paint);
    paint
      ..color = _kUrsprung.withAlpha(80)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 30), width: 84, height: 124),
      paint,
    );
    canvas.drawCircle(Offset(cx, cy - 50), 34, paint);
    paint.maskFilter = null;

    // 20 Partikel im Orbit
    for (int i = 0; i < 20; i++) {
      // Verschiedene Orbitradien und Geschwindigkeiten
      final orbitR = 90 + (i % 4) * 12.0;
      final speed = 1.0 + (i % 3) * 0.3;
      final angle = animValue * 2 * pi * speed + i * (2 * pi / 20);
      final px = cx + orbitR * cos(angle);
      final py = cy + orbitR * sin(angle) * 0.45; // flacher Orbit
      final particleAlpha = 0.4 + 0.6 * sin(animValue * 2 * pi + i);
      final pColor = i % 4 == 0
          ? _kMaterie
          : i % 4 == 1
              ? _kEnergie
              : i % 4 == 2
                  ? _kVorhang
                  : _kUrsprung;
      paint
        ..color = pColor.withAlpha((particleAlpha * 200).round())
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(px, py), 2.5, paint);
      paint.maskFilter = null;
    }
  }

  @override
  bool shouldRepaint(AvatarPainter oldDelegate) =>
      oldDelegate.animValue != animValue ||
      oldDelegate.stage != stage ||
      oldDelegate.worldBalances != worldBalances;
}

// ═══════════════════════════════════════════════════════════════════════════
// STUFEN-INDIKATOR
// ═══════════════════════════════════════════════════════════════════════════

class _StageIndicator extends StatelessWidget {
  const _StageIndicator({required this.stage, required this.totalXp});

  final int stage;
  final int totalXp;

  @override
  Widget build(BuildContext context) {
    const List<int> stageBoundaries = [0, 500, 1500, 3000, 5000];
    final int nextThreshold =
        stage < 5 ? stageBoundaries[stage] : totalXp; // Stufe 5 = max
    final int prevThreshold = stageBoundaries[stage - 1];
    final double stageProgress = stage < 5
        ? ((totalXp - prevThreshold) / (nextThreshold - prevThreshold))
            .clamp(0.0, 1.0)
        : 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _stageColor(stage).withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _stageColor(stage).withAlpha(120)),
                ),
                child: Text(
                  '$stage',
                  style: TextStyle(
                    color: _stageColor(stage),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stufe $stage — ${_stageName(stage)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '$totalXp XP gesamt',
                    style: TextStyle(
                      color: _kTextMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Fortschrittsbalken zur nächsten Stufe
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: stageProgress,
              minHeight: 6,
              backgroundColor: Colors.white.withAlpha(20),
              valueColor: AlwaysStoppedAnimation<Color>(_stageColor(stage)),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                stage < 5
                    ? 'Nächste Stufe: ${stageBoundaries[stage]} XP'
                    : 'Höchste Stufe erreicht',
                style: TextStyle(color: _kTextMuted, fontSize: 11),
              ),
              if (stage < 5)
                Text(
                  '${nextThreshold - totalXp} XP fehlen',
                  style: TextStyle(color: _kTextMuted, fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static Color _stageColor(int stage) {
    switch (stage) {
      case 1:
        return Colors.grey;
      case 2:
        return _kMaterie;
      case 3:
        return _kEnergie;
      case 4:
        return _kVorhang;
      default:
        return _kUrsprung;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BENUTZERDEFINIERTER TITEL
// ═══════════════════════════════════════════════════════════════════════════

class _CustomTitleField extends StatelessWidget {
  const _CustomTitleField({
    required this.customTitle,
    required this.editing,
    required this.controller,
    required this.onEdit,
    required this.onSave,
    required this.onCancel,
  });

  final String customTitle;
  final bool editing;
  final TextEditingController controller;
  final VoidCallback onEdit;
  final ValueChanged<String> onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Persönlicher Titel',
            style: TextStyle(
                color: _kTextMuted, fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          if (editing)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Dein persönlicher Titel…',
                      hintStyle: TextStyle(color: _kTextMuted, fontSize: 14),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      filled: true,
                      fillColor: Colors.white.withAlpha(10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: _kEnergie.withAlpha(120)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _kEnergie),
                      ),
                    ),
                    onSubmitted: onSave,
                    maxLength: 40,
                    buildCounter: (_,
                            {required currentLength,
                            required isFocused,
                            maxLength}) =>
                        Text(
                      '$currentLength/$maxLength',
                      style: TextStyle(color: _kTextMuted, fontSize: 11),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => onSave(controller.text.trim()),
                  icon: const Icon(Icons.check_rounded, color: _kUrsprung),
                  tooltip: 'Speichern',
                ),
                IconButton(
                  onPressed: onCancel,
                  icon: Icon(Icons.close_rounded, color: _kTextMuted),
                  tooltip: 'Abbrechen',
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: Text(
                    customTitle.isEmpty ? 'Kein Titel gesetzt' : customTitle,
                    style: TextStyle(
                      color: customTitle.isEmpty ? _kTextMuted : Colors.white,
                      fontSize: 15,
                      fontStyle: customTitle.isEmpty
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _kEnergie.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _kEnergie.withAlpha(80)),
                    ),
                    child: const Text(
                      'Bearbeiten',
                      style: TextStyle(color: _kEnergie, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WELTBALANCE-BALKEN
// ═══════════════════════════════════════════════════════════════════════════

class _WorldBalanceBars extends StatelessWidget {
  const _WorldBalanceBars({
    required this.balances,
  });

  final Map<String, double> balances;

  @override
  Widget build(BuildContext context) {
    const List<MapEntry<String, Color>> worlds = [
      MapEntry('materie', _kMaterie),
      MapEntry('energie', _kEnergie),
      MapEntry('vorhang', _kVorhang),
      MapEntry('ursprung', _kUrsprung),
    ];
    const Map<String, String> labels = {
      'materie': 'Materie',
      'energie': 'Energie',
      'vorhang': 'Vorhang',
      'ursprung': 'Ursprung',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weltbalance',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'XP-Verteilung über alle Welten',
            style: TextStyle(color: _kTextMuted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          ...worlds.map((entry) {
            final double value = (balances[entry.key] ?? 0.0).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        labels[entry.key] ?? entry.key,
                        style: TextStyle(
                          color: entry.value,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${(value * 100).round()}%',
                        style: TextStyle(color: _kTextMuted, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 7,
                      backgroundColor: Colors.white.withAlpha(15),
                      valueColor: AlwaysStoppedAnimation<Color>(
                          entry.value.withAlpha(220)),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// AUSGERÜSTETE ARTEFAKTE
// ═══════════════════════════════════════════════════════════════════════════

class _EquippedArtifacts extends StatelessWidget {
  const _EquippedArtifacts({required this.artifacts});

  final List<String> artifacts;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ausgerüstete Artefakte',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          if (artifacts.isEmpty)
            Text(
              'Keine Artefakte ausgerüstet',
              style: TextStyle(
                  color: _kTextMuted,
                  fontSize: 14,
                  fontStyle: FontStyle.italic),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: artifacts
                  .map(
                    (name) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _kVorhang.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _kVorhang.withAlpha(80)),
                      ),
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}
