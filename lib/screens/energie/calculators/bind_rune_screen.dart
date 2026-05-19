// Bind-Rune-Generator: 2-3 Runen ueber gemeinsamem Stav kombinieren.
// Bereich D1 -- vereinfachte CustomPainter-Variante, die jede gewaehlte
// Rune zentral ueberlagert (gleicher Stav-Punkt), ohne komplexe Linien-
// Union-Algorithmen.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/spirit_reading_service.dart';
import '../../../services/streak_tracking_service.dart';
import '../../../core/storage/unified_storage_service.dart';
import '../../../widgets/cinematic/wb_ambient_particles.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/cinematic/wb_vignette.dart';
import '../../../theme/wb_cinematic_tokens.dart';

class _BindRune {
  final String glyph;
  final String name;
  final String shortPower;
  const _BindRune(this.glyph, this.name, this.shortPower);
}

const List<_BindRune> _runes = [
  _BindRune('ᚠ', 'Fehu', 'Reichtum'),
  _BindRune('ᚢ', 'Uruz', 'Urkraft'),
  _BindRune('ᚦ', 'Thurisaz', 'Schutz'),
  _BindRune('ᚨ', 'Ansuz', 'Inspiration'),
  _BindRune('ᚱ', 'Raidho', 'Reise'),
  _BindRune('ᚲ', 'Kenaz', 'Erkenntnis'),
  _BindRune('ᚷ', 'Gebo', 'Gabe'),
  _BindRune('ᚹ', 'Wunjo', 'Freude'),
  _BindRune('ᚺ', 'Hagalaz', 'Wandlung'),
  _BindRune('ᚾ', 'Nauthiz', 'Geduld'),
  _BindRune('ᛁ', 'Isa', 'Stillstand'),
  _BindRune('ᛃ', 'Jera', 'Ernte'),
  _BindRune('ᛇ', 'Eihwaz', 'Transformation'),
  _BindRune('ᛈ', 'Perthro', 'Schicksal'),
  _BindRune('ᛉ', 'Algiz', 'Schutz'),
  _BindRune('ᛊ', 'Sowilo', 'Sieg'),
  _BindRune('ᛏ', 'Tiwaz', 'Mut'),
  _BindRune('ᛒ', 'Berkano', 'Wachstum'),
  _BindRune('ᛖ', 'Ehwaz', 'Bewegung'),
  _BindRune('ᛗ', 'Mannaz', 'Selbst'),
  _BindRune('ᛚ', 'Laguz', 'Intuition'),
  _BindRune('ᛜ', 'Ingwaz', 'Reife'),
  _BindRune('ᛞ', 'Dagaz', 'Erwachen'),
  _BindRune('ᛟ', 'Othala', 'Heimat'),
];

class BindRuneScreen extends StatefulWidget {
  const BindRuneScreen({super.key});

  @override
  State<BindRuneScreen> createState() => _BindRuneScreenState();
}

class _BindRuneScreenState extends State<BindRuneScreen> {
  final Set<int> _selected = {}; // Indices in _runes
  final _intentionCtrl = TextEditingController();
  static const _gold = Color(0xFFC9A84C);
  static const _bg = Color(0xFF030610);

  @override
  void initState() {
    super.initState();
    StreakTrackingService().trackToolUsage('bind_rune');
  }

  @override
  void dispose() {
    _intentionCtrl.dispose();
    super.dispose();
  }

  void _toggle(int i) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selected.contains(i)) {
        _selected.remove(i);
      } else if (_selected.length < 3) {
        _selected.add(i);
      } else {
        // Wenn schon 3 ausgewaehlt: ersetze aelteste durch neue.
        final first = _selected.first;
        _selected.remove(first);
        _selected.add(i);
      }
    });
  }

  Future<void> _save() async {
    if (_selected.length < 2) return;
    HapticFeedback.mediumImpact();
    final runes = _selected.map((i) => _runes[i]).toList();
    final glyphs = runes.map((r) => r.glyph).join('');
    final names = runes.map((r) => r.name).join(' · ');
    final intention = _intentionCtrl.text.trim();
    final username = UnifiedStorageService().getUsername('energie');
    final userId =
        await UnifiedStorageService().getCurrentUserId() ?? 'anonym';
    final saved = await SpiritReadingService.instance.save(
      userId: userId,
      username: username,
      tool: 'bind_rune',
      summary: '🪬 Bind-Rune $glyphs · $names'
          '${intention.isEmpty ? '' : ' (Intention: $intention)'}',
      result: {
        'runes': runes.map((r) => r.name).toList(),
        'glyphs': glyphs,
        'intention': intention,
      },
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(saved != null
          ? '🪬 Bind-Rune gespeichert'
          : 'Speichern fehlgeschlagen'),
      backgroundColor: _gold,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected.map((i) => _runes[i]).toList();
    return Scaffold(
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      appBar: const WBGlassAppBar(
        title: 'Bind-Rune',
        world: WBWorld.energie,
      ),
      body: Stack(
        children: [
          const IgnorePointer(
            child: WBAmbientParticles(world: WBWorld.energie, count: 24),
          ),
          const WBVignette(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 64, 20, 24),
              child: Column(
                children: [
                  _previewCard(selected),
                  const SizedBox(height: 14),
                  _intentionField(),
                  const SizedBox(height: 14),
                  _gridLabel(),
                  const SizedBox(height: 8),
                  _runeGrid(),
                  const SizedBox(height: 16),
                  _saveButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewCard(List<_BindRune> selected) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E1B2C), Color(0xFF1B2C3F)],
        ),
        border: Border.all(color: _gold.withValues(alpha: 0.4), width: 1.4),
        boxShadow: [
          BoxShadow(
              color: _gold.withValues(alpha: 0.25),
              blurRadius: 28,
              offset: const Offset(0, 8)),
        ],
      ),
      child: selected.isEmpty
          ? const Center(
              child: Text(
                'Waehle 2-3 Runen aus dem Raster unten.',
                style: TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            )
          : Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size.infinite,
                  painter: _BindRunePainter(selected: selected),
                ),
                Positioned(
                  bottom: 12,
                  left: 16,
                  right: 16,
                  child: Center(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      alignment: WrapAlignment.center,
                      children: selected
                          .map((r) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _gold.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: _gold.withValues(alpha: 0.5)),
                                ),
                                child: Text('${r.glyph} ${r.name}',
                                    style: const TextStyle(
                                        color: _gold,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700)),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _intentionField() {
    return TextField(
      controller: _intentionCtrl,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      maxLength: 80,
      decoration: InputDecoration(
        hintText: 'Intention (optional, z.B. "Schutz auf Reisen")',
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        counterStyle: const TextStyle(color: Colors.white38, fontSize: 10),
      ),
    );
  }

  Widget _gridLabel() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        '24 RUNEN · ${_selected.length}/3 gewaehlt',
        style: const TextStyle(
            color: Color(0xFFC9A84C),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2),
      ),
    );
  }

  Widget _runeGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 0.9,
      ),
      itemCount: _runes.length,
      itemBuilder: (_, i) {
        final r = _runes[i];
        final sel = _selected.contains(i);
        return GestureDetector(
          onTap: () => _toggle(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: sel
                  ? _gold.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: sel ? _gold : Colors.white.withValues(alpha: 0.12),
                width: sel ? 1.6 : 1,
              ),
              boxShadow: sel
                  ? [
                      BoxShadow(
                        color: _gold.withValues(alpha: 0.35),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(r.glyph,
                    style: TextStyle(
                        fontSize: 22,
                        color: sel ? _gold : Colors.white70,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(r.name,
                    style: TextStyle(
                        fontSize: 8.5,
                        color: sel ? Colors.white : Colors.white54,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _saveButton() {
    final ok = _selected.length >= 2;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: ok ? _save : null,
        icon: const Icon(Icons.save_alt_rounded),
        label: const Text('Bind-Rune speichern'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _gold,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1),
        ),
      ),
    );
  }
}

/// Vereinfachter Bind-Rune-Painter:
/// - Gemeinsamer vertikaler Stav (Mittellinie) in Gold.
/// - Alle gewaehlten Runen werden als TextPainter zentral ueber dem Stav
///   gerendert mit Glow-Effekt und leichter Versetzung horizontal.
/// Echte Vektor-Union waere ein eigenes Projekt -- diese Variante liefert
/// das Bind-Rune-Gefuehl ohne 24x Geometrie-Tabellen.
class _BindRunePainter extends CustomPainter {
  final List<_BindRune> selected;
  _BindRunePainter({required this.selected});

  static const _gold = Color(0xFFC9A84C);

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final topY = size.height * 0.18;
    final bottomY = size.height * 0.72;

    // Stav (Mittellinie)
    final stavPaint = Paint()
      ..color = _gold.withValues(alpha: 0.85)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    final stavGlow = Paint()
      ..color = _gold.withValues(alpha: 0.35)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawLine(
        Offset(centerX, topY), Offset(centerX, bottomY), stavGlow);
    canvas.drawLine(
        Offset(centerX, topY), Offset(centerX, bottomY), stavPaint);

    // Runen ueberlagert auf dem Stav -- groesster TextPainter, semi-trans.
    for (int i = 0; i < selected.length; i++) {
      final r = selected[i];
      // Leichte horizontale Versetzung damit man die einzelnen Glyphen
      // noch unterscheiden kann, ohne dass es zerfaellt.
      final offsetX = (i - (selected.length - 1) / 2) * 6.0;
      final opacity = 0.85 - i * 0.15;
      final tp = TextPainter(
        text: TextSpan(
          text: r.glyph,
          style: TextStyle(
            fontSize: 130,
            color: Colors.white.withValues(alpha: opacity.clamp(0.3, 1.0)),
            fontWeight: FontWeight.w700,
            shadows: [
              Shadow(color: _gold.withValues(alpha: 0.7), blurRadius: 18),
              Shadow(color: _gold.withValues(alpha: 0.35), blurRadius: 40),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(centerX + offsetX - tp.width / 2,
            (topY + bottomY) / 2 - tp.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(_BindRunePainter old) =>
      old.selected.length != selected.length ||
      !_listEquals(old.selected, selected);

  bool _listEquals(List<_BindRune> a, List<_BindRune> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].name != b[i].name) return false;
    }
    return true;
  }
}
