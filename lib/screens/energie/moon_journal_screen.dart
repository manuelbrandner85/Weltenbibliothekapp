import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

// ──────────────────────────────────────────────────────────────
// Mondtagebuch – Weltenbibliothek Energie-Welt
// Cinema-Stil: Sternenhimmel + astronomisch korrekte Mondphasen
// ──────────────────────────────────────────────────────────────

class MoonJournalScreen extends StatefulWidget {
  const MoonJournalScreen({super.key});

  @override
  State<MoonJournalScreen> createState() => _MoonJournalScreenState();
}

class _MoonJournalScreenState extends State<MoonJournalScreen>
    with TickerProviderStateMixin {
  // ── Animation Controllers ──────────────────────────────────
  late final AnimationController _starCtrl;
  late final AnimationController _moonGlowCtrl;
  late final AnimationController _entryCtrl;

  // ── State ──────────────────────────────────────────────────
  final TextEditingController _noteController = TextEditingController();
  List<_MoonEntry> _entries = [];
  String _selectedMood = '';
  bool _isSaving = false;
  Database? _db;

  // ── Stimmungen ─────────────────────────────────────────────
  static const List<_Mood> _moods = [
    _Mood('😌', 'Ruhig'),
    _Mood('✨', 'Inspiriert'),
    _Mood('💫', 'Träumerisch'),
    _Mood('🌊', 'Emotional'),
    _Mood('🔥', 'Energetisch'),
    _Mood('🌑', 'Dunkel'),
    _Mood('🌟', 'Klar'),
  ];

  static const List<String> _prompts = [
    'Wie fühle ich mich heute?',
    'Was träume ich?',
    'Was lasse ich los?',
  ];

  // ── Farben ─────────────────────────────────────────────────
  static const Color _bg = Color(0xFF06040F);
  static const Color _accent = Color(0xFF9C6FFF);
  static const Color _accentLight = Color(0xFFB99FFF);
  static const Color _teal = Color(0xFF4ECDC4);

  @override
  void initState() {
    super.initState();
    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _moonGlowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _initDb();
  }

  @override
  void dispose() {
    _starCtrl.dispose();
    _moonGlowCtrl.dispose();
    _entryCtrl.dispose();
    _noteController.dispose();
    _db?.close();
    super.dispose();
  }

  // ── SQLite ─────────────────────────────────────────────────
  Future<void> _initDb() async {
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dbPath, 'moon_journal.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE moon_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date_iso TEXT NOT NULL,
            note TEXT NOT NULL,
            mood TEXT,
            moon_phase_pct REAL,
            moon_phase_name TEXT
          )
        ''');
      },
    );
    await _loadEntries();
  }

  Future<void> _loadEntries() async {
    if (_db == null) return;
    final rows = await _db!.query(
      'moon_entries',
      orderBy: 'date_iso DESC',
      limit: 50,
    );
    if (mounted) {
      setState(() {
        _entries = rows.map(_MoonEntry.fromMap).toList();
      });
    }
  }

  Future<void> _saveEntry() async {
    final text = _noteController.text.trim();
    if (text.isEmpty) return;
    if (_db == null) return;

    setState(() => _isSaving = true);
    // ignore: unawaited_futures
    HapticFeedback.lightImpact();

    final now = DateTime.now();
    final phasePct = _getMoonPhaseProgress();
    final phaseName = _getMoonPhaseName(phasePct);

    final id = await _db!.insert('moon_entries', {
      'date_iso': now.toIso8601String(),
      'note': text,
      'mood': _selectedMood,
      'moon_phase_pct': phasePct,
      'moon_phase_name': phaseName,
    });

    final entry = _MoonEntry(
      id: id,
      date: now,
      note: text,
      mood: _selectedMood,
      moonPhasePct: phasePct,
      moonPhaseName: phaseName,
    );

    _noteController.clear();
    if (mounted) {
      setState(() {
        _entries.insert(0, entry);
        _selectedMood = '';
        _isSaving = false;
      });
    }
    // ignore: unawaited_futures
    _entryCtrl.forward(from: 0);
  }

  Future<void> _deleteEntry(int id) async {
    await _db?.delete('moon_entries', where: 'id = ?', whereArgs: [id]);
    if (mounted) {
      setState(() => _entries.removeWhere((e) => e.id == id));
    }
  }

  // ── Mondphasen-Berechnung (Julian Day Number) ──────────────
  double _getMoonPhaseProgress() {
    final now = DateTime.now();
    final a = (14 - now.month) ~/ 12;
    final y = now.year + 4800 - a;
    final m = now.month + 12 * a - 3;
    final jdn = now.day +
        (153 * m + 2) ~/ 5 +
        365 * y +
        y ~/ 4 -
        y ~/ 100 +
        y ~/ 400 -
        32045;
    final jd = jdn.toDouble() +
        (now.hour - 12) / 24.0 +
        now.minute / 1440.0;
    const synodicMonth = 29.53058867;
    const knownNewMoon = 2451550.1; // 6. Januar 2000
    final raw = ((jd - knownNewMoon) % synodicMonth) / synodicMonth;
    return raw < 0 ? raw + 1.0 : raw;
  }

  String _getMoonPhaseName(double pct) {
    if (pct < 0.03 || pct >= 0.97) return 'Neumond';
    if (pct < 0.22) return 'Zunehmende Sichel';
    if (pct < 0.28) return 'Erstes Viertel';
    if (pct < 0.47) return 'Zunehmender Mond';
    if (pct < 0.53) return 'Vollmond';
    if (pct < 0.72) return 'Abnehmender Mond';
    if (pct < 0.78) return 'Letztes Viertel';
    return 'Abnehmende Sichel';
  }

  double _getIllumination(double pct) {
    return 1.0 - (2 * pct - 1).abs();
  }

  DateTime _getNextFullMoon() {
    final now = DateTime.now();
    final pct = _getMoonPhaseProgress();
    const synodicMonth = 29.53058867;
    final daysToFull =
        pct < 0.5 ? (0.5 - pct) * synodicMonth : (1.5 - pct) * synodicMonth;
    return now.add(Duration(hours: (daysToFull * 24).round()));
  }

  DateTime _getNextNewMoon() {
    final now = DateTime.now();
    final pct = _getMoonPhaseProgress();
    const synodicMonth = 29.53058867;
    final daysToNew = (1.0 - pct) * synodicMonth;
    return now.add(Duration(hours: (daysToNew * 24).round()));
  }

  // ── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final phasePct = _getMoonPhaseProgress();
    final phaseName = _getMoonPhaseName(phasePct);
    final illumination = _getIllumination(phasePct);
    final nextFull = _getNextFullMoon();
    final nextNew = _getNextNewMoon();
    final daysToFull = nextFull.difference(DateTime.now()).inDays;
    final daysToNew = nextNew.difference(DateTime.now()).inDays;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // ── Sternenhimmel ──
          AnimatedBuilder(
            animation: _starCtrl,
            builder: (_, __) => CustomPaint(
              painter: _StarfieldPainter(_starCtrl.value),
              size: MediaQuery.of(context).size,
            ),
          ),
          // ── Nebel-Gradient ──
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.4, -0.6),
                  radius: 0.8,
                  colors: [
                    const Color(0xFF3D1D6E).withValues(alpha: 0.3),
                    _bg.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          // ── Haupt-Inhalt ──
          CustomScrollView(
            slivers: [
              _buildAppBar(phasePct),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      _buildMoonVisual(phasePct),
                      const SizedBox(height: 16),
                      _buildPhaseInfo(phaseName, illumination, phasePct,
                          daysToFull, daysToNew),
                      const SizedBox(height: 20),
                      _buildMoodPicker(),
                      const SizedBox(height: 16),
                      _buildJournalInput(),
                      const SizedBox(height: 24),
                      _buildEntriesHeader(),
                    ],
                  ),
                ),
              ),
              _buildEntriesList(),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ],
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────
  SliverAppBar _buildAppBar(double phasePct) {
    return SliverAppBar(
      expandedHeight: 60,
      pinned: true,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white70, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Text(
                      'Mondtagebuch',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    _MiniMoon(phase: phasePct, size: 36),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Mond-Visualisierung ────────────────────────────────────
  Widget _buildMoonVisual(double phasePct) {
    return AnimatedBuilder(
      animation: _moonGlowCtrl,
      builder: (_, __) {
        final glow = 0.6 + 0.4 * _moonGlowCtrl.value;
        return Center(
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _accentLight.withValues(alpha: 0.15 * glow),
                  blurRadius: 40 + 20 * _moonGlowCtrl.value,
                  spreadRadius: 10,
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.05 * glow),
                  blurRadius: 60,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: CustomPaint(
              painter: _MoonPainter(
                phase: phasePct,
                glowIntensity: glow,
              ),
              size: const Size(160, 160),
            ),
          ),
        );
      },
    );
  }

  // ── Phasen-Info ────────────────────────────────────────────
  Widget _buildPhaseInfo(String phaseName, double illumination, double pct,
      int daysToFull, int daysToNew) {
    final daysSinceNew = (pct * 29.53).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Text(
            phaseName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _InfoChip(
                label: 'Beleuchtung',
                value: '${(illumination * 100).round()}%',
                icon: Icons.brightness_high_rounded,
                color: _accentLight,
              ),
              _InfoChip(
                label: 'Seit Neumond',
                value: '${daysSinceNew}d',
                icon: Icons.timelapse_rounded,
                color: _teal,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CountdownTile(
                  label: 'Nächster Vollmond',
                  days: daysToFull,
                  color: const Color(0xFFFFF176),
                  icon: '🌕',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CountdownTile(
                  label: 'Nächster Neumond',
                  days: daysToNew,
                  color: _accentLight,
                  icon: '🌑',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Stimmungs-Picker ───────────────────────────────────────
  Widget _buildMoodPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HEUTIGE STIMMUNG',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _moods.map((mood) {
            final selected = _selectedMood == mood.emoji;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedMood = selected ? '' : mood.emoji;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? _accent.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? _accent.withValues(alpha: 0.7)
                        : Colors.white.withValues(alpha: 0.12),
                    width: selected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(mood.emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text(
                      mood.label,
                      style: TextStyle(
                        color: selected ? _accentLight : Colors.white70,
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Journal-Eingabe ────────────────────────────────────────
  Widget _buildJournalInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MONDREFLEKTION',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _noteController,
            maxLines: 4,
            style:
                const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
            decoration: InputDecoration(
              hintText: 'Schreibe deine Gedanken bei diesem Mondstand...',
              hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            children: _prompts.map((prompt) {
              return GestureDetector(
                onTap: () {
                  _noteController.text = prompt;
                  _noteController.selection = TextSelection.fromPosition(
                    TextPosition(offset: prompt.length),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: _accent.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    prompt,
                    style: TextStyle(
                      color: _accentLight.withValues(alpha: 0.9),
                      fontSize: 11,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveEntry,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent.withValues(alpha: 0.85),
                foregroundColor: Colors.white,
                disabledBackgroundColor: _accent.withValues(alpha: 0.3),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Eintrag speichern',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Eintrags-Header ────────────────────────────────────────
  Widget _buildEntriesHeader() {
    return Row(
      children: [
        const Icon(Icons.auto_stories_rounded, color: _accentLight, size: 18),
        const SizedBox(width: 8),
        Text(
          'Meine Einträge',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${_entries.length}',
            style: const TextStyle(color: _accentLight, fontSize: 13),
          ),
        ),
      ],
    );
  }

  // ── Eintrags-Liste ─────────────────────────────────────────
  Widget _buildEntriesList() {
    if (_entries.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.nights_stay_rounded,
                  color: Colors.white.withValues(alpha: 0.2), size: 48),
              const SizedBox(height: 12),
              Text(
                'Noch keine Einträge vorhanden',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Beginne dein Mondtagebuch oben',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.2),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          final entry = _entries[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: _EntryCard(
              entry: entry,
              onDelete: () => _deleteEntry(entry.id),
            ),
          );
        },
        childCount: _entries.length,
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Datenmodelle
// ──────────────────────────────────────────────────────────────

class _Mood {
  final String emoji;
  final String label;
  const _Mood(this.emoji, this.label);
}

class _MoonEntry {
  final int id;
  final DateTime date;
  final String note;
  final String mood;
  final double moonPhasePct;
  final String moonPhaseName;

  const _MoonEntry({
    required this.id,
    required this.date,
    required this.note,
    required this.mood,
    required this.moonPhasePct,
    required this.moonPhaseName,
  });

  factory _MoonEntry.fromMap(Map<String, dynamic> map) {
    return _MoonEntry(
      id: map['id'] as int,
      date: DateTime.parse(map['date_iso'] as String),
      note: map['note'] as String,
      mood: (map['mood'] as String?) ?? '',
      moonPhasePct: (map['moon_phase_pct'] as num?)?.toDouble() ?? 0.0,
      moonPhaseName: (map['moon_phase_name'] as String?) ?? '',
    );
  }
}

// ──────────────────────────────────────────────────────────────
// CustomPainter: Sternenhimmel
// ──────────────────────────────────────────────────────────────

class _StarfieldPainter extends CustomPainter {
  final double animValue;

  static final List<_Star> _stars = _generateStars();

  static List<_Star> _generateStars() {
    final rng = math.Random(42);
    return List.generate(200, (_) {
      return _Star(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: 0.5 + rng.nextDouble() * 2.0,
        phase: rng.nextDouble() * 2 * math.pi,
        speed: 0.3 + rng.nextDouble() * 0.7,
      );
    });
  }

  const _StarfieldPainter(this.animValue);

  @override
  void paint(Canvas canvas, Size size) {
    // Milchstraßen-Schimmer
    final milkyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.025),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.2, 0.5, 0.8],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), milkyPaint);

    for (final star in _stars) {
      final twinkle = 0.3 +
          0.7 *
              (0.5 +
                  0.5 *
                      math.sin(animValue * 2 * math.pi * star.speed +
                          star.phase));
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: twinkle);
      if (star.size > 1.5) {
        paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8);
      }
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarfieldPainter old) => old.animValue != animValue;
}

class _Star {
  final double x, y, size, phase, speed;
  const _Star(
      {required this.x,
      required this.y,
      required this.size,
      required this.phase,
      required this.speed});
}

// ──────────────────────────────────────────────────────────────
// CustomPainter: Mond
// ──────────────────────────────────────────────────────────────

class _MoonPainter extends CustomPainter {
  final double phase; // 0..1, 0=Neumond, 0.5=Vollmond
  final double glowIntensity;

  const _MoonPainter({required this.phase, this.glowIntensity = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 8;

    _drawCraters(canvas, cx, cy, r);

    final moonPaint = Paint()
      ..color = const Color(0xFFE8E0F0)
      ..style = PaintingStyle.fill;

    final clipPath = Path()
      ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));

    canvas.save();
    canvas.clipPath(clipPath);
    canvas.drawCircle(Offset(cx, cy), r, moonPaint);

    final shadowPaint = Paint()
      ..color = const Color(0xFF06040F)
      ..style = PaintingStyle.fill;

    if (phase < 0.5) {
      final t = phase / 0.5; // 0..1
      if (t < 0.5) {
        // Neumond → erstes Viertel: linke Hälfte + ovale Überlagerung rechts
        canvas.drawRect(
            Rect.fromLTWH(cx - r, cy - r, r, r * 2), shadowPaint);
        _drawShadowEllipse(
            canvas, cx, cy, r, (1.0 - t * 2), left: false, paint: shadowPaint);
      } else {
        // Erstes Viertel → Vollmond: Ellipse verschwindet rechts
        _drawShadowEllipse(
            canvas, cx, cy, r, (t * 2 - 1.0), left: true, paint: shadowPaint);
      }
    } else {
      final t = (phase - 0.5) / 0.5; // 0..1
      if (t < 0.5) {
        // Vollmond → letztes Viertel: rechte Hälfte wird dunkel
        canvas.drawRect(Rect.fromLTWH(cx, cy - r, r, r * 2), shadowPaint);
        _drawShadowEllipse(
            canvas, cx, cy, r, (1.0 - t * 2), left: true, paint: shadowPaint);
      } else {
        // Letztes Viertel → Neumond
        canvas.drawRect(Rect.fromLTWH(cx, cy - r, r, r * 2), shadowPaint);
        _drawShadowEllipse(
            canvas, cx, cy, r, (t * 2 - 1.0), left: false, paint: shadowPaint);
      }
    }

    canvas.restore();

    // Glow-Ring
    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06 * glowIntensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(cx, cy), r + 6, ringPaint);
  }

  void _drawShadowEllipse(Canvas canvas, double cx, double cy, double r,
      double scaleX, {required bool left, required Paint paint}) {
    canvas.save();
    canvas.translate(cx, cy);
    if (left) canvas.scale(-1.0, 1.0);
    canvas.scale(scaleX.clamp(0.0, 1.0), 1.0);
    canvas.drawOval(
        Rect.fromCircle(center: Offset.zero, radius: r), paint);
    canvas.restore();
  }

  void _drawCraters(Canvas canvas, double cx, double cy, double r) {
    final craterPaint = Paint()
      ..color = const Color(0xFFD0C8E0).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    const craterDefs = [
      [0.25, 0.2, 0.06],
      [-0.3, -0.1, 0.08],
      [0.1, -0.35, 0.05],
      [-0.15, 0.3, 0.07],
      [0.35, -0.25, 0.04],
    ];
    for (final c in craterDefs) {
      canvas.drawCircle(
          Offset(cx + c[0] * r, cy + c[1] * r), c[2] * r * 2, craterPaint);
    }
  }

  @override
  bool shouldRepaint(_MoonPainter old) =>
      old.phase != phase || old.glowIntensity != glowIntensity;
}

// ──────────────────────────────────────────────────────────────
// Hilfs-Widgets
// ──────────────────────────────────────────────────────────────

class _MiniMoon extends StatelessWidget {
  final double phase;
  final double size;

  const _MiniMoon({required this.phase, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MoonPainter(phase: phase),
        size: Size(size, size),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _CountdownTile extends StatelessWidget {
  final String label;
  final int days;
  final Color color;
  final String icon;

  const _CountdownTile({
    required this.label,
    required this.days,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  days == 0 ? 'Heute!' : 'in ${days}d',
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final _MoonEntry entry;
  final VoidCallback onDelete;

  const _EntryCard({required this.entry, required this.onDelete});

  static const List<String> _months = [
    'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
    'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez',
  ];

  String _formatDate(DateTime dt) {
    return '${dt.day}. ${_months[dt.month - 1]} ${dt.year}';
  }

  String _phaseIcon(double pct) {
    if (pct < 0.06 || pct >= 0.94) return '🌑';
    if (pct < 0.25) return '🌒';
    if (pct < 0.35) return '🌓';
    if (pct < 0.48) return '🌔';
    if (pct < 0.55) return '🌕';
    if (pct < 0.72) return '🌖';
    if (pct < 0.82) return '🌗';
    return '🌘';
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF9C6FFF);
    const accentLight = Color(0xFFB99FFF);

    return Dismissible(
      key: Key('entry_${entry.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.redAccent, size: 24),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.12),
                border:
                    Border.all(color: accent.withValues(alpha: 0.2)),
              ),
              child: Text(_phaseIcon(entry.moonPhasePct),
                  style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _formatDate(entry.date),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                      if (entry.mood.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(entry.mood,
                            style: const TextStyle(fontSize: 14)),
                      ],
                      const Spacer(),
                      Text(
                        entry.moonPhaseName,
                        style: TextStyle(
                          color: accentLight.withValues(alpha: 0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    entry.note,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.45,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
