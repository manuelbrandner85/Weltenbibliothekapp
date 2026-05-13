import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/knowledge_graph_widget.dart';

class KnowledgeGraphScreen extends StatefulWidget {
  const KnowledgeGraphScreen({super.key});

  @override
  State<KnowledgeGraphScreen> createState() => _KnowledgeGraphScreenState();
}

class _KnowledgeGraphScreenState extends State<KnowledgeGraphScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _searchCtrl = TextEditingController();
  final _ivCtrl = TransformationController();

  List<KnowledgeNode> _nodes = [];
  List<KnowledgeEdge> _edges = [];
  Set<String> _discoveredIds = {};
  String? _worldFilter;
  String _searchQuery = '';
  bool _loading = true;
  String? _error;

  late AnimationController _bgCtrl;

  static const _worlds = ['ursprung', 'vorhang', 'energie', 'materie'];
  static const _worldLabels = {
    'ursprung': 'Ursprung',
    'vorhang':  'Vorhang',
    'energie':  'Energie',
    'materie':  'Materie',
  };
  static const _worldColors = {
    'ursprung': Color(0xFFFFD700),
    'vorhang':  Color(0xFFE53935),
    'energie':  Color(0xFF7C4DFF),
    'materie':  Color(0xFF2196F3),
  };

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat(reverse: true);
    _loadData();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _searchCtrl.dispose();
    _ivCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final user = _supabase.auth.currentUser;

      final nodeRows = await _supabase
          .from('knowledge_nodes')
          .select()
          .order('level')
          .timeout(const Duration(seconds: 12));

      final edgeRows = await _supabase
          .from('knowledge_edges')
          .select()
          .timeout(const Duration(seconds: 12));

      Set<String> discovered = {};
      if (user != null) {
        final progRows = await _supabase
            .from('user_node_progress')
            .select('node_id')
            .eq('user_id', user.id)
            .timeout(const Duration(seconds: 8));
        discovered = {for (final r in progRows) r['node_id'] as String};
      }

      final nodes = nodeRows.map<KnowledgeNode>((r) => KnowledgeNode(
        id:          r['id'] as String,
        slug:        r['slug'] as String,
        title:       r['title'] as String,
        description: r['description'] as String?,
        world:       r['world'] as String,
        category:    r['category'] as String?,
        icon:        r['icon'] as String?,
        level:       (r['level'] as int?) ?? 1,
        discovered:  discovered.contains(r['id'] as String),
      )).toList();

      final edges = edgeRows.map<KnowledgeEdge>((r) => KnowledgeEdge(
        id:       r['id'] as String,
        sourceId: r['source_id'] as String,
        targetId: r['target_id'] as String,
        relation: r['relation'] as String,
        strength: (r['strength'] as num?)?.toDouble() ?? 1.0,
      )).toList();

      setState(() {
        _nodes = nodes;
        _edges = edges;
        _discoveredIds = discovered;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Fehler beim Laden: $e';
        _loading = false;
      });
    }
  }

  Future<void> _discoverNode(KnowledgeNode node) async {
    final user = _supabase.auth.currentUser;
    if (user == null || _discoveredIds.contains(node.id)) return;
    try {
      await _supabase.from('user_node_progress').upsert({
        'user_id': user.id,
        'node_id': node.id,
      });
      setState(() {
        _discoveredIds.add(node.id);
        _nodes = _nodes.map((n) => n.id == node.id
            ? KnowledgeNode(
                id: n.id, slug: n.slug, title: n.title,
                description: n.description, world: n.world,
                category: n.category, icon: n.icon, level: n.level,
                discovered: true,
              )
            : n).toList();
      });
    } catch (_) {}
  }

  List<KnowledgeNode> get _visibleNodes {
    var nodes = _worldFilter == null
        ? _nodes
        : _nodes.where((n) => n.world == _worldFilter).toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      nodes = nodes.where((n) =>
          n.title.toLowerCase().contains(q) ||
          (n.description?.toLowerCase().contains(q) ?? false) ||
          (n.category?.toLowerCase().contains(q) ?? false)
      ).toList();
    }
    return nodes;
  }

  void _onNodeTap(KnowledgeNode node) {
    HapticFeedback.lightImpact();
    _discoverNode(node);
    _showNodeBottomSheet(node);
  }

  void _showNodeBottomSheet(KnowledgeNode node) {
    final edgesForNode = _edges.where((e) =>
        e.sourceId == node.id || e.targetId == node.id).toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _NodeBottomSheet(
        node: node,
        edges: edgesForNode,
        allNodes: _nodes,
        color: node.worldColor,
      ),
    );
  }

  int get _totalDiscovered => _discoveredIds.length;
  int get _totalNodes => _nodes.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06040F),
      body: AnimatedBuilder(
        animation: _bgCtrl,
        builder: (context, child) => Stack(
          children: [
            Positioned.fill(child: Container(color: const Color(0xFF06040F))),
            Positioned(
              top: -60 + _bgCtrl.value * 40, right: -40,
              child: _CineOrb(color: const Color(0xFFFFD700), size: 320,
                  opacity: 0.06 + _bgCtrl.value * 0.03),
            ),
            Positioned(
              bottom: -60, left: -40 + _bgCtrl.value * 30,
              child: _CineOrb(color: const Color(0xFF7C4DFF), size: 280, opacity: 0.07),
            ),
            Positioned(
              top: 200 + _bgCtrl.value * 20, left: -30,
              child: _CineOrb(color: const Color(0xFF2196F3), size: 200,
                  opacity: 0.05 + _bgCtrl.value * 0.02),
            ),
            child!,
          ],
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildFilterChips(),
              _buildSearchBar(),
              _buildProgressBanner(),
              Expanded(child: _buildGraphArea()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Wissensgraph', style: TextStyle(
                  color: Colors.white, fontSize: 20,
                  fontWeight: FontWeight.w700, letterSpacing: 0.3,
                )),
                Text('Interaktives Wissensnetz',
                    style: TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white54),
            onPressed: _loadData,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          _FilterChip(
            label: 'Alle', selected: _worldFilter == null,
            color: Colors.white70,
            onTap: () => setState(() => _worldFilter = null),
          ),
          ..._worlds.map((w) => _FilterChip(
            label: _worldLabels[w]!,
            selected: _worldFilter == w,
            color: _worldColors[w]!,
            onTap: () => setState(() => _worldFilter = _worldFilter == w ? null : w),
          )),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Wissen durchsuchen…',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded,
              color: Colors.white.withValues(alpha: 0.4), size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.white38, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.06),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF7C4DFF), width: 1.5),
          ),
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
      ),
    );
  }

  Widget _buildProgressBanner() {
    if (_loading) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.hub_rounded, color: Color(0xFF7C4DFF), size: 16),
            const SizedBox(width: 8),
            Text('$_totalDiscovered / $_totalNodes Knoten entdeckt',
                style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
            const Spacer(),
            SizedBox(
              width: 100,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _totalNodes > 0 ? _totalDiscovered / _totalNodes : 0,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF7C4DFF)),
                  minHeight: 5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraphArea() {
    if (_loading) {
      return const Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFF7C4DFF)),
          SizedBox(height: 16),
          Text('Lade Wissensgraph…',
              style: TextStyle(color: Colors.white54, fontSize: 13)),
        ],
      ));
    }
    if (_error != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: Colors.white38, size: 48),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.white54, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh, color: Color(0xFF7C4DFF)),
              label: const Text('Erneut versuchen',
                  style: TextStyle(color: Color(0xFF7C4DFF))),
            ),
          ],
        ),
      ));
    }
    final visible = _visibleNodes;
    if (visible.isEmpty) {
      return Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, color: Colors.white24, size: 48),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isNotEmpty
                ? 'Keine Knoten für "$_searchQuery"'
                : 'Keine Knoten für diesen Filter',
            style: const TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ));
    }
    return InteractiveViewer(
      transformationController: _ivCtrl,
      boundaryMargin: const EdgeInsets.all(200),
      minScale: 0.15,
      maxScale: 3.5,
      constrained: false,
      child: KnowledgeGraphWidget(
        nodes: visible,
        edges: _edges,
        worldFilter: _worldFilter,
        searchQuery: _searchQuery,
        onNodeTap: _onNodeTap,
      ),
    );
  }
}

// ── NodeBottomSheet ──────────────────────────────────────────────────────────────────
class _NodeBottomSheet extends StatelessWidget {
  final KnowledgeNode node;
  final List<KnowledgeEdge> edges;
  final List<KnowledgeNode> allNodes;
  final Color color;

  const _NodeBottomSheet({
    required this.node, required this.edges,
    required this.allNodes, required this.color,
  });

  String _nodeTitle(String id) {
    try { return allNodes.firstWhere((n) => n.id == id).title; }
    catch (_) { return id.substring(0, 8); }
  }

  String _relLabel(String rel) {
    switch (rel) {
      case 'basiert_auf':  return 'basiert auf';
      case 'enthält':      return 'enthält';
      case 'führt_zu':     return 'führt zu';
      case 'ähnlich':      return 'ähnlich wie';
      case 'widerspricht': return 'widerspricht';
      default:             return rel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final outgoing = edges.where((e) => e.sourceId == node.id).toList();
    final incoming = edges.where((e) => e.targetId == node.id).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF10101E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 30)],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            )),
            Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      color.withValues(alpha: 0.7),
                      color.withValues(alpha: 0.2),
                    ]),
                    border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
                  ),
                  child: Center(child: Text(node.icon ?? '?',
                      style: const TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(node.discovered ? node.title : '??? Unbekannter Knoten',
                        style: const TextStyle(color: Colors.white, fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: color.withValues(alpha: 0.3)),
                        ),
                        child: Text(node.world.toUpperCase(),
                            style: TextStyle(color: color, fontSize: 10,
                                fontWeight: FontWeight.w600, letterSpacing: 1)),
                      ),
                      if (node.category != null) ...[const SizedBox(width: 6),
                        Text(node.category!, style: const TextStyle(
                            color: Colors.white38, fontSize: 11))],
                      const SizedBox(width: 6),
                      ...List.generate(node.level, (_) =>
                          const Text('★', style: TextStyle(
                              color: Color(0xFFFFD700), fontSize: 10))),
                    ]),
                  ],
                )),
              ],
            ),
            if (node.discovered && node.description != null) ...[const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Text(node.description!, style: const TextStyle(
                    color: Colors.white70, fontSize: 13.5, height: 1.5)),
              )
            ] else if (!node.discovered) ...[const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(children: [
                  Icon(Icons.lock_outline, color: Colors.white38, size: 16),
                  SizedBox(width: 8),
                  Text('Erkunde diesen Knoten um mehr zu erfahren',
                      style: TextStyle(color: Colors.white38, fontSize: 13)),
                ]),
              ),
            ],
            if (outgoing.isNotEmpty || incoming.isNotEmpty) ...[const SizedBox(height: 16),
              const Text('Verbindungen', style: TextStyle(
                  color: Colors.white54, fontSize: 12,
                  fontWeight: FontWeight.w600, letterSpacing: 0.8)),
              const SizedBox(height: 8),
              ...outgoing.map((e) => _EdgeTile(prefix: '→',
                  label: _relLabel(e.relation),
                  target: _nodeTitle(e.targetId), color: e.relationColor)),
              ...incoming.map((e) => _EdgeTile(prefix: '←',
                  label: _relLabel(e.relation),
                  target: _nodeTitle(e.sourceId),
                  color: e.relationColor.withValues(alpha: 0.7))),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _EdgeTile extends StatelessWidget {
  final String prefix;
  final String label;
  final String target;
  final Color color;
  const _EdgeTile({required this.prefix, required this.label,
      required this.target, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Text(prefix, style: TextStyle(color: color, fontSize: 14,
            fontWeight: FontWeight.bold)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(label, style: TextStyle(color: color, fontSize: 10)),
        ),
        const SizedBox(width: 6),
        Flexible(child: Text(target,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
            overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}

// ── FilterChip ─────────────────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.12),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(label, style: TextStyle(
          color: selected ? color : Colors.white54,
          fontSize: 12.5,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        )),
      ),
    );
  }
}

// ── CineOrb ────────────────────────────────────────────────────────────────────────────
class _CineOrb extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;
  const _CineOrb({required this.color, required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [
        color.withValues(alpha: opacity),
        color.withValues(alpha: 0),
      ]),
    ),
  );
}
