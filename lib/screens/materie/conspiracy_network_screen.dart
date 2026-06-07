// Conspiracy-Network-Screen (R3): Verflechtungs-Netz mit Filterung und Statistik.
//
// Erweiterung von R2:
//   - Typ-Filter (Person/Organisation/Ort/Konzept) per FilterChip
//   - Beziehungs-Filter (Property-Label-basiert)
//   - Statistik-Panel (Knoten-Grad, Typ-Verteilung, Top-Properties)
//   - Knotengroesse basiert auf Grad-Zentralitaet
//   - Gruppen-Ansicht nach Entitaetstyp
//   - Master/Display-Daten-Trennung: Filter aendert nur die Anzeige,
//     nicht die geladenen Daten.
//
// Quellen (unveraendert): Wikidata P361/P463/P108/P39/P127/P749/P159,
//   LittleSis, DBpedia. Hard cap: 50 Nodes.

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

enum _ViewMode { graph, list, grouped }

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
  _ViewMode _viewMode = _ViewMode.graph;
  String _activeChip = 'Illuminati';

  // --- Master-Daten (unveraendert durch Filter) ---
  final Map<String, WikidataEntry> _allEntries = {};
  final List<WikidataRelation> _allRelations = [];
  final Map<String, String> _typeMap = {};

  // --- Aktive Filter (leere Sets = alle anzeigen) ---
  final Set<_EntityType> _typeFilter = {};
  final Set<String> _propertyFilter = {};

  // --- Angezeigte Daten (aus Master + Filter berechnet) ---
  final Map<String, WikidataEntry> _displayEntries = {};
  final List<WikidataRelation> _displayRelations = [];

  // --- Graph-Daten fuer graphview ---
  final Map<String, int> _idToNodeId = {};
  final Map<int, String> _nodeIdToWikidataId = {};
  int _nextNodeId = 0;
  final Graph _graph = Graph()..isTree = false;
  final _algorithm = FruchtermanReingoldAlgorithm(iterations: 250);

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

  static const _chipQIds = <String, String>{
    'Illuminati': 'Q173453',
    'Bilderberg': 'Q189485',
    'Freimaurer': 'Q41726',
    'Rothschild': 'Q156646',
    'Geheimbund': 'Q864108',
    'MK Ultra': 'Q319009',
    'Gladio': 'Q695073',
    'Bohemian Grove': 'Q864801',
  };

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

  // Grad-Zentralitaet (Anzahl Verbindungen) aus einer beliebigen Relations-Liste.
  Map<String, int> _computeDegrees(List<WikidataRelation> relations) {
    final degrees = <String, int>{};
    for (final r in relations) {
      degrees[r.sourceId] = (degrees[r.sourceId] ?? 0) + 1;
      degrees[r.targetId] = (degrees[r.targetId] ?? 0) + 1;
    }
    return degrees;
  }

  List<String> _allPropertyLabels() {
    final labels = <String>{};
    for (final r in _allRelations) {
      if (r.propertyLabel.isNotEmpty) labels.add(r.propertyLabel);
    }
    return labels.toList()..sort();
  }

  // Filter anwenden: _displayEntries / _displayRelations / _graph neu aufbauen.
  void _applyFilters() {
    _displayEntries.clear();
    _displayRelations.clear();
    _idToNodeId.clear();
    _nodeIdToWikidataId.clear();
    _nextNodeId = 0;
    _graph.nodes.clear();
    _graph.edges.clear();

    // Knoten filtern.
    for (final entry in _allEntries.values) {
      final type = _typeOf(entry);
      if (_typeFilter.isEmpty || _typeFilter.contains(type)) {
        final nodeId = _nextNodeId++;
        _displayEntries[entry.id] = entry;
        _idToNodeId[entry.id] = nodeId;
        _nodeIdToWikidataId[nodeId] = entry.id;
        _graph.addNode(Node.Id(nodeId));
      }
    }

    // Kanten filtern: nur wenn beide Endpunkte sichtbar.
    for (final r in _allRelations) {
      if (!_displayEntries.containsKey(r.sourceId)) continue;
      if (!_displayEntries.containsKey(r.targetId)) continue;
      if (_propertyFilter.isNotEmpty &&
          !_propertyFilter.contains(r.propertyLabel)) continue;
      final exists = _displayRelations.any((x) =>
          x.sourceId == r.sourceId &&
          x.targetId == r.targetId &&
          x.propertyId == r.propertyId);
      if (exists) continue;
      _displayRelations.add(r);
      final s = _idToNodeId[r.sourceId];
      final t = _idToNodeId[r.targetId];
      if (s == null || t == null) continue;
      _graph.addEdge(
        _graph.nodes.firstWhere((n) => n.key!.value == s),
        _graph.nodes.firstWhere((n) => n.key!.value == t),
      );
    }
  }

  Future<void> _load(String query) async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      _allEntries.clear();
      _allRelations.clear();
      _typeMap.clear();
      _typeFilter.clear();
      _propertyFilter.clear();

      final curatedQid = _chipQIds[query];
      final List<WikidataEntry> seeds;
      if (curatedQid != null) {
        final results = await _api
            .fetchWikidataEntries(query, limit: 1)
            .catchError((_) => <WikidataEntry>[]);
        seeds = [
          WikidataEntry(
            id: curatedQid,
            label: results.isNotEmpty ? results.first.label : query,
            description:
                results.isNotEmpty ? results.first.description : null,
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
        _addMasterEntry(e);
      }

      // Hop 1.
      final hop1Rels = await Future.wait(
        seeds.map((e) => _api
            .fetchWikidataRelations(e.id)
            .catchError((_) => <WikidataRelation>[])),
      );
      final hop1TargetIds = <String>{};
      for (final rels in hop1Rels) {
        for (final r in rels) {
          _ingestMasterRelation(r);
          hop1TargetIds.add(r.targetId);
        }
      }

      // Hop 2 (max 8 Nachbarn, Quota schonen).
      final hop2Seeds = hop1TargetIds.take(8).toList();
      if (hop2Seeds.isNotEmpty && _allEntries.length < _kMaxNodes) {
        final hop2Rels = await Future.wait(
          hop2Seeds.map((id) => _api
              .fetchWikidataRelations(id)
              .catchError((_) => <WikidataRelation>[])),
        );
        for (final rels in hop2Rels) {
          for (final r in rels) {
            if (_allEntries.containsKey(r.targetId) ||
                _allEntries.length < _kMaxNodes) {
              _ingestMasterRelation(r);
            }
          }
        }
      }

      // P31-Klassifizierung.
      try {
        final cls =
            await _api.fetchWikidataClassification(_allEntries.keys.toList());
        _typeMap.addAll(cls);
      } catch (e) {
        if (kDebugMode) debugPrint('classification: $e');
      }

      // Anreicherung LittleSis + DBpedia.
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

      _applyFilters();
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (kDebugMode) debugPrint('conspiracy_network_screen _load: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _addMasterEntry(WikidataEntry e) {
    if (_allEntries.containsKey(e.id)) return;
    if (_allEntries.length >= _kMaxNodes) return;
    _allEntries[e.id] = e;
  }

  void _ingestMasterRelation(WikidataRelation r) {
    if (_allEntries.length >= _kMaxNodes) return;
    if (!_allEntries.containsKey(r.sourceId)) return;
    if (!_allEntries.containsKey(r.targetId)) {
      if (_allEntries.length >= _kMaxNodes) return;
      _addMasterEntry(WikidataEntry(
        id: r.targetId,
        label: r.targetLabel,
        description: null,
        url: 'https://www.wikidata.org/wiki/${r.targetId}',
      ));
    }
    final exists = _allRelations.any((x) =>
        x.sourceId == r.sourceId &&
        x.targetId == r.targetId &&
        x.propertyId == r.propertyId);
    if (exists) return;
    _allRelations.add(r);
  }

  void _ingestEnrichmentRelations(
    String sourceQid,
    List<LittleSisRelation> lsRels,
    List<DbpediaRelation> dbRels,
  ) {
    if (_allEntries.length >= _kMaxNodes) return;
    var counter = 0;
    for (final r in lsRels) {
      if (_allEntries.length >= _kMaxNodes) break;
      final synthId = 'ls:${r.targetName.hashCode}_${counter++}';
      if (_allEntries.containsKey(synthId)) continue;
      _addMasterEntry(WikidataEntry(
        id: synthId,
        label: r.targetName,
        description: r.description,
        url: r.url,
      ));
      _typeMap[synthId] = _ltSisToType(r.category);
      _allRelations.add(WikidataRelation(
        sourceId: sourceQid,
        targetId: synthId,
        targetLabel: r.targetName,
        propertyId: 'LS',
        propertyLabel: _shortenLs(r.description),
      ));
    }
    for (final r in dbRels) {
      if (_allEntries.length >= _kMaxNodes) break;
      final synthId = 'db:${r.targetLabel.hashCode}_${counter++}';
      if (_allEntries.containsKey(synthId)) continue;
      _addMasterEntry(WikidataEntry(
        id: synthId,
        label: r.targetLabel,
        description: null,
        url:
            'https://dbpedia.org/page/${Uri.encodeComponent(r.targetLabel)}',
      ));
      _typeMap[synthId] = 'concept';
      _allRelations.add(WikidataRelation(
        sourceId: sourceQid,
        targetId: synthId,
        targetLabel: r.targetLabel,
        propertyId: 'DB',
        propertyLabel: r.propertyLabel,
      ));
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

  Future<void> _expandNode(WikidataEntry entry) async {
    setState(() => _loading = true);
    try {
      final rels = await _api.fetchWikidataRelations(entry.id);
      final newIds = <String>{};
      for (final r in rels) {
        final isNew = !_allEntries.containsKey(r.targetId);
        _ingestMasterRelation(r);
        if (isNew && _allEntries.containsKey(r.targetId)) {
          newIds.add(r.targetId);
        }
      }
      if (newIds.isNotEmpty) {
        final cls =
            await _api.fetchWikidataClassification(newIds.toList());
        _typeMap.addAll(cls);
      }
      _applyFilters();
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
    final d = (e.description ?? '').toLowerCase();
    if (d.contains('person') ||
        d.contains('schauspiel') ||
        d.contains('politiker') ||
        d.contains('businessman') ||
        d.contains('autor') ||
        d.contains('musiker')) return _EntityType.person;
    if (d.contains('organisation') ||
        d.contains('unternehmen') ||
        d.contains('company') ||
        d.contains('bank') ||
        d.contains('gesellschaft') ||
        d.contains('orden') ||
        d.contains('group')) return _EntityType.organisation;
    if (d.contains('stadt') ||
        d.contains('country') ||
        d.contains('land') ||
        d.contains('city')) return _EntityType.location;
    return _EntityType.concept;
  }

  Color _colorOf(_EntityType t) {
    switch (t) {
      case _EntityType.person:
        return const Color(0xFFE53935);
      case _EntityType.organisation:
        return const Color(0xFFFFA726);
      case _EntityType.location:
        return const Color(0xFF42A5F5);
      case _EntityType.concept:
        return const Color(0xFFAB47BC);
    }
  }

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

  void _showNodeDetail(WikidataEntry entry) {
    final outRels =
        _allRelations.where((r) => r.sourceId == entry.id).toList();
    final inRels =
        _allRelations.where((r) => r.targetId == entry.id).toList();
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
          typeLabel: _typeLabel(_typeOf(entry)),
          outRels: outRels,
          inRels: inRels,
          scrollController: sc,
          onExpand: () async {
            Navigator.pop(ctx);
            await _expandNode(entry);
          },
          onResolveLabel: (id) => _allEntries[id]?.label,
        ),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _kSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _FilterSheet(
        typeFilter: Set.from(_typeFilter),
        propertyFilter: Set.from(_propertyFilter),
        allProperties: _allPropertyLabels(),
        colorOf: _colorOf,
        typeLabelOf: _typeLabel,
        onApply: (types, props) {
          setState(() {
            _typeFilter
              ..clear()
              ..addAll(types);
            _propertyFilter
              ..clear()
              ..addAll(props);
            _applyFilters();
          });
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showStatsSheet() {
    final degrees = _computeDegrees(_allRelations);
    final topNodes = _allEntries.values.toList()
      ..sort(
          (a, b) => (degrees[b.id] ?? 0).compareTo(degrees[a.id] ?? 0));
    final propCounts = <String, int>{};
    for (final r in _allRelations) {
      propCounts[r.propertyLabel] =
          (propCounts[r.propertyLabel] ?? 0) + 1;
    }
    final topProps = propCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final typeCounts = <_EntityType, int>{};
    for (final e in _allEntries.values) {
      final t = _typeOf(e);
      typeCounts[t] = (typeCounts[t] ?? 0) + 1;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: _kSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _StatsSheet(
        totalNodes: _allEntries.length,
        totalEdges: _allRelations.length,
        topNodes: topNodes.take(5).toList(),
        topProperties: topProps.take(5).toList(),
        typeCounts: typeCounts,
        degrees: degrees,
        colorOf: _colorOf,
        typeLabelOf: _typeLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasFilter =
        _typeFilter.isNotEmpty || _propertyFilter.isNotEmpty;
    return Scaffold(
      backgroundColor: const Color(0xFF04080F),
      appBar: WBGlassAppBar(
        world: WBWorld.materie,
        title: 'Verflechtungs-Netz',
        actions: [
          if (_allEntries.isNotEmpty)
            IconButton(
              icon:
                  const Icon(Icons.bar_chart_rounded, color: _kAccent),
              tooltip: 'Statistiken',
              onPressed: _showStatsSheet,
            ),
          IconButton(
            icon: Icon(
              _viewMode == _ViewMode.graph
                  ? Icons.list
                  : _viewMode == _ViewMode.list
                      ? Icons.account_tree
                      : Icons.bubble_chart,
              color: _kAccent,
            ),
            tooltip: _viewMode == _ViewMode.graph
                ? 'Listenansicht'
                : _viewMode == _ViewMode.list
                    ? 'Gruppenansicht'
                    : 'Graphansicht',
            onPressed: () => setState(() {
              _viewMode = _ViewMode
                  .values[(_viewMode.index + 1) % _ViewMode.values.length];
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildChips(),
          _buildFilterBar(hasFilter),
          _buildLegend(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: _kAccent))
                : _displayEntries.isEmpty
                    ? _buildEmpty(hasFilter)
                    : _viewMode == _ViewMode.graph
                        ? _buildGraphView()
                        : _viewMode == _ViewMode.list
                            ? _buildListView()
                            : _buildGroupedView(),
          ),
          if (_allEntries.isNotEmpty) _buildStatusBar(hasFilter),
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
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    color: active ? _kAccent : Colors.white12),
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

  Widget _buildFilterBar(bool hasFilter) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          TextButton.icon(
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              backgroundColor: hasFilter
                  ? _kAccent.withValues(alpha: 0.15)
                  : _kSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                    color: hasFilter ? _kAccent : Colors.white12),
              ),
            ),
            icon: Icon(Icons.filter_list_rounded,
                size: 16,
                color: hasFilter ? _kAccent : Colors.white60),
            label: Text(
              hasFilter ? 'Filter aktiv' : 'Filter',
              style: TextStyle(
                  color: hasFilter ? _kAccent : Colors.white60,
                  fontSize: 12),
            ),
            onPressed: _showFilterSheet,
          ),
          if (hasFilter) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() {
                _typeFilter.clear();
                _propertyFilter.clear();
                _applyFilters();
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close, size: 12, color: Colors.white54),
                    SizedBox(width: 4),
                    Text('Zuruecksetzen',
                        style: TextStyle(
                            color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ),
            ),
          ],
          const Spacer(),
          if (_allEntries.isNotEmpty)
            Text(
              '${_displayEntries.length}/${_allEntries.length}',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    Widget dot(String label, Color c) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: c, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 10)),
          ],
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Wrap(
        spacing: 12,
        children: [
          dot('Person', _colorOf(_EntityType.person)),
          dot('Organisation', _colorOf(_EntityType.organisation)),
          dot('Ort', _colorOf(_EntityType.location)),
          dot('Konzept', _colorOf(_EntityType.concept)),
        ],
      ),
    );
  }

  Widget _buildStatusBar(bool hasFilter) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: Colors.black54,
      child: Row(
        children: [
          Text(
            '${_displayEntries.length} Knoten  -  ${_displayRelations.length} Kanten',
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
          if (hasFilter)
            const Text('  (gefiltert)',
                style: TextStyle(color: _kAccent, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildGraphView() {
    final degrees = _computeDegrees(_displayRelations);
    final maxDeg = degrees.values.fold(1, (a, b) => a > b ? a : b).toDouble();
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
          final entry =
              wikidataId == null ? null : _displayEntries[wikidataId];
          if (entry == null) return const SizedBox.shrink();
          final color = _colorOf(_typeOf(entry));
          final deg = degrees[entry.id] ?? 0;
          final ratio = (deg / maxDeg).clamp(0.0, 1.0);
          return _GraphNode(
            entry: entry,
            color: color,
            sizeRatio: ratio,
            onTap: () => _showNodeDetail(entry),
          );
        },
      ),
    );
  }

  Widget _buildListView() {
    final degrees = _computeDegrees(_displayRelations);
    final list = _displayEntries.values.toList()
      ..sort(
          (a, b) => (degrees[b.id] ?? 0).compareTo(degrees[a.id] ?? 0));
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.0,
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
          degree: degrees[e.id] ?? 0,
          typeLabel: _typeLabel(t),
          onTap: () => _showNodeDetail(e),
        );
      },
    );
  }

  Widget _buildGroupedView() {
    final degrees = _computeDegrees(_displayRelations);
    final groups = <_EntityType, List<WikidataEntry>>{};
    for (final e in _displayEntries.values) {
      groups.putIfAbsent(_typeOf(e), () => []).add(e);
    }
    final sortedTypes = _EntityType.values
        .where((t) => groups.containsKey(t))
        .toList();
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sortedTypes.length,
      itemBuilder: (_, gi) {
        final type = sortedTypes[gi];
        final nodes = groups[type]!
          ..sort((a, b) =>
              (degrees[b.id] ?? 0).compareTo(degrees[a.id] ?? 0));
        final color = _colorOf(type);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(_typeLabel(type),
                      style: TextStyle(
                          color: color,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8)),
                  const SizedBox(width: 8),
                  Text('${nodes.length}',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            ...nodes.map((e) => _GroupedListTile(
                  entry: e,
                  color: color,
                  degree: degrees[e.id] ?? 0,
                  onTap: () => _showNodeDetail(e),
                )),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildEmpty(bool hasFilter) {
    final msg = hasFilter
        ? 'Filter zu restriktiv - keine Treffer.'
        : 'Waehle ein Thema oder suche manuell.';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasFilter
                ? Icons.filter_list_off_rounded
                : Icons.hub_outlined,
            color: Colors.white24,
            size: 64,
          ),
          const SizedBox(height: 12),
          Text(
            hasFilter ? 'Keine Ergebnisse' : 'Kein Netzwerk geladen',
            style: const TextStyle(color: Colors.white38, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(msg,
              style: const TextStyle(
                  color: Colors.white24, fontSize: 13)),
          if (hasFilter) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() {
                _typeFilter.clear();
                _propertyFilter.clear();
                _applyFilters();
              }),
              child: const Text('Filter zuruecksetzen',
                  style: TextStyle(color: _kAccent)),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Graph-Knoten (Groesse skaliert mit Grad-Zentralitaet)
// ---------------------------------------------------------------------------
class _GraphNode extends StatelessWidget {
  final WikidataEntry entry;
  final Color color;
  final double sizeRatio;
  final VoidCallback onTap;

  const _GraphNode({
    required this.entry,
    required this.color,
    required this.sizeRatio,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = 80.0 + sizeRatio * 60.0;
    final height = 40.0 + sizeRatio * 12.0;
    final label = entry.label.length > 16
        ? '${entry.label.substring(0, 15)}...'
        : entry.label;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: color, width: 1.2 + sizeRatio * 0.8),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.25 + sizeRatio * 0.2),
              blurRadius: 6.0 + sizeRatio * 6.0,
              spreadRadius: 1,
            ),
          ],
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 9.0 + sizeRatio * 2.0,
            fontWeight:
                sizeRatio > 0.5 ? FontWeight.bold : FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Raster-Karte (Listen-Ansicht)
// ---------------------------------------------------------------------------
class _ListCard extends StatelessWidget {
  final WikidataEntry entry;
  final Color color;
  final int degree;
  final String typeLabel;
  final VoidCallback onTap;

  const _ListCard({
    required this.entry,
    required this.color,
    required this.degree,
    required this.typeLabel,
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
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 1.2),
                  ),
                  child: Icon(Icons.hub, color: color, size: 14),
                ),
                const Spacer(),
                if (degree > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('$degree',
                        style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              entry.label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(typeLabel,
                style: TextStyle(
                    color: color.withValues(alpha: 0.8), fontSize: 10)),
            const SizedBox(height: 3),
            Expanded(
              child: Text(
                entry.description ?? entry.id,
                style: const TextStyle(
                    color: Colors.white54, fontSize: 10),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Gruppen-Zeile (Gruppen-Ansicht)
// ---------------------------------------------------------------------------
class _GroupedListTile extends StatelessWidget {
  final WikidataEntry entry;
  final Color color;
  final int degree;
  final VoidCallback onTap;

  const _GroupedListTile({
    required this.entry,
    required this.color,
    required this.degree,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.hub, color: color, size: 13),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                  if (entry.description != null &&
                      entry.description!.isNotEmpty)
                    Text(entry.description!,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (degree > 0)
                  Text('$degree',
                      style: TextStyle(
                          color: color,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                const Text('Links',
                    style: TextStyle(
                        color: Colors.white38, fontSize: 9)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter-Sheet
// ---------------------------------------------------------------------------
class _FilterSheet extends StatefulWidget {
  final Set<_EntityType> typeFilter;
  final Set<String> propertyFilter;
  final List<String> allProperties;
  final Color Function(_EntityType) colorOf;
  final String Function(_EntityType) typeLabelOf;
  final void Function(Set<_EntityType>, Set<String>) onApply;

  const _FilterSheet({
    required this.typeFilter,
    required this.propertyFilter,
    required this.allProperties,
    required this.colorOf,
    required this.typeLabelOf,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late final Set<_EntityType> _types;
  late final Set<String> _props;

  @override
  void initState() {
    super.initState();
    _types = Set.from(widget.typeFilter);
    _props = Set.from(widget.propertyFilter);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
          const Text('Filter',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          const Text('Entitaetstyp',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _EntityType.values.map((t) {
              final active = _types.contains(t);
              final color = widget.colorOf(t);
              return FilterChip(
                selected: active,
                label: Text(
                  widget.typeLabelOf(t),
                  style: TextStyle(
                      color: active ? Colors.white : Colors.white60,
                      fontSize: 12),
                ),
                backgroundColor: _kSurface,
                selectedColor: color.withValues(alpha: 0.3),
                checkmarkColor: color,
                side: BorderSide(
                    color: active ? color : Colors.white24),
                onSelected: (v) => setState(
                    () => v ? _types.add(t) : _types.remove(t)),
              );
            }).toList(),
          ),
          if (widget.allProperties.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('Beziehungstyp',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: widget.allProperties.take(20).map((prop) {
                final active = _props.contains(prop);
                return FilterChip(
                  selected: active,
                  label: Text(
                    prop,
                    style: TextStyle(
                        color:
                            active ? Colors.white : Colors.white60,
                        fontSize: 11),
                  ),
                  backgroundColor: _kSurface,
                  selectedColor: _kAccent.withValues(alpha: 0.2),
                  checkmarkColor: _kAccent,
                  side: BorderSide(
                      color: active ? _kAccent : Colors.white24),
                  onSelected: (v) => setState(
                      () => v ? _props.add(prop) : _props.remove(prop)),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white60,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => setState(() {
                    _types.clear();
                    _props.clear();
                  }),
                  child: const Text('Alles anzeigen'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => widget.onApply(_types, _props),
                  child: const Text('Anwenden'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Statistik-Sheet
// ---------------------------------------------------------------------------
class _StatsSheet extends StatelessWidget {
  final int totalNodes;
  final int totalEdges;
  final List<WikidataEntry> topNodes;
  final List<MapEntry<String, int>> topProperties;
  final Map<_EntityType, int> typeCounts;
  final Map<String, int> degrees;
  final Color Function(_EntityType) colorOf;
  final String Function(_EntityType) typeLabelOf;

  const _StatsSheet({
    required this.totalNodes,
    required this.totalEdges,
    required this.topNodes,
    required this.topProperties,
    required this.typeCounts,
    required this.degrees,
    required this.colorOf,
    required this.typeLabelOf,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
          const Text('Netzwerk-Statistiken',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatTile(value: '$totalNodes', label: 'Knoten'),
              const SizedBox(width: 12),
              _StatTile(value: '$totalEdges', label: 'Kanten'),
              const SizedBox(width: 12),
              _StatTile(
                value: totalNodes > 0
                    ? (totalEdges / totalNodes).toStringAsFixed(1)
                    : '0',
                label: 'Kanten/Knoten',
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text('Typenverteilung',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8)),
          const SizedBox(height: 8),
          ..._EntityType.values
              .where((t) => (typeCounts[t] ?? 0) > 0)
              .map((t) {
            final count = typeCounts[t] ?? 0;
            final ratio = totalNodes > 0 ? count / totalNodes : 0.0;
            final color = colorOf(t);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(typeLabelOf(t),
                        style: TextStyle(color: color, fontSize: 12)),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        backgroundColor: Colors.white10,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(color),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('$count',
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 11)),
                ],
              ),
            );
          }),
          if (topNodes.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text('Wichtigste Knoten (Grad)',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8)),
            const SizedBox(height: 8),
            ...topNodes.asMap().entries.map((e) {
              final node = e.value;
              final deg = degrees[node.id] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      child: Text('${e.key + 1}.',
                          style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11)),
                    ),
                    Expanded(
                      child: Text(node.label,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                          overflow: TextOverflow.ellipsis),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _kAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('$deg Links',
                          style: const TextStyle(
                              color: _kAccent, fontSize: 10)),
                    ),
                  ],
                ),
              );
            }),
          ],
          if (topProperties.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text('Haeufigste Beziehungen',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8)),
            const SizedBox(height: 8),
            ...topProperties.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(e.key,
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12)),
                      ),
                      Text('${e.value}x',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;

  const _StatTile({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    color: _kAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: Colors.white54, fontSize: 10),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Knoten-Detail-Sheet
// ---------------------------------------------------------------------------
class _NodeDetailSheet extends StatelessWidget {
  final WikidataEntry entry;
  final _EntityType type;
  final Color color;
  final String typeLabel;
  final List<WikidataRelation> outRels;
  final List<WikidataRelation> inRels;
  final ScrollController scrollController;
  final Future<void> Function() onExpand;
  final String? Function(String id) onResolveLabel;

  const _NodeDetailSheet({
    required this.entry,
    required this.type,
    required this.color,
    required this.typeLabel,
    required this.outRels,
    required this.inRels,
    required this.scrollController,
    required this.onExpand,
    required this.onResolveLabel,
  });

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
                    Text(entry.label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(typeLabel,
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
              style: const TextStyle(
                  color: Colors.white38, fontSize: 12)),
          if (entry.description != null &&
              entry.description!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(entry.description!,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 14)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _StatPill(
                icon: Icons.arrow_forward,
                value: '${outRels.length}',
                label: 'ausgehend',
                color: color,
              ),
              const SizedBox(width: 8),
              _StatPill(
                icon: Icons.arrow_back,
                value: '${inRels.length}',
                label: 'eingehend',
                color: Colors.white38,
              ),
              const SizedBox(width: 8),
              _StatPill(
                icon: Icons.link,
                value: '${outRels.length + inRels.length}',
                label: 'gesamt',
                color: Colors.white60,
              ),
            ],
          ),
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
                    padding:
                        const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.account_tree_outlined,
                      size: 16),
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
                    padding:
                        const EdgeInsets.symmetric(vertical: 12),
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
    final otherLabel = outgoing
        ? r.targetLabel
        : (onResolveLabel(r.sourceId) ?? r.sourceId);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(outgoing ? Icons.arrow_forward : Icons.arrow_back,
              color: Colors.white38, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12),
                children: [
                  TextSpan(
                      text: r.propertyLabel,
                      style: const TextStyle(
                          color: _kAccent,
                          fontWeight: FontWeight.bold)),
                  const TextSpan(text: '  '),
                  TextSpan(text: otherLabel),
                  TextSpan(
                      text: '  ($otherId)',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 10)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatPill({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(
                    color: Colors.white38, fontSize: 9)),
          ],
        ),
      ),
    );
  }
}
