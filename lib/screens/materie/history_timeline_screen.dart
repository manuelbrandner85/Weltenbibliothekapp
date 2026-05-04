import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../services/group_tools_service.dart';
import '../../services/user_service.dart';
import '../../services/free_api_service.dart';

/// GESCHICHTE-ZEITLEISTE — Community + Wikidata Live-Recherche + "Heute in der Geschichte"
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

  List<Map<String, dynamic>> _events = [];
  bool _isLoading = false;
  String _selectedCategory = 'all';

  // Wikidata
  List<WikidataEntry> _wikiResults = [];
  bool _loadingWiki = false;
  final _wikiCtrl = TextEditingController(text: 'Tartaria ancient civilization');
  String _wikiQuery = 'Tartaria ancient civilization';

  // Heute in der Geschichte
  List<Map<String, dynamic>> _todayEvents = [];
  bool _loadingToday = false;

  final Map<String, dynamic> _categories = {
    'all': {'name': 'Alle', 'color': Colors.white, 'icon': '📜'},
    'tartaria': {'name': 'Tartaria', 'color': Colors.amber, 'icon': '🏛️'},
    'ancient': {'name': 'Antike Hochkulturen', 'color': Colors.orange, 'icon': '⚱️'},
    'mudflood': {'name': 'Mud Flood', 'color': Colors.brown, 'icon': '🌊'},
    'reset': {'name': 'Zivilisations-Reset', 'color': Colors.red, 'icon': '🔄'},
    'artifacts': {'name': 'Unerklärliche Artefakte', 'color': Colors.purple, 'icon': '🗿'},
    'technology': {'name': 'Verlorene Technologie', 'color': Colors.blue, 'icon': '⚙️'},
  };

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadEvents();
    _loadWikidata();
    _loadOnThisDay();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _wikiCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final events = await _toolsService.getHistoryEvents(roomId: widget.roomId);
      if (mounted) {
        setState(() {
          _events = events;
          _events.sort((a, b) => (a['event_year'] ?? 0).compareTo(b['event_year'] ?? 0));
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
    setState(() { _loadingWiki = true; _wikiQuery = q; });
    final result = await _api.fetchWikidataEntries(q, limit: 15);
    if (mounted) setState(() { _wikiResults = result; _loadingWiki = false; });
  }

  Future<void> _loadOnThisDay() async {
    final now = DateTime.now();
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    setState(() => _loadingToday = true);
    try {
      final res = await http.get(
        Uri.parse('https://history.muffinlabs.com/date/$mm/$dd'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final events = (data['data']?['Events'] as List? ?? []);
        if (mounted) setState(() {
          _todayEvents = events
              .take(25)
              .map((e) => {
                    'year': int.tryParse(e['year']?.toString() ?? '') ?? 0,
                    'text': e['text'] as String? ?? '',
                  })
              .toList();
          _loadingToday = false;
        });
      } else {
        if (mounted) setState(() => _loadingToday = false);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('OnThisDay load: $e');
      if (mounted) setState(() => _loadingToday = false);
    }
  }

  List<Map<String, dynamic>> get _filteredEvents {
    if (_selectedCategory == 'all') return _events;
    return _events.where((e) => e['category'] == _selectedCategory).toList();
  }

  String get _todayLabel {
    final now = DateTime.now();
    const months = [
      '', 'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
      'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'
    ];
    return '${now.day}. ${months[now.month]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0505),
      appBar: _buildAppBar(),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildCommunityTab(),
          _buildWikidataTab(),
          _buildTodayTab(),
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A0D00), Color(0xFF0D0D1A)],
          ),
          border: Border(bottom: BorderSide(color: Color(0x33FFAB00), width: 1)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: kToolbarHeight,
                child: Row(
                  children: [
                    const SizedBox(width: 4),
                    BackButton(color: Colors.white70),
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
                tabs: [
                  const Tab(text: 'Community'),
                  const Tab(text: 'Wikidata'),
                  Tab(text: 'Heute'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab 1: Community Zeitleiste ──────────────────────────────────────────

  Widget _buildCommunityTab() {
    final filteredEvents = _filteredEvents;
    return Column(
      children: [
        // Kategorie-Filter
        Container(
          height: 60,
          color: const Color(0xFF0D0505),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            children: _categories.entries.map((entry) {
              final cat = entry.key;
              final data = entry.value;
              final isSelected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (data['color'] as Color).withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? data['color'] as Color
                            : Colors.white.withValues(alpha: 0.1),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(data['icon'] as String, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          data['name'] as String,
                          style: TextStyle(
                            color: isSelected ? data['color'] as Color : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
              ? const Center(child: CircularProgressIndicator(color: Colors.amber))
              : filteredEvents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.history_edu, size: 64, color: Colors.white24),
                          const SizedBox(height: 16),
                          const Text('Keine Ereignisse vorhanden',
                              style: TextStyle(color: Colors.white54, fontSize: 16)),
                          const SizedBox(height: 8),
                          const Text('Recherchiere Themen im "Wikidata"-Tab!',
                              style: TextStyle(color: Colors.white38, fontSize: 12)),
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
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredEvents.length,
                      cacheExtent: 200.0,
                      addAutomaticKeepAlives: false,
                      addRepaintBoundaries: true,
                      itemBuilder: (context, index) {
                        final event = filteredEvents[index];
                        final category = event['category'] ?? 'ancient';
                        final catData = _categories[category] ?? _categories['ancient']!;
                        final year = event['event_year'] ?? 0;
                        final yearString =
                            year < 0 ? '${(year as int).abs()} v. Chr.' : '$year n. Chr.';
                        return RepaintBoundary(
                          key: ValueKey(event['event_id']),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    Container(
                                      width: 40, height: 40,
                                      decoration: BoxDecoration(
                                        color: (catData['color'] as Color).withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: catData['color'] as Color, width: 2),
                                      ),
                                      child: Center(
                                        child: Text(catData['icon'] as String,
                                            style: const TextStyle(fontSize: 18)),
                                      ),
                                    ),
                                    if (index < filteredEvents.length - 1)
                                      Container(width: 2, height: 60,
                                          color: Colors.white.withValues(alpha: 0.1)),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.08)),
                                    ),
                                    child: Padding(
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
                                                  color: (catData['color'] as Color)
                                                      .withValues(alpha: 0.2),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  yearString,
                                                  style: TextStyle(
                                                    color: catData['color'] as Color,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                catData['name'] as String,
                                                style: TextStyle(
                                                    color: catData['color'] as Color, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            event['event_title'] ?? 'Unbekanntes Ereignis',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            event['event_description'] ?? '',
                                            style: const TextStyle(
                                                color: Colors.white70, fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  // ── Tab 2: Wikidata Recherche ────────────────────────────────────────────

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
                      Text('Durchsuche Wikidata…', style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                )
              : _wikiResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off, size: 48, color: Colors.white24),
                          const SizedBox(height: 12),
                          const Text('Keine Wikidata-Einträge',
                              style: TextStyle(color: Colors.white54)),
                          TextButton(
                            onPressed: () => _loadWikidata(),
                            child: const Text('Neu laden',
                                style: TextStyle(color: Colors.amber)),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadWikidata(),
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
      color: const Color(0xFF0D0505),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _wikiCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'z.B. Tartaria, Atlantis, Mud Flood…',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
                prefixIcon: const Icon(Icons.travel_explore, color: Colors.amber),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
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
                    style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                Text('${_wikiResults.length} Einträge für "$_wikiQuery" · Klick = Wikipedia',
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
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
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final uri = Uri.tryParse(entry.url);
          if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Center(child: Text('🏛️', style: TextStyle(fontSize: 18))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.label,
                      style: const TextStyle(
                          color: Colors.amber, fontWeight: FontWeight.w600),
                    ),
                    if (entry.description != null && entry.description!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        entry.description!,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 3),
                    Text(entry.id,
                        style: const TextStyle(color: Colors.white24, fontSize: 10)),
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

  // ── Tab 3: Heute in der Geschichte ──────────────────────────────────────

  Widget _buildTodayTab() {
    return Column(
      children: [
        // Header-Banner mit heutigem Datum
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.amber.withValues(alpha: 0.15), Colors.orange.withValues(alpha: 0.08)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Text('📅', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 14),
              Column(
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
              const Spacer(),
              if (!_loadingToday)
                Text(
                  '${_todayEvents.length}',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
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
                          const Icon(Icons.history, size: 48, color: Colors.white24),
                          const SizedBox(height: 12),
                          const Text('Keine Daten verfügbar',
                              style: TextStyle(color: Colors.white54)),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _loadOnThisDay,
                            child: const Text('Neu laden',
                                style: TextStyle(color: Colors.amber)),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadOnThisDay,
                      color: Colors.amber,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _todayEvents.length,
                        itemBuilder: (ctx, i) => _buildTodayCard(_todayEvents[i], i),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildTodayCard(Map<String, dynamic> event, int index) {
    final year = event['year'] as int;
    final text = event['text'] as String;

    // Jahres-Farbe je nach Epoche
    Color yearColor;
    if (year < 0) {
      yearColor = Colors.purple;
    } else if (year < 1000) {
      yearColor = Colors.blue;
    } else if (year < 1800) {
      yearColor = Colors.teal;
    } else if (year < 1950) {
      yearColor = Colors.amber;
    } else {
      yearColor = Colors.orange;
    }

    final yearLabel = year < 0 ? '${year.abs()} v. Chr.' : '$year';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Jahr-Badge prominent links
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: yearColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: yearColor.withValues(alpha: 0.4)),
              ),
              child: Text(
                yearLabel,
                style: TextStyle(
                  color: yearColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Dialog: Ereignis hinzufügen ──────────────────────────────────────────

  void _showAddEventDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final yearController = TextEditingController();
    String selectedCategory = 'tartaria';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Historisches Ereignis', style: TextStyle(color: Colors.amber)),
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
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Jahr (negativ für v. Chr.)',
                    labelStyle: TextStyle(color: Colors.white70),
                    hintText: 'z.B. -10000 oder 1850',
                    hintStyle: TextStyle(color: Colors.white30),
                  ),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Kategorie:', style: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.entries
                      .where((e) => e.key != 'all')
                      .map((entry) {
                    final isSelected = selectedCategory == entry.key;
                    return InkWell(
                      onTap: () => setDialogState(() => selectedCategory = entry.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (entry.value['color'] as Color).withValues(alpha: 0.3)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? entry.value['color'] as Color
                                : Colors.grey[700]!,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(entry.value['icon'] as String,
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 4),
                            Text(
                              entry.value['name'] as String,
                              style: TextStyle(
                                color: isSelected
                                    ? entry.value['color'] as Color
                                    : Colors.white70,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) return;
                Navigator.pop(context);
                try {
                  await _toolsService.createHistoryEvent(
                    roomId: widget.roomId,
                    userId: UserService.getCurrentUserId(),
                    username: 'Anonym',
                    title: titleController.text.trim(),
                    description: descController.text.trim(),
                    eventYear: int.tryParse(yearController.text.trim()) ?? 0,
                    category: selectedCategory,
                  );
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Ereignis hinzugefügt!'),
                        backgroundColor: Colors.green),
                  );
                  _loadEvents();
                } catch (e) {
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Fehler: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber, foregroundColor: Colors.black),
              child: const Text('Hinzufügen'),
            ),
          ],
        ),
      ),
    );
  }
}
