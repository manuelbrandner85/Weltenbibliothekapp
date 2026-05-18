import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart'
    if (dart.library.html) '../../stubs/sqflite_stub.dart';
import 'package:path/path.dart' as p;

import '../theme/wb_cinematic_tokens.dart';
// ──────────────────────────────────────────────────────────────
// Astrales Tagebuch – Weltenbibliothek Energie-Welt
// Cinema-Stil: Kosmisches Void, Nebel-Orbs, Sternenfeld
// ──────────────────────────────────────────────────────────────

class AstralJournalScreen extends StatefulWidget {
  const AstralJournalScreen({super.key});

  @override
  State<AstralJournalScreen> createState() => _AstralJournalScreenState();
}

class _AstralJournalScreenState extends State<AstralJournalScreen>
    with TickerProviderStateMixin {
  // ── AnimationController ────────────────────────────────────
  late final AnimationController _nebulaCtrl;
  late final AnimationController _starCtrl;
  late final AnimationController _entryFadeCtrl;
  late final TabController _tabCtrl;

  // ── State ──────────────────────────────────────────────────
  List<_AstralEntry> _entries = [];
  bool _isLoading = false;
  bool _showAddForm = false;
  Database? _db;

  // Formular-State
  final TextEditingController _descCtrl = TextEditingController();
  int _quality = 3;
  int _durationMin = 20;
  double _vividness = 0.5;
  double _control = 0.5;
  String _selectedTechnique = '';
  final Set<String> _selectedTags = {};

  // ── Farben ─────────────────────────────────────────────────
  static const Color _bgDark = Color(0xFF06040F);

  /// Theme-aware background. Light-Mode liefert helle `context.wb.bgVoid`,
  /// Dark-Mode behält den Original-Ton.
  Color _bg(BuildContext context) {
    final wb = Theme.of(context).extension<WBCinematic>();
    return wb?.bgVoid ?? _bgDark;
  }
  static const Color _purple = Color(0xFF9C6FFF);
  static const Color _purpleLight = Color(0xFFB99FFF);
  static const Color _teal = Color(0xFF4ECDC4);
  static const Color _pink = Color(0xFFFF6B9D);

  // ── Besonderheiten-Tags ────────────────────────────────────
  static const List<String> _tags = [
    'Fliegen', 'Tunnel', 'Licht', 'Geräusche', 'Vibration',
    'Schlaflähmung', 'Spiegelwelt', 'Begegnung', 'Zeitreise',
    'Healing', 'Botschaft', 'Architektur',
  ];

  // ── Techniken ──────────────────────────────────────────────
  static const List<_AstralTechnique> _techniques = [
    _AstralTechnique(
      name: 'Wake-Back-To-Bed (WBTB)',
      icon: '⏰',
      difficulty: 2,
      description:
          'Nach 5–6h Schlaf aufwachen, 30–60 min wach bleiben, dann wieder einschlafen. '
          'Erhöht REM-Schlaf-Intensität erheblich.',
      steps: ['Um 4–5 Uhr wecken', '30 Min lesen oder meditieren',
          'Bewusst mit Intention einschlafen', 'WILD oder MILD kombinieren'],
      color: Color(0xFF7C4DFF),
    ),
    _AstralTechnique(
      name: 'Monroe-Technik',
      icon: '🌀',
      difficulty: 3,
      description:
          'Robert Monroe\'s klassische Methode: Entspannung → hypnagoge Halluzinationen '
          'nutzen → bewusst in Schlaflähmung übergehen.',
      steps: ['Tiefe Entspannung in 10 Atemzügen', 'Hypnagoge Bilder beobachten',
          'Vibrationszustand einleiten', 'Aus dem Körper rollen oder gleiten'],
      color: Color(0xFF651FFF),
    ),
    _AstralTechnique(
      name: 'WILD – Wake-Initiated',
      icon: '🔮',
      difficulty: 4,
      description:
          'Wake Initiated Lucid Dream: Bewusstsein direkt vom Wachzustand in Traum '
          'übertragen, ohne Bewusstlosigkeit.',
      steps: ['Schlafparalyse bewusst herbeiführen', 'HI/Hypnagoge Bilder beobachten',
          'Traumbild stabilisieren', 'Körper verlassen oder in Traum eintreten'],
      color: Color(0xFF4A148C),
    ),
    _AstralTechnique(
      name: 'Rope-Technik',
      icon: '🪢',
      difficulty: 2,
      description:
          'Stell dir ein Seil vor, das von der Decke hängt. Klettere imaginär daran '
          'hinauf, bis du den Körper verlässt.',
      steps: ['Tief entspannen', 'Imaginäres Seil über dir visualisieren',
          'Hände geistig ausstrecken', 'Langsam am Seil hinaufklettern'],
      color: Color(0xFF9C27B0),
    ),
    _AstralTechnique(
      name: 'Silva-Methode',
      icon: '🧘',
      difficulty: 2,
      description:
          'José Silva\'s Alphazustand-Methode: Tiefe Entspannung auf Alpha-Ebene '
          '(7–14 Hz) mit Visualisierungstechniken.',
      steps: ['Countdown 10 → 1 zur Entspannung', 'Visualisiere einen sicheren Ort',
          'Bewusstsein ausdehnen', 'Führe die AP-Intention ein'],
      color: Color(0xFF3F51B5),
    ),
    _AstralTechnique(
      name: 'Hypnagogischer Trance',
      icon: '💤',
      difficulty: 3,
      description:
          'Den hypnagogen Schlaf-Wach-Übergang bewusst verlängern und nutzen. '
          'Idealer Einstiegspunkt für OBEs.',
      steps: ['Arm leicht angewinkelt halten (Wächtermethode)', 'Einschlafphase bewusst beobachten',
          'Bei Arm-Fallen sofort Bewusstsein fokussieren', 'In Traumbilder einsteigen'],
      color: Color(0xFF1A237E),
    ),
    _AstralTechnique(
      name: 'Traumzeichen-Methode',
      icon: '🔍',
      difficulty: 1,
      description:
          'Persönliche Traumzeichen (Realitätschecks) im Wachleben üben, '
          'damit sie im Traum zum Lucidity-Trigger werden.',
      steps: ['10x täglich Realitätschecks durchführen', 'Traumtagebuch führen',
          'Persönliche Traumzeichen identifizieren', 'Im Traum auf Zeichen achten'],
      color: Color(0xFF006064),
    ),
    _AstralTechnique(
      name: 'Phänomenologie',
      icon: '🌌',
      difficulty: 5,
      description:
          'Fortgeschrittene Methode: Vollständige Losgelöstheit von Körpergefühl '
          'durch Bewusstseinsverschiebung in der Tiefenmeditation.',
      steps: ['Mindestens 30 Min Meditation vorher', 'Körpergefühl schrittweise loslassen',
          'Bewusstsein als Punkt im Raum visualisieren', 'Expansion des Bewusstseinsfeldes'],
      color: Color(0xFF4A148C),
    ),
  ];

  // ── Symbole ─────────────────────────────────────────────────
  static const List<_AstralSymbol> _symbols = [
    _AstralSymbol('Tunnel / Portal', '🌀', 'Übergang zwischen Bewusstseinsebenen, Transformation, Schwellenzustand'),
    _AstralSymbol('Weißes Licht', '✨', 'Göttliche Präsenz, Reinigung, höhere Führung, Erleuchtung'),
    _AstralSymbol('Doppelgänger', '👤', 'Aspekte des Selbst, Schattenarbeit, Integration'),
    _AstralSymbol('Fliegen', '🕊️', 'Freiheit, spirituelle Erhebung, Überwindung von Grenzen'),
    _AstralSymbol('Silberne Schnur', '🧶', 'Verbindung zum physischen Körper, Lebensenergie, Schutz'),
    _AstralSymbol('Spiegel', '🪞', 'Selbsterkenntnis, parallele Realitäten, Reflexion des Selbst'),
    _AstralSymbol('Verstorbene', '🕯️', 'Botschaften aus dem Jenseits, Heilung, Abschluss'),
    _AstralSymbol('Kristalle', '💎', 'Energie-Anker, Schutz, Informationsspeicher'),
    _AstralSymbol('Bibliothek', '📚', 'Akashische Aufzeichnungen, Wissen, Aktualisierung des Bewusstseins'),
    _AstralSymbol('Ozean', '🌊', 'Kollektives Unbewusstes, emotionale Tiefe, Urenergie'),
    _AstralSymbol('Tempelbau', '🏛️', 'Heilige Orte, spirituelle Ausbildung, innere Führung'),
    _AstralSymbol('Sternenfeld', '🌌', 'Kosmisches Bewusstsein, Unendlichkeit, Verbindung zum All'),
  ];

  @override
  void initState() {
    super.initState();
    _nebulaCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _entryFadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _tabCtrl = TabController(length: 3, vsync: this);

    _initDb();
  }

  @override
  void dispose() {
    _nebulaCtrl.dispose();
    _starCtrl.dispose();
    _entryFadeCtrl.dispose();
    _tabCtrl.dispose();
    _descCtrl.dispose();
    _db?.close();
    super.dispose();
  }

  // ── SQLite ─────────────────────────────────────────────────
  Future<void> _initDb() async {
    setState(() => _isLoading = true);
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dbPath, 'astral_journal.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE astral_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date_iso TEXT NOT NULL,
            duration_min INTEGER,
            quality INTEGER,
            description TEXT,
            technique TEXT,
            vividness REAL,
            control REAL,
            tags TEXT
          )
        ''');
      },
    );
    await _loadEntries();
  }

  Future<void> _loadEntries() async {
    if (_db == null) return;
    final rows = await _db!.query(
      'astral_entries',
      orderBy: 'date_iso DESC',
      limit: 50,
    );
    if (mounted) {
      setState(() {
        _entries = rows.map(_AstralEntry.fromMap).toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveEntry() async {
    final desc = _descCtrl.text.trim();
    if (desc.isEmpty) return;
    if (_db == null) return;

    // ignore: unawaited_futures
    HapticFeedback.lightImpact();
    final now = DateTime.now();

    final id = await _db!.insert('astral_entries', {
      'date_iso': now.toIso8601String(),
      'duration_min': _durationMin,
      'quality': _quality,
      'description': desc,
      'technique': _selectedTechnique,
      'vividness': _vividness,
      'control': _control,
      'tags': _selectedTags.join(','),
    });

    final entry = _AstralEntry(
      id: id,
      date: now,
      durationMin: _durationMin,
      quality: _quality,
      description: desc,
      technique: _selectedTechnique,
      vividness: _vividness,
      control: _control,
      tags: _selectedTags.toList(),
    );

    _descCtrl.clear();
    if (mounted) {
      setState(() {
        _entries.insert(0, entry);
        _showAddForm = false;
        _quality = 3;
        _durationMin = 20;
        _vividness = 0.5;
        _control = 0.5;
        _selectedTechnique = '';
        _selectedTags.clear();
      });
    }
    // ignore: unawaited_futures
    _entryFadeCtrl.forward(from: 0);
  }

  Future<void> _deleteEntry(int id) async {
    await _db?.delete('astral_entries', where: 'id = ?', whereArgs: [id]);
    if (mounted) {
      setState(() => _entries.removeWhere((e) => e.id == id));
    }
  }

  // ── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg(context),
      body: Stack(
        children: [
          // ── Sternenhimmel ──
          AnimatedBuilder(
            animation: _starCtrl,
            builder: (_, __) => CustomPaint(
              painter: _AstralStarfieldPainter(_starCtrl.value),
              size: MediaQuery.of(context).size,
            ),
          ),
          // ── Nebula-Orbs ──
          AnimatedBuilder(
            animation: _nebulaCtrl,
            builder: (_, __) => _buildNebulaOrbs(context),
          ),
          // ── Haupt-Inhalt ──
          Column(
            children: [
              _buildAppBar(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _buildExperiencesTab(),
                    _buildTechniquesTab(),
                    _buildSymbolsTab(),
                  ],
                ),
              ),
            ],
          ),
          // ── Add-Button ──
          Positioned(
            right: 16,
            bottom: 24,
            child: _buildFAB(),
          ),
        ],
      ),
    );
  }

  // ── Nebula-Orbs ────────────────────────────────────────────
  Widget _buildNebulaOrbs(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final angle = _nebulaCtrl.value * 2 * math.pi;

    return Stack(
      children: [
        // Lila Orb oben rechts
        Positioned(
          right: -60 + 30 * math.cos(angle),
          top: -40 + 30 * math.sin(angle),
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF7C4DFF).withValues(alpha: 0.25),
                  const Color(0xFF7C4DFF).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        // Türkis Orb unten links
        Positioned(
          left: -80 + 20 * math.cos(angle + math.pi * 0.66),
          bottom: size.height * 0.2 + 20 * math.sin(angle + math.pi * 0.66),
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF4ECDC4).withValues(alpha: 0.18),
                  const Color(0xFF4ECDC4).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        // Pink Orb mittig
        Positioned(
          left: size.width * 0.3 + 25 * math.cos(angle + math.pi * 1.33),
          top: size.height * 0.5 + 25 * math.sin(angle + math.pi * 1.33),
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFF6B9D).withValues(alpha: 0.12),
                  const Color(0xFFFF6B9D).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── AppBar ─────────────────────────────────────────────────
  Widget _buildAppBar() {
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white70, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Text(
                    'Astrales Tagebuch',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _purple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: _purple.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${_entries.length} OBEs',
                      style: const TextStyle(
                        color: _purpleLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── TabBar ─────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: Colors.black.withValues(alpha: 0.3),
      child: TabBar(
        controller: _tabCtrl,
        indicatorColor: _purple,
        indicatorWeight: 2,
        labelColor: _purpleLight,
        unselectedLabelColor: Colors.white38,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Erfahrungen'),
          Tab(text: 'Techniken'),
          Tab(text: 'Symbole'),
        ],
      ),
    );
  }

  // ── Tab 1: Erfahrungen ─────────────────────────────────────
  Widget _buildExperiencesTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _purple),
      );
    }

    if (_showAddForm) {
      return _buildAddForm();
    }

    if (_entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.travel_explore_rounded,
                color: Colors.white.withValues(alpha: 0.2), size: 56),
            const SizedBox(height: 16),
            Text(
              'Noch keine Erfahrungen',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tippe auf + um deine erste OBE zu dokumentieren',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.25),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: _entries.length,
      itemBuilder: (context, i) {
        return _AstralEntryCard(
          entry: _entries[i],
          onDelete: () => _deleteEntry(_entries[i].id),
        );
      },
    );
  }

  // ── Formular ───────────────────────────────────────────────
  Widget _buildAddForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'Neue OBE-Erfahrung',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() => _showAddForm = false),
                child: Text('Abbrechen',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Beschreibung
          _buildFormCard(
            label: 'ERFAHRUNG',
            child: TextField(
              controller: _descCtrl,
              maxLines: 4,
              style: const TextStyle(
                  color: Colors.white, fontSize: 14, height: 1.5),
              decoration: InputDecoration(
                hintText: 'Beschreibe deine außerkörperliche Erfahrung...',
                hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Dauer + Qualität
          Row(
            children: [
              Expanded(
                child: _buildFormCard(
                  label: 'DAUER',
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_rounded,
                            color: Colors.white54, size: 20),
                        onPressed: () => setState(
                            () => _durationMin = math.max(1, _durationMin - 5)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$_durationMin Min',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add_rounded,
                            color: Colors.white54, size: 20),
                        onPressed: () =>
                            setState(() => _durationMin += 5),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFormCard(
                  label: 'QUALITÄT',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final filled = i < _quality;
                      return GestureDetector(
                        onTap: () => setState(() => _quality = i + 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Icon(
                            filled ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: filled ? const Color(0xFFFFD700) : Colors.white30,
                            size: 22,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Lebhaftigkeit + Kontrolle
          _buildFormCard(
            label: 'LEBHAFTIGKEIT',
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Verschwommen',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
                    Text('Kristallklar',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
                  ],
                ),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: _purple,
                    inactiveTrackColor: _purple.withValues(alpha: 0.2),
                    thumbColor: _purpleLight,
                    overlayColor: _purple.withValues(alpha: 0.15),
                  ),
                  child: Slider(
                    value: _vividness,
                    onChanged: (v) => setState(() => _vividness = v),
                    min: 0,
                    max: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildFormCard(
            label: 'KONTROLLE',
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Keine',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
                    Text('Vollständig',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
                  ],
                ),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: _teal,
                    inactiveTrackColor: _teal.withValues(alpha: 0.2),
                    thumbColor: _teal,
                    overlayColor: _teal.withValues(alpha: 0.15),
                  ),
                  child: Slider(
                    value: _control,
                    onChanged: (v) => setState(() => _control = v),
                    min: 0,
                    max: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Technik auswählen
          _buildFormCard(
            label: 'VERWENDETE TECHNIK',
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _techniques.map((t) {
                final sel = _selectedTechnique == t.name;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedTechnique = sel ? '' : t.name;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: sel
                          ? t.color.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: sel
                            ? t.color.withValues(alpha: 0.7)
                            : Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(t.icon, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(
                          t.name.split(' ').first,
                          style: TextStyle(
                            color: sel ? Colors.white : Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          // Besonderheiten-Tags
          _buildFormCard(
            label: 'BESONDERHEITEN',
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _tags.map((tag) {
                final sel = _selectedTags.contains(tag);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (sel) {
                      _selectedTags.remove(tag);
                    } else {
                      _selectedTags.add(tag);
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: sel
                          ? _pink.withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: sel
                            ? _pink.withValues(alpha: 0.6)
                            : Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: sel ? Colors.white : Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveEntry,
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple.withValues(alpha: 0.85),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Erfahrung speichern',
                style:
                    TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard({required String label, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  // ── Tab 2: Techniken ───────────────────────────────────────
  Widget _buildTechniquesTab() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: _techniques.length,
      itemBuilder: (context, i) => _TechniqueCard(technique: _techniques[i]),
    );
  }

  // ── Tab 3: Symbole ─────────────────────────────────────────
  Widget _buildSymbolsTab() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.9,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _symbols.length,
      itemBuilder: (context, i) => _SymbolCard(symbol: _symbols[i]),
    );
  }

  // ── FAB ────────────────────────────────────────────────────
  Widget _buildFAB() {
    if (_tabCtrl.index != 0 || _showAddForm) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _showAddForm = true);
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF9C6FFF), Color(0xFF651FFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _purple.withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Datenmodelle
// ──────────────────────────────────────────────────────────────

class _AstralEntry {
  final int id;
  final DateTime date;
  final int durationMin;
  final int quality;
  final String description;
  final String technique;
  final double vividness;
  final double control;
  final List<String> tags;

  const _AstralEntry({
    required this.id,
    required this.date,
    required this.durationMin,
    required this.quality,
    required this.description,
    required this.technique,
    required this.vividness,
    required this.control,
    required this.tags,
  });

  factory _AstralEntry.fromMap(Map<String, dynamic> map) {
    final tagsStr = (map['tags'] as String?) ?? '';
    return _AstralEntry(
      id: map['id'] as int,
      date: DateTime.parse(map['date_iso'] as String),
      durationMin: (map['duration_min'] as int?) ?? 0,
      quality: (map['quality'] as int?) ?? 3,
      description: (map['description'] as String?) ?? '',
      technique: (map['technique'] as String?) ?? '',
      vividness: (map['vividness'] as num?)?.toDouble() ?? 0.5,
      control: (map['control'] as num?)?.toDouble() ?? 0.5,
      tags: tagsStr.isEmpty ? [] : tagsStr.split(','),
    );
  }
}

class _AstralTechnique {
  final String name;
  final String icon;
  final int difficulty;
  final String description;
  final List<String> steps;
  final Color color;

  const _AstralTechnique({
    required this.name,
    required this.icon,
    required this.difficulty,
    required this.description,
    required this.steps,
    required this.color,
  });
}

class _AstralSymbol {
  final String name;
  final String icon;
  final String meaning;
  const _AstralSymbol(this.name, this.icon, this.meaning);
}

// ──────────────────────────────────────────────────────────────
// CustomPainter: Astral-Sternenhimmel
// ──────────────────────────────────────────────────────────────

class _AstralStarfieldPainter extends CustomPainter {
  final double animValue;
  static final List<_Star2> _stars = _generateStars();

  static List<_Star2> _generateStars() {
    final rng = math.Random(99);
    return List.generate(150, (_) {
      return _Star2(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: 0.4 + rng.nextDouble() * 1.8,
        phase: rng.nextDouble() * 2 * math.pi,
        speed: 0.2 + rng.nextDouble() * 0.8,
      );
    });
  }

  const _AstralStarfieldPainter(this.animValue);

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in _stars) {
      final twinkle = 0.2 +
          0.8 *
              (0.5 +
                  0.5 *
                      math.sin(animValue * 2 * math.pi * star.speed +
                          star.phase));
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: twinkle * 0.9);
      if (star.size > 1.2) {
        paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0);
      }
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_AstralStarfieldPainter old) =>
      old.animValue != animValue;
}

class _Star2 {
  final double x, y, size, phase, speed;
  const _Star2(
      {required this.x,
      required this.y,
      required this.size,
      required this.phase,
      required this.speed});
}

// ──────────────────────────────────────────────────────────────
// Hilfs-Widgets
// ──────────────────────────────────────────────────────────────

class _AstralEntryCard extends StatelessWidget {
  final _AstralEntry entry;
  final VoidCallback onDelete;

  const _AstralEntryCard({required this.entry, required this.onDelete});

  static const List<String> _months = [
    'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
    'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez',
  ];

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF9C6FFF);
    const purpleLight = Color(0xFFB99FFF);

    return Dismissible(
      key: Key('astral_${entry.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.redAccent, size: 22),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: purple.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: purple.withValues(alpha: 0.06),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header-Zeile
            Row(
              children: [
                const Text('🌌', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.date.day}. ${_months[entry.date.month - 1]} ${entry.date.year}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                    if (entry.technique.isNotEmpty)
                      Text(
                        entry.technique,
                        style: const TextStyle(
                          color: purpleLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                // Sterne-Rating
                Row(
                  children: List.generate(5, (i) => Icon(
                    i < entry.quality
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: i < entry.quality
                        ? const Color(0xFFFFD700)
                        : Colors.white24,
                    size: 16,
                  )),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: purple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${entry.durationMin} Min',
                    style: TextStyle(
                      color: purpleLight.withValues(alpha: 0.9),
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Beschreibung
            Text(
              entry.description,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.45,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            // Slider-Balken
            if (entry.vividness > 0 || entry.control > 0) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  _MiniBar(
                    label: 'Lebhaftigkeit',
                    value: entry.vividness,
                    color: purple,
                  ),
                  const SizedBox(width: 12),
                  _MiniBar(
                    label: 'Kontrolle',
                    value: entry.control,
                    color: const Color(0xFF4ECDC4),
                  ),
                ],
              ),
            ],
            // Tags
            if (entry.tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: entry.tags
                    .map((t) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B9D)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFFFF6B9D)
                                    .withValues(alpha: 0.25)),
                          ),
                          child: Text(t,
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 10)),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _MiniBar(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4), fontSize: 10)),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

class _TechniqueCard extends StatefulWidget {
  final _AstralTechnique technique;

  const _TechniqueCard({required this.technique});

  @override
  State<_TechniqueCard> createState() => _TechniqueCardState();
}

class _TechniqueCardState extends State<_TechniqueCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.technique;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _expanded = !_expanded);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: t.color.withValues(alpha: 0.15),
                    border: Border.all(color: t.color.withValues(alpha: 0.3)),
                  ),
                  child: Text(t.icon, style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Schwierigkeit: ',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 11,
                            ),
                          ),
                          ...List.generate(
                            5,
                            (i) => Icon(
                              i < t.difficulty
                                  ? Icons.circle
                                  : Icons.circle_outlined,
                              color: i < t.difficulty
                                  ? t.color
                                  : t.color.withValues(alpha: 0.3),
                              size: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: Colors.white38,
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'SCHRITTE',
                      style: TextStyle(
                        color: t.color,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...t.steps.asMap().entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: t.color.withValues(alpha: 0.2),
                                ),
                                child: Text(
                                  '${e.key + 1}',
                                  style: TextStyle(
                                    color: t.color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  e.value,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.65),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      ),
    );
  }
}

class _SymbolCard extends StatelessWidget {
  final _AstralSymbol symbol;

  const _SymbolCard({required this.symbol});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFF9C6FFF).withValues(alpha: 0.2)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF9C6FFF).withValues(alpha: 0.05),
            const Color(0xFF06040F).withValues(alpha: 0.0),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(symbol.icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            symbol.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            symbol.meaning,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
