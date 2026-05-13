import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/wb_design.dart';
import '../../widgets/knowledge_graph_widget.dart';
import '../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../widgets/cinematic/wb_vignette.dart';
import '../../theme/wb_cinematic_tokens.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 🕸️ KNOWLEDGE GRAPH SCREEN — Interaktiver Wissensgraph
// Zeigt Wissensknoten + Kanten aus Supabase als Force-Directed-Graph.
// Welt-Filter, Suche, Node-Detail-Sheet, Bookmarks.
// ═══════════════════════════════════════════════════════════════════════════

class KnowledgeGraphScreen extends StatefulWidget {
  final String world; // materie | energie | vorhang | ursprung
  final String? initialQuery;

  const KnowledgeGraphScreen({
    super.key,
    required this.world,
    this.initialQuery,
  });

  @override
  State<KnowledgeGraphScreen> createState() => _KnowledgeGraphScreenState();
}

class _KnowledgeGraphScreenState extends State<KnowledgeGraphScreen>
    with TickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _searchCtrl = TextEditingController();

  List<KnowledgeNode> _nodes = [];
  List<KnowledgeEdge> _edges = [];
  Set<String> _bookmarkedIds = {};

  bool _loading = false;
  bool _showList = false; // false = Graph, true = Listenansicht
  String? _highlightedNodeId;
  String _searchQuery = '';

  // Filter
  String _typeFilter = 'alle'; // alle | concept | person | event | …
  static const _typeOptions = [
    'alle',
    'concept',
    'person',
    'event',
    'theory',
    'place',
    'artifact',
  ];

  late AnimationController _fabCtrl;

  @override
  void initState() {
    super.initState();
    _fabCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _searchQuery = widget.initialQuery ?? '';
    if (_searchQuery.isNotEmpty) _searchCtrl.text = _searchQuery;
    _loadData();
    _loadBookmarks();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _fabCtrl.dispose();
    super.dispose();
  }

  // ── Farben je nach Welt ────────────────────────────────────────────────────────────

  Color get _accent {
    switch (widget.world) {
      case 'energie':
        return WbDesign.energiePurple;
      case 'vorhang':
        return WbDesign.vorhangGold;
      case 'ursprung':
        return WbDesign.ursprungCyan;
      default:
        return WbDesign.materieBlue;
    }
  }

  Color get _bg {
    switch (widget.world) {
      case 'energie':
        return WbDesign.bgEnergie;
      case 'vorhang':
        return WbDesign.bgVorhang;
      case 'ursprung':
        return WbDesign.bgUrsprung;
      default:
        return WbDesign.bgMaterie;
    }
  }

  WBWorld get _wbWorld {
    switch (widget.world) {
      case 'energie':
        return WBWorld.energie;
      case 'vorhang':
        return WBWorld.vorhang;
      case 'ursprung':
        return WBWorld.ursprung;
      default:
        return WBWorld.materie;
    }
  }

  // ── Daten laden ──────────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      // Knoten laden
      var nodeQuery = _supabase
          .from('knowledge_graph_nodes')
          .select()
          .or('world.eq.${widget.world},world.eq.universal')
          .order('weight', ascending: false)
          .limit(120);

      if (_typeFilter != 'alle') {
        nodeQuery = _supabase
            .from('knowledge_graph_nodes')
            .select()
            .or('world.eq.${widget.world},world.eq.universal')
            .eq('node_type', _typeFilter)
            .order('weight', ascending: false)
            .limit(120);
      }

      final nodeRes = await nodeQuery.timeout(const Duration(seconds: 10));

      // Kanten laden (nur zwischen geladenen Knoten)
      final nodeIds = (nodeRes as List)
          .map((r) => r['id'] as String)
          .toList();

      List edgeRes = [];
      if (nodeIds.isNotEmpty) {
        edgeRes = await _supabase
            .from('knowledge_graph_edges')
            .select()
            .inFilter('source_id', nodeIds)
            .inFilter('target_id', nodeIds)
            .limit(300)
            .timeout(const Duration(seconds: 10));
      }

      if (!mounted) return;
      setState(() {
        _nodes = _parseNodes(nodeRes);
        _edges = _parseEdges(edgeRes);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Laden: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadBookmarks() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final res = await _supabase
          .from('user_graph_bookmarks')
          .select('node_id')
          .eq('user_id', userId)
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      setState(() {
        _bookmarkedIds = {
          for (final r in res as List) r['node_id'] as String
        };
      });
    } catch (_) {
      // Bookmarks sind optional — kein Fehler anzeigen
    }
  }

  Future<void> _toggleBookmark(KnowledgeNode node) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final isBookmarked = _bookmarkedIds.contains(node.id);
    setState(() {
      if (isBookmarked) {
        _bookmarkedIds.remove(node.id);
      } else {
        _bookmarkedIds.add(node.id);
      }
    });

    try {
      if (isBookmarked) {
        await _supabase
            .from('user_graph_bookmarks')
            .delete()
            .eq('user_id', userId)
            .eq('node_id', node.id);
      } else {
        await _supabase.from('user_graph_bookmarks').upsert({
          'user_id': userId,
          'node_id': node.id,
        });
      }
    } catch (e) {
      // Rollback
      if (mounted) {
        setState(() {
          if (isBookmarked) {
            _bookmarkedIds.add(node.id);
          } else {
            _bookmarkedIds.remove(node.id);
          }
        });
      }
    }
  }

  // ── Parsing ───────────────────────────────────────────────────────────────────

  List<KnowledgeNode> _parseNodes(List data) {
    return data.map((r) {
      Color color;
      try {
        final hex = (r['color_hex'] as String? ?? '#4A90D9')
            .replaceAll('#', '');
        color = Color(int.parse('FF$hex', radix: 16));
      } catch (_) {
        color = _accent;
      }
      return KnowledgeNode(
        id: r['id'] as String,
        label: r['label'] as String? ?? '?',
        description: r['description'] as String?,
        nodeType: r['node_type'] as String? ?? 'concept',
        iconEmoji: r['icon_emoji'] as String? ?? '🔵',
        color: color,
        weight: (r['weight'] as int?) ?? 1,
        isBookmarked: _bookmarkedIds.contains(r['id'] as String),
      );
    }).toList();
  }

  List<KnowledgeEdge> _parseEdges(List data) {
    return data.map((r) {
      return KnowledgeEdge(
        sourceId: r['source_id'] as String,
        targetId: r['target_id'] as String,
        relation: r['relation'] as String? ?? 'related',
        strength: (r['strength'] as int?) ?? 5,
      );
    }).toList();
  }

  // ── Gefilterte Knoten ─────────────────────────────────────────────────────────────

  List<KnowledgeNode> get _filteredNodes {
    final nodes = _nodes.map((n) {
      return n.copyWith(isBookmarked: _bookmarkedIds.contains(n.id));
    }).toList();

    if (_searchQuery.isEmpty) return nodes;
    final q = _searchQuery.toLowerCase();
    return nodes
        .where((n) =>
            n.label.toLowerCase().contains(q) ||
            (n.description?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  // ── Verbundene Knoten für Detail-Sheet ────────────────────────────────────

  List<KnowledgeNode> _connectedNodes(KnowledgeNode node) {
    final connectedIds = _edges
        .where((e) => e.sourceId == node.id || e.targetId == node.id)
        .map((e) => e.sourceId == node.id ? e.targetId : e.sourceId)
        .toSet();
    return _nodes.where((n) => connectedIds.contains(n.id)).toList();
  }

  // ── Node-Tap ────────────────────────────────────────────────────────────────────

  void _onNodeTap(KnowledgeNode node) {
    setState(() => _highlightedNodeId = node.id);
    NodeDetailSheet.show(
      context: context,
      node: node.copyWith(isBookmarked: _bookmarkedIds.contains(node.id)),
      connectedNodes: _connectedNodes(node),
      accentColor: _accent,
      onBookmarkToggle: () {
        _toggleBookmark(node);
        Navigator.pop(context);
      },
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredNodes;
    // Kanten auf gefilterte Knoten einschränken
    final filteredIds = {for (final n in filtered) n.id};
    final filteredEdges = _edges
        .where((e) =>
            filteredIds.contains(e.sourceId) &&
            filteredIds.contains(e.targetId))
        .toList();

    return Scaffold(
      backgroundColor: _bg,
      appBar: WBGlassAppBar(
        title: 'Wissensgraph',
        world: _wbWorld,
        actions: [
          // Ansicht umschalten
          IconButton(
            icon: Icon(
              _showList ? Icons.account_tree : Icons.list,
              color: Colors.white70,
            ),
            tooltip: _showList ? 'Graph-Ansicht' : 'Listen-Ansicht',
            onPressed: () => setState(() => _showList = !_showList),
          ),
          // Neu laden
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            tooltip: 'Neu laden',
            onPressed: _loading ? null : _loadData,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Hintergrund-Gradient
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _bg,
                    Color.lerp(_bg, Colors.black, 0.5) ?? Colors.black,
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),
          const Positioned.fill(child: IgnorePointer(child: WBVignette())),

          Column(
            children: [
              // Suchleiste + Filter
              _buildSearchBar(),
              _buildTypeFilter(),

              // Haupt-Inhalt
              Expanded(
                child: _loading
                    ? _buildLoadingState()
                    : _showList
                        ? _buildListView(filtered)
                        : _buildGraphView(filtered, filteredEdges),
              ),

              // Legende (nur im Graph-Modus)
              if (!_showList && !_loading)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: KnowledgeGraphLegend(accentColor: _accent),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  // ── Sub-Widgets ───────────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Wissensgraph durchsuchen…',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          prefixIcon:
              Icon(Icons.search, color: _accent.withValues(alpha: 0.7)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white54),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.07),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _accent.withValues(alpha: 0.5)),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildTypeFilter() {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _typeOptions.length,
        itemBuilder: (context, i) {
          final type = _typeOptions[i];
          final isSelected = _typeFilter == type;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_typeLabel(type)),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _typeFilter = type);
                _loadData();
              },
              selectedColor: _accent.withValues(alpha: 0.3),
              checkmarkColor: _accent,
              labelStyle: TextStyle(
                color: isSelected ? _accent : Colors.white60,
                fontSize: 12,
              ),
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              side: BorderSide(
                color: isSelected
                    ? _accent.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.12),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              visualDensity: VisualDensity.compact,
            ),
          );
        },
      ),
    );
  }

  Widget _buildGraphView(
      List<KnowledgeNode> nodes, List<KnowledgeEdge> edges) {
    return KnowledgeGraphWidget(
      nodes: nodes,
      edges: edges,
      accentColor: _accent,
      backgroundColor: _bg,
      onNodeTap: _onNodeTap,
      highlightedNodeId: _highlightedNodeId,
    );
  }

  Widget _buildListView(List<KnowledgeNode> nodes) {
    if (nodes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off,
                size: 56, color: _accent.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              'Keine Ergebnisse',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: nodes.length,
      itemBuilder: (context, i) {
        final node = nodes[i];
        return _NodeListTile(
          node: node,
          accentColor: _accent,
          onTap: () => _onNodeTap(node),
          onBookmark: () => _toggleBookmark(node),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              color: _accent,
              strokeWidth: 2.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Wissensgraph lädt…',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton(
      backgroundColor: _accent,
      foregroundColor: Colors.white,
      onPressed: _showAddNodeDialog,
      tooltip: 'Knoten hinzufügen',
      mini: true,
      child: const Icon(Icons.add, size: 22),
    );
  }

  // ── Neuen Knoten hinzufügen ───────────────────────────────────────────────

  Future<void> _showAddNodeDialog() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte einloggen um Knoten hinzuzufügen'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final labelCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedType = 'concept';

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF0D0D1E),
          title: Text(
            'Neuen Knoten erstellen',
            style: TextStyle(color: _accent),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Bezeichnung',
                  hintStyle: TextStyle(color: Colors.white38),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Beschreibung (optional)',
                  hintStyle: TextStyle(color: Colors.white38),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedType,
                dropdownColor: const Color(0xFF1A1A2E),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Typ',
                  labelStyle: TextStyle(color: Colors.white54),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                ),
                items: _typeOptions
                    .where((t) => t != 'alle')
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(_typeLabel(t)),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedType = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen',
                  style: TextStyle(color: Colors.white54)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: _accent),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Erstellen'),
            ),
          ],
        ),
      ),
    );

    labelCtrl.dispose();
    descCtrl.dispose();

    if (confirmed != true || labelCtrl.text.trim().isEmpty) return;

    try {
      await _supabase.from('knowledge_graph_nodes').insert({
        'world': widget.world,
        'label': labelCtrl.text.trim(),
        'description': descCtrl.text.trim().isEmpty
            ? null
            : descCtrl.text.trim(),
        'node_type': selectedType,
        'icon_emoji': _defaultEmoji(selectedType),
        'color_hex': _hexColor(_accent),
        'weight': 3,
        'created_by': userId,
      });
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Knoten erstellt'),
            backgroundColor: Colors.green,
          ),
        );
      }
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
  }

  static String _typeLabel(String type) {
    switch (type) {
      case 'alle':
        return 'Alle';
      case 'concept':
        return 'Konzepte';
      case 'person':
        return 'Personen';
      case 'event':
        return 'Ereignisse';
      case 'theory':
        return 'Theorien';
      case 'place':
        return 'Orte';
      case 'artifact':
        return 'Artefakte';
      default:
        return type;
    }
  }

  static String _defaultEmoji(String type) {
    switch (type) {
      case 'person':
        return '👤';
      case 'event':
        return '📅';
      case 'place':
        return '📍';
      case 'artifact':
        return '🎺';
      case 'theory':
        return '💡';
      default:
        return '🔵';
    }
  }

  static String _hexColor(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }
}

// ── Listen-Tile ────────────────────────────────────────────────────────────────────────────

class _NodeListTile extends StatelessWidget {
  final KnowledgeNode node;
  final Color accentColor;
  final VoidCallback onTap;
  final VoidCallback onBookmark;

  const _NodeListTile({
    required this.node,
    required this.accentColor,
    required this.onTap,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: node.color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: node.color.withValues(alpha: 0.2),
            border: Border.all(
              color: node.color.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              node.iconEmoji,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        title: Text(
          node.label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: node.description != null && node.description!.isNotEmpty
            ? Text(
                node.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Typ-Badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: node.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _shortType(node.nodeType),
                style: TextStyle(
                  color: node.color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(
                node.isBookmarked
                    ? Icons.bookmark
                    : Icons.bookmark_border,
                color: node.isBookmarked
                    ? Colors.amber
                    : Colors.white.withValues(alpha: 0.3),
                size: 20,
              ),
              onPressed: onBookmark,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _shortType(String type) {
    switch (type) {
      case 'concept':
        return 'Konzept';
      case 'person':
        return 'Person';
      case 'event':
        return 'Event';
      case 'theory':
        return 'Theorie';
      case 'place':
        return 'Ort';
      case 'artifact':
        return 'Artefakt';
      default:
        return type;
    }
  }
}
