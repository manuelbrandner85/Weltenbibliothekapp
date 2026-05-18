// SYMBOL DES TAGES - 1-Tap deterministic daily symbol reveal.
//
// Picks 1 of 12 sacred-geometry symbols per (date + userId) hash. No AI call.
// Class name kept (LichtspracheDecoderScreen) for easter_egg_sheet.dart import.

import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/wb_cinematic_tokens.dart';
import '../../widgets/cinematic/wb_ambient_particles.dart';
import '../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../widgets/cinematic/wb_vignette.dart';

// ---------------------------------------------------------------------------
// Symbol data
// ---------------------------------------------------------------------------

class _DailySymbol {
  final String glyph;
  final String name;
  final String meaning;
  final String impulse;
  const _DailySymbol(this.glyph, this.name, this.meaning, this.impulse);
}

const List<_DailySymbol> _kSymbols = <_DailySymbol>[
  _DailySymbol(
    '☉',
    'Sonne',
    'Bewusstsein und Selbst.',
    'Sei heute sichtbar. Zeig wer du bist.',
  ),
  _DailySymbol(
    '☽',
    'Mond',
    'Intuition und Innenwelt.',
    'Hoer auf deinen Bauch. Achte auf Traeume.',
  ),
  _DailySymbol(
    '△',
    'Dreieck',
    'Aufstieg und Manifestation.',
    'Setze heute einen klaren Schritt.',
  ),
  _DailySymbol(
    '◯',
    'Kreis',
    'Ganzheit und ewiger Kreislauf.',
    'Schliesse heute etwas ab was offen war.',
  ),
  _DailySymbol(
    '✦',
    'Stern',
    'Hoffnung und Orientierung.',
    'Vertraue dem naechsten richtigen Schritt.',
  ),
  _DailySymbol(
    '❀',
    'Lebensblume',
    'Verbundenheit allen Lebens.',
    'Begegne heute jemandem mit offenem Herzen.',
  ),
  _DailySymbol(
    '☯',
    'Yin-Yang',
    'Polaritaet und Balance.',
    'Halte heute beides aus -- Licht und Schatten.',
  ),
  _DailySymbol(
    '♾',
    'Unendlichkeit',
    'Ewiger Fluss.',
    'Was du gibst, kehrt zurueck. Sei grosszuegig.',
  ),
  _DailySymbol(
    '⚡',
    'Blitz',
    'Erkenntnis und Durchbruch.',
    'Eine Wahrheit will heute durch dich hindurch.',
  ),
  _DailySymbol(
    '🔯',
    'Hexagramm',
    'Vereinigung Himmel-Erde.',
    'Bring dein Wesen mit deinem Tun in Einklang.',
  ),
  _DailySymbol(
    '✶',
    'Vesica Piscis',
    'Begegnung der Welten.',
    'Heute kreuzen sich Wege. Sei aufmerksam.',
  ),
  _DailySymbol(
    '✸',
    'Sigil',
    'Manifestation und Wille.',
    'Eine klare Absicht reicht heute aus.',
  ),
];

// ---------------------------------------------------------------------------
// History entry
// ---------------------------------------------------------------------------

class _HistoryEntry {
  final String date; // yyyy-mm-dd
  final int symbolIndex;
  const _HistoryEntry(this.date, this.symbolIndex);

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'date': date, 'symbolIndex': symbolIndex};

  static _HistoryEntry? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final date = raw['date'];
    final idx = raw['symbolIndex'];
    if (date is! String || idx is! int) return null;
    if (idx < 0 || idx >= _kSymbols.length) return null;
    return _HistoryEntry(date, idx);
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class LichtspracheDecoderScreen extends StatefulWidget {
  const LichtspracheDecoderScreen({super.key});

  @override
  State<LichtspracheDecoderScreen> createState() =>
      _LichtspracheDecoderScreenState();
}

class _LichtspracheDecoderScreenState extends State<LichtspracheDecoderScreen>
    with TickerProviderStateMixin {
  static const Color _bg = Color(0xFF0A0414);
  static const Color _gold = Color(0xFFFFD700);
  static const Color _primary = Color(0xFF7C4DFF);
  static const String _prefsKey = 'daily_symbol_history_v1';
  static const int _maxHistory = 30;

  late final AnimationController _ambientCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _revealCtrl;
  late final Animation<double> _revealOpacity;
  late final Animation<double> _revealScale;

  late final String _todayKey;
  late final int _todayIndex;
  bool _revealed = false;
  List<_HistoryEntry> _history = <_HistoryEntry>[];

  @override
  void initState() {
    super.initState();
    _ambientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _revealOpacity = CurvedAnimation(
      parent: _revealCtrl,
      curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
    );
    _revealScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _revealCtrl, curve: Curves.easeOutBack),
    );

    final now = DateTime.now();
    _todayKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final userId = _safeUserId();
    final seed = _todayKey.hashCode + (userId?.hashCode ?? 0);
    _todayIndex = seed.abs() % _kSymbols.length;

    _loadHistory();
  }

  String? _safeUserId() {
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final entries = <_HistoryEntry>[];
      for (final item in decoded) {
        final e = _HistoryEntry.fromJson(item);
        if (e != null) entries.add(e);
      }
      if (!mounted) return;
      setState(() {
        _history = entries;
        // If today's entry already exists, auto-reveal so the user can see it.
        if (entries.any((e) => e.date == _todayKey)) {
          _revealed = true;
          _revealCtrl.value = 1.0;
        }
      });
    } catch (_) {
      // Ignore corrupt prefs.
    }
  }

  Future<void> _persistHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Keep newest first, cap at _maxHistory.
      final trimmed = _history.take(_maxHistory).toList();
      final encoded = jsonEncode(trimmed.map((e) => e.toJson()).toList());
      await prefs.setString(_prefsKey, encoded);
    } catch (_) {
      // Ignore persist errors silently.
    }
  }

  void _addTodayToHistory() {
    if (_history.any((e) => e.date == _todayKey)) return;
    final updated = <_HistoryEntry>[
      _HistoryEntry(_todayKey, _todayIndex),
      ..._history,
    ];
    if (updated.length > _maxHistory) {
      updated.removeRange(_maxHistory, updated.length);
    }
    setState(() => _history = updated);
    _persistHistory();
  }

  void _reveal() {
    HapticFeedback.mediumImpact();
    setState(() => _revealed = true);
    _revealCtrl.forward(from: 0.0);
    _addTodayToHistory();
  }

  void _saveSnack() {
    HapticFeedback.lightImpact();
    _addTodayToHistory();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Symbol im Verlauf gespeichert.'),
        backgroundColor: _primary.withValues(alpha: 0.85),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openHistorySheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _HistorySheet(history: _history.take(14).toList()),
    );
  }

  @override
  void dispose() {
    _ambientCtrl.dispose();
    _pulseCtrl.dispose();
    _revealCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final symbol = _kSymbols[_todayIndex];

    return Scaffold(
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      appBar: WBGlassAppBar(
        world: WBWorld.neutral,
        titleWidget: ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            colors: <Color>[_gold, _primary],
          ).createShader(r),
          child: const Text(
            'SYMBOL DES TAGES',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // Backdrop gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: <Color>[
                  Color(0x553F1E8C),
                  Color(0x331A0833),
                  _bg,
                ],
              ),
            ),
          ),
          // Orbs
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _ambientCtrl,
              builder: (_, __) => CustomPaint(
                painter: _LsOrbsPainter(_ambientCtrl.value),
                size: Size.infinite,
              ),
            ),
          ),
          const IgnorePointer(
            child: WBAmbientParticles(world: WBWorld.neutral, count: 50),
          ),
          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: _revealed
                  ? _buildRevealed(symbol)
                  : _buildInitial(),
            ),
          ),
          const IgnorePointer(child: WBVignette()),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // States
  // -------------------------------------------------------------------------

  Widget _buildInitial() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) {
              final t = _pulseCtrl.value;
              final radius = 90.0 + t * 18.0;
              final alpha = 0.18 + t * 0.18;
              return Container(
                width: radius * 2,
                height: radius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: <Color>[
                      _gold.withValues(alpha: alpha),
                      _primary.withValues(alpha: alpha * 0.5),
                      Colors.transparent,
                    ],
                    stops: const <double>[0.0, 0.55, 1.0],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: _gold,
                    size: 48,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 28),
          const Text(
            'Heute hat das Universum',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(
            'ein Zeichen fuer dich.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),
          ElevatedButton.icon(
            onPressed: _reveal,
            icon: const Icon(Icons.visibility_rounded),
            label: const Text(
              'SYMBOL ENTHUELLEN',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.6,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 6,
              shadowColor: _primary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Fuer heute, $_todayKey',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 12,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 28),
          if (_history.isNotEmpty)
            TextButton.icon(
              onPressed: _openHistorySheet,
              icon: const Icon(Icons.history_rounded, color: Colors.white70),
              label: const Text(
                'Mein Verlauf',
                style: TextStyle(color: Colors.white70, letterSpacing: 0.8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRevealed(_DailySymbol symbol) {
    return FadeTransition(
      opacity: _revealOpacity,
      child: ScaleTransition(
        scale: _revealScale,
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(height: 12),
                Text(
                  _todayKey,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 18),
                // Glow halo behind symbol
                SizedBox(
                  width: 240,
                  height: 240,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (_, __) {
                          final t = _pulseCtrl.value;
                          return Container(
                            width: 200 + t * 24,
                            height: 200 + t * 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: <Color>[
                                  _gold.withValues(alpha: 0.35 + t * 0.15),
                                  _primary.withValues(alpha: 0.18),
                                  Colors.transparent,
                                ],
                                stops: const <double>[0.0, 0.55, 1.0],
                              ),
                            ),
                          );
                        },
                      ),
                      Text(
                        symbol.glyph,
                        style: TextStyle(
                          fontSize: 128,
                          color: _gold,
                          height: 1.0,
                          shadows: <Shadow>[
                            Shadow(
                              color: _gold.withValues(alpha: 0.85),
                              blurRadius: 28,
                            ),
                            Shadow(
                              color: _primary.withValues(alpha: 0.5),
                              blurRadius: 48,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  symbol.name.toUpperCase(),
                  style: const TextStyle(
                    color: _gold,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    symbol.meaning,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _gold.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    children: <Widget>[
                      const Text(
                        'TAGESIMPULS',
                        style: TextStyle(
                          color: _gold,
                          fontSize: 10,
                          letterSpacing: 2.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        symbol.impulse,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 14,
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    ElevatedButton.icon(
                      onPressed: _saveSnack,
                      icon: const Icon(Icons.bookmark_added_rounded, size: 18),
                      label: const Text(
                        'Speichern',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _openHistorySheet,
                      icon: const Icon(Icons.history_rounded, size: 18),
                      label: const Text(
                        'Verlauf',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _gold,
                        side: BorderSide(
                          color: _gold.withValues(alpha: 0.6),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Morgen erscheint ein neues Symbol.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// History bottom sheet
// ---------------------------------------------------------------------------

class _HistorySheet extends StatelessWidget {
  final List<_HistoryEntry> history;
  const _HistorySheet({required this.history});

  static const Color _gold = Color(0xFFFFD700);
  static const Color _primary = Color(0xFF7C4DFF);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A0414).withValues(alpha: 0.92),
            border: Border(
              top: BorderSide(color: _gold.withValues(alpha: 0.3)),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'MEIN VERLAUF',
                style: TextStyle(
                  color: _gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Letzte 14 Symbole.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 14),
              if (history.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Noch kein Symbol gespeichert.',
                      style: TextStyle(color: Colors.white60),
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.55,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: history.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final entry = history[i];
                      final s = _kSymbols[entry.symbolIndex];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            SizedBox(
                              width: 44,
                              child: Text(
                                s.glyph,
                                style: TextStyle(
                                  fontSize: 28,
                                  color: _gold,
                                  shadows: <Shadow>[
                                    Shadow(
                                      color: _gold.withValues(alpha: 0.6),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    s.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    entry.date,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.55,
                                      ),
                                      fontSize: 11,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text(
                    'Schliessen',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Background orbs painter
// ---------------------------------------------------------------------------

class _LsOrbsPainter extends CustomPainter {
  final double t;
  _LsOrbsPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    _draw(
      canvas,
      Offset(
        size.width * 0.2,
        size.height * (0.3 + math.sin(t * 2 * math.pi) * 0.05),
      ),
      110,
      const Color(0xFFFFD700),
    );
    _draw(
      canvas,
      Offset(
        size.width * 0.85,
        size.height * (0.6 + math.cos(t * 2 * math.pi) * 0.04),
      ),
      100,
      const Color(0xFF7C4DFF),
    );
  }

  void _draw(Canvas c, Offset o, double r, Color col) {
    c.drawCircle(
      o,
      r,
      Paint()
        ..color = col.withValues(alpha: 0.1)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.5),
    );
  }

  @override
  bool shouldRepaint(_LsOrbsPainter o) => o.t != t;
}
