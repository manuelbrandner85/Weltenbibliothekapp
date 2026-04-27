import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:url_launcher/url_launcher.dart';
import '../../services/group_tools_service.dart';
import '../../services/user_service.dart';
import '../../services/free_api_service.dart';

/// 🎭 GEOPOLITIK-KARTIERUNG SCREEN
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

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
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
      if (kDebugMode) debugPrint('⚠️ Own events: $e');
      if (mounted) setState(() => _loadingOwn = false);
    }
  }

  Future<void> _loadGdelt() async {
    setState(() => _loadingGdelt = true);
    final result = await _api.fetchGdeltEvents(
      query: 'geopolitics conflict crisis war protest',
      limit: 25,
    );
    if (mounted) setState(() { _gdeltEvents = result; _loadingGdelt = false; });
  }

  Future<void> _loadUsgs() async {
    setState(() => _loadingUsgs = true);
    final result = await _api.fetchEarthquakes();
    if (mounted) setState(() { _earthquakes = result; _loadingUsgs = false; });
  }

  void _showAddDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('🎭 Geopolitisches Ereignis', style: TextStyle(color: Colors.red)),
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
                  const SnackBar(content: Text('✅ Ereignis hinzugefügt!'), backgroundColor: Colors.green),
                );
                _loadOwnEvents();
              } catch (e) {
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('❌ Fehler: $e'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Hinzufügen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        title: const Text('🎭 Geopolitik-Kartierung'),
        backgroundColor: const Color(0xFF1B263B),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAll),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.red,
          labelColor: Colors.red,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Community'),
            Tab(text: '🌍 GDELT Live'),
            Tab(text: '🔴 Erdbeben'),
          ],
        ),
      ),
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
              backgroundColor: Colors.red,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  // ── Tab 1: Eigene Community-Ereignisse ──────────────────────────────────

  Widget _buildOwnTab() {
    if (_loadingOwn) {
      return const Center(child: CircularProgressIndicator(color: Colors.red));
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
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
        return Card(
          color: const Color(0xFF1A1A2E),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red, width: 2),
              ),
              child: const Center(child: Text('🎭', style: TextStyle(fontSize: 24))),
            ),
            title: Text(
              event['event_title'] ?? 'Ereignis',
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              event['event_description'] ?? '',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
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
    if (_loadingGdelt) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.red),
            SizedBox(height: 16),
            Text('Lade Weltpolitik-Ereignisse…', style: TextStyle(color: Colors.white54)),
          ],
        ),
      );
    }
    if (_gdeltEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: Colors.white24),
            const SizedBox(height: 12),
            const Text('GDELT nicht erreichbar', style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 12),
            TextButton(onPressed: _loadGdelt, child: const Text('Neu laden', style: TextStyle(color: Colors.red))),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadGdelt,
      color: Colors.red,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _gdeltEvents.length + 1,
        itemBuilder: (ctx, i) {
          if (i == 0) return _buildGdeltHeader();
          final article = _gdeltEvents[i - 1];
          return _buildGdeltCard(article);
        },
      ),
    );
  }

  Widget _buildGdeltHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Text('🌍', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GDELT Global Events',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_gdeltEvents.length} aktuelle Weltpolitik-Artikel · Echtzeit',
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

    return Card(
      color: const Color(0xFF1A1A2E),
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          final uri = Uri.tryParse(article.url);
          if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                article.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.language, size: 12, color: Colors.white38),
                  const SizedBox(width: 4),
                  Text(article.domain, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  if (article.sourcecountry != null) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.flag, size: 12, color: Colors.white38),
                    const SizedBox(width: 4),
                    Text(article.sourcecountry!, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                  const Spacer(),
                  Text(dateStr, style: const TextStyle(color: Colors.white38, fontSize: 11)),
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
            const Text('Keine signifikanten Erdbeben diese Woche', style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 12),
            TextButton(onPressed: _loadUsgs, child: const Text('Neu laden', style: TextStyle(color: Colors.orange))),
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
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Text('🔴', style: TextStyle(fontSize: 24)),
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
    final dateStr = '${date.day}.${date.month}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Card(
      color: const Color(0xFF1A1A2E),
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
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
                  color: magColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: magColor, width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      eq.magnitude.toStringAsFixed(1),
                      style: TextStyle(color: magColor, fontSize: 18, fontWeight: FontWeight.bold),
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
                        Text(eq.magnitudeLabel, style: TextStyle(color: magColor, fontSize: 12)),
                        if (eq.depth != null) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_downward, size: 12, color: Colors.white38),
                          Text(
                            '${eq.depth!.toStringAsFixed(0)} km Tiefe',
                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(dateStr, style: const TextStyle(color: Colors.white38, fontSize: 11)),
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
