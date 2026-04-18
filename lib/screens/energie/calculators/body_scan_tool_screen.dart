import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BodyScanToolScreen – 3 Tabs
//   Tab 0: Scan    (Symptome wählen → Chakra-Score berechnen)
//   Tab 1: Verlauf (vergangene Scans aus body_scan_results)
//   Tab 2: Info    (statisches Chakra-Lexikon)
// ─────────────────────────────────────────────────────────────────────────────

const _kPink = Color(0xFFE91E63);
const _kDarkBg = Color(0xFF0A0A0F);
const _kCardBg = Color(0xFF1A1A2E);
const _kBorder = Color(0xFF2A2A4E);

final _db = Supabase.instance.client;

const _categories = [
  ('alle', 'Alle'),
  ('körperlich', '🫀 Körper'),
  ('emotional', '💗 Gefühle'),
  ('mental', '🧠 Gedanken'),
  ('spirituell', '✨ Spirit'),
];

class BodyScanToolScreen extends StatefulWidget {
  const BodyScanToolScreen({super.key});

  @override
  State<BodyScanToolScreen> createState() => _BodyScanToolScreenState();
}

class _BodyScanToolScreenState extends State<BodyScanToolScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kDarkBg,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        title: const Text('🧘 Körperscan',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: _kPink,
          labelColor: _kPink,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.sensors), text: 'Scan'),
            Tab(icon: Icon(Icons.history), text: 'Verlauf'),
            Tab(icon: Icon(Icons.info_outline), text: 'Chakren'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _ScanTab(),
          _HistoryTab(),
          _InfoTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 0: Scan  (Phase 7.2b/c/d füllen diesen Stub)
// ─────────────────────────────────────────────────────────────────────────────

class _ScanTab extends StatefulWidget {
  const _ScanTab();
  @override
  State<_ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<_ScanTab> {
  List<Map<String, dynamic>> _symptoms = [];
  final Set<String> _selected = {};
  String _filterCategory = 'alle';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await _db
          .from('chakra_symptoms')
          .select()
          .order('chakra_number')
          .order('sort_order');
      if (!mounted) return;
      setState(() {
        _symptoms = List<Map<String, dynamic>>.from(rows);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_symptoms.isEmpty) {
      return const Center(
          child: Text('Keine Symptome geladen',
              style: TextStyle(color: Colors.white54)));
    }

    // Filter nach Kategorie
    final filtered = _filterCategory == 'alle'
        ? _symptoms
        : _symptoms
            .where((s) => s['symptom_category'] == _filterCategory)
            .toList();

    // Gruppieren nach Chakra
    final byChakra = <int, List<Map<String, dynamic>>>{};
    for (final s in filtered) {
      final n = s['chakra_number'] as int;
      byChakra.putIfAbsent(n, () => []).add(s);
    }
    final chakraKeys = byChakra.keys.toList()..sort();

    return Column(
      children: [
        // Filter-Chips
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: _categories.length,
            itemBuilder: (_, i) {
              final cat = _categories[i];
              final sel = _filterCategory == cat.$1;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat.$2,
                      style: TextStyle(
                          color: sel ? Colors.white : Colors.white54,
                          fontSize: 12)),
                  selected: sel,
                  selectedColor: _kPink,
                  backgroundColor: _kCardBg,
                  side: const BorderSide(color: _kBorder),
                  onSelected: (_) =>
                      setState(() => _filterCategory = cat.$1),
                ),
              );
            },
          ),
        ),
        // Selected-Counter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text('${_selected.length} Symptom(e) ausgewählt',
                  style:
                      const TextStyle(color: Colors.white54, fontSize: 12)),
              const Spacer(),
              if (_selected.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() => _selected.clear()),
                  child: const Text('Zurücksetzen',
                      style: TextStyle(color: _kPink, fontSize: 12)),
                ),
            ],
          ),
        ),
        // Symptom-Liste
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
            itemCount: chakraKeys.length,
            itemBuilder: (_, i) {
              final chakra = chakraKeys[i];
              final items = byChakra[chakra]!;
              final first = items.first;
              return Card(
                color: _kCardBg,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                      color: _parseColor(first['chakra_color'] as String?)
                          .withValues(alpha: 0.3)),
                ),
                child: Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    iconColor: Colors.white54,
                    collapsedIconColor: Colors.white54,
                    title: Row(children: [
                      Text(first['chakra_emoji'] as String? ?? '',
                          style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(first['chakra_name'] as String? ?? '',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ),
                      Text('${items.length}',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12)),
                    ]),
                    children: items.map((s) {
                      final id = s['id'] as String;
                      final sel = _selected.contains(id);
                      return CheckboxListTile(
                        dense: true,
                        value: sel,
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            _selected.add(id);
                          } else {
                            _selected.remove(id);
                          }
                        }),
                        activeColor: _kPink,
                        checkColor: Colors.white,
                        title: Text(s['symptom_text'] as String,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                        subtitle: Text(s['symptom_category'] as String,
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 10)),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _parseColor(String? hex) {
    if (hex == null) return Colors.white;
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1: Verlauf (Phase 7.2e füllt diesen Stub)
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Verlauf – Phase 7.2e',
          style: TextStyle(color: Colors.white38)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2: Info (Phase 7.2f füllt diesen Stub)
// ─────────────────────────────────────────────────────────────────────────────

class _InfoTab extends StatelessWidget {
  const _InfoTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Chakra-Info – Phase 7.2f',
          style: TextStyle(color: Colors.white38)),
    );
  }
}
