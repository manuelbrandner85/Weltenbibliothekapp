// Event-Predictor (R4): 4 Tabs - Klassik (hardcoded Fallback), Live-
// Indikatoren (GDELT/USGS/DONKI/Guardian), Community-Voting
// (prediction_votes-Tabelle), Archiv (prediction_outcomes verifiziert).

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/free_api_service.dart';
import '../../services/supabase_service.dart';

class EventPredictorScreen extends StatefulWidget {
  const EventPredictorScreen({super.key});

  @override
  State<EventPredictorScreen> createState() => _EventPredictorScreenState();
}

class _EventPredictorScreenState extends State<EventPredictorScreen>
    with SingleTickerProviderStateMixin {
  static const _accent = Color(0xFF2196F3);
  static const _bg = Color(0xFF0A0A0A);

  late final TabController _tab;
  final _searchController = TextEditingController();
  String _selectedCategory = 'all';

  List<Map<String, dynamic>>? _predictions;
  List<Map<String, dynamic>>? _filteredPredictions;
  bool _isLoading = false;

  // Hardcoded fallback predictions (gekuerzt vs Original).
  final Map<String, List<Map<String, dynamic>>> _predictionDatabase = {
    'economy': [
      {
        'id': 'wirtschaftskrise-2025',
        'title': 'Globale Wirtschaftskrise 2025',
        'probability': 68,
        'timeframe': '2025-Q2',
        'category': 'economy',
        'patterns': ['Aehnlich 2008', 'Schuldenblase', 'Inflation 1970er'],
        'indicators': [
          'Inflation >7% in Industrielaendern',
          'Zentralbanken Zinsen 5%+',
          'Aktienmarkt -20% Korrekturen',
          'Immobilienpreise fallen US/EU'
        ],
        'description':
            'Historische Schuldenblasen fuehren zu Finanzkrisen. Aktuelle Zinspolitik verschaerft Spannungen.',
        'alternativePerspektive':
            'Mainstream verschweigt: Fiat-Geldsystem am Ende. Bitcoin & Edelmetalle als Schutz.',
      },
      {
        'id': 'euro-krise-2',
        'title': 'Euro-Krise 2.0',
        'probability': 55,
        'timeframe': '2025-2026',
        'category': 'economy',
        'patterns': ['Euro-Krise 2011-2013', 'Staatsschuldenkrise'],
        'indicators': [
          'Italien Schuldenquote >150%',
          'EZB Bondaufkaeufe steigen',
          'Sued-Nord-Spreads ausweiten',
        ],
        'description':
            'Strukturprobleme der Eurozone ungeloest. Suedlaender-Schulden nicht tragfaehig.',
        'alternativePerspektive':
            'EU-Zentralisierung gescheitert. Dezentrale Loesungen noetig.',
      },
      {
        'id': 'brics-currency',
        'title': 'BRICS-Waehrung Launch',
        'probability': 42,
        'timeframe': '2024-2025',
        'category': 'economy',
        'patterns': ['Petrodollar Ende', 'Goldrueckdeckung'],
        'indicators': [
          'Russland/China Handel in Yuan',
          'Goldreserven BRICS steigen',
          'De-Dollarisierung beschleunigt',
        ],
        'description':
            'BRICS-Staaten arbeiten an Dollar-Alternative. Gold-gedeckte Waehrung geplant.',
        'alternativePerspektive':
            'Multipolare Weltordnung entsteht. Dollar-Hegemonie endet.',
      },
    ],
    'politics': [
      {
        'id': 'geo-eskalation',
        'title': 'Geopolitische Eskalation Europa',
        'probability': 72,
        'timeframe': '2024-2025',
        'category': 'politics',
        'patterns': ['Kalter Krieg', 'Balkan 1990er'],
        'indicators': [
          'NATO-Russland Spannungen maximal',
          'Militaerausgaben steigen EU >2%',
          'Wehrpflicht-Diskussionen',
        ],
        'description':
            'Militarisierung fuehrt historisch zu Konflikten. Rhetorik verschaerft sich.',
        'alternativePerspektive':
            'Waffenlobby profitiert. Friedensbewegung totgeschwiegen.',
      },
      {
        'id': 'eu-fragmentierung',
        'title': 'EU-Fragmentierung',
        'probability': 58,
        'timeframe': '2025-2027',
        'category': 'politics',
        'patterns': ['Brexit 2016', 'Sowjetunion Zerfall'],
        'indicators': [
          'Rechtspopulisten staerker',
          'EU-Kritik steigt',
          'Bruessel-Distanz waechst',
        ],
        'description':
            'Zentrifugale Kraefte in EU staerker. Mitgliedstaaten wollen Souveraenitaet.',
        'alternativePerspektive':
            'Demokratiedefizit EU nicht loesbar. Dezentralisierung ist Zukunft.',
      },
    ],
    'technology': [
      {
        'id': 'ki-arbeitsmarkt',
        'title': 'KI ersetzt 30% der Buerojobs',
        'probability': 65,
        'timeframe': '2025-2027',
        'category': 'technology',
        'patterns': ['Industrielle Revolution', 'Automatisierung'],
        'indicators': [
          'GPT-Modelle uebernehmen Texte',
          'Junior-Jobs verschwinden',
          'Entlassungswellen Tech',
        ],
        'description':
            'KI-Modelle ersetzen Routine-Buerojobs schneller als erwartet.',
        'alternativePerspektive':
            'Tech-Konzerne profitieren. Soziale Spaltung verschaerft.',
      },
    ],
    'society': [
      {
        'id': 'zensur-infrastruktur',
        'title': 'Globale Zensur-Infrastruktur',
        'probability': 75,
        'timeframe': '2024-2026',
        'category': 'society',
        'patterns': ['DSA EU', 'Plattform-Regulierung'],
        'indicators': [
          'DSA EU Durchsetzung',
          'Algorithmische Moderation Standard',
          'Bewegungsprofile Standard',
        ],
        'description':
            'Technologie ermoeglicht totalitaere Ueberwachung. Privatsphaere verschwindet.',
        'alternativePerspektive':
            'Social-Credit-System nach chinesischem Vorbild geplant.',
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _loadAllPredictions();
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadAllPredictions() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 300), () {
      final all = <Map<String, dynamic>>[];
      _predictionDatabase.forEach((_, list) => all.addAll(list));
      all.sort((a, b) =>
          (b['probability'] as int).compareTo(a['probability'] as int));
      if (!mounted) return;
      setState(() {
        _predictions = all;
        _filteredPredictions = all;
        _isLoading = false;
      });
    });
  }

  void _searchPredictions(String query) {
    if (_predictions == null) return;
    setState(() {
      if (query.isEmpty) {
        _filteredPredictions = _predictions;
      } else {
        final q = query.toLowerCase();
        _filteredPredictions = _predictions!.where((p) {
          return (p['title'] as String).toLowerCase().contains(q) ||
              (p['description'] as String).toLowerCase().contains(q);
        }).toList();
      }
      if (_selectedCategory != 'all') {
        _filteredPredictions = _filteredPredictions!
            .where((p) => p['category'] == _selectedCategory)
            .toList();
      }
    });
  }

  void _filterByCategory(String c) {
    setState(() => _selectedCategory = c);
    _searchPredictions(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        elevation: 0,
        title: const Text('EVENT PREDICTOR',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2)),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          indicatorColor: const Color(0xFFE91E63),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
          tabs: const [
            Tab(text: 'KLASSIK'),
            Tab(text: 'LIVE'),
            Tab(text: 'COMMUNITY'),
            Tab(text: 'ARCHIV'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF1A1A1A), Color(0xFF000000)],
          ),
        ),
        child: TabBarView(
          controller: _tab,
          children: [
            _buildKlassikTab(),
            const _LiveIndicatorsTab(),
            const _CommunityVotingTab(),
            const _ArchivTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildKlassikTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Thema suchen ...',
                hintStyle: TextStyle(color: Colors.white38),
                prefixIcon: Icon(Icons.search, color: Colors.white54),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(14),
              ),
              onChanged: _searchPredictions,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _categoryChip('all', 'Alle', Icons.grid_view),
              _categoryChip('economy', 'Wirtschaft', Icons.attach_money),
              _categoryChip('politics', 'Politik', Icons.gavel),
              _categoryChip('technology', 'Technologie', Icons.computer),
              _categoryChip('society', 'Gesellschaft', Icons.groups),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: _accent))
              : (_filteredPredictions?.isEmpty ?? true)
                  ? Center(
                      child: Text('Keine Vorhersagen gefunden',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5))),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredPredictions!.length,
                      itemBuilder: (_, i) =>
                          _predictionCard(_filteredPredictions![i]),
                    ),
        ),
      ],
    );
  }

  Widget _categoryChip(String c, String label, IconData icon) {
    final sel = _selectedCategory == c;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: sel,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14, color: sel ? Colors.white : Colors.white70),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        onSelected: (_) => _filterByCategory(c),
        backgroundColor: Colors.white.withValues(alpha: 0.05),
        selectedColor: _accent,
        labelStyle: TextStyle(
            color: sel ? Colors.white : Colors.white70,
            fontSize: 11,
            fontWeight: sel ? FontWeight.bold : FontWeight.normal),
        side: BorderSide(
            color: sel ? _accent : Colors.white.withValues(alpha: 0.2)),
      ),
    );
  }

  Widget _predictionCard(Map<String, dynamic> pred) {
    final p = pred['probability'] as int;
    final Color color = p > 70
        ? const Color(0xFFF44336)
        : p > 50
            ? const Color(0xFFFF9800)
            : p > 30
                ? const Color(0xFFFFC107)
                : const Color(0xFF4CAF50);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.1)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(pred['title'],
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$p%',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.access_time,
                  color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Text(pred['timeframe'],
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Text(pred['description'],
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, height: 1.5)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE91E63).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: const Color(0xFFE91E63).withValues(alpha: 0.5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.remove_red_eye,
                    color: Color(0xFFE91E63), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ALTERNATIVE PERSPEKTIVE',
                          style: TextStyle(
                              color: Color(0xFFE91E63),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Text(pred['alternativePerspektive'],
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: (pred['patterns'] as List<String>)
                .map((p) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(p,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 10)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 10),
          ...(pred['indicators'] as List<String>).map((i) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.trending_up, color: color, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(i,
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              height: 1.4)),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton.icon(
                icon: const Icon(Icons.psychology, size: 14),
                label: const Text('KI-Analyse'),
                style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFE91E63),
                    padding: const EdgeInsets.symmetric(horizontal: 8)),
                onPressed: () => _showAiAnalysis(pred, color),
              ),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.thumb_up_alt_outlined, size: 14),
                label: const Text('Voten'),
                style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(horizontal: 8)),
                onPressed: () => _voteForPrediction(pred),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAiAnalysis(Map<String, dynamic> pred, Color color) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(pred['title'],
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Synthese aus Mustern und Indikatoren:',
              style:
                  TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Text(
              '${pred['description']}\n\n'
              'Treiber: ${(pred['indicators'] as List).take(2).join("; ")}.\n'
              'Historische Parallelen: ${(pred['patterns'] as List).join(", ")}.\n\n'
              'Konfidenz: ${pred['probability']}% bis ${pred['timeframe']}.',
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                border:
                    Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Hinweis: Heuristische Analyse, keine Anlage- oder Politikberatung.',
                style: TextStyle(color: Colors.amber, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _voteForPrediction(Map<String, dynamic> pred) async {
    try {
      final client = supabase;
      await client.from('prediction_votes').insert({
        'prediction_id': pred['id'],
        'vote': 1,
        'user_id': client.auth.currentUser?.id,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vote registriert'),
            backgroundColor: Color(0xFF2196F3)),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('vote err: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vote derzeit nicht moeglich')),
      );
    }
  }
}

// ─── LIVE-INDIKATOREN-TAB ────────────────────────────────────────────────────

class _LiveIndicatorsTab extends StatefulWidget {
  const _LiveIndicatorsTab();

  @override
  State<_LiveIndicatorsTab> createState() => _LiveIndicatorsTabState();
}

class _LiveIndicatorsTabState extends State<_LiveIndicatorsTab>
    with SingleTickerProviderStateMixin {
  static const _accent = Color(0xFF2196F3);

  late final TabController _sub;
  final _api = FreeApiService.instance;

  List<GdeltArticle> _gdelt = [];
  List<Earthquake> _quakes = [];
  List<DonkiEvent> _donki = [];
  List<GuardianArticle> _news = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _sub = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _sub.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait<dynamic>([
      _api.fetchGdeltEvents(query: 'crisis OR election OR conflict')
          .catchError((_) => <GdeltArticle>[]),
      _api.fetchEarthquakes(period: 'week').catchError((_) => <Earthquake>[]),
      _api.fetchDonkiEvents(daysBack: 7).catchError((_) => <DonkiEvent>[]),
      _api.fetchGuardianNews('forecast', limit: 10)
          .catchError((_) => <GuardianArticle>[]),
    ]);
    if (!mounted) return;
    setState(() {
      _gdelt = (results[0] as List).cast<GdeltArticle>();
      _quakes = (results[1] as List).cast<Earthquake>();
      _donki = (results[2] as List).cast<DonkiEvent>();
      _news = (results[3] as List).cast<GuardianArticle>();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.black54,
          child: TabBar(
            controller: _sub,
            indicatorColor: _accent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            isScrollable: true,
            labelStyle:
                const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'GDELT (${_gdelt.length})'),
              Tab(text: 'BEBEN (${_quakes.length})'),
              Tab(text: 'SONNE (${_donki.length})'),
              Tab(text: 'GUARDIAN (${_news.length})'),
            ],
          ),
        ),
        if (_loading) const LinearProgressIndicator(color: _accent),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            color: _accent,
            child: TabBarView(
              controller: _sub,
              children: [
                _gdeltList(),
                _quakeList(),
                _donkiList(),
                _newsList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _gdeltList() {
    if (_gdelt.isEmpty) return _empty('Keine GDELT-Daten.');
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _gdelt.length,
      itemBuilder: (_, i) {
        final a = _gdelt[i];
        return _tile(
            title: a.title,
            subtitle: '${a.domain} - ${a.seendate}',
            url: a.url,
            icon: Icons.public,
            color: Colors.orange);
      },
    );
  }

  Widget _quakeList() {
    if (_quakes.isEmpty) return _empty('Keine signifikanten Beben.');
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _quakes.length,
      itemBuilder: (_, i) {
        final q = _quakes[i];
        return _tile(
            title: '${q.magnitudeLabel} M${q.magnitude.toStringAsFixed(1)}',
            subtitle: '${q.place} - ${q.time.toIso8601String().substring(0, 16)}',
            url: q.url,
            icon: Icons.terrain,
            color: q.magnitude >= 7
                ? Colors.red
                : q.magnitude >= 6
                    ? Colors.orange
                    : Colors.yellow);
      },
    );
  }

  Widget _donkiList() {
    if (_donki.isEmpty) return _empty('Keine Weltraumwetter-Events.');
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _donki.length,
      itemBuilder: (_, i) {
        final e = _donki[i];
        return _tile(
            title: e.activityId ?? 'Solar Event',
            subtitle: '${e.startTime ?? ""} - ${e.instruments.join(", ")}',
            url: e.link,
            icon: Icons.wb_sunny,
            color: Colors.amber);
      },
    );
  }

  Widget _newsList() {
    if (_news.isEmpty) return _empty('Keine Guardian-Artikel.');
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _news.length,
      itemBuilder: (_, i) {
        final a = _news[i];
        final date = a.webPublicationDate;
        return _tile(
            title: a.webTitle,
            subtitle:
                '${a.sectionName ?? ""} - ${date != null && date.length >= 10 ? date.substring(0, 10) : ""}',
            url: a.webUrl,
            icon: Icons.article,
            color: Colors.cyan);
      },
    );
  }

  Widget _tile({
    required String title,
    required String subtitle,
    required String? url,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title,
            style: const TextStyle(color: Colors.white, fontSize: 13)),
        subtitle: Text(subtitle,
            style:
                const TextStyle(color: Colors.white60, fontSize: 11)),
        trailing: url == null
            ? null
            : const Icon(Icons.open_in_new,
                color: Colors.white38, size: 16),
        onTap: url == null
            ? null
            : () async {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri,
                      mode: LaunchMode.externalApplication);
                }
              },
      ),
    );
  }

  Widget _empty(String msg) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(msg,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
        ),
      );
}

// ─── COMMUNITY-VOTING-TAB ────────────────────────────────────────────────────

class _CommunityVotingTab extends StatefulWidget {
  const _CommunityVotingTab();

  @override
  State<_CommunityVotingTab> createState() => _CommunityVotingTabState();
}

class _CommunityVotingTabState extends State<_CommunityVotingTab> {
  List<Map<String, dynamic>> _ranks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final client = supabase;
      final res = await client
          .from('prediction_votes')
          .select('prediction_id, vote')
          .limit(500);
      final Map<String, int> tally = {};
      for (final row in res as List) {
        final m = Map<String, dynamic>.from(row as Map);
        final id = m['prediction_id'] as String? ?? '';
        final v = (m['vote'] as num?)?.toInt() ?? 0;
        if (id.isEmpty) continue;
        tally[id] = (tally[id] ?? 0) + v;
      }
      final ranks = tally.entries
          .map((e) => {'id': e.key, 'score': e.value})
          .toList()
        ..sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
      if (!mounted) return;
      setState(() {
        _ranks = ranks;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _ranks = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF2196F3)));
    }
    if (_ranks.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        color: const Color(0xFF2196F3),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Column(
                children: [
                  Icon(Icons.how_to_vote_outlined,
                      color: Colors.white.withValues(alpha: 0.3), size: 64),
                  const SizedBox(height: 12),
                  Text('Noch keine Votes.',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 14)),
                  const SizedBox(height: 6),
                  Text('Stimme im Klassik-Tab fuer eine Vorhersage ab.',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF2196F3),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _ranks.length,
        itemBuilder: (_, i) {
          final r = _ranks[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFF2196F3).withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2196F3),
                    shape: BoxShape.circle,
                  ),
                  child: Text('${i + 1}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(r['id'] as String,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('+${r['score']}',
                      style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── ARCHIV-TAB ──────────────────────────────────────────────────────────────

class _ArchivTab extends StatefulWidget {
  const _ArchivTab();

  @override
  State<_ArchivTab> createState() => _ArchivTabState();
}

class _ArchivTabState extends State<_ArchivTab> {
  List<Map<String, dynamic>> _outcomes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final client = supabase;
      final res = await client
          .from('prediction_outcomes')
          .select()
          .order('resolved_at', ascending: false)
          .limit(50);
      if (!mounted) return;
      setState(() {
        _outcomes =
            (res as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _outcomes = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF2196F3)));
    }
    if (_outcomes.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        color: const Color(0xFF2196F3),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Column(
                children: [
                  Icon(Icons.archive_outlined,
                      color: Colors.white.withValues(alpha: 0.3), size: 64),
                  const SizedBox(height: 12),
                  Text('Noch keine aufgeloeste Vorhersagen.',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF2196F3),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _outcomes.length,
        itemBuilder: (_, i) {
          final o = _outcomes[i];
          final correct = o['was_correct'] == true;
          final color = correct ? Colors.green : Colors.red;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(correct ? Icons.check_circle : Icons.cancel,
                        color: color, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        o['prediction_id'] as String? ?? '',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(o['resolved_at']?.toString().substring(0, 10) ?? '',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11)),
                  ],
                ),
                if (o['notes'] != null) ...[
                  const SizedBox(height: 6),
                  Text(o['notes'].toString(),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
