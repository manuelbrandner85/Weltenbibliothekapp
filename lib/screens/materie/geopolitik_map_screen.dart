import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:url_launcher/url_launcher.dart';
import '../../services/group_tools_service.dart';
import '../../services/user_service.dart';
import '../../services/free_api_service.dart';

/// GEOPOLITIK-KARTIERUNG SCREEN
/// Eigene Ereignisse + Live-Daten von GDELT (Weltpolitik) & USGS (Erdbeben)
class GeopolitikMapScreen extends StatefulWidget {
  final String roomId;

  const GeopolitikMapScreen({super.key, required this.roomId});

  @override
  State<GeopolitikMapScreen> createState() => _GeopolitikMapScreenState();
}

class _GeopolitikMapScreenState extends State<GeopolitikMapScreen>
    with SingleTickerProviderStateMixin {
  final GroupToolsService _toolsService = GroupToolsService();
  final _api = FreeApiService.instance;

  late final TabController _tabCtrl;

  List<Map<String, dynamic>> _ownEvents = [];
  List<GdeltArticle> _gdeltEvents = [];
  List<Earthquake> _earthquakes = [];

  bool _loadingOwn = false;
  bool _loadingGdelt = false;
  bool _loadingUsgs = false;

  // GDELT Suche & Filter
  final _searchCtrl = TextEditingController(text: 'geopolitics conflict');
  String _activeFilter = 'Alle';

  static const _accentRed = Color(0xFFE53935);

  static const _filters = <String, String>{
    'Alle': 'geopolitics conflict crisis war protest',
    'Krieg': 'war military conflict armed battle',
    'Politik': 'politics election government parliament democracy',
    'Wirtschaft': 'economy trade sanctions finance currency inflation',
    'Klima': 'climate change environment disaster flood earthquake',
  };

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
    _loadAll();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _loadAll() {
    _loadOwnEvents();
    _loadGdelt();
    _loadUsgs();
  }

  Future<void> _loadOwnEvents() async {
    setState(() => _loadingOwn = true);
    try {
      final events = await _toolsService.getGeopoliticsEvents(roomId: widget.roomId);
      if (mounted) setState(() { _ownEvents = events; _loadingOwn = false; });
    } catch (e) {
      if (kDebugMode) debugPrint('Own events: $e');
      if (mounted) setState(() => _loadingOwn = false);
    }
  }

  Future<void> _loadGdelt([String? query]) async {
    setState(() => _loadingGdelt = true);
    final q = query ?? _filters[_activeFilter] ?? _filters['Alle']!;
    final result = await _api.fetchGdeltEvents(query: q, limit: 25);
    if (mounted) setState(() { _gdeltEvents = result; _loadingGdelt = false; });
  }

  Future<void> _loadUsgs() async {
    setState(() => _loadingUsgs = true);
    final result = await _api.fetchEarthquakes();
    if (mounted) setState(() { _earthquakes = result; _loadingUsgs = false; });
  }

  void _applyFilter(String filter) {
    if (_activeFilter == filter) return;
    setState(() => _activeFilter = filter);
    _loadGdelt(_filters[filter]);
  }

  void _applySearch(String query) {
    if (query.trim().isNotEmpty) {
      _loadGdelt(query.trim());
    }
  }

  void _showAddDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Geopolitisches Ereignis', style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Titel',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descCtrl,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Beschreibung',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              try {
                await _toolsService.createGeopoliticsEvent(
                  roomId: widget.roomId,
                  userId: UserService.getCurrentUserId(),
                  username: UserService.getCurrentUserId() != 'user_anonymous'
                      ? UserService.getCurrentUserId()
                      : 'Anonym',
                  title: titleCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                );
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ereignis hinzugefügt!'), backgroundColor: Colors.green),
                );
                _loadOwnEvents();
              } catch (e) {
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Hinzufügen'),
          ),
        ],
      ),
    ).whenComplete(() {
      titleCtrl.dispose();
      descCtrl.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0505),
      appBar: _buildAppBar(),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildOwnTab(),
          _buildGdeltTab(),
          _buildUsgsTab(),
        ],
      ),
      floatingActionButton: _tabCtrl.index == 0
          ? FloatingActionButton(
              onPressed: _showAddDialog,
              backgroundColor: _accentRed,
              child: const Icon(Icons.add, color: Colors.white),
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
            colors: [Color(0xFF1A0505), Color(0xFF0D0D1A)],
          ),
          border: Border(bottom: BorderSide(color: Color(0x33E53935), width: 1)),
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
                    const Text(
                      'Geopolitik-Kartierung',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white70),
                      onPressed: _loadAll,
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabCtrl,
                indicatorColor: _accentRed,
                indicatorWeight: 3,
                labelColor: _accentRed,
                unselectedLabelColor: Colors.white54,
                tabs: const [
                  Tab(text: 'Community'),
                  Tab(text: 'GDELT Live'),
                  Tab(text: 'Erdbeben'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab 1: Eigene Community-Ereignisse ──────────────────────────────────

  Widget _buildOwnTab() {
    if (_loadingOwn) {
      return const Center(child: CircularProgressIndicator(color: _accentRed));
    }
    if (_ownEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.public, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            const Text('Keine eigenen Ereignisse', style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 8),
            const Text(
              'Schau dir live Weltpolitik im "GDELT Live"-Tab an!',
              style: TextStyle(color: Colors.white38, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add),
              label: const Text('Erstes Ereignis'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _accentRed, foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _ownEvents.length,
      itemBuilder: (ctx, i) {
        final event = _ownEvents[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: _accentRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _accentRed.withValues(alpha: 0.4)),
              ),
              child: const Center(child: Text('🎭', style: TextStyle(fontSize: 22))),
            ),
            title: Text(
              event['event_title'] ?? 'Ereignis',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              event['event_description'] ?? '',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }

  // ── Tab 2: GDELT Live ───────────────────────────────────────────────────

  Widget _buildGdeltTab() {
    return Column(
      children: [
        _buildGdeltSearchBar(),
        _buildFilterRow(),
        Expanded(
          child: _loadingGdelt
              ? _buildSkeletonList()
              : _gdeltEvents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.wifi_off, size: 48, color: Colors.white24),
                          const SizedBox(height: 12),
                          const Text('GDELT nicht erreichbar',
                              style: TextStyle(color: Colors.white54)),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _loadGdelt,
                            child: const Text('Neu laden',
                                style: TextStyle(color: _accentRed)),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadGdelt,
                      color: _accentRed,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                        itemCount: _gdeltEvents.length + 1,
                        itemBuilder: (ctx, i) {
                          if (i == 0) return _buildGdeltHeader();
                          return _buildGdeltCard(_gdeltEvents[i - 1]);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildGdeltSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: Colors.white),
        onSubmitted: _applySearch,
        decoration: InputDecoration(
          hintText: 'Thema suchen (z.B. Ukraine, NATO, China…)',
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
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _accentRed.withValues(alpha: 0.5)),
          ),
          prefixIcon: const Icon(Icons.search, color: _accentRed, size: 20),
          suffixIcon: IconButton(
            icon: const Icon(Icons.send, color: Colors.white38, size: 18),
            onPressed: () => _applySearch(_searchCtrl.text),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Container(
      height: 46,
      padding: const EdgeInsets.only(bottom: 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: _filters.keys.map((label) {
          final isActive = _activeFilter == label;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _applyFilter(label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive
                      ? _accentRed.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? _accentRed.withValues(alpha: 0.7)
                        : Colors.white.withValues(alpha: 0.1),
                    width: isActive ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isActive ? _accentRed : Colors.white60,
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Shimmer-ähnliche Skeleton-Cards beim Laden
  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 3,
      itemBuilder: (ctx, i) => _buildSkeletonCard(),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titel-Skeleton (zwei Zeilen)
          Container(
            height: 14,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 14,
            width: 220,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 12),
          // Meta-Skeleton
          Row(
            children: [
              Container(
                height: 10, width: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Spacer(),
              Container(
                height: 24, width: 70,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGdeltHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _accentRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accentRed.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Text('🌍', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GDELT Global Events',
                  style: TextStyle(
                      color: _accentRed, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_gdeltEvents.length} Artikel · Filter: $_activeFilter',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGdeltCard(GdeltArticle article) {
    final date = article.parsedDate;
    final dateStr = date != null
        ? '${date.day}.${date.month}.${date.year}'
        : '';

    // Quell-Domain kürzen
    final sourceName = article.domain.replaceFirst(RegExp(r'^www\.'), '');

    // Tone-Badge: GDELT API liefert keinen direkt; wir zeigen Quelle + Land
    final country = article.sourcecountry;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final uri = Uri.tryParse(article.url);
          if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titel
              Text(
                article.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              // Meta-Zeile: Quelle | Land | Datum + Sentiment-Badge
              Row(
                children: [
                  // Quelle
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.language, size: 12, color: Colors.white38),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            sourceName,
                            style: const TextStyle(color: Colors.white38, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (country != null) ...[
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.flag, size: 12, color: Colors.white38),
                        const SizedBox(width: 3),
                        Text(country,
                            style: const TextStyle(color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                  ],
                  const Spacer(),
                  // Datum-Badge
                  if (dateStr.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        dateStr,
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ),
                  const SizedBox(width: 6),
                  // Öffnen-Icon
                  const Icon(Icons.open_in_new, size: 14, color: Colors.white24),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab 3: USGS Erdbeben ────────────────────────────────────────────────

  Widget _buildUsgsTab() {
    if (_loadingUsgs) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.orange),
            SizedBox(height: 16),
            Text('Lade Erdbeben-Daten…', style: TextStyle(color: Colors.white54)),
          ],
        ),
      );
    }
    if (_earthquakes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 48, color: Colors.green),
            const SizedBox(height: 12),
            const Text('Keine signifikanten Erdbeben diese Woche',
                style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadUsgs,
              child: const Text('Neu laden', style: TextStyle(color: Colors.orange)),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadUsgs,
      color: Colors.orange,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _earthquakes.length + 1,
        itemBuilder: (ctx, i) {
          if (i == 0) return _buildUsgsHeader();
          return _buildEarthquakeCard(_earthquakes[i - 1]);
        },
      ),
    );
  }

  Widget _buildUsgsHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Text('🔴', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'USGS Erdbeben-Monitor',
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_earthquakes.length} signifikante Erdbeben · letzte 7 Tage',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarthquakeCard(Earthquake eq) {
    final magColor = eq.magnitude >= 7.0
        ? Colors.red
        : eq.magnitude >= 6.0
            ? Colors.orange
            : Colors.yellow;

    final date = eq.time.toLocal();
    final dateStr =
        '${date.day}.${date.month}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          if (eq.url != null) {
            final uri = Uri.tryParse(eq.url!);
            if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: magColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: magColor.withValues(alpha: 0.6), width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      eq.magnitude.toStringAsFixed(1),
                      style: TextStyle(
                          color: magColor, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text('M', style: TextStyle(color: magColor, fontSize: 10)),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eq.place,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.circle, size: 8, color: magColor),
                        const SizedBox(width: 4),
                        Text(eq.magnitudeLabel,
                            style: TextStyle(color: magColor, fontSize: 12)),
                        if (eq.depth != null) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_downward, size: 12, color: Colors.white38),
                          Text(
                            '${eq.depth!.toStringAsFixed(0)} km',
                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(dateStr,
                        style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
