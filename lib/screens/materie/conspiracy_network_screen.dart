// Conspiracy-Network-Screen (R2): echte Wikidata-Relations als Force-Graph.
//
// Edges stammen aus FreeApiService.fetchWikidataRelations() ueber die
// Properties P361 (Teil von), P463 (Mitglied von), P108 (Arbeitgeber),
// P39 (Position), P127 (Eigentuemer), P749 (Mutterorganisation),
// P159 (Hauptsitz). Knoten werden nach Entity-Typ (Heuristik aus
// description) farblich differenziert. Tap auf Knoten oeffnet ein Sheet
// mit "Netzwerk erweitern" -> fetcht zusaetzliche Relations.
// Hard cap: 50 Nodes.

import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/free_api_service.dart';
import '../../theme/wb_cinematic_tokens.dart';
import '../../widgets/cinematic/wb_glass_app_bar.dart';

const _kAccent = Color(0xFFE53935);
const _kSurface = Color(0xFF1A0000);
const _kMaxNodes = 50;

enum _EntityType { person, organisation, location, concept }

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

  bool _loading = false;
  bool _showGraph = true;
  String _activeChip = 'Illuminati';

  // Aktueller Netzwerkzustand.
  final Map<String, WikidataEntry> _entries = {}; // id -> Entry
  final List<WikidataRelation> _relations = [];
  final Map<String, int> _idToNodeId = {}; // wikidata-id -> graph-int-id
  final Map<int, String> _nodeIdToWikidataId =
      {}; // graph-int-id -> wikidata-id
  // P31-basierte Klassifizierung pro Q-ID. Wird beim Laden via
  // FreeApiService.fetchWikidataClassification() befuellt.
  final Map<String, String> _typeMap = {};
  int _nextNodeId = 0;

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

  /// Handgepflegte Wikidata-Q-IDs fuer die Standard-Chips.
  /// Verhindert "Bilderberg 10x"-Problem: statt einer wbsearchentities-Suche
  /// (die alle homonymen Treffer liefert) wird direkt die korrekte Entity
  /// geladen. Fuer freie Suchanfragen wird weiterhin der Top-1-Treffer
  /// genommen.
  static const _chipQIds = <String, String>{
    'Illuminati': 'Q173453', // Bavarian Illuminati
    'Bilderberg': 'Q189485', // Bilderberg Group
    'Freimaurer': 'Q41726', // Freemasonry
    'Rothschild': 'Q156646', // Rothschild family
    'Geheimbund': 'Q864108', // Geheimgesellschaft
    'MK Ultra': 'Q319009', // Project MKULTRA
    'Gladio': 'Q695073', // Operation Gladio
    'Bohemian Grove': 'Q864801', // Bohemian Club
  };

  final Graph _graph = Graph()..isTree = false;
  final _algorithm = FruchtermanReingoldAlgorithm(iterations: 250);

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

  Future<void> _load(String query) async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      // Reset graph fuer neuen Seed.
      _entries.clear();
      _relations.clear();
      _idToNodeId.clear();
      _nodeIdToWikidataId.clear();
      _typeMap.clear();
      _nextNodeId = 0;
      _graph.nodes.clear();
      _graph.edges.clear();

      // --- A) Seed bestimmen: Curated Q-ID (chip) ODER Top-1-Suche ---
      final curatedQid = _chipQIds[query];
      final List<WikidataEntry> seeds;
      if (curatedQid != null) {
        // Genaues Label/Description fuer die kuratierte Q-ID via Batch-Lookup.
        final results =
            await _api.fetchWikidataEntries(query, limit: 1).catchError(
                  (_) => <WikidataEntry>[],
                );
        seeds = [
          WikidataEntry(
            id: curatedQid,
            label: results.isNotEmpty ? results.first.label : query,
            description: results.isNotEmpty ? results.first.description : null,
            url: 'https://www.wikidata.org/wiki/$curatedQid',
          ),
        ];
      } else {
        final results = await _api.fetchWikidataEntries(query, limit: 1);
        if (results.isEmpty) {
          if (!mounted) return;
          setState(() => _loading = false);
          return;
        }
        seeds = [results.first];
      }
      for (final e in seeds) {
        _addEntryAsNode(e);
      }

      // --- C) Hop 1: Relations vom Seed laden ---
      final hop1Rels = await Future.wait(
        seeds.map((e) => _api
            .fetchWikidataRelations(e.id)
            .catchError((_) => <WikidataRelation>[])),
      );
      final hop1TargetIds = <String>{};
      for (final rels in hop1Rels) {
        for (final r in rels) {
          _ingestRelation(r);
          hop1TargetIds.add(r.targetId);
        }
      }

      // --- C) Hop 2: Relations fuer die ersten Nachbarknoten laden ---
      // Max 8 Nachbarn um Quota zu schonen.
      final hop2Seeds = hop1TargetIds.take(8).toList();
      if (hop2Seeds.isNotEmpty && _entries.length < _kMaxNodes) {
        final hop2Rels = await Future.wait(
          hop2Seeds.map((id) => _api
              .fetchWikidataRelations(id)
              .catchError((_) => <WikidataRelation>[])),
        );
        for (final rels in hop2Rels) {
          for (final r in rels) {
            // Nur Edges zu bereits bekannten Knoten oder neue, wenn noch Platz.
            if (_entries.containsKey(r.targetId) ||
                _entries.length < _kMaxNodes) {
              _ingestRelation(r);
            }
          }
        }
      }

      // --- B) Klassifizierung: alle Knoten via P31 typisieren ---
      try {
        final classification =
            await _api.fetchWikidataClassification(_entries.keys.toList());
        _typeMap.addAll(classification);
      } catch (e) {
        if (kDebugMode) debugPrint('classification: $e');
      }

      // --- D) Anreicherung: LittleSis + DBpedia (best-effort, parallel) ---
      // Liefert weitere Edges fuer den Seed-Namen. Targets bekommen
      // synthetische IDs, damit sie als separate Knoten erscheinen.
      final seedLabel = seeds.first.label;
      final enrichResults = await Future.wait([
        _api
            .fetchLittleSisRelations(seedLabel, limit: 12)
            .catchError((_) => <LittleSisRelation>[]),
        _api
            .fetchDbpediaRelations(seedLabel, limit: 20)
            .catchError((_) => <DbpediaRelation>[]),
      ]);
      final lsRels = enrichResults[0] as List<LittleSisRelation>;
      final dbRels = enrichResults[1] as List<DbpediaRelation>;
      _ingestEnrichmentRelations(seeds.first.id, lsRels, dbRels);

      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (kDebugMode) debugPrint('conspiracy_network_screen _load: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  /// Verarbeitet LittleSis- und DBpedia-Beziehungen als synthetische
  /// Wikidata-Relations. Quelle wird als Q-ID-Praefix kodiert
  /// ('ls:'/'db:') damit es nicht mit echten Wikidata-IDs kollidiert.
  void _ingestEnrichmentRelations(
    String sourceQid,
    List<LittleSisRelation> lsRels,
    List<DbpediaRelation> dbRels,
  ) {
    if (_entries.length >= _kMaxNodes) return;
    var counter = 0;
    for (final r in lsRels) {
      if (_entries.length >= _kMaxNodes) break;
      final synthId = 'ls:${r.targetName.hashCode}_${counter++}';
      if (_entries.containsKey(synthId)) continue;
      _addEntryAsNode(WikidataEntry(
        id: synthId,
        label: r.targetName,
        description: r.description,
        url: r.url,
      ));
      _typeMap[synthId] = _ltSisToType(r.category);
      _relations.add(WikidataRelation(
        sourceId: sourceQid,
        targetId: synthId,
        targetLabel: r.targetName,
        propertyId: 'LS',
        propertyLabel: _shortenLs(r.description),
      ));
      _addGraphEdge(sourceQid, synthId);
    }
    for (final r in dbRels) {
      if (_entries.length >= _kMaxNodes) break;
      final synthId = 'db:${r.targetLabel.hashCode}_${counter++}';
      if (_entries.containsKey(synthId)) continue;
      _addEntryAsNode(WikidataEntry(
        id: synthId,
        label: r.targetLabel,
        description: null,
        url: 'https://dbpedia.org/page/${Uri.encodeComponent(r.targetLabel)}',
      ));
      _typeMap[synthId] = 'concept'; // DBpedia liefert keine P31
      _relations.add(WikidataRelation(
        sourceId: sourceQid,
        targetId: synthId,
        targetLabel: r.targetLabel,
        propertyId: 'DB',
        propertyLabel: r.propertyLabel,
      ));
      _addGraphEdge(sourceQid, synthId);
    }
  }

  static String _ltSisToType(String? cat) {
    if (cat == null) return 'organisation';
    final c = cat.toLowerCase();
    if (c.contains('family') || c.contains('member')) return 'person';
    return 'organisation';
  }

  static String _shortenLs(String desc) {
    if (desc.length <= 18) return desc;
    return '${desc.substring(0, 17)}...';
  }

  void _addGraphEdge(String fromId, String toId) {
    final s = _idToNodeId[fromId];
    final t = _idToNodeId[toId];
    if (s == null || t == null) return;
    _graph.addEdge(
      _graph.nodes.firstWhere((n) => n.key!.value == s),
      _graph.nodes.firstWhere((n) => n.key!.value == t),
    );
  }

  void _addEntryAsNode(WikidataEntry e) {
    if (_entries.containsKey(e.id)) return;
    if (_entries.length >= _kMaxNodes) return;
    final nodeId = _nextNodeId++;
    _entries[e.id] = e;
    _idToNodeId[e.id] = nodeId;
    _nodeIdToWikidataId[nodeId] = e.id;
    _graph.addNode(Node.Id(nodeId));
  }

  void _ingestRelation(WikidataRelation r) {
    if (_entries.length >= _kMaxNodes) return;
    // Source muss existieren.
    if (!_entries.containsKey(r.sourceId)) return;
    // Target ggf. anlegen (als Light-Entry).
    if (!_entries.containsKey(r.targetId)) {
      if (_entries.length >= _kMaxNodes) return;
      _addEntryAsNode(WikidataEntry(
        id: r.targetId,
        label: r.targetLabel,
        description: null,
        url: 'https://www.wikidata.org/wiki/${r.targetId}',
      ));
    }
    // Doppelte Edge vermeiden.
    final exists = _relations.any((x) =>
        x.sourceId == r.sourceId &&
        x.targetId == r.targetId &&
        x.propertyId == r.propertyId);
    if (exists) return;
    _relations.add(r);
    final s = _idToNodeId[r.sourceId];
    final t = _idToNodeId[r.targetId];
    if (s == null || t == null) return;
    _graph.addEdge(
      _graph.nodes.firstWhere((n) => n.key!.value == s),
      _graph.nodes.firstWhere((n) => n.key!.value == t),
    );
  }

  Future<void> _expandNode(WikidataEntry entry) async {
    setState(() => _loading = true);
    try {
      final rels = await _api.fetchWikidataRelations(entry.id);
      final newIds = <String>{};
      for (final r in rels) {
        final isNew = !_entries.containsKey(r.targetId);
        _ingestRelation(r);
        if (isNew && _entries.containsKey(r.targetId)) newIds.add(r.targetId);
      }
      // Klassifiziere die neu hinzugekommenen Knoten.
      if (newIds.isNotEmpty) {
        final cls = await _api.fetchWikidataClassification(newIds.toList());
        _typeMap.addAll(cls);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('conspiracy_network_screen expand: $e');
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (value.trim().isNotEmpty) _load(value.trim());
    });
  }

  _EntityType _typeOf(WikidataEntry e) {
    // Primaer: P31-basierte Klassifizierung aus Wikidata.
    final cls = _typeMap[e.id];
    if (cls != null) {
      switch (cls) {
        case 'person':
          return _EntityType.person;
        case 'organisation':
          return _EntityType.organisation;
        case 'location':
          return _EntityType.location;
        case 'concept':
          return _EntityType.concept;
      }
    }
    // Fallback: alte String-Heuristik auf Description (nur falls P31-Call
    // gescheitert ist oder noch nicht abgeschlossen).
    final d = (e.description ?? '').toLowerCase();
    if (d.contains('person') ||
        d.contains('schauspiel') ||
        d.contains('politiker') ||
        d.contains('businessman') ||
        d.contains('autor') ||
        d.contains('musiker')) {
      return _EntityType.person;
    }
    if (d.contains('organisation') ||
        d.contains('unternehmen') ||
        d.contains('company') ||
        d.contains('bank') ||
        d.contains('gesellschaft') ||
        d.contains('orden') ||
        d.contains('group')) {
      return _EntityType.organisation;
    }
    if (d.contains('stadt') ||
        d.contains('country') ||
        d.contains('land') ||
        d.contains('city')) {
      return _EntityType.location;
    }
    return _EntityType.concept;
  }

  Color _colorOf(_EntityType t) {
    switch (t) {
      case _EntityType.person:
        return const Color(0xFFE53935); // Materie Rot
      case _EntityType.organisation:
        return const Color(0xFFFFA726); // Orange
      case _EntityType.location:
        return const Color(0xFF42A5F5); // Blau
      case _EntityType.concept:
        return const Color(0xFFAB47BC); // Lila
    }
  }

  void _showNodeDetail(WikidataEntry entry) {
    final outRels = _relations.where((r) => r.sourceId == entry.id).toList();
    final inRels = _relations.where((r) => r.targetId == entry.id).toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: _kSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.92,
        builder: (_, sc) => _NodeDetailSheet(
          entry: entry,
          type: _typeOf(entry),
          color: _colorOf(_typeOf(entry)),
          outRels: outRels,
          inRels: inRels,
          scrollController: sc,
          onExpand: () async {
            Navigator.pop(ctx);
            await _expandNode(entry);
          },
          onResolveLabel: (id) => _entries[id]?.label,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04080F),
      appBar: WBGlassAppBar(
        world: WBWorld.materie,
        title: 'Verschwörungs-Netzwerk',
        actions: [
          IconButton(
            icon: Icon(_showGraph ? Icons.list : Icons.bubble_chart,
                color: _kAccent),
            tooltip: _showGraph ? 'Listenansicht' : 'Graphansicht',
            onPressed: () => setState(() => _showGraph = !_showGraph),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildChips(),
          _buildLegend(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: _kAccent))
                : _entries.isEmpty
                    ? _buildEmpty()
                    : _showGraph
                        ? _buildGraphView()
                        : _buildListView(),
          ),
          if (_entries.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              color: Colors.black54,
              child: Row(
                children: [
                  Text(
                    '${_entries.length}/$_kMaxNodes Knoten - ${_relations.length} Kanten',
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ),
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
          hintText: 'Thema suchen ...',
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: active ? _kAccent : _kSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: active ? _kAccent : Colors.white12),
              ),
              child: Text(
                seed,
                style: TextStyle(
                  color: active ? Colors.white : Colors.white60,
                  fontSize: 12,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegend() {
    Widget chip(String label, Color c) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Wrap(
        spacing: 12,
        children: [
          chip('Person', _colorOf(_EntityType.person)),
          chip('Organisation', _colorOf(_EntityType.organisation)),
          chip('Ort', _colorOf(_EntityType.location)),
          chip('Konzept', _colorOf(_EntityType.concept)),
        ],
      ),
    );
  }

  Widget _buildGraphView() {
    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(240),
      minScale: 0.15,
      maxScale: 3.0,
      child: GraphView(
        graph: _graph,
        algorithm: _algorithm,
        paint: Paint()
          ..color = _kAccent.withValues(alpha: 0.45)
          ..strokeWidth = 1.1
          ..style = PaintingStyle.stroke,
        builder: (Node node) {
          final id = node.key!.value as int;
          final wikidataId = _nodeIdToWikidataId[id];
          final entry = wikidataId == null ? null : _entries[wikidataId];
          if (entry == null) return const SizedBox.shrink();
          final type = _typeOf(entry);
          final color = _colorOf(type);
          return _GraphNode(
            entry: entry,
            color: color,
            onTap: () => _showNodeDetail(entry),
          );
        },
      ),
    );
  }

  Widget _buildListView() {
    final list = _entries.values.toList();
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final e = list[i];
        final t = _typeOf(e);
        return _ListCard(
          entry: e,
          color: _colorOf(t),
          onTap: () => _showNodeDetail(e),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hub_outlined, color: Colors.white24, size: 64),
          SizedBox(height: 12),
          Text('Keine Ergebnisse',
              style: TextStyle(color: Colors.white38, fontSize: 16)),
          SizedBox(height: 6),
          Text('Waehle ein Thema oder suche manuell.',
              style: TextStyle(color: Colors.white24, fontSize: 13)),
        ],
      ),
    );
  }
}

class _GraphNode extends StatelessWidget {
  final WikidataEntry entry;
  final Color color;
  final VoidCallback onTap;

  const _GraphNode({
    required this.entry,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = entry.label.length > 14
        ? '${entry.label.substring(0, 13)}...'
        : entry.label;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 40,
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 1.4),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
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

class _ListCard extends StatelessWidget {
  final WikidataEntry entry;
  final Color color;
  final VoidCallback onTap;

  const _ListCard({
    required this.entry,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
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
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 1.2),
              ),
              child: Icon(Icons.hub, color: color, size: 16),
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
                style: const TextStyle(color: Colors.white54, fontSize: 11),
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

class _NodeDetailSheet extends StatelessWidget {
  final WikidataEntry entry;
  final _EntityType type;
  final Color color;
  final List<WikidataRelation> outRels;
  final List<WikidataRelation> inRels;
  final ScrollController scrollController;
  final Future<void> Function() onExpand;
  final String? Function(String id) onResolveLabel;

  const _NodeDetailSheet({
    required this.entry,
    required this.type,
    required this.color,
    required this.outRels,
    required this.inRels,
    required this.scrollController,
    required this.onExpand,
    required this.onResolveLabel,
  });

  String _typeLabel(_EntityType t) {
    switch (t) {
      case _EntityType.person:
        return 'Person';
      case _EntityType.organisation:
        return 'Organisation';
      case _EntityType.location:
        return 'Ort';
      case _EntityType.concept:
        return 'Konzept';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.5),
                ),
                child: Icon(Icons.hub, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(_typeLabel(type),
                          style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('ID: ${entry.id}',
              style: const TextStyle(color: Colors.white38, fontSize: 12)),
          if (entry.description != null && entry.description!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(entry.description!,
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ],
          if (outRels.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text('Verbindungen',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
            const SizedBox(height: 6),
            ...outRels.map((r) => _relTile(r, outgoing: true)),
          ],
          if (inRels.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('Eingehende Verbindungen',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
            const SizedBox(height: 6),
            ...inRels.map((r) => _relTile(r, outgoing: false)),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.account_tree_outlined, size: 16),
                  label: const Text('Netzwerk erweitern'),
                  onPressed: onExpand,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.open_in_new, size: 14),
                  label: const Text('Wikidata'),
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
        ],
      ),
    );
  }

  Widget _relTile(WikidataRelation r, {required bool outgoing}) {
    final otherId = outgoing ? r.targetId : r.sourceId;
    final otherLabel =
        outgoing ? r.targetLabel : (onResolveLabel(r.sourceId) ?? r.sourceId);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            outgoing ? Icons.arrow_forward : Icons.arrow_back,
            color: Colors.white38,
            size: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                children: [
                  TextSpan(
                      text: r.propertyLabel,
                      style: TextStyle(
                          color: _kAccent.withValues(alpha: 0.9),
                          fontWeight: FontWeight.bold)),
                  const TextSpan(text: '  '),
                  TextSpan(text: otherLabel),
                  TextSpan(
                      text: '  ($otherId)',
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 10)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
