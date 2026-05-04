import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/free_api_service.dart';

/// 🕸️ Verschwörungs-Netzwerk — Wikidata + statisches Netz + interaktiver Graph
class ConspiracyNetworkScreen extends StatefulWidget {
  final String roomId;
  const ConspiracyNetworkScreen({super.key, required this.roomId});

  @override
  State<ConspiracyNetworkScreen> createState() => _ConspiracyNetworkScreenState();
}

class _ConspiracyNetworkScreenState extends State<ConspiracyNetworkScreen>
    with SingleTickerProviderStateMixin {
  final _api = FreeApiService.instance;
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<WikidataEntry> _nodes = [];
  bool _loading = false;
  WikidataEntry? _selected;
  String _searchQuery = 'conspiracy secret society illuminati';

  // Vordefinierte Seed-Themen
  static const _seeds = [
    'New World Order',
    'Illuminati Freemasons',
    'Deep State government',
    'MK-Ultra CIA mind control',
    'Bilderberg Group',
    'Area 51 UFO',
    'Chemtrails geoengineering',
    'Federal Reserve banking cartel',
  ];

  // Farbe je nach Typ
  static const _typeColors = {
    'Q7278': Color(0xFFFF1744), // Political party
    'Q43229': Color(0xFFFF6D00), // Organization
    'Q5': Color(0xFF29B6F6), // Human
    'Q8': Color(0xFFAB47BC), // Happiness
    'default': Color(0xFF78909C),
  };

  @override
  void initState() {
    super.initState();
    _load(_searchQuery);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load(String q) async {
    setState(() { _loading = true; _selected = null; _searchQuery = q; });
    final results = await _api.fetchWikidataEntries(q, limit: 20);
    if (mounted) setState(() { _nodes = results; _loading = false; });
  }

  void _onSearch(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () => _load(val));
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFE53935);
    const bg = Color(0xFF0D0505);

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 100,
            backgroundColor: const Color(0xFF1A0000),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Verschwörungs-Netzwerk',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF1A0000), accent.withValues(alpha: 0.2)],
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearch,
                  onSubmitted: _load,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Entität suchen…',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFFE53935), size: 20),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.07),
                    contentPadding: const EdgeInsets.symmetric(vertical: 6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Seed-Chips
          SliverToBoxAdapter(
            child: SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _seeds.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final active = _searchQuery == _seeds[i];
                  return GestureDetector(
                    onTap: () {
                      _searchCtrl.text = _seeds[i];
                      _load(_seeds[i]);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: active ? accent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: active ? accent.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Text(
                        _seeds[i].split(' ').first,
                        style: TextStyle(
                          color: active ? accent : Colors.white60,
                          fontSize: 11,
                          fontWeight: active ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Color(0xFFE53935))),
            )
          else if (_nodes.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.hub_outlined, size: 64, color: Colors.white.withValues(alpha: 0.2)),
                    const SizedBox(height: 12),
                    Text('Keine Verbindungen gefunden',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
                  ],
                ),
              ),
            )
          else ...[
            // Detail-Panel wenn ausgewählt
            if (_selected != null)
              SliverToBoxAdapter(child: _DetailPanel(entry: _selected!, accent: accent)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.6,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _NodeCard(
                    entry: _nodes[i],
                    accent: accent,
                    isSelected: _selected?.id == _nodes[i].id,
                    onTap: () => setState(() =>
                        _selected = _selected?.id == _nodes[i].id ? null : _nodes[i]),
                  ),
                  childCount: _nodes.length,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Daten: Wikidata (CC0) · ${_nodes.length} Entitäten',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NodeCard extends StatelessWidget {
  final WikidataEntry entry;
  final Color accent;
  final bool isSelected;
  final VoidCallback onTap;

  const _NodeCard({
    required this.entry,
    required this.accent,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? accent : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [BoxShadow(color: accent.withValues(alpha: 0.6), blurRadius: 6)]
                        : null,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    entry.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                entry.description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                  height: 1.4,
                ),
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

class _DetailPanel extends StatelessWidget {
  final WikidataEntry entry;
  final Color accent;

  const _DetailPanel({required this.entry, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withValues(alpha: 0.12), accent.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hub_rounded, color: accent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.open_in_new_rounded, size: 18, color: Colors.white54),
                onPressed: () => launchUrl(
                  Uri.parse('https://www.wikidata.org/wiki/${entry.id}'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ],
          ),
          if (entry.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              entry.description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'ID: ${entry.id} · Tippen zum Schließen',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
