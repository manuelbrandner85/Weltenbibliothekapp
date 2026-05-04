import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:url_launcher/url_launcher.dart';
import '../../services/group_tools_service.dart';
import '../../services/user_service.dart';
import '../../services/free_api_service.dart';

/// 🌿 Natürliche Heilmethoden + PubMed Forschung (Energie-Welt)
class AlternativeHealingScreen extends StatefulWidget {
  final String roomId;
  const AlternativeHealingScreen({super.key, required this.roomId});

  @override
  State<AlternativeHealingScreen> createState() => _AlternativeHealingScreenState();
}

class _AlternativeHealingScreenState extends State<AlternativeHealingScreen>
    with SingleTickerProviderStateMixin {
  final _svc = GroupToolsService();
  final _api = FreeApiService.instance;

  late final TabController _tabCtrl;

  List<Map<String, dynamic>> _items = [];
  bool _loading = false;

  // PubMed state
  List<PubMedStudy> _studies = [];
  bool _loadingStudies = false;
  String _pubmedQuery = 'herbal medicine plant healing';
  final _queryCtrl = TextEditingController(text: 'herbal medicine plant healing');

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
    _loadStudies();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _queryCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await _svc.getHealingMethods(roomId: widget.roomId);
      if (mounted) setState(() { _items = items; _loading = false; });
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ healing load: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadStudies([String? query]) async {
    final q = query ?? _pubmedQuery;
    setState(() { _loadingStudies = true; _pubmedQuery = q; });
    final result = await _api.fetchPubMedStudies(q, limit: 8);
    if (mounted) setState(() { _studies = result; _loadingStudies = false; });
  }

  void _add() {
    final title = TextEditingController();
    final desc = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A30),
        title: const Text('🌿 Heilmethode hinzufügen', style: TextStyle(color: Color(0xFF7C4DFF))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Name',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: desc,
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
              if (title.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await _svc.createHealingMethod(
                roomId: widget.roomId,
                userId: UserService.getCurrentUserId(),
                username: 'Anonym',
                methodName: title.text.trim(),
                methodDescription: desc.text.trim(),
                category: 'alternative',
              );
              await _load();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C4DFF)),
            child: const Text('Hinzufügen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        title: const Text('🌿 Natürliche Heilmethoden'),
        backgroundColor: const Color(0xFF12121F),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () { _load(); _loadStudies(); },
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: const Color(0xFF7C4DFF),
          labelColor: const Color(0xFF7C4DFF),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Community'),
            Tab(text: '🔬 PubMed Studien'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildCommunityTab(),
          _buildPubMedTab(),
        ],
      ),
      floatingActionButton: _tabCtrl.index == 0
          ? FloatingActionButton(
              onPressed: _add,
              backgroundColor: const Color(0xFF7C4DFF),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  // ── Tab 1: Community Heilmethoden ────────────────────────────────────────

  Widget _buildCommunityTab() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: const Color(0xFF7C4DFF)));
    }
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.healing, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            const Text('Noch keine Heilmethoden', style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 8),
            const Text('Schau dir wissenschaftliche Studien im PubMed-Tab an!',
                style: TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add),
              label: const Text('Erste Methode'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C4DFF)),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      itemBuilder: (ctx, i) {
        final item = _items[i];
        return Card(
          color: const Color(0xFF1A1A30),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.healing, color: const Color(0xFF7C4DFF), size: 32),
            title: Text(
              item['method_name'] ?? 'Methode',
              style: const TextStyle(color: const Color(0xFF7C4DFF), fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              item['method_description'] ?? '',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              maxLines: 2,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.search, color: Colors.white38, size: 18),
              tooltip: 'PubMed-Studien dazu suchen',
              onPressed: () {
                final name = item['method_name'] as String? ?? '';
                _queryCtrl.text = name;
                _loadStudies(name);
                _tabCtrl.animateTo(1);
              },
            ),
          ),
        );
      },
    );
  }

  // ── Tab 2: PubMed Studien ────────────────────────────────────────────────

  Widget _buildPubMedTab() {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: _loadingStudies
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: const Color(0xFF7C4DFF)),
                      SizedBox(height: 16),
                      Text('Suche PubMed-Datenbank…',
                          style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                )
              : _studies.isEmpty
                  ? _buildPubMedEmpty()
                  : RefreshIndicator(
                      onRefresh: () => _loadStudies(),
                      color: const Color(0xFF7C4DFF),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _studies.length + 1,
                        itemBuilder: (ctx, i) {
                          if (i == 0) return _buildPubMedHeader();
                          return _buildStudyCard(_studies[i - 1]);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: const Color(0xFF0D0D1A),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _queryCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'z.B. curcumin inflammation, meditation stress…',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF1A1A30),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.science, color: const Color(0xFF7C4DFF)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onSubmitted: (v) => _loadStudies(v.trim()),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _loadStudies(_queryCtrl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C4DFF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
            child: const Icon(Icons.search),
          ),
        ],
      ),
    );
  }

  Widget _buildPubMedHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF7C4DFF).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF7C4DFF).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Text('🔬', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PubMed Wissenschaftliche Studien',
                    style: TextStyle(color: const Color(0xFF7C4DFF), fontWeight: FontWeight.bold)),
                Text('${_studies.length} Ergebnisse für "$_pubmedQuery"',
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPubMedEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, size: 48, color: Colors.white24),
          const SizedBox(height: 12),
          const Text('Keine Studien gefunden', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 6),
          const Text('Versuche einen anderen Suchbegriff',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStudyCard(PubMedStudy study) {
    return Card(
      color: const Color(0xFF1A1A30),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () async {
          final uri = Uri.parse(study.pubmedUrl);
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                study.title,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              if (study.authors.isNotEmpty)
                Text(
                  study.authors.join(', '),
                  style: const TextStyle(color: const Color(0xFF7C4DFF), fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (study.source != null) ...[
                    const Icon(Icons.book, size: 12, color: Colors.white38),
                    const SizedBox(width: 4),
                    Text(study.source!, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    const SizedBox(width: 10),
                  ],
                  if (study.pubDate != null)
                    Text(study.pubDate!, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  const Spacer(),
                  const Icon(Icons.open_in_new, size: 14, color: const Color(0xFF7C4DFF)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
