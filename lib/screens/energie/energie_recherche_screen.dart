import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ═══════════════════════════════════════════════════════════════════════════
// MODELLE
// ═══════════════════════════════════════════════════════════════════════════

class _BookResult {
  final String title;
  final String author;
  final int? year;
  final String? key;

  const _BookResult({
    required this.title,
    required this.author,
    this.year,
    this.key,
  });

  String get openLibUrl => key != null ? 'https://openlibrary.org$key' : '';
}

class _WikiResult {
  final String title;
  final String extract;
  final String url;

  const _WikiResult({
    required this.title,
    required this.extract,
    required this.url,
  });
}

class _PubMedResult {
  final String pmid;
  final String title;

  const _PubMedResult({required this.pmid, required this.title});

  String get url => 'https://pubmed.ncbi.nlm.nih.gov/$pmid/';
}

// ═══════════════════════════════════════════════════════════════════════════
// SPIRITUELLE KONTEXT-DATENBANK (lokal, kein API nötig)
// ═══════════════════════════════════════════════════════════════════════════

const Map<String, String> _spiritualContexts = {
  'meditation':
      'In spirituellen Traditionen weltweit gilt Meditation als direkter Weg zum höheren Bewusstsein. '
          'Vom Buddhismus bis zur vedischen Tradition, von der christlichen Kontemplation bis zum Sufismus '
          '— stille Innenschau öffnet den Geist für transpersonale Erfahrungen und tiefe Heilung.',
  'manifestation':
      'Das Gesetz der Anziehung beschreibt, dass Gedanken und Gefühle die Realität formen. '
          'Spirituelle Traditionen lehren: Was du im Inneren lebst, erschaffst du im Außen. '
          'Klare Intention, emotionale Resonanz und geduldiges Loslassen sind der Schlüssel.',
  'karma': 'Karma (Sanskrit: "Tat") bezeichnet das universelle Kausalitätsprinzip: Jede Handlung '
      'erzeugt Wirkungen, die im selben oder künftigen Leben erfahren werden. '
      'Karma ist kein Schicksal, sondern Einladung zur Verantwortung und Bewusstseinserweiterung.',
  'chakren': 'Die sieben Hauptchakren sind Energiezentren entlang der Wirbelsäule aus der vedischen Tradition. '
      'Von Muladhara (Wurzel) bis Sahasrara (Krone) regulieren sie körperliche, emotionale und '
      'spirituelle Aspekte des Lebens. Blockierte Chakren zeigen sich als körperliche oder seelische Beschwerden.',
  'akasha':
      'Die Akasha-Chronik (Sanskrit: "Äther, Himmel") ist nach theosophischer Lehre ein nichtlineares '
          'kosmisches Gedächtnis, das alle Erfahrungen jeder Seele enthält. '
          'Medial begabte Menschen sollen Zugang zu diesen Aufzeichnungen haben.',
  'astralreise':
      'Die Astralprojektion beschreibt das Verlassen des physischen Körpers durch den Astralleib. '
          'In schamanischen, hinduistischen und okkulten Traditionen gilt dies als erweiterter Bewusstseinszustand, '
          'der tiefe spirituelle Einsichten ermöglicht.',
  'mondphasen':
      'Der Mond beeinflusst nach alter Überlieferung nicht nur Gezeiten, sondern auch Energien, '
          'Emotionen und spirituelle Qualitäten. Neumond steht für Neuanfänge, Vollmond für Fülle '
          'und Enthüllung. Viele Rituale richten sich nach dem Mondkalender.',
  'heilung': 'Spirituelle Heilung umfasst Energiearbeit, Gebet, Handauflegen und schamanische Praktiken. '
      'Sie ergänzt schulmedizinische Behandlungen durch den Einbezug des Geist-Körper-Seele-Kontinuums. '
      'Die Quantenphysik liefert erste Modelle für Fernheilung und Bewusstseinswirkung.',
  'quantenbewusstsein':
      'Die Quantenbewusstseinstheorie, vertreten u.a. von Penrose und Hameroff, postuliert dass '
          'Bewusstsein in Quantenprozessen in Mikrotubuli des Gehirns entsteht. '
          'Spirituelle Interpreten sehen darin eine Brücke zwischen Materie und Geist.',
  'dreifältige göttin':
      'Die Dreifältige Göttin der Wicca und Neopaganismus repräsentiert in ihren Aspekten '
          'Jungfrau, Mutter und Weise die drei Lebensphasen der Frau und die Mondphasen. '
          'Sie verkörpert die Kraft der Natur und des göttlichen Weiblichen.',
  'reiki': 'Reiki (japanisch: "universelle Lebensenergie") ist eine Energieheilmethode, '
      'die 1922 von Mikao Usui entwickelt wurde. Durch Handauflegen soll Heilenergie '
      'übertragen werden, die Blockaden löst und den natürlichen Energiefluss wiederherstellt.',
  'schamanismus':
      'Schamanismus ist die älteste bekannte spirituelle Praxis der Menschheit. '
          'Schamanen reisen in veränderten Bewusstseinszuständen in andere Weltenebenen, '
          'um Heilung, Führung und Wissen für ihre Gemeinschaft zu holen.',
  'numerologie':
      'Die Numerologie ist die Lehre von der mystischen Bedeutung der Zahlen. '
          'Jeder Buchstabe und jede Zahl hat einen spirituellen Wert, der Charakter, '
          'Schicksal und Lebenszweck einer Person offenbaren soll.',
  'astrologie':
      'Astrologie ist die Deutung kosmischer Einflüsse auf das irdische Leben. '
          'Die Stellung der Planeten zum Geburtszeitpunkt — der Geburtshoroskop — '
          'gilt als Blaupause der Seele und ihrer Aufgaben in diesem Leben.',
  'tarot':
      'Tarot ist ein Orakelsystem aus 78 Karten, das im 15. Jahrhundert in Norditalien entstand. '
          'Die Großen Arcana (22 Karten) symbolisieren universelle Lebensprinzipien, '
          'die Kleinen Arcana (56 Karten) alltägliche Erfahrungen.',
  'kristalle':
      'Heilkristalle werden seit Jahrtausenden in spirituellen Traditionen als Energie-Verstärker '
          'und Heilwerkzeuge eingesetzt. Jeder Kristall hat eine spezifische Schwingungsfrequenz, '
          'die bestimmte Chakren und Bewusstseinszustände unterstützt.',
  'kabbala': 'Die Kabbala ist die mystische Tradition des Judentums. '
      'Der Lebensbaum (Sephirot) beschreibt mit 10 Sefirot und 22 Pfaden '
      'die Struktur der göttlichen Emanation und den Weg der Seele zur Erleuchtung.',
  'hermetik':
      'Die Hermetik basiert auf den Schriften des mythischen Hermes Trismegistus. '
          'Die sieben Hermetischen Gesetze — wie "Wie oben, so unten" — '
          'beschreiben Universalprinzipien, die Materie, Energie und Bewusstsein verbinden.',
  'yoga': 'Yoga (Sanskrit: "Verbindung") ist ein System spiritueller, mentaler und körperlicher Praktiken. '
      'Ursprünglich aus dem alten Indien stammend, vereint es Asanas, Pranayama und Dhyana '
      'zur Befreiung des Bewusstseins aus dem Kreislauf von Geburt und Tod.',
  'human design':
      'Human Design ist ein modernes Synthesesystem aus Astrologie, Kabbala, dem I-Ging und '
          'der Quantenphysik, entwickelt von Ra Uru Hu. Es beschreibt 4 Typen mit spezifischen '
          'Strategien und Autoritäten zur bewussten Lebensführung.',
};

// ═══════════════════════════════════════════════════════════════════════════
// ENERGIE RECHERCHE SCREEN
// ═══════════════════════════════════════════════════════════════════════════

class EnergieRechercheScreen extends StatefulWidget {
  const EnergieRechercheScreen({super.key});

  @override
  State<EnergieRechercheScreen> createState() => _EnergieRechercheScreenState();
}

class _EnergieRechercheScreenState extends State<EnergieRechercheScreen>
    with TickerProviderStateMixin {
  // ── Animationen ──────────────────────────────────────────────────────────
  late final AnimationController _bgCtrl;
  late final AnimationController _starCtrl;
  late final AnimationController _entryCtrl;
  late final Animation<double> _entryAnim;

  // ── State ────────────────────────────────────────────────────────────────
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isLoading = false;
  String? _currentQuery;

  List<_BookResult> _books = [];
  List<_WikiResult> _wikiResults = [];
  List<_PubMedResult> _pubmedResults = [];
  String? _spiritualContext;
  String? _error;

  // ── Farben ───────────────────────────────────────────────────────────────
  static const _bg = Color(0xFF06040F);
  static const _card = Color(0xFF0E0A1C);
  static const _purple = Color(0xFFAB47BC);
  static const _purpleD = Color(0xFF4A148C);
  static const _teal = Color(0xFF26C6DA);
  static const _gold = Color(0xFFFFD54F);

  static const _suggestions = [
    'Meditation',
    'Manifestation',
    'Karma',
    'Chakren',
    'Akasha',
    'Astralreise',
    'Mondphasen',
    'Heilung',
    'Quantenbewusstsein',
    'Dreifältige Göttin',
    'Reiki',
    'Schamanismus',
    'Numerologie',
    'Astrologie',
    'Tarot',
    'Kristalle',
    'Kabbala',
    'Hermetik',
    'Yoga',
    'Human Design',
  ];

  // ── Sterne (für CustomPainter) ───────────────────────────────────────────
  late final List<_Star> _stars;
  final _rng = math.Random(42);

  @override
  void initState() {
    super.initState();
    _bgCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..repeat(reverse: true);
    _starCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat(reverse: true);
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _entryAnim =
        CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic);
    _entryCtrl.forward();

    _stars = List.generate(
        100,
        (_) => _Star(
              x: _rng.nextDouble(),
              y: _rng.nextDouble(),
              size: _rng.nextDouble() * 2.0 + 0.5,
              brightness: _rng.nextDouble(),
            ));
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _starCtrl.dispose();
    _entryCtrl.dispose();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Suche ─────────────────────────────────────────────────────────────────
  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _currentQuery = query.trim();
      _books = [];
      _wikiResults = [];
      _pubmedResults = [];
      _spiritualContext = null;
      _error = null;
    });

    try {
      await Future.wait([
        _searchOpenLibrary(query),
        _searchWikipedia(query),
        _searchPubMed(query),
      ]);
      _findSpiritualContext(query);
    } catch (e) {
      if (mounted) {
        setState(() =>
            _error = 'Fehler beim Laden: Bitte Internetverbindung prüfen.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    // Sanft nach unten scrollen
    await Future.delayed(const Duration(milliseconds: 400));
    if (_scrollCtrl.hasClients) {
      await _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent * 0.3,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _searchOpenLibrary(String query) async {
    try {
      final encoded = Uri.encodeComponent('$query spirituality');
      final uri =
          Uri.parse('https://openlibrary.org/search.json?q=$encoded&limit=5');
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final docs = (data['docs'] as List<dynamic>?) ?? [];
        if (mounted) {
          setState(() {
            _books = docs.take(5).map((d) {
              final doc = d as Map<String, dynamic>;
              final authors =
                  (doc['author_name'] as List<dynamic>?)?.cast<String>() ?? [];
              return _BookResult(
                title: (doc['title'] as String?) ?? 'Unbekannter Titel',
                author: authors.isNotEmpty ? authors.first : 'Unbekannt',
                year: doc['first_publish_year'] as int?,
                key: doc['key'] as String?,
              );
            }).toList();
          });
        }
      }
    } catch (_) {
      // Fehler ignorieren — andere Quellen laufen weiter
    }
  }

  Future<void> _searchWikipedia(String query) async {
    try {
      // Erst: Volltextsuche
      final searchUri = Uri.parse(
          'https://de.wikipedia.org/w/api.php?action=query&list=search'
          '&srsearch=${Uri.encodeComponent(query)}&srlimit=4&format=json&origin=*');
      final searchResp =
          await http.get(searchUri).timeout(const Duration(seconds: 8));

      if (searchResp.statusCode == 200) {
        final searchData = json.decode(searchResp.body) as Map<String, dynamic>;
        final queryNode = searchData['query'] as Map<String, dynamic>?;
        final hits = (queryNode?['search'] as List<dynamic>?) ?? [];

        final results = <_WikiResult>[];
        for (final hit in hits.take(3)) {
          final title = (hit as Map<String, dynamic>)['title'] as String? ?? '';
          if (title.isEmpty) continue;
          try {
            final summaryUri = Uri.parse(
                'https://de.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(title)}');
            final summaryResp =
                await http.get(summaryUri).timeout(const Duration(seconds: 6));
            if (summaryResp.statusCode == 200) {
              final s = json.decode(summaryResp.body) as Map<String, dynamic>;
              final extract = (s['extract'] as String?) ?? '';
              final contentUrls = s['content_urls'] as Map<String, dynamic>?;
              final desktop = contentUrls?['desktop'] as Map<String, dynamic>?;
              final url = (desktop?['page'] as String?) ?? '';
              if (extract.isNotEmpty) {
                results.add(_WikiResult(
                  title: title,
                  extract: extract.length > 350
                      ? '${extract.substring(0, 347)}…'
                      : extract,
                  url: url,
                ));
              }
            }
          } catch (_) {}
        }
        if (mounted) setState(() => _wikiResults = results);
      }
    } catch (_) {}
  }

  Future<void> _searchPubMed(String query) async {
    try {
      final term = Uri.encodeComponent('$query meditation spirituality');
      final uri =
          Uri.parse('https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi'
              '?db=pubmed&term=$term&retmax=5&retmode=json');
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final esearchResult = data['esearchresult'] as Map<String, dynamic>?;
        final ids =
            (esearchResult?['idlist'] as List<dynamic>?)?.cast<String>() ?? [];

        if (ids.isNotEmpty) {
          // Zusammenfassung per efetch
          final idsStr = ids.take(5).join(',');
          final fetchUri = Uri.parse(
              'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi'
              '?db=pubmed&id=$idsStr&retmode=json');
          final fetchResp =
              await http.get(fetchUri).timeout(const Duration(seconds: 8));

          if (fetchResp.statusCode == 200) {
            final fData = json.decode(fetchResp.body) as Map<String, dynamic>;
            final result = (fData['result'] as Map<String, dynamic>?) ?? {};
            final uids =
                (result['uids'] as List<dynamic>?)?.cast<String>() ?? [];

            final results = <_PubMedResult>[];
            for (final uid in uids) {
              final entry = result[uid] as Map<String, dynamic>?;
              if (entry == null) continue;
              final title = (entry['title'] as String?) ?? '';
              if (title.isNotEmpty) {
                results.add(_PubMedResult(pmid: uid, title: title));
              }
            }
            if (mounted) setState(() => _pubmedResults = results);
          }
        }
      }
    } catch (_) {}
  }

  void _findSpiritualContext(String query) {
    final q = query.toLowerCase();
    String? found;
    for (final key in _spiritualContexts.keys) {
      if (q.contains(key) || key.contains(q)) {
        found = _spiritualContexts[key];
        break;
      }
    }
    // Fuzzy: erstes Wort des Querys
    if (found == null) {
      final firstWord = q.split(' ').first;
      for (final key in _spiritualContexts.keys) {
        if (key.contains(firstWord) || firstWord.contains(key)) {
          found = _spiritualContexts[key];
          break;
        }
      }
    }
    if (mounted) setState(() => _spiritualContext = found);
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(children: [
        _buildStarfieldBg(),
        SafeArea(
          child: Column(children: [
            _buildHeader(),
            Expanded(
              child:
                  _currentQuery == null ? _buildEmptyState() : _buildResults(),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Hintergrund: Sternenhimmel ────────────────────────────────────────────
  Widget _buildStarfieldBg() {
    return AnimatedBuilder(
      animation: _starCtrl,
      builder: (_, __) => CustomPaint(
        painter: _StarfieldPainter(
          stars: _stars,
          twinkle: _starCtrl.value,
          primaryColor: _purple,
          secondaryColor: _teal,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }

  // ── Header mit Suchfeld ───────────────────────────────────────────────────
  Widget _buildHeader() {
    return FadeTransition(
      opacity: _entryAnim,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(children: [
          Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white70, size: 16),
              ),
            ),
            const SizedBox(width: 12),
            const Text('🔮 Spirituelle Recherche',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 14),
          // Suchfeld
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, __) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  _purple.withValues(alpha: 0.15 + _bgCtrl.value * 0.05),
                  _teal.withValues(alpha: 0.08),
                ]),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color:
                        _purple.withValues(alpha: 0.4 + _bgCtrl.value * 0.1)),
              ),
              child: Row(children: [
                const SizedBox(width: 14),
                const Text('🔍', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'z.B. Meditation, Chakren, Mondenergie …',
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    onSubmitted: _search,
                    textInputAction: TextInputAction.search,
                  ),
                ),
                GestureDetector(
                  onTap: () => _search(_searchCtrl.text),
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient:
                          const LinearGradient(colors: [_purple, _purpleD]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text('Suchen',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          // Vorschlags-Chips
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _suggestions.length,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () {
                  _searchCtrl.text = _suggestions[i];
                  _search(_suggestions[i]);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(18),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: Text(_suggestions[i],
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 12)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }

  // ── Leerer Zustand ────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: AnimatedBuilder(
        animation: _bgCtrl,
        builder: (_, __) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _purple.withValues(alpha: 0.3 + _bgCtrl.value * 0.1),
                  _teal.withValues(alpha: 0.1),
                  Colors.transparent,
                ]),
                boxShadow: [
                  BoxShadow(
                    color: _purple.withValues(alpha: 0.2 + _bgCtrl.value * 0.1),
                    blurRadius: 30,
                  )
                ],
              ),
              child: Center(
                child: Text('🔮',
                    style: TextStyle(fontSize: 44 + _bgCtrl.value * 4)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Starte deine spirituelle Recherche',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Bücher, Wikipedia, Wissenschaft & mehr',
                style: TextStyle(color: Colors.white38, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // ── Ergebnisse ────────────────────────────────────────────────────────────
  Widget _buildResults() {
    return ListView(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      physics: const BouncingScrollPhysics(),
      children: [
        // Suche-Label
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _purple.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _purple.withValues(alpha: 0.4)),
              ),
              child: Text('🔍 "$_currentQuery"',
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ),
          ]),
        ),

        // Loading Shimmer
        if (_isLoading) ...[
          _buildShimmerSection('📖 Bücher & Texte'),
          _buildShimmerSection('🌐 Wikipedia'),
          _buildShimmerSection('🔬 Wissenschaft'),
        ],

        // Fehler
        if (_error != null && !_isLoading) _buildErrorCard(),

        // Ergebnisse (immer sichtbar, auch während Nachladen)
        if (!_isLoading) ...[
          // Spirituelle Perspektive (zuoberst wenn vorhanden)
          if (_spiritualContext != null) ...[
            _buildSectionHeader('✨ Geistige Perspektive'),
            _buildSpiritualCard(),
            const SizedBox(height: 16),
          ],

          // Bücher
          if (_books.isNotEmpty) ...[
            _buildSectionHeader('📖 Bücher & Texte'),
            ..._books.asMap().entries.map((e) => _AnimatedCard(
                delay: e.key * 80, child: _buildBookCard(e.value))),
            const SizedBox(height: 16),
          ],

          // Wikipedia
          if (_wikiResults.isNotEmpty) ...[
            _buildSectionHeader('🌐 Wikipedia'),
            ..._wikiResults.asMap().entries.map((e) => _AnimatedCard(
                delay: e.key * 80, child: _buildWikiCard(e.value))),
            const SizedBox(height: 16),
          ],

          // PubMed
          if (_pubmedResults.isNotEmpty) ...[
            _buildSectionHeader('🔬 Wissenschaft & Spiritualität'),
            ..._pubmedResults.asMap().entries.map((e) => _AnimatedCard(
                delay: e.key * 80, child: _buildPubMedCard(e.value))),
            const SizedBox(height: 16),
          ],

          // Keine Ergebnisse
          if (_books.isEmpty &&
              _wikiResults.isEmpty &&
              _pubmedResults.isEmpty &&
              _spiritualContext == null &&
              !_isLoading)
            _buildNoResultsCard(),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title,
          style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5)),
    );
  }

  // ── Karten ────────────────────────────────────────────────────────────────
  Widget _buildSpiritualCard() {
    return AnimatedBuilder(
      animation: _bgCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _purple.withValues(alpha: 0.35 + _bgCtrl.value * 0.08),
              _teal.withValues(alpha: 0.15),
              _gold.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: _purple.withValues(alpha: 0.4 + _bgCtrl.value * 0.1)),
          boxShadow: [
            BoxShadow(
              color: _purple.withValues(alpha: 0.18 + _bgCtrl.value * 0.07),
              blurRadius: 20,
            )
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('✨', style: TextStyle(fontSize: 22 + _bgCtrl.value * 3)),
            const SizedBox(width: 10),
            const Text('Spirituelle Bedeutung',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 10),
          Text(_spiritualContext!,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.6,
                  fontStyle: FontStyle.italic)),
        ]),
      ),
    );
  }

  Widget _buildBookCard(_BookResult book) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color(0xFFFFD54F).withValues(alpha: 0.12),
            border: Border.all(
                color: const Color(0xFFFFD54F).withValues(alpha: 0.3)),
          ),
          child:
              const Center(child: Text('📖', style: TextStyle(fontSize: 22))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(book.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text(
                '${book.author}${book.year != null ? "  ·  ${book.year}" : ""}',
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ]),
        ),
        if (book.openLibUrl.isNotEmpty)
          Icon(Icons.open_in_new,
              color: _gold.withValues(alpha: 0.5), size: 16),
      ]),
    );
  }

  Widget _buildWikiCard(_WikiResult wiki) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _teal.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _teal.withValues(alpha: 0.12),
              border: Border.all(color: _teal.withValues(alpha: 0.3)),
            ),
            child:
                const Center(child: Text('🌐', style: TextStyle(fontSize: 16))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(wiki.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis),
          ),
          Icon(Icons.open_in_new,
              color: _teal.withValues(alpha: 0.5), size: 14),
        ]),
        const SizedBox(height: 8),
        Text(wiki.extract,
            style: const TextStyle(
                color: Colors.white54, fontSize: 11, height: 1.5)),
      ]),
    );
  }

  Widget _buildPubMedCard(_PubMedResult study) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _purple.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: _purple.withValues(alpha: 0.12),
            border: Border.all(color: _purple.withValues(alpha: 0.3)),
          ),
          child:
              const Center(child: Text('🔬', style: TextStyle(fontSize: 20))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(study.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text('PubMed ID: ${study.pmid}',
                style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ]),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _purple.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _purple.withValues(alpha: 0.4)),
          ),
          child: const Text('Ansehen',
              style: TextStyle(
                  color: Color(0xFFCE93D8),
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  Widget _buildShimmerSection(String title) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(title,
            style: const TextStyle(
                color: Colors.white38,
                fontSize: 13,
                fontWeight: FontWeight.bold)),
      ),
      ...List.generate(2, (_) => _ShimmerCard()),
      const SizedBox(height: 16),
    ]);
  }

  Widget _buildErrorCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFB71C1C).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: const Color(0xFFEF5350).withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.wifi_off, color: Color(0xFFEF9A9A), size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(_error!,
              style: const TextStyle(color: Color(0xFFEF9A9A), fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _buildNoResultsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: const Column(children: [
        Text('🌌', style: TextStyle(fontSize: 40)),
        SizedBox(height: 12),
        Text('Keine Ergebnisse gefunden',
            style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.bold)),
        SizedBox(height: 6),
        Text('Versuche einen anderen Begriff aus den Vorschlägen',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 12)),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STERNENHIMMEL PAINTER
// ═══════════════════════════════════════════════════════════════════════════

class _Star {
  final double x;
  final double y;
  final double size;
  final double brightness;
  const _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.brightness,
  });
}

class _StarfieldPainter extends CustomPainter {
  final List<_Star> stars;
  final double twinkle;
  final Color primaryColor;
  final Color secondaryColor;

  const _StarfieldPainter({
    required this.stars,
    required this.twinkle,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Hintergrund
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF06040F),
    );

    // Ambient Orbs
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.15),
      160,
      Paint()
        ..color = primaryColor.withValues(alpha: 0.08 + twinkle * 0.03)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60),
    );
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.75),
      140,
      Paint()
        ..color = secondaryColor.withValues(alpha: 0.06 + twinkle * 0.02)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50),
    );

    // Sterne
    for (final star in stars) {
      final opacity = star.brightness * (0.4 + twinkle * 0.3 * star.brightness);
      final px = star.x * size.width;
      final py = star.y * size.height;
      canvas.drawCircle(
        Offset(px, py),
        star.size,
        Paint()..color = Colors.white.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_StarfieldPainter old) => old.twinkle != twinkle;
}

// ═══════════════════════════════════════════════════════════════════════════
// SHIMMER CARD
// ═══════════════════════════════════════════════════════════════════════════

class _ShimmerCard extends StatefulWidget {
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04 + _anim.value * 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    Colors.white.withValues(alpha: 0.06 + _anim.value * 0.03),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 10,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white
                          .withValues(alpha: 0.07 + _anim.value * 0.03),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 8,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.white
                          .withValues(alpha: 0.04 + _anim.value * 0.02),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ANIMIERTE KARTE (Fade + Slide)
// ═══════════════════════════════════════════════════════════════════════════

class _AnimatedCard extends StatefulWidget {
  final Widget child;
  final int delay;

  const _AnimatedCard({required this.child, this.delay = 0});

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
