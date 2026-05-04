import 'dart:async';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/free_api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Materie-Farben
// ─────────────────────────────────────────────────────────────────────────────
const _kAccent = Color(0xFFE53935);
const _kBg = Color(0xFF0D0505);
const _kSurface = Color(0xFF1A0000);

/// 🕸️ Verschwörungs-Netzwerk — Wikidata-Daten als interaktiver Force-Graph
class ConspiracyNetworkScreen extends StatefulWidget {
  final String roomId;
  const ConspiracyNetworkScreen({super.key, required this.roomId});

  @override
  State<ConspiracyNetworkScreen> createState() =>
      _ConspiracyNetworkScreenState();
}

class _ConspiracyNetworkScreenState extends State<ConspiracyNetworkScreen> {
  final _api = FreeApiService.instance;
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<WikidataEntry> _entries = [];
  bool _loading = false;
  bool _showGraph = true; // true = Graph, false = Liste

  String _activeChip = 'Illuminati';

  static const _seeds = [
    'Illuminati',
    'Bilderberg',
    'Freimaurer',
    'Rothschild',
    'Geheimbund',
    'MK Ultra',
    'Gladio',
    'Bohemian Grove',
  ];

  // Graph-State
  final Graph _graph = Graph()..isTree = false;
  final _algorithm = FruchtermanReingoldAlgorithm(iterations: 200);

  // Mapping WikidataEntry.id → Graph-Node für Tap-Detection
  final Map<int, WikidataEntry> _nodeMap = {};

  @override
  void initState() {
    super.initState();
    _load(_activeChip);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ── Daten laden ──────────────────────────────────────────────────────────

  Future<void> _load(String query) async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final results = await _api.fetchWikidataEntries(query, limit: 20);
      if (!mounted) return;
      setState(() {
        _entries = results;
        _buildGraph(results);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (value.trim().isNotEmpty) _load(value.trim());
    });
  }

  // ── Graph aufbauen ───────────────────────────────────────────────────────

  void _buildGraph(List<WikidataEntry> entries) {
    // Graph leeren
    _graph.nodes.clear();
    _graph.edges.clear();
    _nodeMap.clear();

    if (entries.isEmpty) return;

    // Nodes erstellen — jede WikidataEntry bekommt einen Node
    final nodes = <Node>[];
    for (int i = 0; i < entries.length; i++) {
      final node = Node.Id(i);
      nodes.add(node);
      _nodeMap[i] = entries[i];
    }

    // Alle Nodes zum Graph hinzufügen
    for (final node in nodes) {
      _graph.addNode(node);
    }

    // Kanten: jeder Node → nächster (Kette) + jeder dritte → Node 0 (Hub)
    for (int i = 0; i < nodes.length - 1; i++) {
      _graph.addEdge(nodes[i], nodes[i + 1]);
    }
    // Hub-Verbindungen: alle 3 Nodes zurück zu Node 0
    for (int i = 3; i < nodes.length; i += 3) {
      _graph.addEdge(nodes[i], nodes[0]);
    }
  }

  // ── Bottom Sheet bei Node-Tap ────────────────────────────────────────────

  void _showNodeDetail(WikidataEntry entry) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _NodeDetailSheet(entry: entry),
    );
  }

  // ── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kSurface,
        title: const Text(
          'Verschwörungs-Netzwerk',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Graph / Liste togglen
          IconButton(
            icon: Icon(
              _showGraph ? Icons.list : Icons.bubble_chart,
              color: _kAccent,
            ),
            tooltip: _showGraph ? 'Listenansicht' : 'Graphansicht',
            onPressed: () => setState(() => _showGraph = !_showGraph),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildChips(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: _kAccent),
                  )
                : _entries.isEmpty
                    ? _buildEmpty()
                    : _showGraph
                        ? _buildGraphView()
                        : _buildListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Thema suchen …',
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: const Icon(Icons.search, color: _kAccent),
          filled: true,
          fillColor: _kSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        ),
        onChanged: _onSearch,
      ),
    );
  }

  Widget _buildChips() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: _seeds.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final seed = _seeds[i];
          final active = seed == _activeChip;
          return GestureDetector(
            onTap: () {
              setState(() => _activeChip = seed);
              _searchCtrl.clear();
              _load(seed);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: active ? _kAccent : _kSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? _kAccent : Colors.white12,
                ),
              ),
              child: Text(
                seed,
                style: TextStyle(
                  color: active ? Colors.white : Colors.white60,
                  fontSize: 12,
                  fontWeight:
                      active ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Graphansicht ─────────────────────────────────────────────────────────

  Widget _buildGraphView() {
    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(200),
      minScale: 0.2,
      maxScale: 3.0,
      child: GraphView(
        graph: _graph,
        algorithm: _algorithm,
        paint: Paint()
          ..color = _kAccent.withOpacity(0.5)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke,
        builder: (Node node) {
          final id = node.key!.value as int;
          final entry = _nodeMap[id];
          if (entry == null) return const SizedBox.shrink();
          return _GraphNode(
            entry: entry,
            onTap: () => _showNodeDetail(entry),
          );
        },
      ),
    );
  }

  // ── Listenansicht ────────────────────────────────────────────────────────

  Widget _buildListView() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _entries.length,
      itemBuilder: (_, i) => _ListCard(
        entry: _entries[i],
        onTap: () => _showNodeDetail(_entries[i]),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hub_outlined, color: Colors.white24, size: 64),
          const SizedBox(height: 12),
          const Text(
            'Keine Ergebnisse',
            style: TextStyle(color: Colors.white38, fontSize: 16),
          ),
          const SizedBox(height: 6),
          const Text(
            'Wähle ein Thema oder suche manuell.',
            style: TextStyle(color: Colors.white24, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Graph-Node-Widget
// ─────────────────────────────────────────────────────────────────────────────

class _GraphNode extends StatelessWidget {
  final WikidataEntry entry;
  final VoidCallback onTap;

  const _GraphNode({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = entry.label.length > 14
        ? '${entry.label.substring(0, 13)}…'
        : entry.label;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 40,
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kAccent, width: 1.4),
          boxShadow: [
            BoxShadow(
              color: _kAccent.withOpacity(0.35),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Listen-Karte
// ─────────────────────────────────────────────────────────────────────────────

class _ListCard extends StatelessWidget {
  final WikidataEntry entry;
  final VoidCallback onTap;

  const _ListCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kAccent.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: _kAccent.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _kAccent.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: _kAccent, width: 1.2),
              ),
              child: const Icon(Icons.hub, color: _kAccent, size: 16),
            ),
            const SizedBox(height: 8),
            Text(
              entry.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                entry.description ?? entry.id,
                style:
                    const TextStyle(color: Colors.white54, fontSize: 11),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Node-Detail Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _NodeDetailSheet extends StatelessWidget {
  final WikidataEntry entry;

  const _NodeDetailSheet({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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
          const SizedBox(height: 16),
          // Icon + Titel
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _kAccent.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: _kAccent, width: 1.5),
                ),
                child:
                    const Icon(Icons.hub, color: _kAccent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Wikidata-ID
          Text(
            'ID: ${entry.id}',
            style:
                const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          if (entry.description != null && entry.description!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              entry.description!,
              style:
                  const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
          const SizedBox(height: 18),
          // Wikidata-Link
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Auf Wikidata öffnen'),
              onPressed: () async {
                final uri = Uri.parse(entry.url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri,
                      mode: LaunchMode.externalApplication);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
