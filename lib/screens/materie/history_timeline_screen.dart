import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:timeline_tile/timeline_tile.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/free_api_service.dart';
import '../../services/group_tools_service.dart';
import '../../services/user_service.dart';

/// GESCHICHTE-ZEITLEISTE — 4 Tabs:
/// 1. Community (user-contributed events)
/// 2. Wikidata Recherche (live search)
/// 3. Heute in der Geschichte (timeline_tile)
/// 4. Zeitungsarchiv – Library of Congress Chronicling America
class HistoryTimelineScreen extends StatefulWidget {
  final String roomId;

  const HistoryTimelineScreen({super.key, required this.roomId});

  @override
  State<HistoryTimelineScreen> createState() => _HistoryTimelineScreenState();
}

class _HistoryTimelineScreenState extends State<HistoryTimelineScreen>
    with SingleTickerProviderStateMixin {
  final GroupToolsService _toolsService = GroupToolsService();
  final _api = FreeApiService.instance;

  late final TabController _tabCtrl;

  // ── Tab 1: Community ──────────────────────────────────────────────────────
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = false;
  String _selectedCategory = 'all';

  // ── Tab 2: Wikidata ───────────────────────────────────────────────────────
  List<WikidataEntry> _wikiResults = [];
  bool _loadingWiki = false;
  final _wikiCtrl = TextEditingController(text: 'Tartaria ancient civilization');
  String _wikiQuery = 'Tartaria ancient civilization';
  Timer? _wikiDebounce;

  // ── Tab 3: Heute in der Geschichte ───────────────────────────────────────
  List<Map<String, dynamic>> _todayEvents = [];
  bool _loadingToday = false;

  // ── Tab 4: Library of Congress Zeitungsarchiv ─────────────────────────────
  List<Map<String, dynamic>> _locItems = [];
  bool _loadingLoc = false;
  String _locError = '';
  final _locCtrl = TextEditingController(text: 'secret society government');
  String _locQuery = 'secret society government';
  int _locTotalItems = 0;

  static const _accent = Color(0xFFE53935);
  static const _bg = Color(0xFF0D0505);
  static const _surface = Color(0xFF1A0000);

  final Map<String, Map<String, dynamic>> _categories = {
    'all':        {'name': 'Alle',                  'color': Colors.white,    'icon': '📜'},
    'tartaria':   {'name': 'Tartaria',               'color': Colors.amber,    'icon': '🏛️'},
    'ancient':    {'name': 'Antike',                 'color': Colors.orange,   'icon': '⚱️'},
    'mudflood':   {'name': 'MudFlood',               'color': Color(0xFF8D6E63), 'icon': '🌊'},
    'reset':      {'name': 'Reset',                  'color': Colors.red,      'icon': '🔄'},
    'artifacts':  {'name': 'Artefakte',              'color': Colors.purple,   'icon': '🗿'},
    'technology': {'name': 'Technologie',            'color': Colors.blue,     'icon': '⚙️'},
  };

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _tabCtrl.addListener(_onTabChanged);
    _loadEvents();
    _loadWikidata();
    _loadOnThisDay();
    _loadLoc();
  }

  @override
  void dispose() {
    _tabCtrl.removeListener(_onTabChanged);
    _tabCtrl.dispose();
    _wikiCtrl.dispose();
    _locCtrl.dispose();
    _wikiDebounce?.cancel();
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final events = await _toolsService.getHistoryEvents(roomId: widget.roomId);
      if (mounted) {
        setState(() {
          _events = events;
          _events.sort((a, b) =>
              (a['event_year'] ?? 0).compareTo(b['event_year'] ?? 0));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('history load: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadWikidata([String? query]) async {
    final q = query ?? _wikiQuery;
    if (mounted) setState(() { _loadingWiki = true; _wikiQuery = q; });
    final result = await _api.fetchWikidataEntries(q, limit: 15);
    if (mounted) setState(() { _wikiResults = result; _loadingWiki = false; });
  }

  Future<void> _loadOnThisDay() async {
    final now = DateTime.now();
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    if (mounted) setState(() => _loadingToday = true);
    try {
      final res = await http.get(
        Uri.parse('https://history.muffinlabs.com/date/$mm/$dd'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final events = data['data']?['Events'] as List? ?? [];
        if (mounted) {
          setState(() {
            _todayEvents = events.take(40).map((e) => {
              'year': int.tryParse(e['year']?.toString() ?? '') ?? 0,
              'text': e['text'] as String? ?? '',
            }).toList();
            _loadingToday = false;
          });
        }
      } else {
        if (mounted) setState(() => _loadingToday = false);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('OnThisDay: $e');
      if (mounted) setState(() => _loadingToday = false);
    }
  }

  Future<void> _loadLoc([String? query]) async {
    final q = query ?? _locQuery;
    if (mounted) setState(() { _loadingLoc = true; _locError = ''; _locQuery = q; });
    try {
      final url = Uri.parse(
        'https://chroniclingamerica.loc.gov/search/pages/results/'
        '?andtext=${Uri.encodeQueryComponent(q)}&format=json',
      );
      final res = await http.get(
        url,
        headers: {'User-Agent': 'WeltenbibliothekApp/5.42'},
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final items = data['items'] as List? ?? [];
        final total = data['totalItems'] as int? ?? items.length;
        if (mounted) {
          setState(() {
            _locItems = items.take(30).map((item) {
              final m = item as Map<String, dynamic>;
              // Parse date "YYYYMMDD"
              DateTime? parsedDate;
              final rawDate = m['date'] as String?;
              if (rawDate != null && rawDate.length == 8) {
                try {
                  parsedDate = DateTime(
                    int.parse(rawDate.substring(0, 4)),
                    int.parse(rawDate.substring(4, 6)),
                    int.parse(rawDate.substring(6, 8)),
                  );
                } catch (_) {}
              }
              return {
                'title': m['title'] as String? ?? 'Unbekannte Zeitung',
                'date': parsedDate,
                'url': m['url'] as String? ?? '',
                'subjects': (m['subject'] as List?)?.cast<String>() ?? <String>[],
              };
            }).toList();
            _locTotalItems = total;
            _loadingLoc = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _locError = 'Server-Fehler ${res.statusCode}';
            _loadingLoc = false;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('LoC: $e');
      if (mounted) {
        setState(() {
          _locError = 'Netzwerkfehler. Bitte Verbindung prüfen.';
          _loadingLoc = false;
        });
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> get _filteredEvents {
    if (_selectedCategory == 'all') return _events;
    return _events.where((e) => e['category'] == _selectedCategory).toList();
  }

  Color _epochColor(int year) {
    if (year < 0)    return Colors.purple;
    if (year < 1000) return Colors.blue;
    if (year < 1800) return Colors.teal;
    if (year < 1950) return Colors.amber;
    return Colors.orange;
  }

  String get _todayLabel {
    final now = DateTime.now();
    const months = [
      '', 'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
      'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember',
    ];
    return '${now.day}. ${months[now.month]}';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildCommunityTab(),
          _buildWikidataTab(),
          _buildTodayTab(),
          _buildLocTab(),
        ],
      ),
      floatingActionButton: _tabCtrl.index == 0
          ? FloatingActionButton.extended(
              onPressed: _showAddEventDialog,
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.add),
              label: const Text('Ereignis'),
            )
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 48),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A0D00), Color(0xFF0D0D1A)],
          ),
          border: Border(
            bottom: BorderSide(color: Colors.amber.withValues(alpha: 0.2), width: 1),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: kToolbarHeight,
                child: Row(
                  children: [
                    const SizedBox(width: 4),
                    const BackButton(color: Colors.white70),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Geschichte-Zeitleiste',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Heute: $_todayLabel',
                            style: TextStyle(
                              color: Colors.amber.withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white70),
                      onPressed: () {
                        _loadEvents();
                        _loadWikidata();
                        _loadOnThisDay();
                        _loadLoc();
                      },
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabCtrl,
                indicatorColor: Colors.amber,
                indicatorWeight: 3,
                labelColor: Colors.amber,
                unselectedLabelColor: Colors.white54,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: const [
                  Tab(text: '📜 Community'),
                  Tab(text: '🏛️ Wikidata'),
                  Tab(text: '📅 Heute'),
                  Tab(text: '📰 Zeitungsarchiv'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 1 — COMMUNITY
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildCommunityTab() {
    final filtered = _filteredEvents;
    return Column(
      children: [
        // Kategorie-Filter-Chips
        Container(
          height: 60,
          color: _bg,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            children: _categories.entries.map((entry) {
              final cat  = entry.key;
              final data = entry.value;
              final isSelected = _selectedCategory == cat;
              final color = data['color'] as Color;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () => setState(() => _selectedCategory = cat),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? color
                            : Colors.white.withValues(alpha: 0.1),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(data['icon'] as String,
                            style: const TextStyle(fontSize: 15)),
                        const SizedBox(width: 6),
                        Text(
                          data['name'] as String,
                          style: TextStyle(
                            color: isSelected ? color : Colors.white70,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.amber))
              : filtered.isEmpty
                  ? _buildCommunityEmpty()
                  : RefreshIndicator(
                      onRefresh: _loadEvents,
                      color: Colors.amber,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) =>
                            _buildCommunityEventTile(filtered[i], i, filtered.length),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildCommunityEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history_edu, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          const Text('Keine Ereignisse vorhanden',
              style: TextStyle(color: Colors.white54, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Recherchiere im Wikidata-Tab oder füge eigene hinzu!',
              style: TextStyle(color: Colors.white38, fontSize: 12),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddEventDialog,
            icon: const Icon(Icons.add),
            label: const Text('Erstes Ereignis hinzufügen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityEventTile(
      Map<String, dynamic> event, int index, int total) {
    final category = event['category'] as String? ?? 'ancient';
    final catData = _categories[category] ?? _categories['ancient']!;
    final color = catData['color'] as Color;
    final year = event['event_year'] as int? ?? 0;
    final yearStr =
        year < 0 ? '${year.abs()} v. Chr.' : '$year n. Chr.';

    return RepaintBoundary(
      key: ValueKey(event['event_id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline indicator column
            Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Center(
                    child: Text(catData['icon'] as String,
                        style: const TextStyle(fontSize: 18)),
                  ),
                ),
                if (index < total - 1)
                  Container(
                    width: 2,
                    height: 70,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            // Event card
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08)),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            yearStr,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(catData['name'] as String,
                            style:
                                TextStyle(color: color, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event['event_title'] as String? ??
                          'Unbekanntes Ereignis',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      event['event_description'] as String? ?? '',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 2 — WIKIDATA
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildWikidataTab() {
    return Column(
      children: [
        _buildWikiSearchBar(),
        Expanded(
          child: _loadingWiki
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.amber),
                      SizedBox(height: 16),
                      Text('Durchsuche Wikidata…',
                          style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                )
              : _wikiResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off,
                              size: 48, color: Colors.white24),
                          const SizedBox(height: 12),
                          const Text('Keine Wikidata-Einträge',
                              style: TextStyle(color: Colors.white54)),
                          TextButton(
                            onPressed: _loadWikidata,
                            child: const Text('Neu laden',
                                style: TextStyle(color: Colors.amber)),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadWikidata,
                      color: Colors.amber,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _wikiResults.length + 1,
                        itemBuilder: (ctx, i) {
                          if (i == 0) return _buildWikiHeader();
                          return _buildWikiCard(_wikiResults[i - 1]);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildWikiSearchBar() {
    return Container(
      color: _bg,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _wikiCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'z.B. Tartaria, Atlantis, Mud Flood…',
                hintStyle:
                    const TextStyle(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Colors.amber, width: 1.5),
                ),
                prefixIcon: const Icon(Icons.travel_explore,
                    color: Colors.amber),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12),
              ),
              onChanged: (v) {
                _wikiDebounce?.cancel();
                _wikiDebounce = Timer(const Duration(milliseconds: 500),
                    () => _loadWikidata(v.trim()));
              },
              onSubmitted: (v) => _loadWikidata(v.trim()),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _loadWikidata(_wikiCtrl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Icon(Icons.search),
          ),
        ],
      ),
    );
  }

  Widget _buildWikiHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: Colors.amber.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Text('🌐', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Wikidata Wissens-Datenbank',
                    style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold)),
                Text(
                  '${_wikiResults.length} Einträge für "$_wikiQuery"',
                  style:
                      const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWikiCard(WikidataEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final uri = Uri.tryParse(entry.url);
          if (uri != null) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                    child: Text('🏛️', style: TextStyle(fontSize: 18))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.label,
                        style: const TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.w600)),
                    if (entry.description != null &&
                        entry.description!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        entry.description!,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(entry.id,
                        style: const TextStyle(
                            color: Colors.white24, fontSize: 10)),
                  ],
                ),
              ),
              const Icon(Icons.open_in_new, size: 14, color: Colors.amber),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 3 — HEUTE IN DER GESCHICHTE (timeline_tile)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildTodayTab() {
    return Column(
      children: [
        // Header-Banner
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.amber.withValues(alpha: 0.15),
                Colors.orange.withValues(alpha: 0.07),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: Colors.amber.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Text('📅', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Heute in der Geschichte',
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      _todayLabel,
                      style: TextStyle(
                        color: Colors.amber.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (!_loadingToday)
                Column(
                  children: [
                    Text(
                      '${_todayEvents.length}',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('Ereignisse',
                        style:
                            TextStyle(color: Colors.white38, fontSize: 10)),
                  ],
                ),
            ],
          ),
        ),
        // Epoche-Legende
        if (_todayEvents.isNotEmpty) _buildEpochLegend(),
        // Timeline
        Expanded(
          child: _loadingToday
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.amber),
                      SizedBox(height: 16),
                      Text('Lade historische Ereignisse…',
                          style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                )
              : _todayEvents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.history,
                              size: 48, color: Colors.white24),
                          const SizedBox(height: 12),
                          const Text('Keine Daten verfügbar',
                              style: TextStyle(color: Colors.white54)),
                          TextButton(
                            onPressed: _loadOnThisDay,
                            child: const Text('Neu laden',
                                style:
                                    TextStyle(color: Colors.amber)),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadOnThisDay,
                      color: Colors.amber,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(0, 4, 12, 24),
                        itemCount: _todayEvents.length,
                        itemBuilder: (ctx, i) =>
                            _buildTimelineTile(_todayEvents[i], i),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildEpochLegend() {
    final epochs = [
      {'label': 'Vorzeit', 'color': Colors.purple},
      {'label': 'Antike', 'color': Colors.blue},
      {'label': 'Mittelalter', 'color': Colors.teal},
      {'label': 'Neuzeit', 'color': Colors.amber},
      {'label': 'Modern', 'color': Colors.orange},
    ];
    return Container(
      height: 36,
      margin: const EdgeInsets.only(bottom: 4),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: epochs.map((e) {
          final color = e['color'] as Color;
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: color, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text(e['label'] as String,
                    style: TextStyle(color: color, fontSize: 11)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimelineTile(Map<String, dynamic> event, int i) {
    final year = event['year'] as int;
    final text = event['text'] as String;
    final color = _epochColor(year);
    final isFirst = i == 0;
    final isLast = i == _todayEvents.length - 1;

    final yearLabel = year < 0 ? '${year.abs()}\nv.Chr.' : '$year';

    return TimelineTile(
      axis: TimelineAxis.vertical,
      alignment: TimelineAlign.start,
      isFirst: isFirst,
      isLast: isLast,
      indicatorStyle: IndicatorStyle(
        width: 18,
        height: 18,
        color: color,
        padding: const EdgeInsets.all(2),
        indicator: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.25),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
        ),
      ),
      afterLineStyle: LineStyle(
        color: color.withValues(alpha: 0.25),
        thickness: 2,
      ),
      beforeLineStyle: LineStyle(
        color: color.withValues(alpha: 0.25),
        thickness: 2,
      ),
      startChild: Container(
        width: 64,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Text(
          yearLabel,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
          textAlign: TextAlign.center,
          maxLines: 3,
        ),
      ),
      endChild: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 4 — LIBRARY OF CONGRESS ZEITUNGSARCHIV
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildLocTab() {
    return Column(
      children: [
        _buildLocSearchBar(),
        _buildLocStatsBanner(),
        Expanded(
          child: _loadingLoc
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: _accent),
                      SizedBox(height: 16),
                      Text('Durchsuche historische Zeitungen…',
                          style: TextStyle(color: Colors.white54)),
                      SizedBox(height: 8),
                      Text('Library of Congress · 1770–1963',
                          style: TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                )
              : _locError.isNotEmpty
                  ? _buildLocError()
                  : _locItems.isEmpty
                      ? _buildLocEmpty()
                      : RefreshIndicator(
                          onRefresh: _loadLoc,
                          color: _accent,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                            itemCount: _locItems.length,
                            itemBuilder: (ctx, i) =>
                                _buildLocCard(_locItems[i]),
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildLocSearchBar() {
    return Container(
      color: _bg,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _locCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'z.B. secret society, government, war…',
                hintStyle:
                    const TextStyle(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: _accent, width: 1.5),
                ),
                prefixIcon:
                    const Icon(Icons.newspaper, color: _accent),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12),
              ),
              onSubmitted: (v) {
                final q = v.trim();
                if (q.isNotEmpty) _loadLoc(q);
              },
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              final q = _locCtrl.text.trim();
              if (q.isNotEmpty) _loadLoc(q);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Icon(Icons.search),
          ),
        ],
      ),
    );
  }

  Widget _buildLocStatsBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Text('🗞️', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _locTotalItems > 0
                  ? '$_locTotalItems historische Zeitungsseiten (1770–1963)'
                  : 'Library of Congress · Chronicling America',
              style: TextStyle(
                color: _accent.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (!_loadingLoc && _locItems.isNotEmpty)
            Text('${_locItems.length} Treffer',
                style: const TextStyle(
                    color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildLocError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.white24),
            const SizedBox(height: 12),
            Text(_locError,
                style: const TextStyle(color: Colors.white54),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadLoc,
              icon: const Icon(Icons.refresh),
              label: const Text('Erneut versuchen'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.find_in_page,
              size: 48, color: Colors.white24),
          const SizedBox(height: 12),
          const Text('Keine Zeitungsseiten gefunden',
              style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 8),
          const Text('Versuche andere Suchbegriffe',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadLoc,
            icon: const Icon(Icons.refresh),
            label: const Text('Neu laden'),
            style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildLocCard(Map<String, dynamic> item) {
    final title = item['title'] as String;
    final date = item['date'] as DateTime?;
    final url = item['url'] as String;
    final subjects = item['subjects'] as List<String>;

    String dateStr = 'Datum unbekannt';
    if (date != null) {
      const months = [
        '', 'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
        'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez',
      ];
      dateStr = '${date.day}. ${months[date.month]} ${date.year}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent.withValues(alpha: 0.12)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          if (url.isEmpty) return;
          final uri = Uri.tryParse(
            url.startsWith('http') ? url : 'https://chroniclingamerica.loc.gov$url',
          );
          if (uri != null) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + date row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                        child:
                            Text('📰', style: TextStyle(fontSize: 18))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.calendar_today,
                                size: 11,
                                color: _accent.withValues(alpha: 0.7)),
                            const SizedBox(width: 4),
                            Text(
                              dateStr,
                              style: TextStyle(
                                color: _accent.withValues(alpha: 0.8),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.open_in_new,
                      size: 14, color: Colors.white38),
                ],
              ),
              // Subject chips
              if (subjects.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: subjects.take(4).map((s) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Text(
                        s,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                ),
              ],
              // "Öffnen" button
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () async {
                    if (url.isEmpty) return;
                    final uri = Uri.tryParse(
                      url.startsWith('http')
                          ? url
                          : 'https://chroniclingamerica.loc.gov$url',
                    );
                    if (uri != null) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.article_outlined,
                      size: 14, color: _accent),
                  label: const Text('Öffnen',
                      style: TextStyle(color: _accent, fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    backgroundColor: _accent.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DIALOG — EREIGNIS HINZUFÜGEN
  // ══════════════════════════════════════════════════════════════════════════

  void _showAddEventDialog() {
    final titleController = TextEditingController();
    final descController  = TextEditingController();
    final yearController  = TextEditingController();
    String selectedCategory = 'tartaria';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Text('Historisches Ereignis',
              style: TextStyle(color: Colors.amber)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Ereignis-Titel',
                    labelStyle: TextStyle(color: Colors.white70),
                    hintText: 'z.B. Tartaria Hauptstadt entdeckt',
                    hintStyle: TextStyle(color: Colors.white30),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: yearController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: const TextInputType.numberWithOptions(
                      signed: true),
                  decoration: const InputDecoration(
                    labelText: 'Jahr (negativ = v. Chr.)',
                    labelStyle: TextStyle(color: Colors.white70),
                    hintText: 'z.B. -10000 oder 1850',
                    hintStyle: TextStyle(color: Colors.white30),
                  ),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Kategorie:',
                      style: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.entries
                      .where((e) => e.key != 'all')
                      .map((entry) {
                    final isSelected = selectedCategory == entry.key;
                    final color = entry.value['color'] as Color;
                    return InkWell(
                      onTap: () => setDialogState(
                          () => selectedCategory = entry.key),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withValues(alpha: 0.25)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? color
                                : Colors.grey[700]!,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(entry.value['icon'] as String,
                                style: const TextStyle(fontSize: 15)),
                            const SizedBox(width: 4),
                            Text(
                              entry.value['name'] as String,
                              style: TextStyle(
                                color: isSelected
                                    ? color
                                    : Colors.white70,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Beschreibung',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen',
                  style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                if (titleController.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await _toolsService.createHistoryEvent(
                    roomId: widget.roomId,
                    userId: UserService.getCurrentUserId(),
                    username: UserService.getCurrentUsername(),
                    title: titleController.text.trim(),
                    description: descController.text.trim(),
                    eventYear:
                        int.tryParse(yearController.text.trim()) ?? 0,
                    category: selectedCategory,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ereignis hinzugefügt!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                  _loadEvents();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Fehler: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Hinzufügen'),
            ),
          ],
        ),
      ),
    );
  }
}
