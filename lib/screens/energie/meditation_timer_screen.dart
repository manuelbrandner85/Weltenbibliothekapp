import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:sqflite/sqflite.dart'
    if (dart.library.html) '../../stubs/sqflite_stub.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// Datenbank-Helfer
// ---------------------------------------------------------------------------

class _MeditationDb {
  static Database? _db;

  static Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, 'meditation.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (d, _) async {
        await d.execute('''
          CREATE TABLE IF NOT EXISTS meditation_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            meditation_id TEXT,
            title TEXT,
            duration_min INTEGER,
            completed_at TEXT,
            is_personal INTEGER DEFAULT 0
          )
        ''');
        await d.execute('''
          CREATE TABLE IF NOT EXISTS personal_meditations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            duration_min INTEGER,
            breath_pattern TEXT,
            intention TEXT,
            color_hex TEXT,
            created_at TEXT
          )
        ''');
      },
    );
  }

  static Future<void> insertSession({
    required String meditationId,
    required String title,
    required int durationMin,
    required bool isPersonal,
  }) async {
    final d = await db;
    await d.insert('meditation_sessions', {
      'meditation_id': meditationId,
      'title': title,
      'duration_min': durationMin,
      'completed_at': DateTime.now().toIso8601String(),
      'is_personal': isPersonal ? 1 : 0,
    });
  }

  static Future<List<Map<String, dynamic>>> getSessions() async {
    final d = await db;
    return d.query('meditation_sessions', orderBy: 'completed_at DESC');
  }

  static Future<void> insertPersonal(Map<String, dynamic> m) async {
    final d = await db;
    await d.insert('personal_meditations', m);
  }

  static Future<List<Map<String, dynamic>>> getPersonal() async {
    final d = await db;
    return d.query('personal_meditations', orderBy: 'created_at DESC');
  }

  static Future<void> deletePersonal(int id) async {
    final d = await db;
    await d.delete('personal_meditations', where: 'id = ?', whereArgs: [id]);
  }
}

// ---------------------------------------------------------------------------
// Meditations-Daten (statisch, immer in der App)
// ---------------------------------------------------------------------------

class _MeditationData {
  final String id;
  final String title;
  final String subtitle;
  final int durationMin;
  final String category;
  final Color color;
  final IconData icon;
  final String description;
  final List<String> benefits;
  final String breathPattern;
  final List<String> steps;

  const _MeditationData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.durationMin,
    required this.category,
    required this.color,
    required this.icon,
    required this.description,
    required this.benefits,
    required this.breathPattern,
    required this.steps,
  });
}

const List<_MeditationData> _kMeditations = [
  _MeditationData(
    id: 'atem',
    title: 'Atemmeditation',
    subtitle: 'Ankommen im Moment',
    durationMin: 10,
    category: 'Anfänger',
    color: Color(0xFF26C6DA),
    icon: Icons.air,
    description:
        'Richte deine Aufmerksamkeit sanft auf deinen Atem. Beobachte das Ein- und Ausströmen ohne es zu verändern.',
    benefits: ['Stressreduktion', 'Klarheit', 'Erdung'],
    breathPattern: '4-4-4-4',
    steps: [
      'Setze oder lege dich bequem hin. Schließe sanft die Augen.',
      'Beobachte deinen natürlichen Atem — ohne ihn zu verändern.',
      'Atme 4 Sekunden ein, halte 4 Sekunden, atme 4 Sekunden aus, warte 4 Sekunden.',
      'Wenn der Geist wandert, bringe ihn sanft zurück zum Atem.',
      'Erkenne jeden Gedanken wie eine Wolke am Himmel — er kommt und geht.',
      'In den letzten 2 Minuten: weite das Bewusstsein auf den gesamten Körper aus.',
    ],
  ),
  _MeditationData(
    id: 'body_scan',
    title: 'Body Scan',
    subtitle: 'Reise durch deinen Körper',
    durationMin: 20,
    category: 'Anfänger',
    color: Color(0xFF66BB6A),
    icon: Icons.accessibility_new,
    description:
        'Wandere aufmerksam durch jeden Teil deines Körpers und lass Anspannungen los.',
    benefits: ['Körperbewusstsein', 'Entspannung', 'Schlafqualität'],
    breathPattern: '4-7-8',
    steps: [
      'Lege dich auf den Rücken, Arme leicht vom Körper entfernt.',
      'Schließe die Augen. Atme dreimal tief ein und aus.',
      'Bringe die Aufmerksamkeit zu den Zehen des linken Fußes.',
      'Wandere langsam aufwärts: Fuß, Knöchel, Unterschenkel, Knie...',
      'Linkes Bein, dann rechtes Bein, Becken, Bauch, Brust...',
      'Arme, Hände, Schultern, Hals, Gesicht, Scheitel.',
      'Spüre den gesamten Körper als leuchtende Einheit.',
    ],
  ),
  _MeditationData(
    id: 'loving_kindness',
    title: 'Loving Kindness (Metta)',
    subtitle: 'Mitgefühl kultivieren',
    durationMin: 15,
    category: 'Anfänger',
    color: Color(0xFFEC407A),
    icon: Icons.favorite,
    description:
        'Kultiviere bedingungslose Liebe und Mitgefühl für dich und alle Wesen.',
    benefits: ['Mitgefühl', 'Soziale Verbindung', 'Selbstliebe'],
    breathPattern: '4-4-6',
    steps: [
      'Setze dich aufrecht hin. Lege eine Hand aufs Herz.',
      'Rufe ein Bild von dir selbst auf — wie du jetzt gerade bist.',
      'Wiederhole innerlich: Möge ich glücklich sein. Möge ich gesund sein. Möge ich frei sein.',
      'Weite das Gefühl auf jemanden aus, den du liebst.',
      'Dann auf neutrale Personen in deinem Leben.',
      'Dann auf alle Wesen auf der Welt — ohne Ausnahme.',
      'Kehre zum Herzen zurück. Spüre die Wärme.',
    ],
  ),
  _MeditationData(
    id: 'chakra',
    title: 'Chakra-Meditation',
    subtitle: 'Energiezentren harmonisieren',
    durationMin: 25,
    category: 'Fortgeschritten',
    color: Color(0xFF9C27B0),
    icon: Icons.spa,
    description:
        'Harmonisiere alle sieben Chakren durch Visualisierung und Mantras.',
    benefits: ['Energiebalance', 'Chakra-Heilung', 'Spirituelles Wachstum'],
    breathPattern: '4-4-8',
    steps: [
      'Setze dich in Lotussitz oder auf einem Stuhl mit geradem Rücken.',
      'Wurzelchakra (Rot): Visualisiere rotes Licht am Steißbein. Summe LAM.',
      'Sakralchakra (Orange): Orangefarbenes Licht im Unterbauch. Summe VAM.',
      'Solarplexus (Gelb): Goldenes Licht im Magenbereich. Summe RAM.',
      'Herzchakra (Grün): Strahlendes Grün im Herzen. Summe YAM.',
      'Kehlchakra (Blau): Himmelsblaues Licht im Hals. Summe HAM.',
      'Stirnchakra (Indigo): Indigofarbenes Licht zwischen den Augen. Summe OM.',
      'Kronenchakra (Violett): Weißviolettes Licht am Scheitel. Stille.',
    ],
  ),
  _MeditationData(
    id: 'mantra',
    title: 'Mantra-Meditation',
    subtitle: 'Kraft der heiligen Klänge',
    durationMin: 20,
    category: 'Spirituell',
    color: Color(0xFFFFD54F),
    icon: Icons.music_note,
    description:
        'Nutze die Schwingungskraft heiliger Klänge um den Geist zu zentrieren.',
    benefits: ['Fokus', 'Vibrationshebung', 'Stille des Geistes'],
    breathPattern: '4-0-8',
    steps: [
      'Wähle ein Mantra: OM, So Hum, Aham Brahmasmi, oder ein persönliches.',
      'Setze dich bequem. Schließe die Augen.',
      'Atme tief ein. Beim Ausatmen summe innerlich das Mantra.',
      'Lass das Mantra von selbst entstehen — ohne es zu erzwingen.',
      'Wenn Gedanken kommen: Kehre sanft zum Mantra zurück.',
      'Nach 15 Minuten: Lasse das Mantra los. Sitze in der Stille.',
      'Spüre die Vibration im gesamten Körper.',
    ],
  ),
  _MeditationData(
    id: 'visualization',
    title: 'Visualisierungs-Meditation',
    subtitle: 'Die Kraft innerer Bilder',
    durationMin: 20,
    category: 'Fortgeschritten',
    color: Color(0xFF26A69A),
    icon: Icons.visibility,
    description:
        'Nutze die Kraft deiner Vorstellungskraft zur inneren Heilung und Manifestation.',
    benefits: ['Kreativität', 'Manifestation', 'Innere Heilung'],
    breathPattern: '4-4-8',
    steps: [
      'Lege dich hin oder sitze bequem. Schließe die Augen.',
      'Atme dreimal tief durch. Entspanne jeden Muskel.',
      'Visualisiere einen heilenden goldenen Lichtstrahl von oben.',
      'Das Licht füllt deinen Körper von Kopf bis Fuß.',
      'Stelle dir vor, wie Blockaden als graue Wolken ausatmen.',
      'Visualisiere dich in deinem Herzens-Ort — einem sicheren inneren Raum.',
      'Bleibe dort. Empfange Botschaften. Sei offen.',
    ],
  ),
  _MeditationData(
    id: 'moonlight',
    title: 'Mondlicht-Meditation',
    subtitle: 'Mit der Mondenergie fließen',
    durationMin: 15,
    category: 'Spirituell',
    color: Color(0xFFB0BEC5),
    icon: Icons.nightlight_round,
    description:
        'Verbinde dich mit der heiligen Mondenergie für emotionale Reinigung und Intuition.',
    benefits: ['Intuition', 'Weibliche Energie', 'Emotionale Reinigung'],
    breathPattern: '4-4-6',
    steps: [
      'Wenn möglich, setze dich im Mondlicht oder stelle dir es vor.',
      'Schließe die Augen. Spüre das sanfte Silberlicht auf deiner Haut.',
      'Visualisiere, wie das Mondlicht in dein Kronenchakra einströmt.',
      'Das silberne Licht reinigt dein Energiefeld von allem Alten.',
      'Atme Mondlicht ein — Dunkelheit und Schwere aus.',
      'Spreche innerlich: Ich bin im Fluss. Ich vertraue dem Zyklus des Lebens.',
      'Ruhe in der sanften Mondenergie.',
    ],
  ),
  _MeditationData(
    id: 'grounding',
    title: 'Erdungs-Meditation',
    subtitle: 'Wurzeln in der Erde',
    durationMin: 10,
    category: 'Anfänger',
    color: Color(0xFF8D6E63),
    icon: Icons.landscape,
    description:
        'Verankere dich tief in der Erde und finde Sicherheit und Stabilität.',
    benefits: ['Erdung', 'Sicherheit', 'Stabilität'],
    breathPattern: '4-2-6',
    steps: [
      'Stelle beide Füße fest auf den Boden. Sitz oder steh.',
      'Schließe die Augen. Spüre das Gewicht deines Körpers.',
      'Stelle dir Wurzeln vor, die von deinen Füßen in die Erde wachsen.',
      'Die Wurzeln reichen tief — durch Gestein, Wasser, bis zum Erdkern.',
      'Atme Erdenergie auf — braun, stabil, nährend.',
      'Du bist verankert. Du bist sicher. Du gehörst hierher.',
      'Öffne langsam die Augen. Spüre den festen Kontakt mit dem Boden.',
    ],
  ),
  _MeditationData(
    id: 'wim_hof',
    title: 'Wim-Hof-Atmung',
    subtitle: 'Atemtechnik für Energie',
    durationMin: 15,
    category: 'Fortgeschritten',
    color: Color(0xFF42A5F5),
    icon: Icons.air,
    description:
        'Aktiviere dein Immunsystem und steigere deine Energie durch kontrollierte Hyperventilation.',
    benefits: ['Energie', 'Immunsystem', 'Mentale Stärke'],
    breathPattern: '0-0-0',
    steps: [
      'Lege dich auf den Rücken. Atme entspannt.',
      'Runde 1: 30x schnelle tiefe Atemzüge (Nase rein, Mund raus).',
      'Nach dem 30. Ausatmen: Halten. So lange wie möglich.',
      'Wenn nötig: Tief einatmen, 15 Sekunden halten, ausatmen.',
      'Runde 2 und 3 wiederholen.',
      'Nach den Runden: In der Stille sitzen. Körper spüren.',
      'VORSICHT: Nicht im Wasser oder beim Autofahren.',
    ],
  ),
  _MeditationData(
    id: 'healing',
    title: 'Heilungs-Meditation',
    subtitle: 'Selbstheilungskräfte aktivieren',
    durationMin: 25,
    category: 'Heilung',
    color: Color(0xFF81C784),
    icon: Icons.healing,
    description:
        'Aktiviere die natürlichen Selbstheilungskräfte deines Körpers durch heilendes Licht.',
    benefits: ['Selbstheilung', 'Schmerzlinderung', 'Regeneration'],
    breathPattern: '4-4-8',
    steps: [
      'Lege dich bequem hin. Atme dreimal tief ein.',
      'Stelle dir ein strahlendes goldgrünes Licht über dir vor.',
      'Beim Einatmen: Dieses Heilungslicht fließt in deinen Körper.',
      'Richte das Licht zu einem Bereich der Heilung bedarf.',
      'Stelle dir vor, wie jede Zelle von diesem Licht durchdrungen wird.',
      'Sprich innerlich: Mein Körper weiß, wie er heilt. Ich gebe die Erlaubnis.',
      'Bleibe 15 Minuten in diesem Heilungsraum. Danke dem Licht.',
    ],
  ),
  _MeditationData(
    id: 'third_eye',
    title: 'Drittes Auge Öffnen',
    subtitle: 'Intuition und Wahrnehmung',
    durationMin: 20,
    category: 'Spirituell',
    color: Color(0xFF7C4DFF),
    icon: Icons.remove_red_eye,
    description:
        'Öffne dein drittes Auge für höhere Wahrnehmung und spirituelle Intuition.',
    benefits: ['Intuition', 'Hellsehen', 'Spirituelle Wahrnehmung'],
    breathPattern: '4-6-8',
    steps: [
      'Setze dich in aufrechter Haltung. Schließe die Augen.',
      'Fokussiere die Aufmerksamkeit auf den Punkt zwischen den Augenbrauen.',
      'Stelle dir dort eine indigo-violette Kugel leuchtenden Lichts vor.',
      'Mit jedem Atemzug wird die Kugel heller und größer.',
      'Summe innerlich: OM oder AUM.',
      'Empfange Bilder, Gefühle oder Eindrücke ohne sie zu bewerten.',
      'Diese Bilder sind Botschaften deines höheren Selbst.',
    ],
  ),
  _MeditationData(
    id: 'silent',
    title: 'Stille-Meditation',
    subtitle: 'Im Nichts ruhen',
    durationMin: 30,
    category: 'Fortgeschritten',
    color: Color(0xFF78909C),
    icon: Icons.do_not_disturb,
    description:
        'Die reinste Form der Meditation — einfach sitzen und beobachten was ist.',
    benefits: ['Tiefe Stille', 'Bewusstsein', 'Erleuchtung'],
    breathPattern: '0-0-0',
    steps: [
      'Setze dich still. Keine Technik. Keine Erwartung.',
      'Beobachte einfach, was ist.',
      'Gedanken kommen — lass sie gehen.',
      'Gefühle kommen — lass sie gehen.',
      'Du bist nicht deine Gedanken. Du bist der Beobachter.',
      'In der Stille zwischen den Gedanken: das bist du.',
      'Bleibe einfach hier. Anwesend.',
    ],
  ),
];

const List<String> _kCategories = [
  'Alle',
  'Anfänger',
  'Fortgeschritten',
  'Heilung',
  'Spirituell',
];

// ---------------------------------------------------------------------------
// Hilfsfunktionen Atemphase
// ---------------------------------------------------------------------------

List<int> _parseBreathPattern(String pattern) {
  if (pattern == '0-0-0') return [4, 0, 6, 0];
  final parts = pattern.split('-').map(int.tryParse).toList();
  if (parts.length == 3) {
    return [parts[0] ?? 4, parts[1] ?? 4, parts[2] ?? 8, 0];
  } else if (parts.length == 4) {
    return [
      parts[0] ?? 4,
      parts[1] ?? 4,
      parts[2] ?? 4,
      parts[3] ?? 4,
    ];
  }
  return [4, 4, 4, 0];
}

String _getBreathPhase(double progress, String pattern) {
  final parts = _parseBreathPattern(pattern);
  final inhale = parts[0];
  final hold1 = parts[1];
  final exhale = parts[2];
  final hold2 = parts[3];
  final total = inhale + hold1 + exhale + hold2;
  if (total == 0) return 'Atmen';
  final t = progress * total;
  if (t < inhale) return 'Einatmen';
  if (t < inhale + hold1) return 'Halten';
  if (t < inhale + hold1 + exhale) return 'Ausatmen';
  return 'Pause';
}

double _getOrbScale(double progress, String pattern) {
  final parts = _parseBreathPattern(pattern);
  final inhale = parts[0];
  final hold1 = parts[1];
  final exhale = parts[2];
  final hold2 = parts[3];
  final total = (inhale + hold1 + exhale + hold2).toDouble();
  if (total == 0) {
    return 1.0 + 0.4 * math.sin(progress * math.pi * 2);
  }
  final t = progress * total;
  if (t < inhale) {
    return 1.0 + (t / inhale) * 0.8;
  } else if (t < inhale + hold1) {
    return 1.8;
  } else if (t < inhale + hold1 + exhale) {
    final ep = (t - inhale - hold1) / exhale;
    return 1.8 - ep * 0.8;
  } else {
    return 1.0;
  }
}

// ---------------------------------------------------------------------------
// Haupt-Screen
// ---------------------------------------------------------------------------

class MeditationTimerScreen extends StatefulWidget {
  const MeditationTimerScreen({super.key});

  @override
  State<MeditationTimerScreen> createState() => _MeditationTimerScreenState();
}

class _MeditationTimerScreenState extends State<MeditationTimerScreen>
    with TickerProviderStateMixin {
  late final TabController _tabCtrl;
  late final AnimationController _headerPulse;

  String _activeCategory = 'Alle';
  List<Map<String, dynamic>> _personal = [];
  List<Map<String, dynamic>> _sessions = [];
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _headerPulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _loadData();
  }

  Future<void> _loadData() async {
    final personal = await _MeditationDb.getPersonal();
    final sessions = await _MeditationDb.getSessions();
    if (mounted) {
      setState(() {
        _personal = personal;
        _sessions = sessions;
        _loadingHistory = false;
      });
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _headerPulse.dispose();
    super.dispose();
  }

  void _startMeditation(_MeditationData med) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _MeditationSessionScreen(
          title: med.title,
          durationMin: med.durationMin,
          color: med.color,
          breathPattern: med.breathPattern,
          steps: med.steps,
          meditationId: med.id,
          isPersonal: false,
        ),
      ),
    ).then((_) => _loadData());
  }

  void _startPersonal(Map<String, dynamic> m) {
    final colorHex = m['color_hex'] as String? ?? 'FF7C4DFF';
    final colorVal = int.tryParse(colorHex, radix: 16) ?? 0xFF7C4DFF;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _MeditationSessionScreen(
          title: m['title'] as String? ?? 'Meine Meditation',
          durationMin: m['duration_min'] as int? ?? 10,
          color: Color(colorVal),
          breathPattern: m['breath_pattern'] as String? ?? '4-4-8',
          steps: const [
            'Setze dich bequem hin. Schließe die Augen.',
            'Folge deinem Atem. Sei einfach präsent.',
            'Wenn dein Geist wandert, kehre sanft zurück.',
            'Ruhe in der Stille. Du bist angekommen.',
          ],
          meditationId: 'personal_${m['id']}',
          isPersonal: true,
        ),
      ),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06040F),
      body: NestedScrollView(
        headerSliverBuilder: (ctx, innerBoxScrolled) => [
          SliverAppBar(
            backgroundColor: const Color(0xFF06040F),
            expandedHeight: 160,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildAnimatedHeader(),
            ),
            bottom: TabBar(
              controller: _tabCtrl,
              indicatorColor: const Color(0xFF7C4DFF),
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Geführt'),
                Tab(text: 'Persönlich'),
                Tab(text: 'Verlauf'),
              ],
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _GuidedTab(
              activeCategory: _activeCategory,
              onCategoryChanged: (c) => setState(() => _activeCategory = c),
              onStart: _startMeditation,
            ),
            _PersonalTab(
              personal: _personal,
              onStart: _startPersonal,
              onRefresh: _loadData,
            ),
            _HistoryTab(
              sessions: _sessions,
              isLoading: _loadingHistory,
              onRefresh: _loadData,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return AnimatedBuilder(
      animation: _headerPulse,
      builder: (_, __) {
        final pulse = _headerPulse.value;
        return Stack(
          children: [
            // Hintergrund-Orb
            Positioned(
              top: -40 + pulse * 20,
              left: -60,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF7C4DFF)
                          .withValues(alpha: 0.35 + pulse * 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 20,
              right: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF26C6DA)
                          .withValues(alpha: 0.2 + pulse * 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Texte
            Positioned(
              bottom: 54,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🧘 Meditation',
                    style: TextStyle(
                      color: Color(0xFF7C4DFF),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ShaderMask(
                    shaderCallback: (r) => const LinearGradient(
                      colors: [Colors.white, Color(0xFFCE93D8)],
                    ).createShader(r),
                    child: const Text(
                      'Wähle deine Meditation',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 1 — Geführte Meditationen
// ---------------------------------------------------------------------------

class _GuidedTab extends StatelessWidget {
  final String activeCategory;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<_MeditationData> onStart;

  const _GuidedTab({
    required this.activeCategory,
    required this.onCategoryChanged,
    required this.onStart,
  });

  List<_MeditationData> get _filtered {
    if (activeCategory == 'Alle') return _kMeditations;
    return _kMeditations.where((m) => m.category == activeCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Kategorie-Chips
        SliverToBoxAdapter(
          child: SizedBox(
            height: 52,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              scrollDirection: Axis.horizontal,
              itemCount: _kCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final cat = _kCategories[i];
                final active = cat == activeCategory;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onCategoryChanged(cat);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFF7C4DFF)
                          : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active
                            ? const Color(0xFF7C4DFF)
                            : Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: active ? Colors.white : Colors.white70,
                        fontSize: 13,
                        fontWeight:
                            active ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // Grid
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final med = _filtered[i];
                return _MeditationCard(med: med, onStart: onStart);
              },
              childCount: _filtered.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
          ),
        ),
      ],
    );
  }
}

class _MeditationCard extends StatelessWidget {
  final _MeditationData med;
  final ValueChanged<_MeditationData> onStart;

  const _MeditationCard({required this.med, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              med.color.withValues(alpha: 0.35),
              const Color(0xFF0D0A1A),
            ],
          ),
          border: Border.all(
            color: med.color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon + Kategorie-Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: med.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(med.icon, color: med.color, size: 22),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${med.durationMin} min',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                med.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                med.subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              // Starten-Button
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onStart(med);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        med.color.withValues(alpha: 0.8),
                        med.color.withValues(alpha: 0.5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Starten',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MeditationDetailSheet(med: med, onStart: onStart),
    );
  }
}

class _MeditationDetailSheet extends StatelessWidget {
  final _MeditationData med;
  final ValueChanged<_MeditationData> onStart;

  const _MeditationDetailSheet({required this.med, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D0A1A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: med.color.withValues(alpha: 0.3), width: 1),
        ),
        child: ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
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
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: med.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(med.icon, color: med.color, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        med.subtitle,
                        style: TextStyle(
                          color: med.color,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              med.description,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 16),
            // Vorteile
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: med.benefits
                  .map((b) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: med.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: med.color.withValues(alpha: 0.4)),
                        ),
                        child: Text(b,
                            style: TextStyle(color: med.color, fontSize: 12)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            // Schritte
            const Text(
              'Ablauf der Meditation',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(med.steps.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: med.color.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: med.color.withValues(alpha: 0.5)),
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: med.color,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        med.steps[i],
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  HapticFeedback.mediumImpact();
                  onStart(med);
                },
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                label: Text(
                  'Meditation starten (${med.durationMin} min)',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: med.color,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 2 — Persönliche Meditationen
// ---------------------------------------------------------------------------

class _PersonalTab extends StatelessWidget {
  final List<Map<String, dynamic>> personal;
  final ValueChanged<Map<String, dynamic>> onStart;
  final VoidCallback onRefresh;

  const _PersonalTab({
    required this.personal,
    required this.onStart,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        personal.isEmpty
            ? _buildEmpty()
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: personal.length,
                itemBuilder: (ctx, i) {
                  final m = personal[i];
                  return _PersonalCard(
                    data: m,
                    onStart: () => onStart(m),
                    onDelete: () async {
                      await _MeditationDb.deletePersonal(m['id'] as int);
                      onRefresh();
                    },
                  );
                },
              ),
        Positioned(
          bottom: 24,
          right: 20,
          child: FloatingActionButton.extended(
            backgroundColor: const Color(0xFF7C4DFF),
            onPressed: () => _showCreateDialog(context),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Neu erstellen',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF7C4DFF).withValues(alpha: 0.1),
            ),
            child: const Icon(Icons.self_improvement,
                size: 56, color: Color(0xFF7C4DFF)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Noch keine persönlichen\nMeditationen',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tippe auf "Neu erstellen" um\ndeine eigene Meditation zu gestalten.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreatePersonalSheet(onCreated: onRefresh),
    );
  }
}

class _PersonalCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onStart;
  final VoidCallback onDelete;

  const _PersonalCard({
    required this.data,
    required this.onStart,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorHex = data['color_hex'] as String? ?? 'FF7C4DFF';
    final colorVal = int.tryParse(colorHex, radix: 16) ?? 0xFF7C4DFF;
    final color = Color(colorVal);
    final title = data['title'] as String? ?? 'Meine Meditation';
    final duration = data['duration_min'] as int? ?? 10;
    final pattern = data['breath_pattern'] as String? ?? '4-4-8';
    final intention = data['intention'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.2),
            const Color(0xFF0D0A1A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: color.withValues(alpha: 0.6), blurRadius: 8)
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Colors.white38, size: 20),
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: const Color(0xFF1A1230),
                    title: const Text('Löschen?',
                        style: TextStyle(color: Colors.white)),
                    content: const Text(
                        'Diese persönliche Meditation wirklich löschen?',
                        style: TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Abbrechen',
                            style: TextStyle(color: Colors.white54)),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onDelete();
                        },
                        child: const Text('Löschen',
                            style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _Badge(label: '$duration min', color: color),
              const SizedBox(width: 8),
              _Badge(label: pattern, color: Colors.white30),
            ],
          ),
          if (intention.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '"$intention"',
              style: TextStyle(
                  color: color.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                onStart();
              },
              icon: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 18),
              label: const Text('Starten',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: color.withValues(alpha: 0.7),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _CreatePersonalSheet extends StatefulWidget {
  final VoidCallback onCreated;
  const _CreatePersonalSheet({required this.onCreated});

  @override
  State<_CreatePersonalSheet> createState() => _CreatePersonalSheetState();
}

class _CreatePersonalSheetState extends State<_CreatePersonalSheet> {
  final _titleCtrl = TextEditingController();
  final _intentionCtrl = TextEditingController();
  double _duration = 10;
  String _breathPattern = '4-4-8';
  int _colorIndex = 0;

  static const _colors = [
    Color(0xFF7C4DFF),
    Color(0xFF26C6DA),
    Color(0xFF66BB6A),
    Color(0xFFEC407A),
    Color(0xFFFFD54F),
    Color(0xFF8D6E63),
    Color(0xFF42A5F5),
    Color(0xFF9C27B0),
  ];

  static const _patterns = [
    '4-4-8',
    '4-7-8',
    '4-4-4-4',
    '4-2-6',
    '4-0-8',
  ];

  static const _patternLabels = [
    'Entspannung (4-4-8)',
    'Schlaf (4-7-8)',
    'Box (4-4-4-4)',
    'Erdung (4-2-6)',
    'Energie (4-0-8)',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _intentionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kbHeight = MediaQuery.of(context).viewInsets.bottom;
    final color = _colors[_colorIndex];

    return Container(
      margin: const EdgeInsets.only(top: 60),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + kbHeight),
      decoration: const BoxDecoration(
        color: Color(0xFF0D0A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
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
            const SizedBox(height: 20),
            const Text(
              'Persönliche Meditation erstellen',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Name
            TextField(
              controller: _titleCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Name der Meditation',
                labelStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: color.withValues(alpha: 0.4)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: color),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Dauer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Dauer',
                    style: TextStyle(
                        color: Colors.white70, fontWeight: FontWeight.w600)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_duration.round()} min',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            Slider(
              value: _duration,
              min: 5,
              max: 60,
              divisions: 11,
              activeColor: color,
              inactiveColor: color.withValues(alpha: 0.2),
              onChanged: (v) => setState(() => _duration = v),
            ),
            const SizedBox(height: 16),
            // Atemübung
            const Text('Atemübung',
                style: TextStyle(
                    color: Colors.white70, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_patterns.length, (i) {
                final active = _patterns[i] == _breathPattern;
                return GestureDetector(
                  onTap: () => setState(() => _breathPattern = _patterns[i]),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: active
                          ? color.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: active
                            ? color
                            : Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Text(
                      _patternLabels[i],
                      style: TextStyle(
                        color: active ? color : Colors.white54,
                        fontSize: 12,
                        fontWeight:
                            active ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            // Farbe
            const Text('Farbe',
                style: TextStyle(
                    color: Colors.white70, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_colors.length, (i) {
                final selected = i == _colorIndex;
                return GestureDetector(
                  onTap: () => setState(() => _colorIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _colors[i],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                  color: _colors[i].withValues(alpha: 0.6),
                                  blurRadius: 8)
                            ]
                          : [],
                    ),
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            // Intention
            TextField(
              controller: _intentionCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Intention (optional)',
                labelStyle: const TextStyle(color: Colors.white54),
                hintText: 'z.B. "Ich finde Frieden und Klarheit"',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: color.withValues(alpha: 0.4)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: color),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_rounded, color: Colors.white),
                label: const Text(
                  'Meditation speichern & starten',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim().isEmpty
        ? 'Meine Meditation'
        : _titleCtrl.text.trim();
    final colorHex =
        _colors[_colorIndex].toARGB32().toRadixString(16).padLeft(8, '0');
    await _MeditationDb.insertPersonal({
      'title': title,
      'duration_min': _duration.round(),
      'breath_pattern': _breathPattern,
      'intention': _intentionCtrl.text.trim(),
      'color_hex': colorHex,
      'created_at': DateTime.now().toIso8601String(),
    });
    if (mounted) {
      Navigator.pop(context);
      widget.onCreated();
    }
  }
}

// ---------------------------------------------------------------------------
// Tab 3 — Verlauf
// ---------------------------------------------------------------------------

class _HistoryTab extends StatelessWidget {
  final List<Map<String, dynamic>> sessions;
  final bool isLoading;
  final VoidCallback onRefresh;

  const _HistoryTab({
    required this.sessions,
    required this.isLoading,
    required this.onRefresh,
  });

  int get _totalMinutes =>
      sessions.fold<int>(0, (s, m) => s + (m['duration_min'] as int? ?? 0));

  int get _weekCount {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return sessions.where((m) {
      final d = DateTime.tryParse(m['completed_at'] as String? ?? '');
      return d != null && d.isAfter(weekAgo);
    }).length;
  }

  int get _streak {
    if (sessions.isEmpty) return 0;
    final dates = sessions
        .map((m) {
          final d = DateTime.tryParse(m['completed_at'] as String? ?? '');
          if (d == null) return null;
          return DateTime(d.year, d.month, d.day);
        })
        .whereType<DateTime>()
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    if (dates.isEmpty) return 0;
    int streak = 1;
    for (int i = 1; i < dates.length; i++) {
      final diff = dates[i - 1].difference(dates[i]).inDays;
      if (diff == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF7C4DFF)));
    }

    return RefreshIndicator(
      color: const Color(0xFF7C4DFF),
      backgroundColor: const Color(0xFF0D0A1A),
      onRefresh: () async => onRefresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _StatsBanner(
                totalMinutes: _totalMinutes,
                weekCount: _weekCount,
                streak: _streak,
              ),
            ),
          ),
          if (sessions.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history_rounded,
                        size: 48, color: Colors.white24),
                    SizedBox(height: 12),
                    Text(
                      'Noch keine Meditationen abgeschlossen.',
                      style: TextStyle(color: Colors.white38, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final s = sessions[i];
                    return _SessionTile(session: s);
                  },
                  childCount: sessions.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatsBanner extends StatelessWidget {
  final int totalMinutes;
  final int weekCount;
  final int streak;

  const _StatsBanner({
    required this.totalMinutes,
    required this.weekCount,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    final timeStr = hours > 0 ? '${hours}h ${mins}min' : '${mins}min';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C4DFF), Color(0xFF26C6DA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C4DFF).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(value: timeStr, label: 'Gesamt'),
          Container(
              height: 40, width: 1, color: Colors.white.withValues(alpha: 0.3)),
          _StatItem(value: '$weekCount', label: 'Diese Woche'),
          Container(
              height: 40, width: 1, color: Colors.white.withValues(alpha: 0.3)),
          _StatItem(value: '$streak 🔥', label: 'Streak'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
        ),
      ],
    );
  }
}

class _SessionTile extends StatelessWidget {
  final Map<String, dynamic> session;
  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final title = session['title'] as String? ?? 'Unbekannt';
    final durationMin = session['duration_min'] as int? ?? 0;
    final completedAt =
        DateTime.tryParse(session['completed_at'] as String? ?? '') ??
            DateTime.now();
    final isPersonal = (session['is_personal'] as int? ?? 0) == 1;
    final dateStr =
        DateFormat('d. MMMM yyyy · HH:mm', 'de').format(completedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF7C4DFF).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPersonal ? Icons.person_rounded : Icons.self_improvement,
              color: const Color(0xFF7C4DFF),
              size: 22,
            ),
          ),
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
                  dateStr,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF7C4DFF).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$durationMin min',
              style: const TextStyle(
                color: Color(0xFF7C4DFF),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Meditations-Session Screen
// ---------------------------------------------------------------------------

class _MeditationSessionScreen extends StatefulWidget {
  final String title;
  final int durationMin;
  final Color color;
  final String breathPattern;
  final List<String> steps;
  final String meditationId;
  final bool isPersonal;

  const _MeditationSessionScreen({
    required this.title,
    required this.durationMin,
    required this.color,
    required this.breathPattern,
    required this.steps,
    required this.meditationId,
    required this.isPersonal,
  });

  @override
  State<_MeditationSessionScreen> createState() =>
      _MeditationSessionScreenState();
}

class _MeditationSessionScreenState extends State<_MeditationSessionScreen>
    with TickerProviderStateMixin {
  late AnimationController _breathCtrl;
  late AnimationController _orbPulse;
  Timer? _sessionTimer;
  Timer? _stepTimer;

  int _remainingSecs = 0;
  int _currentStep = 0;
  bool _isPaused = false;
  // ignore: unused_field
  bool _finished = false;
  bool _stepFading = false;

  @override
  void initState() {
    super.initState();
    _remainingSecs = widget.durationMin * 60;

    // Atemanimation
    final parts = _parseBreathPattern(widget.breathPattern);
    final cycleSecs = parts.fold<int>(0, (s, v) => s + v);
    final cycleDuration = Duration(seconds: cycleSecs > 0 ? cycleSecs : 8);

    _breathCtrl = AnimationController(vsync: this, duration: cycleDuration)
      ..repeat();

    _orbPulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _startTimer();
    _startStepRotation();
  }

  void _startTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isPaused) return;
      setState(() {
        if (_remainingSecs > 0) {
          _remainingSecs--;
        } else {
          _sessionTimer?.cancel();
          _finish();
        }
      });
    });
  }

  void _startStepRotation() {
    _stepTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isPaused || widget.steps.isEmpty) return;
      setState(() {
        _stepFading = true;
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _currentStep = (_currentStep + 1) % widget.steps.length;
            _stepFading = false;
          });
        }
      });
    });
  }

  void _togglePause() {
    HapticFeedback.selectionClick();
    setState(() => _isPaused = !_isPaused);
    if (_isPaused) {
      _breathCtrl.stop();
    } else {
      _breathCtrl.repeat();
    }
  }

  void _finish() {
    _stepTimer?.cancel();
    _breathCtrl.stop();
    _orbPulse.stop();
    setState(() => _finished = true);
    HapticFeedback.heavyImpact();
    _saveAndShowDialog();
  }

  Future<void> _saveAndShowDialog() async {
    await _MeditationDb.insertSession(
      meditationId: widget.meditationId,
      title: widget.title,
      durationMin: widget.durationMin,
      isPersonal: widget.isPersonal,
    );
    if (mounted) {
      unawaited(showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _CompletionDialog(
          title: widget.title,
          durationMin: widget.durationMin,
          color: widget.color,
          onClose: () {
            Navigator.pop(context); // Dialog
            Navigator.pop(context); // Session screen
          },
        ),
      ));
    }
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _stepTimer?.cancel();
    _breathCtrl.dispose();
    _orbPulse.dispose();
    super.dispose();
  }

  String get _timeStr {
    final m = _remainingSecs ~/ 60;
    final s = _remainingSecs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress =>
      1.0 - _remainingSecs / (widget.durationMin * 60).toDouble();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: Listenable.merge([_breathCtrl, _orbPulse]),
        builder: (_, __) {
          final scale = _getOrbScale(_breathCtrl.value, widget.breathPattern);
          final phase =
              _getBreathPhase(_breathCtrl.value, widget.breathPattern);
          final pulse = _orbPulse.value;

          return Stack(
            children: [
              // Hintergrund-Orb mit Welt-Farbe
              Positioned(
                top: -100 + pulse * 40,
                left: -100,
                child: Container(
                  width: 500,
                  height: 500,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        widget.color.withValues(alpha: 0.25 + pulse * 0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // SafeArea Content
              SafeArea(
                child: Column(
                  children: [
                    // Top-Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                backgroundColor: const Color(0xFF1A1230),
                                title: const Text(
                                  'Session beenden?',
                                  style: TextStyle(color: Colors.white),
                                ),
                                content: const Text(
                                  'Die Meditation wird als unvollständig beendet.',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Weiter meditieren',
                                        style:
                                            TextStyle(color: Colors.white54)),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Beenden',
                                        style:
                                            TextStyle(color: Colors.redAccent)),
                                  ),
                                ],
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white70,
                                size: 20,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          // Zeit
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: widget.color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: widget.color.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              _timeStr,
                              style: TextStyle(
                                color: widget.color,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Fortschrittsbalken
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _progress,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(widget.color),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Atemkugel
                    Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              widget.color.withValues(alpha: 0.9),
                              widget.color.withValues(alpha: 0.4),
                              widget.color.withValues(alpha: 0.1),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.color
                                  .withValues(alpha: 0.4 + scale * 0.2),
                              blurRadius: 40 + scale * 20,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Atemphase
                    Text(
                      phase,
                      style: TextStyle(
                        color: widget.color,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Aktueller Schritt
                    if (widget.steps.isNotEmpty)
                      AnimatedOpacity(
                        opacity: _stepFading ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            widget.steps[_currentStep],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    const Spacer(),
                    // Stepper-Dots
                    if (widget.steps.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          widget.steps.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == _currentStep ? 20 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: i == _currentStep
                                  ? widget.color
                                  : Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    // Pause-Button
                    GestureDetector(
                      onTap: _togglePause,
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Icon(
                          _isPaused
                              ? Icons.play_arrow_rounded
                              : Icons.pause_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CompletionDialog extends StatelessWidget {
  final String title;
  final int durationMin;
  final Color color;
  final VoidCallback onClose;

  const _CompletionDialog({
    required this.title,
    required this.durationMin,
    required this.color,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0A1A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 30,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withValues(alpha: 0.4),
                    color.withValues(alpha: 0.1),
                  ],
                ),
                border: Border.all(color: color, width: 2),
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 36),
            ),
            const SizedBox(height: 20),
            const Text(
              'Session abgeschlossen! 🙏',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              '$title\n$durationMin Minuten Meditation',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white60, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '+$durationMin Minuten Erfahrung',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Nimm dir einen Moment um sanft ins Alltagsbewusstsein zurückzukehren.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: Colors.white38, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Wunderbar ✨',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
